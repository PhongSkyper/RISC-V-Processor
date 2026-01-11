module hazard_detection_load (
  input  logic [31:0] inst_ID_i,
  input  logic [31:0] inst_EX_i,

  output logic        ID_EX_flush,
  output logic        pc_en,
  output logic        IF_ID_en
);

  logic [4:0] rs1_ID, rs2_ID, rsW_EX;
  logic       isload_EX;
  // Detect standard RISC-V load opcode 0000011
  assign isload_EX = (inst_EX_i[6:0] == 7'b0000011);

  assign rs1_ID    = inst_ID_i[19:15];
  assign rs2_ID    = inst_ID_i[24:20];
  assign rsW_EX    = inst_EX_i[11:7];

  always_comb begin
    ID_EX_flush = 1'b0;
    IF_ID_en    = 1'b1;
    pc_en       = 1'b1;

    if (isload_EX && (rsW_EX != 5'd0) &&
       ((rsW_EX == rs1_ID) || (rsW_EX == rs2_ID))) begin
      ID_EX_flush = 1'b1;
      IF_ID_en    = 1'b0;
      pc_en       = 1'b0;
    end
  end

endmodule
