module ALU (

    input  logic [31:0] i_op_a,

    input  logic [31:0] i_op_b,

    input  logic [3:0]  i_alu_op,

    output logic [31:0] o_alu_data

);

    logic [31:0] add_out, sub_out;
    logic [31:0] sll_out, srl_out, sra_out, slt_out, sltu_out;

    Add_Sub_32bit u_add (
  .A(i_op_a),
  .B(i_op_b),
  .Sel(1'b0), // ADD
  .Y(add_out),
  .Carry_out(),
  .overflow()
);

Add_Sub_32bit u_sub (
  .A(i_op_a),
  .B(i_op_b),
  .Sel(1'b1), // SUB
  .Y(sub_out),
  .Carry_out(),
  .overflow()
);

    SLL_SRL u_sll (.data_in(i_op_a), .shift_amt(i_op_b[4:0]), .dir(1'b0), .data_out(sll_out));

    SLL_SRL u_srl (.data_in(i_op_a), .shift_amt(i_op_b[4:0]), .dir(1'b1), .data_out(srl_out));

    SRA u_sra (.data_in(i_op_a), .shift_amt(i_op_b[4:0]), .data_out(sra_out));

    SLT_SLTU_32bit u_slt (.A(i_op_a), .B(i_op_b), .mode(1'b0), .Y(slt_out));

    SLT_SLTU_32bit u_sltu(.A(i_op_a), .B(i_op_b), .mode(1'b1), .Y(sltu_out));

    always_comb begin

        case (i_alu_op)

            4'b0000: o_alu_data = add_out;

            4'b0001: o_alu_data = sub_out;

            4'b0010: o_alu_data = slt_out;

            4'b0011: o_alu_data = sltu_out;

            4'b0100: o_alu_data = i_op_a ^ i_op_b;

            4'b0101: o_alu_data = i_op_a | i_op_b;

            4'b0110: o_alu_data = i_op_a & i_op_b;

            4'b0111: o_alu_data = sll_out;

            4'b1000: o_alu_data = srl_out;

            4'b1001: o_alu_data = sra_out;

            4'b1010: o_alu_data = i_op_a;

            4'b1011: o_alu_data = i_op_b;

            default: o_alu_data = 32'b0;

        endcase

    end



endmodule

