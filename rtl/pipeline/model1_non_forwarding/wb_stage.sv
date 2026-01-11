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

    // Select writeback source
    always_comb begin
        case (i_wb_sel)
            2'b00:   o_wb_data = i_alu;               // ALU result
            2'b01:   o_wb_data = i_mem;               // Load data
            2'b10:   o_wb_data = i_pc + 32'd4;        // PC + 4 (JAL/JALR)
            default: o_wb_data = 32'b0;
        endcase
    end

    assign o_rd    = i_inst[11:7];
    assign o_wb_en = i_regwen;

endmodule
