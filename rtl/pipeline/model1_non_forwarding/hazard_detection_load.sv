module hazard_detection_load (
  input  logic [31:0] inst_EX_i,
  input  logic [31:0] inst_MEM_i,
  input  logic        regWEn_EX_i,
  input  logic        regWEn_MEM_i,

  input  logic [4:0]  rs1_ID,
  input  logic [4:0]  rs2_ID,
  input  logic        uses_rs2,   // 1 if the ID instruction consumes rs2

  output logic        ID_EX_flush,
  output logic        pc_en,
  output logic        IF_ID_en
);

  logic [4:0] rsW_EX, rsW_MEM;

  assign rsW_EX  = inst_EX_i[11:7];
  assign rsW_MEM = inst_MEM_i[11:7];

  always_comb begin
    ID_EX_flush = 1'b0;
    IF_ID_en    = 1'b1;
    pc_en       = 1'b1;

    if ( (regWEn_EX_i  && (rsW_EX  != 5'd0) && ((rsW_EX  == rs1_ID) || (uses_rs2 && (rsW_EX  == rs2_ID)))) ||
         (regWEn_MEM_i && (rsW_MEM != 5'd0) && ((rsW_MEM == rs1_ID) || (uses_rs2 && (rsW_MEM == rs2_ID)))) ) begin
      // Non-forwarding: stall+insert bubble until producer reaches WB
      ID_EX_flush = 1'b1;
      IF_ID_en    = 1'b0;
      pc_en       = 1'b0;
    end
  end

endmodule
