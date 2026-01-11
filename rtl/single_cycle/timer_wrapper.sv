`include "params.vh"
module timer_wrapper(
  input  logic        i_clk,
  input  logic        i_rstn,
  input  logic        i_we,
  input  logic [31:0] i_addr,
  input  logic [31:0] i_wdata,
  output logic [31:0] o_rdata
);
  logic        r_en;
  logic [31:0] w_val;
  timer u_tim(.i_clk(i_clk), .i_rstn(i_rstn), .i_en(r_en), .o_value(w_val));
  
  logic sel_ctrl, sel_val;
  assign sel_ctrl = (i_addr == (`BASE_TIMER0 + 32'h0));
  assign sel_val  = (i_addr == (`BASE_TIMER0 + 32'h4));

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) r_en <= 1'b0;
    else if (i_we && sel_ctrl) r_en <= i_wdata[0];
  end

  always_comb begin
    if (sel_ctrl)      o_rdata = {31'd0, r_en};
    else if (sel_val)  o_rdata = w_val;
    else               o_rdata = 32'd0;
  end
endmodule
