module stage_IF_ID (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_stall,
    input  logic        i_flush,

    input  logic [31:0] i_pc,
    input  logic [31:0] i_inst,

    output logic [31:0] o_pc,
    output logic [31:0] o_inst
);

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_pc   <= 32'b0;
            o_inst <= 32'b0;
			end
			else if (i_flush) begin
				o_pc   <= 32'b0;
				o_inst <= 32'b0;
			end
        else if (!i_stall) begin
            o_pc   <= i_pc;
            o_inst <= i_inst;
        end
    end

endmodule
