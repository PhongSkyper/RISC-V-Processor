
module brc (
    input  logic [31:0] i_rs1_data,   // rs1
    input  logic [31:0] i_rs2_data,   // rs2
    input  logic        i_br_un,      // 1: unsigned, 0: signed
    output logic        o_br_less,    // 1 if rs1 < rs2
    output logic        o_br_equal    // 1 if rs1 == rs2
);

    logic [31:0] sub_result;
    logic Cout, Overflow;

    Add_Sub_32bit subtractor (
        .A         (i_rs1_data),
        .B         (i_rs2_data),
        .Sel       (1'b1),          // subtraction
        .Y         (sub_result),
        .Carry_out (Cout),
        .overflow  (Overflow)
    );

    assign o_br_equal = (sub_result == 32'b0);

    always_comb begin
        if (i_br_un)
            o_br_less = ~Cout;                 // unsigned: use carry
        else
            o_br_less = sub_result[31] ^ Overflow; // signed: sign ^ overflow
    end

endmodule
