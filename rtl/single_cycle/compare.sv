// Comparator using subtractor flags
module compare(
  input  logic [31:0] i_a,
  input  logic [31:0] i_b,
  input  logic [31:0] i_sub_sum,  // A - B
  input  logic        i_cout,     // from A - B adder (i_sub=1)
  input  logic        i_ovf,      // from A - B adder (i_sub=1)
  output logic        o_less_s,   // signed A < B
  output logic        o_less_u,   // unsigned A < B
  output logic        o_equal
);
  assign o_less_u = ~i_cout;                  // borrow
  assign o_less_s = i_sub_sum[31] ^ i_ovf;    // sign xor overflow
  assign o_equal  = ~(|(i_a ^ i_b));
endmodule
