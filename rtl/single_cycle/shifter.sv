module shifter (
  input  logic [31:0] i_data,
  input  logic [4:0]  i_shamt,
  output logic [31:0] o_sll,
  output logic [31:0] o_srl,
  output logic [31:0] o_sra
);
  // ---------- SHIFT LEFT LOGIC ----------
  logic [31:0] sll1, sll2, sll3, sll4, sll5;
  assign sll1 = i_shamt[0] ? {i_data[30:0], 1'b0}       : i_data;
  assign sll2 = i_shamt[1] ? {sll1[29:0], 2'b0}         : sll1;
  assign sll3 = i_shamt[2] ? {sll2[27:0], 4'b0}         : sll2;
  assign sll4 = i_shamt[3] ? {sll3[23:0], 8'b0}         : sll3;
  assign sll5 = i_shamt[4] ? {sll4[15:0], 16'b0}        : sll4;
  assign o_sll = sll5;

  // ---------- SHIFT RIGHT LOGIC ----------
  logic [31:0] srl1, srl2, srl3, srl4, srl5;
  assign srl1 = i_shamt[0] ? {1'b0, i_data[31:1]}       : i_data;
  assign srl2 = i_shamt[1] ? {2'b0, srl1[31:2]}         : srl1;
  assign srl3 = i_shamt[2] ? {4'b0, srl2[31:4]}         : srl2;
  assign srl4 = i_shamt[3] ? {8'b0, srl3[31:8]}         : srl3;
  assign srl5 = i_shamt[4] ? {16'b0, srl4[31:16]}       : srl4;
  assign o_srl = srl5;

  // ---------- SHIFT RIGHT ARITHMETIC ----------
  logic [31:0] sra1, sra2, sra3, sra4, sra5;
  wire sign = i_data[31];
  assign sra1 = i_shamt[0] ? {sign, i_data[31:1]}       : i_data;
  assign sra2 = i_shamt[1] ? {{2{sign}}, sra1[31:2]}    : sra1;
  assign sra3 = i_shamt[2] ? {{4{sign}}, sra2[31:4]}    : sra2;
  assign sra4 = i_shamt[3] ? {{8{sign}}, sra3[31:8]}    : sra3;
  assign sra5 = i_shamt[4] ? {{16{sign}}, sra4[31:16]}  : sra4;
  assign o_sra = sra5;
endmodule
