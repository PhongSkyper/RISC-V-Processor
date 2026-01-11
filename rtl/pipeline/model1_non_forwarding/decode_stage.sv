module decode_stage (
    input  logic        i_clk,
    input  logic        i_rst,

    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,

    input  logic [31:0] i_wb_data,
    input  logic [4:0]  i_rd_wb,
    input  logic        i_wb_en,

    output logic [31:0]  o_pc,
    output logic [31:0] o_inst,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data,
    output logic [31:0] o_imm,
    output logic [3:0]  o_alu_sel,
    output logic        o_bru,
    output logic        o_memrw,
    output logic [2:0]  o_load_type,
    output logic [1:0]  o_store_type,
    output logic [1:0]  o_wb_sel,
    output logic        o_regwen,
    output logic        o_asel,
    output logic        o_bsel,

    output logic [4:0]  o_rs1,
    output logic [4:0]  o_rs2,
    output logic        o_insn_vld,
    output logic        o_is_ctrl
);

    logic [2:0] imm_sel;

    regfile registers (
        .clk    (i_clk),
        .reset  (i_rst),
        .rs1    (o_rs1),
        .rs2    (o_rs2),
        .rsW    (i_rd_wb),
        .data_W (i_wb_data),
        .regWEn (i_wb_en),
        .data_1 (o_rs1_data),
        .data_2 (o_rs2_data)
    );

    Imm_Gen ig (
        .instr    (i_inst),
        .Imm_Sel  (imm_sel),
        .imm_out  (o_imm)
    );

    logic pc_sel_unused;
    control_unit cu (
        .instr       (i_inst),
        .br_less     (1'b0),
        .br_equal    (1'b0),
        .pc_sel      (pc_sel_unused),
        .i_rd_wren   (o_regwen),
        .BrUn        (o_bru),
        .opa_sel     (o_asel),
        .opb_sel     (o_bsel),
        .i_alu_op    (o_alu_sel),
        .MemRW       (o_memrw),
        .wb_sel      (o_wb_sel),
        .load_type   (o_load_type),
        .store_type  (o_store_type),
        .Imm_Sel     (imm_sel),
        .insn_vld    (o_insn_vld)
    );

    assign o_rs1 = i_inst[19:15];
    assign o_rs2 = i_inst[24:20];

    assign o_pc   = i_pc;
    assign o_inst = i_inst;

    assign o_is_ctrl =
        (i_inst[6:0] == 7'b1100011) ||
        (i_inst[6:0] == 7'b1101111) ||
        (i_inst[6:0] == 7'b1100111);

endmodule
