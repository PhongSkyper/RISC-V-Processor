module branch_taken (
    input  logic        BrLt_MEM,
    input  logic        BrEq_MEM,
    input  logic [31:0] inst_MEM,

    output logic        PCSel,
    output logic        flush
);

logic [6:0] opcode;
logic [2:0] funct3;

assign opcode = inst_MEM[6:0];
assign funct3 = inst_MEM[14:12];

always_comb begin
    PCSel = 0;
    flush = 0;

    case (opcode)
        7'b1100011: begin
            case (funct3)
                3'b000: PCSel = BrEq_MEM;    // BEQ
                3'b001: PCSel = ~BrEq_MEM;   // BNE
                3'b100: PCSel = BrLt_MEM;    // BLT
                3'b101: PCSel = ~BrLt_MEM;   // BGE
                3'b110: PCSel = BrLt_MEM;    // BLTU
                3'b111: PCSel = ~BrLt_MEM;   // BGEU
            endcase
            flush = PCSel;   // chỉ flush khi quyết định nhánh;
            PCSel =0;
        end

        // ----------- JAL / JALR -----------
        7'b1101111,
        7'b1100111: begin
            PCSel = 1;
            flush = 1;
        end
    endcase
end

endmodule
