module logic_ops(
  input  logic [31:0] i_a,
  input  logic [31:0] i_b,
  output logic [31:0] o_and,
  output logic [31:0] o_or,
  output logic [31:0] o_xor
);
  assign o_and = i_a & i_b;
  assign o_or  = i_a | i_b;
  assign o_xor = i_a ^ i_b;
endmodule
