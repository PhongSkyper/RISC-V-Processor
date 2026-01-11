module stage_23 (
    input  logic        i_clk,
    input  logic        i_reset, // active-low
    input  logic        i_flush,
    input  logic        i_stall,

    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,
    input  logic [31:0] i_rs1,
    input  logic [31:0] i_rs2,
    input  logic [31:0] i_imm,
    input  logic [3:0]  i_alu_sel,
    input  logic        i_bru,
    input  logic        i_memrw,
    input  logic [2:0]  i_load_type,
    input  logic [1:0]  i_wb_sel,
    input  logic        i_regwen,
    input  logic        i_asel,
    input  logic        i_bsel,

    output logic [31:0] o_pc,
    output logic [31:0] o_inst,
    output logic [31:0] o_rs1,
    output logic [31:0] o_rs2,
    output logic [31:0] o_imm,
    output logic [3:0]  o_alu_sel,
    output logic        o_bru,
    output logic        o_memrw,
    output logic [2:0]  o_load_type,
    output logic [1:0]  o_wb_sel,
    output logic        o_regwen,
    output logic        o_asel,
    output logic        o_bsel
);
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc         <= 32'b0;
            o_inst       <= 32'b0;
            o_rs1        <= 32'b0;
            o_rs2        <= 32'b0;
            o_imm        <= 32'b0;
            o_alu_sel    <= 4'b0;
            o_bru        <= 1'b0;
            o_memrw      <= 1'b0;
            o_load_type  <= 3'b0;
            o_wb_sel     <= 2'b0;
            o_regwen     <= 1'b0;
            o_asel       <= 1'b0;
            o_bsel       <= 1'b0;
		  end else if (i_flush) begin
            o_pc         <= 32'b0;
            o_inst       <= 32'b0;
            o_rs1        <= 32'b0;
            o_rs2        <= 32'b0;
            o_imm        <= 32'b0;
            o_alu_sel    <= 4'b0;
            o_bru        <= 1'b0;
            o_memrw      <= 1'b0;
            o_load_type  <= 3'b0;
            o_wb_sel     <= 2'b0;
            o_regwen     <= 1'b0;
            o_asel       <= 1'b0;
            o_bsel       <= 1'b0;
        end else if (!i_stall) begin
            o_pc         <= i_pc;
            o_inst       <= i_inst;
            o_rs1        <= i_rs1;
            o_rs2        <= i_rs2;
            o_imm        <= i_imm;
            o_alu_sel    <= i_alu_sel;
            o_bru        <= i_bru;
            o_memrw      <= i_memrw;
            o_load_type  <= i_load_type;
            o_wb_sel     <= i_wb_sel;
            o_regwen     <= i_regwen;
            o_asel       <= i_asel;
            o_bsel       <= i_bsel;
        end
    end
endmodule
