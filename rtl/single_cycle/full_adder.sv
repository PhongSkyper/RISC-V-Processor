// 1-bit Full Adder (no '+' on datapath)
module full_adder(
  input  logic i_a,
  input  logic i_b,
  input  logic i_cin,
  output logic o_sum,
  output logic o_cout
);
  // Sum/carry via boolean equations
  assign o_sum  = i_a ^ i_b ^ i_cin;
  assign o_cout = (i_a & i_b) | (i_a & i_cin) | (i_b & i_cin);
endmodule
