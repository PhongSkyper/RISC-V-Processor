module reg32 (
  input  logic        i_clk,
  input  logic        i_rstn,   // 0 -> clear tại posedge
  input  logic        i_en,
  input  logic [31:0] i_d,
  output logic [31:0] o_q
);
  always_ff @(posedge i_clk) begin
    if (!i_rstn)  o_q <= 32'd0;
    else if (i_en) o_q <= i_d;
  end
endmodule
