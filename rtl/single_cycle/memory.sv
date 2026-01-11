// memory.sv — synth-only (Cyclone II)
module memory #(
  parameter int unsigned BYTES = 2048
)(
  input  logic        i_clk,
  input  logic        i_we, i_re,
  input  logic [31:0] i_addr,
  input  logic [31:0] i_wdata,
  output logic [31:0] o_rdata_mem
);
  localparam int WORDS = BYTES/4;
  // (* ramstyle = "M4K" *)
  logic [31:0] mem [0:WORDS-1];

  // async read
  assign o_rdata_mem = i_re ? mem[i_addr[31:2]] : 32'd0;

  // sync write
  always_ff @(posedge i_clk)
    if (i_we) mem[i_addr[31:2]] <= i_wdata;
endmodule
