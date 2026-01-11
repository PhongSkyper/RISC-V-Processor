

module Add_Sub_32bit (
    input  logic [31:0] A,          // operand A
    input  logic [31:0] B,          // operand B
    input  logic        Sel,        // 0: ADD, 1: SUB
    output logic [31:0] Y,          // result
    output logic        Carry_out,  // carry-out
    output logic        overflow    // overflow flag
);
    logic [31:0] B_eff;
    logic [32:0] c;
    // ----------------------------------------------------------
    assign B_eff  = B ^ {32{Sel}};
    assign c[0]   = Sel;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : GEN_FA
            full_adder fa_i (
                .a   (A[i]),
                .b   (B_eff[i]),
                .cin (c[i]),
                .s   (Y[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign Carry_out = c[32];
    assign overflow = (!Sel && (A[31] == B[31]) && (Y[31] != A[31])) ||
                      ( Sel && (A[31] != B[31]) && (Y[31] != A[31]));

endmodule 
