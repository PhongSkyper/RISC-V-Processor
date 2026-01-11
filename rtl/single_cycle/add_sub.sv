// 32-bit ripple-carry adder/subtractor (A + B) or (A - B)
module add_sub(
  input  logic [31:0] i_a,
  input  logic [31:0] i_b,
  input  logic        i_sub,     // 1: A - B, 0: A + B
  output logic [31:0] o_sum,     // result
  output logic        o_cout,    // carry out (for A+B) / ~borrow (for A-B)
  output logic        o_ovf      // signed overflow flag
);
  logic [31:0] b_eff;
  logic        cin;
  assign b_eff = i_b ^ {32{i_sub}}; // ~B when subtract
  assign cin   = i_sub;             // +1 in subtract

  logic [31:0] carry;
  genvar k;
  generate
    for (k = 0; k < 32; k++) begin : GEN_FA
      if (k == 0) begin
        full_adder u_fa0(
          .i_a(i_a[k]), .i_b(b_eff[k]), .i_cin(cin),
          .o_sum(o_sum[k]), .o_cout(carry[k])
        );
      end else begin
        full_adder u_faN(
          .i_a(i_a[k]), .i_b(b_eff[k]), .i_cin(carry[k-1]),
          .o_sum(o_sum[k]), .o_cout(carry[k])
        );
      end
    end
  endgenerate
  assign o_cout = carry[31];
  // overflow = carry into MSB XOR carry out of MSB
  assign o_ovf  = carry[30] ^ carry[31];
endmodule
