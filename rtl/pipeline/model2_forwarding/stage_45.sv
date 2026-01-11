module stage_45 (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_flush,

    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,
    input  logic [31:0] i_alu,
    input  logic [31:0] i_mem,
    input  logic [1:0]  i_wb_sel,
    input  logic        i_regwen,

    output logic [31:0] o_pc,
    output logic [31:0] o_inst,
    output logic [31:0] o_alu,
    output logic [31:0] o_mem,
    output logic [1:0]  o_wb_sel,
    output logic        o_regwen
);
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc     <= 32'b0;
            o_inst   <= 32'b0;
            o_alu    <= 32'b0;
            o_mem    <= 32'b0;
            o_wb_sel <= 2'b0;
            o_regwen <= 1'b0;
		  end else if (i_flush) begin
            o_pc     <= 32'b0;
            o_inst   <= 32'b0;
            o_alu    <= 32'b0;
            o_mem    <= 32'b0;
            o_wb_sel <= 2'b0;
            o_regwen <= 1'b0;
        end else begin
            o_pc     <= i_pc;
            o_inst   <= i_inst;
            o_alu    <= i_alu;
            o_mem    <= i_mem;
            o_wb_sel <= i_wb_sel;
            o_regwen <= i_regwen;
        end
    end
endmodule
