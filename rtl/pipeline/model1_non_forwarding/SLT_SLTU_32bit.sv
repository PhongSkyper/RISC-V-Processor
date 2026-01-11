module SLT_SLTU_32bit (
  input  wire [31:0] A,
  input  wire [31:0] B,
  input  wire        mode,   // 0: SLT signed, 1: SLTU unsigned
  output wire [31:0] Y // 1 âm, 0 dương
);
  wire [31:0] D;
  wire cout;
  wire ovf_dummy;
  Add_Sub_32bit u_sub (.A(A), .B(B), .Sel(1'b1), .Y(D), .Carry_out(cout), .overflow(ovf_dummy));
  wire signA = A[31];
  wire signB = B[31];
  wire signD = D[31];
  wire lt_signed = (signA ^ signB) ? signA : signD;
  wire lt_unsigned = ~cout;
  assign Y = (mode ? lt_unsigned : lt_signed) ? 32'd1 : 32'd0;
endmodule
 
