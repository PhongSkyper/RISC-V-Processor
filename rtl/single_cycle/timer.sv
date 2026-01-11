module timer #(parameter WIDTH=32)(
  input  logic             i_clk,
  input  logic             i_rstn,
  input  logic             i_en,
  output logic [WIDTH-1:0] o_value
);
  logic [31:0] w_inc;
  add_sub u_tim_inc(.i_a(o_value), .i_b(32'd1), .i_sub(1'b0), .o_sum(w_inc), .o_cout(), .o_ovf());
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) o_value <= '0;
    else if (i_en) o_value <= w_inc[WIDTH-1:0];
  end
endmodule
