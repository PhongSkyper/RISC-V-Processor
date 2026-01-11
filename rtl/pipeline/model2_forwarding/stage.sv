module fetch_stage (
    input  logic        i_clk,
    input  logic        i_reset, // active-low
    input  logic        i_pc_sel,
    input  logic [31:0] i_pc_target,
    input  logic        i_stall,
    input  logic        i_flush,
    output logic [31:0] o_pc,
    output logic [31:0] o_inst
);

    logic [31:0] pc_q;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;
    logic [31:0] inst_raw;

    // Next PC selection between sequential and branch/jump target
    Mux2to1 pc_mux (
        .in0(pc_plus4),
        .in1(i_pc_target),
        .sel(i_pc_sel),
        .out(pc_next)
    );

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            pc_q <= 32'd0;
        end else if (!i_stall) begin
            pc_q <= {pc_next[31:2], 2'b00};
        end
    end

        // Increment PC by 4 (RISC-V aligned fetch)
    add_sub_32bit pc_add4 (
        .a         (pc_q),
        .b         (32'd4),
        .add_sub   (1'b0),     // ADD
        .y         (pc_plus4),
        .carry_out (),
        .overflow  ()
    );


   imem u_imem (
    .clk   (i_clk),
    .we    (4'b0000),
    .addr  (pc_q),
    .wdata (32'b0),
    .rdata (inst_raw)
);


    assign o_pc   = pc_q;
    assign o_inst = (i_flush) ? 32'h00000013 : inst_raw; // inject NOP on flush

endmodule

module decode_stage (
    input  logic        i_clk,
    input  logic        i_reset,

    // IF/ID pipeline outputs
    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,

    // Writeback feedback into RegFile
    input  logic [31:0] i_wb_data,
    input  logic [4:0]  i_rd_wb,
    input  logic        i_wb_en,

    // Outputs into ID/EX pipeline register
    output logic [31:0] o_pc,
    output logic [31:0] o_inst,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data,
    output logic [31:0] o_imm,
    output logic [3:0]  o_alu_sel,
    output logic        o_bru,
    output logic        o_memrw,
    output logic [2:0]  o_load_type,
    output logic [1:0]  o_wb_sel,
    output logic        o_regwen,
    output logic        o_asel,
    output logic        o_bsel,

    // For hazard/forward units
    output logic [4:0]  o_rs1,
    output logic [4:0]  o_rs2,
    output logic        o_insn_vld,
    output logic        o_is_ctrl
);

    logic [2:0] imm_sel;

    // Register file reads
    regfile rf (
        .clk     (i_clk),
        .i_reset (i_reset),
        .rs1     (o_rs1),
        .rs2     (o_rs2),
        .rsW     (i_rd_wb),
        .data_W  (i_wb_data),
        .regWEn  (i_wb_en),
        .data_1  (o_rs1_data),
        .data_2  (o_rs2_data)
    );

    // Immediate generator
    Imm_Gen ig (
        .instr    (i_inst),
        .Imm_Sel  (imm_sel),
        .imm_out  (o_imm)
    );

    // Control logic
    control_unit u_ctl (
        .instr      (i_inst),
        .Imm_Sel    (imm_sel),
        .ALU_sel    (o_alu_sel),
        .regWEn     (o_regwen),
        .BrUn       (o_bru),
        .opb_sel    (o_bsel),
        .opa_sel    (o_asel),
        .MemRW      (o_memrw),
        .WBSel      (o_wb_sel),
        .load_type  (o_load_type),
        .store_type (),
        .insn_vld   (o_insn_vld)
    );

    // Decode-time helpers
    assign o_rs1 = i_inst[19:15];
    assign o_rs2 = i_inst[24:20];

    assign o_pc   = i_pc;
    assign o_inst = i_inst;

    // Identify control-flow instructions (for debug/trace)
    assign o_is_ctrl =
            (i_inst[6:0] == 7'b1100011) || // Branch
            (i_inst[6:0] == 7'b1101111) || // JAL
            (i_inst[6:0] == 7'b1100111);   // JALR

endmodule

module mem_stage (
  input  logic        i_clk,
  input  logic        i_reset,
  input  logic [31:0] i_addr,
  input  logic [31:0] i_rs2,
  input  logic        i_memrw,
  input  logic [2:0]  i_load_type,
  input  logic [31:0] i_io_sw,
  input  logic [31:0] i_io_keys,
  input  logic [31:0] i_pc,

  output logic [31:0] o_ld_data,
  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_lcd,
  output logic [31:0] o_io_ledg,
  output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
  output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7
);

  logic [1:0] lsu_size;
  logic       lsu_unsigned;

  always_comb begin
    unique case (i_load_type)
      3'b000: begin lsu_size = 2'b00; lsu_unsigned = 1'b0; end
      3'b001: begin lsu_size = 2'b01; lsu_unsigned = 1'b0; end
      3'b010: begin lsu_size = 2'b10; lsu_unsigned = 1'b0; end
      3'b100: begin lsu_size = 2'b00; lsu_unsigned = 1'b1; end
      3'b101: begin lsu_size = 2'b01; lsu_unsigned = 1'b1; end
      default:begin lsu_size = 2'b10; lsu_unsigned = 1'b0; end
    endcase
  end

  lsu u_lsu (
    .i_clk         (i_clk),
    .i_reset       (i_reset),
    .i_lsu_addr    (i_addr),
    .i_st_data     (i_rs2),
    .i_lsu_wren    (i_memrw),
    .i_lsu_size    (lsu_size),
    .i_lsu_unsigned(lsu_unsigned),
    .i_io_sw       (i_io_sw),
    .o_ld_data     (o_ld_data),
    .o_io_ledr     (o_io_ledr),
    .o_io_ledg     (o_io_ledg),
    .o_io_lcd      (o_io_lcd),
    .o_io_hex0     (o_io_hex0),
    .o_io_hex1     (o_io_hex1),
    .o_io_hex2     (o_io_hex2),
    .o_io_hex3     (o_io_hex3),
    .o_io_hex4     (o_io_hex4),
    .o_io_hex5     (o_io_hex5),
    .o_io_hex6     (o_io_hex6),
    .o_io_hex7     (o_io_hex7)
  );
endmodule


module execute_stage (
    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,
    input  logic [31:0] i_rs1,
    input  logic [31:0] i_rs2,
    input  logic [31:0] i_imm,
    input  logic        i_asel,
    input  logic        i_bsel,
    input  logic        i_bru,
    input  logic [3:0]  i_alu_sel,
    input  logic [1:0]  i_fwdA_sel, 
    input  logic [1:0]  i_fwdB_sel,
    input  logic [31:0] i_alu_mem,
    input  logic [31:0] i_wb_data,

    output logic [31:0] o_alu,
    output logic [31:0] o_rs2_fwd,
    output logic [31:0] o_pc_target,
    output logic        o_pc_sel
);

    logic [31:0] forwardA, forwardB;
    logic [31:0] opA, opB;
    logic [31:0] pc_plus_imm, jalr_sum;
    logic        BrEq, BrLT;
    logic [2:0]  funct3;
    logic        is_branch, is_jal, is_jalr;
    logic        branch_condition_met;

    assign funct3    = i_inst[14:12];
    assign is_branch = (i_inst[6:0] == 7'b1100011);
    assign is_jal    = (i_inst[6:0] == 7'b1101111);
    assign is_jalr   = (i_inst[6:0] == 7'b1100111);

    always_comb begin
        case (i_fwdA_sel)
            2'b10:   forwardA = i_alu_mem;
            2'b01:   forwardA = i_wb_data;
            default: forwardA = i_rs1;
        endcase
    end

    always_comb begin
        case (i_fwdB_sel)
            2'b10:   forwardB = i_alu_mem;
            2'b01:   forwardB = i_wb_data;
            default: forwardB = i_rs2;
        endcase
    end

    assign opA = (i_asel) ? i_pc : forwardA;
    assign opB = (i_bsel) ? i_imm : forwardB;

        alu alu_instance (
        .i_op_a     (opA),
        .i_op_b     (opB),
        .i_alu_op   (i_alu_sel),
        .o_alu_data (o_alu)
    );


    brc brc_instance (
        .i_rs1_data (forwardA),
        .i_rs2_data (forwardB),
        .i_br_un    (i_bru),
        .o_br_less  (BrLT),
        .o_br_equal (BrEq)
    );

    add_sub_32bit adder_pc_imm (
        .a(i_pc),
        .b(i_imm),
        .add_sub(1'b0),
        .y(pc_plus_imm),
        .carry_out(),
        .overflow()
    );

    add_sub_32bit adder_jalr (
        .a(forwardA),
        .b(i_imm),
        .add_sub(1'b0),
        .y(jalr_sum),
        .carry_out(),
        .overflow()
    );

    always_comb begin
        case (funct3)
            3'b000:  branch_condition_met = BrEq;
            3'b001:  branch_condition_met = ~BrEq;
            3'b100:  branch_condition_met = BrLT;
            3'b101:  branch_condition_met = ~BrLT;
            3'b110:  branch_condition_met = BrLT;
            3'b111:  branch_condition_met = ~BrLT;
            default: branch_condition_met = 1'b0;
        endcase
    end

    assign o_pc_sel = is_jal || is_jalr || (is_branch && branch_condition_met);

    always_comb begin
        if (is_jalr) begin
            o_pc_target = {jalr_sum[31:2], 2'b00};
        end else begin
            o_pc_target = {pc_plus_imm[31:2], 2'b00};
        end
    end

    assign o_rs2_fwd = forwardB;

endmodule

module wb_stage (
    input  logic [31:0] i_pc,
    input  logic [31:0] i_alu,
    input  logic [31:0] i_mem,
    input  logic [31:0] i_inst,
    input  logic [1:0]  i_wb_sel,
    input  logic        i_regwen,

    output logic [31:0] o_wb_data,
    output logic [4:0]  o_rd,
    output logic        o_wb_en
);

    logic [31:0] pc_plus4;

    // PC + 4 dùng add_sub_32bit thay vì toán tử +
    add_sub_32bit wb_pc_add4 (
        .a        (i_pc),
        .b        (32'd4),
        .add_sub  (1'b0),
        .y        (pc_plus4),
        .carry_out(),
        .overflow()
    );

    // Select writeback source
    always_comb begin
        unique case (i_wb_sel)
            2'b00:   o_wb_data = i_alu;    // ALU result
            2'b01:   o_wb_data = i_mem;    // Load data
            2'b10:   o_wb_data = pc_plus4; // PC + 4 (JAL/JALR)
            default: o_wb_data = 32'b0;
        endcase
    end

    assign o_rd    = i_inst[11:7];
    assign o_wb_en = i_regwen;

endmodule
