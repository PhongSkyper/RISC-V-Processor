module pipelined2 (
    input  logic        i_clk,
    input  logic        i_reset,   // active-low from testbench
    input  logic [31:0] i_io_sw,
    input  logic [31:0] i_io_keys,

    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [31:0] o_io_lcd,
    output logic [6:0]  o_io_hex0,
    output logic [6:0]  o_io_hex1,
    output logic [6:0]  o_io_hex2,
    output logic [6:0]  o_io_hex3,
    output logic [6:0]  o_io_hex4,
    output logic [6:0]  o_io_hex5,
    output logic [6:0]  o_io_hex6,
    output logic [6:0]  o_io_hex7,

    output logic        o_ctrl,
    output logic        o_mispred,
    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld
);

    // IF / ID wires
    logic [31:0] pc_if, inst_if;
    logic [31:0] pc_id, inst_id;

    // Decode outputs
    logic [31:0] rs1_id_data, rs2_id_data, imm_id;
    logic [31:0] pc_id_dec, inst_id_dec;
    logic [3:0]  alu_sel_id;
    logic        bru_id, memrw_id, asel_id, bsel_id, regwen_id;
    logic [2:0]  load_type_id;
    logic [1:0]  wb_sel_id;
    logic [4:0]  rs1_id, rs2_id;
    logic        insn_vld_id, is_ctrl_id;

    // ID / EX wires
    logic [31:0] pc_ex, inst_ex, rs1_ex, rs2_ex, imm_ex;
    logic [3:0]  alu_sel_ex;
    logic        bru_ex, memrw_ex, asel_ex, bsel_ex, regwen_ex;
    logic [2:0]  load_type_ex;
    logic [1:0]  wb_sel_ex;

    // Execute outputs
    logic [31:0] alu_ex;
    logic [31:0] rs2_fwd_ex;
    logic [31:0] pc_target_ex;
    logic        pc_sel_ex;

    // EX / MEM wires
    logic [31:0] pc_mem, inst_mem, alu_mem, rs2_mem;
    logic        memrw_mem;
    logic [2:0]  load_type_mem;
    logic [1:0]  wb_sel_mem;
    logic        regwen_mem;

    // MEM outputs
    logic [31:0] mem_data_mem;

    // MEM / WB wires
    logic [31:0] pc_wb, inst_wb, alu_wb, mem_wb;
    logic [1:0]  wb_sel_wb;
    logic        regwen_wb;

    // WB outputs
    logic [31:0] wb_data;
    logic [4:0]  rd_wb;
    logic        wb_en;

    // Forward/hazard
    logic [1:0] forwardA_sel, forwardB_sel;
    logic       id_ex_flush;
    logic       pc_en, if_id_en;

    logic flush_branch;
    logic flush_branch_only;  // asserted only for taken branches (not JAL/JALR)
    logic flush_id_ex_comb;
    logic stall_if, stall_id;

  
    assign flush_branch     = pc_sel_ex;
    // Flush ID/EX khi load-use hoặc khi branch/jump được lấy (xóa lệnh trên đường sai).
    assign flush_id_ex_comb = flush_branch | id_ex_flush;
    assign stall_if       = ~pc_en;
    assign stall_id       = ~if_id_en;

    // ------------------ IF stage ------------------
    fetch_stage IFU (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_pc_sel   (pc_sel_ex),
        .i_pc_target(pc_target_ex),
        .i_stall    (stall_if),
        .i_flush    (flush_branch),
        .o_pc       (pc_if),
        .o_inst     (inst_if)
    );

    // ------------------ IF/ID ------------------
    stage_12 STAGE12 (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        .i_flush (flush_branch),
        .i_stall (stall_id),
        .i_pc    (pc_if),
        .i_inst  (inst_if),
        .o_pc    (pc_id),
        .o_inst  (inst_id)
    );

    // ------------------ ID stage ------------------
    decode_stage IDU (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_pc      (pc_id),
        .i_inst    (inst_id),
        .i_wb_data (wb_data),
        .i_rd_wb   (rd_wb),
        .i_wb_en   (wb_en),
        .o_pc      (pc_id_dec),
        .o_inst    (inst_id_dec),
        .o_rs1_data(rs1_id_data),
        .o_rs2_data(rs2_id_data),
        .o_imm     (imm_id),
        .o_alu_sel (alu_sel_id),
        .o_bru     (bru_id),
        .o_memrw   (memrw_id),
        .o_load_type(load_type_id),
        .o_wb_sel  (wb_sel_id),
        .o_regwen  (regwen_id),
        .o_asel    (asel_id),
        .o_bsel    (bsel_id),
        .o_rs1     (rs1_id),
        .o_rs2     (rs2_id),
        .o_insn_vld(insn_vld_id),
        .o_is_ctrl (is_ctrl_id)
    );

    // ------------------ ID/EX ------------------
    stage_23 STAGE23 (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_flush    (flush_id_ex_comb),
        .i_stall    (1'b0),
        .i_pc       (pc_id_dec),
        .i_inst     (inst_id_dec),
        .i_rs1      (rs1_id_data),
        .i_rs2      (rs2_id_data),
        .i_imm      (imm_id),
        .i_alu_sel  (alu_sel_id),
        .i_bru      (bru_id),
        .i_memrw    (memrw_id),
        .i_load_type(load_type_id),
        .i_wb_sel   (wb_sel_id),
        .i_regwen   (regwen_id),
        .i_asel     (asel_id),
        .i_bsel     (bsel_id),
        .o_pc       (pc_ex),
        .o_inst     (inst_ex),
        .o_rs1      (rs1_ex),
        .o_rs2      (rs2_ex),
        .o_imm      (imm_ex),
        .o_alu_sel  (alu_sel_ex),
        .o_bru      (bru_ex),
        .o_memrw    (memrw_ex),
        .o_load_type(load_type_ex),
        .o_wb_sel   (wb_sel_ex),
        .o_regwen   (regwen_ex),
        .o_asel     (asel_ex),
        .o_bsel     (bsel_ex)
    );

    // ------------------ EX stage ------------------
    execute_stage EXU (
        .i_pc        (pc_ex),
        .i_inst      (inst_ex),
        .i_rs1       (rs1_ex),
        .i_rs2       (rs2_ex),
        .i_imm       (imm_ex),
        .i_asel      (asel_ex),
        .i_bsel      (bsel_ex),
        .i_bru       (bru_ex),
        .i_alu_sel   (alu_sel_ex),
        .i_fwdA_sel  (forwardA_sel),
        .i_fwdB_sel  (forwardB_sel),
        .i_alu_mem   (alu_mem),
        .i_wb_data   (wb_data),
        .o_alu       (alu_ex),
        .o_rs2_fwd   (rs2_fwd_ex),
        .o_pc_target (pc_target_ex),
        .o_pc_sel    (pc_sel_ex)
    );

    // ------------------ EX/MEM ------------------
    // Chỉ đánh dấu     // Mispred: static not-taken, asserted only when a branch is taken.
    assign flush_branch_only = flush_branch && (inst_ex[6:0] == 7'b1100011);

    stage_34 STAGE34 (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_flush    (1'b0), // không flush chính lệnh branch đang ở EX/MEM
        .i_pc       (pc_ex),
        .i_inst     (inst_ex),
        .i_alu      (alu_ex),
        .i_rs2      (rs2_fwd_ex),
        .i_memrw    (memrw_ex),
        .i_load_type(load_type_ex),
        .i_wb_sel   (wb_sel_ex),
        .i_regwen   (regwen_ex),
        .o_pc       (pc_mem),
        .o_inst     (inst_mem),
        .o_alu      (alu_mem),
        .o_rs2      (rs2_mem),
        .o_memrw    (memrw_mem),
        .o_load_type(load_type_mem),
        .o_wb_sel   (wb_sel_mem),
        .o_regwen   (regwen_mem)
    );

    // ------------------ MEM stage ------------------
    mem_stage MEMU (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_addr    (alu_mem),
        .i_rs2     (rs2_mem),
        .i_memrw   (memrw_mem),
        .i_load_type(load_type_mem),
        .i_io_sw   (i_io_sw),
        .i_io_keys (i_io_keys),
        .i_pc      (pc_mem),
        .o_ld_data (mem_data_mem),
        .o_io_ledr (o_io_ledr),
        .o_io_ledg (o_io_ledg),
        .o_io_hex0 (o_io_hex0),
        .o_io_hex1 (o_io_hex1),
        .o_io_hex2 (o_io_hex2),
        .o_io_hex3 (o_io_hex3),
        .o_io_hex4 (o_io_hex4),
        .o_io_hex5 (o_io_hex5),
        .o_io_hex6 (o_io_hex6),
        .o_io_hex7 (o_io_hex7),
        .o_io_lcd  (o_io_lcd)
    );

    // ------------------ MEM/WB ------------------
    stage_45 STAGE45 (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .i_flush  (1'b0), // không flush chính lệnh branch đang ở MEM/WB
        .i_pc     (pc_mem),
        .i_inst   (inst_mem),
        .i_alu    (alu_mem),
        .i_mem    (mem_data_mem),
        .i_wb_sel (wb_sel_mem),
        .i_regwen (regwen_mem),
        .o_pc     (pc_wb),
        .o_inst   (inst_wb),
        .o_alu    (alu_wb),
        .o_mem    (mem_wb),
        .o_wb_sel (wb_sel_wb),
        .o_regwen (regwen_wb)
    );

    // ------------------ WB stage ------------------
    wb_stage WBU (
        .i_pc     (pc_wb),
        .i_alu    (alu_wb),
        .i_mem    (mem_wb),
        .i_inst   (inst_wb),
        .i_wb_sel (wb_sel_wb),
        .i_regwen (regwen_wb),
        .o_wb_data(wb_data),
        .o_rd     (rd_wb),
        .o_wb_en  (wb_en)
    );

    // ------------------ Forward & Hazard ------------------
    forward_control FWD (
        .inst_EX_fwd(inst_ex),
        .rd_MEM     (inst_mem[11:7]),
        .rd_WB      (inst_wb[11:7]),
        .regWEn_MEM (regwen_mem),
        .regWEn_WB  (regwen_wb),
        .forwardA_EX(forwardA_sel),
        .forwardB_EX(forwardB_sel)
    );

    hazard_detection_load HZD (
        .inst_ID_i (inst_id),
        .inst_EX_i (inst_ex),
        .ID_EX_flush(id_ex_flush),
        .pc_en     (pc_en),
        .IF_ID_en  (if_id_en)
    );

    // ------------------ Debug ------------------
    // Xuất PC/valid ở giai đoạn WB (lệnh đã retire) để scoreboard không dừng sớm.
    assign o_pc_debug = pc_wb;
    assign o_insn_vld = (inst_wb != 32'b0); // bọt reset/flush không được tính
    assign o_ctrl     = (inst_wb[6:0] == 7'b1100011) || // Branch
                        (inst_wb[6:0] == 7'b1101111) || // JAL
                        (inst_wb[6:0] == 7'b1100111);   // JALR
    // Mispred: static not-taken, chỉ khi branch được lấy (tín hiệu từ EX).
    assign o_mispred = flush_branch_only;
    
endmodule
