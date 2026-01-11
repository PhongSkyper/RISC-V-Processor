// ============================================================================
// Purpose : Generate all five RV32I immediates (I, S, B, U, J) from 32-bit instr
// Ports   : i_instr  - full 32-bit instruction
//           o_imm_*  - selected immediates (each fully sign-extended)
// Notes   : B/J immediates are word-aligned by spec (bit[0] = 0).
// ============================================================================

module immgen (
  input  logic [31:0] i_instr,
  output logic [31:0] o_imm_I,   // I-type  (e.g., ADDI, JALR, LOADs)
  output logic [31:0] o_imm_S,   // S-type  (STOREs)
  output logic [31:0] o_imm_B,   // B-type  (branches BEQ/BNE/BLT/BGE/BLTU/BGEU)
  output logic [31:0] o_imm_U,   // U-type  (LUI/AUIPC)
  output logic [31:0] o_imm_J    // J-type  (JAL)
);

  logic [31:0] instr;
  assign instr = i_instr;

  // I-type: sign-extend bits [31:20]
  assign o_imm_I = {{20{instr[31]}}, instr[31:20]};

  // S-type: sign-extend { [31:25], [11:7] }
  assign o_imm_S = {{20{instr[31]}}, instr[31:25], instr[11:7]};

  // B-type: { [31], [7], [30:25], [11:8], 0 } with sign-extend (bit[0]=0)
  assign o_imm_B = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

  // U-type: upper 20 bits, lower 12 bits are zero
  assign o_imm_U = {instr[31:12], 12'b0};

  // J-type: { [31], [19:12], [20], [30:21], 0 } with sign-extend (bit[0]=0)
  assign o_imm_J = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

endmodule
