//============= add_sub_32bit ==============
module add_sub_32bit (
    input  logic [31:0] a,          // operand A
    input  logic [31:0] b,          // operand B
    input  logic        add_sub,    // 0: ADD, 1: SUB
    output logic [31:0] y,          // result
    output logic        carry_out,  // carry-out
    output logic        overflow    // overflow flag
);
    logic [31:0] b_eff;
    logic [32:0] c;

    // B_eff = (add_sub ? ~b : b)
    assign b_eff  = b ^ {32{add_sub}};
    assign c[0]   = add_sub;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : GEN_FA
            full_adder fa_i (
                .a   (a[i]),
                .b   (b_eff[i]),
                .cin (c[i]),
                .s   (y[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign carry_out = c[32];
    assign overflow = (!add_sub && (a[31] == b[31]) && (y[31] != a[31])) ||
                      ( add_sub && (a[31] != b[31]) && (y[31] != a[31]));
endmodule

//================ alu ==================
module alu (
    input  logic [31:0] i_op_a,
    input  logic [31:0] i_op_b,
    input  logic [3:0]  i_alu_op,
    output logic [31:0] o_alu_data
);

    logic [31:0] add_out, sub_out;
    logic [31:0] slt_out, sltu_out;
    logic [31:0] sll_out, srl_out, sra_out;

    // ADD
    add_sub_32bit u_add (
        .a        (i_op_a),
        .b        (i_op_b),
        .add_sub  (1'b0), // ADD
        .y        (add_out),
        .carry_out(),
        .overflow ()
    );

    // SUB
    add_sub_32bit u_sub (
        .a        (i_op_a),
        .b        (i_op_b),
        .add_sub  (1'b1), // SUB
        .y        (sub_out),
        .carry_out(),
        .overflow ()
    );

    // SLT / SLTU
    compare u_slt (
        .i_a        (i_op_a),
        .i_b        (i_op_b),
        .i_unsigned (1'b0),   // signed
        .o_y        (slt_out)
    );

    compare u_sltu (
        .i_a        (i_op_a),
        .i_b        (i_op_b),
        .i_unsigned (1'b1),   // unsigned
        .o_y        (sltu_out)
    );

    // Shifter 3-trong-1
    shifter u_shifter (
        .i_data  (i_op_a),
        .i_shamt (i_op_b[4:0]),
        .o_sll   (sll_out),
        .o_srl   (srl_out),
        .o_sra   (sra_out)
    );

    always_comb begin
        unique case (i_alu_op)
            4'b0000: o_alu_data = add_out;   // ADD
            4'b0001: o_alu_data = sub_out;   // SUB
            4'b0010: o_alu_data = slt_out;   // SLT
            4'b0011: o_alu_data = sltu_out;  // SLTU
            4'b0100: o_alu_data = i_op_a ^ i_op_b;
            4'b0101: o_alu_data = i_op_a | i_op_b;
            4'b0110: o_alu_data = i_op_a & i_op_b;
            4'b0111: o_alu_data = sll_out;   // SLL
            4'b1000: o_alu_data = srl_out;   // SRL
            4'b1001: o_alu_data = sra_out;   // SRA
            4'b1010: o_alu_data = i_op_a;    // pass A
            4'b1011: o_alu_data = i_op_b;    // pass B / LUI path
            default: o_alu_data = 32'b0;
        endcase
    end
endmodule
