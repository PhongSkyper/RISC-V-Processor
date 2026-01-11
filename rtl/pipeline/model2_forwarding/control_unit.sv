module control_unit (
  input  logic [31:0] instr,

  output logic [2:0]  Imm_Sel,
  output logic [3:0]  ALU_sel,

  output logic        regWEn,
  output logic        BrUn,
  output logic        opb_sel,   // Bsel
  output logic        opa_sel,   // Asel
  output logic        MemRW,

  output logic [1:0]  WBSel,
  output logic [2:0]  load_type,
  output logic [1:0]  store_type,
  output logic        insn_vld
);

  logic [6:0] opcode7;
  logic [2:0] funct3;
  logic       funct7b30;

  assign opcode7   = instr[6:0];
  assign funct3    = instr[14:12];
  assign funct7b30 = instr[30];

  // Loại lệnh RISC-V chuẩn
  logic is_load, is_store, is_branch, is_jal, is_jalr;
  logic is_alui, is_alu, is_lui, is_auipc;

  assign is_load   = (opcode7 == 7'b0000011);
  assign is_store  = (opcode7 == 7'b0100011);
  assign is_branch = (opcode7 == 7'b1100011);
  assign is_jal    = (opcode7 == 7'b1101111);
  assign is_jalr   = (opcode7 == 7'b1100111);
  assign is_alui   = (opcode7 == 7'b0010011);
  assign is_alu    = (opcode7 == 7'b0110011);
  assign is_lui    = (opcode7 == 7'b0110111);
  assign is_auipc  = (opcode7 == 7'b0010111);

    // Imm_Sel encoding (must match your Imm_Gen)
  localparam logic [2:0]
    IMM_I  = 3'd0,
    IMM_S  = 3'd1,
    IMM_B  = 3'd2,
    IMM_U  = 3'd3,
    IMM_J  = 3'd4,
    IMM_SH = 3'd5,
    IMM_SRA= 3'd6;

  always_comb begin
    // Defaults
    Imm_Sel    = IMM_I;
    ALU_sel    = 4'b0000;

    BrUn       = is_branch && (funct3 == 3'b110 || funct3 == 3'b111);
    opa_sel    = is_branch || is_jal || is_auipc;  // A = PC for branches/JAL/AUIPC
    opb_sel    = is_alui || is_load || is_store || is_lui || is_auipc || is_jal || is_jalr || is_branch;
    MemRW      = is_store;
    regWEn     = ~(is_store || is_branch) && (is_load || is_alui || is_alu || is_lui || is_auipc || is_jal || is_jalr);

    // Dùng cùng encoding load_type cho cả load/store để LSU biết kích thước
    load_type  = is_load  ? funct3        :
                 is_store ? funct3        : 3'b010; // default word
    store_type = is_store ? funct3[1:0]   : 2'b10;  // default SW

    // WBSel mapping compatible with your wb_stage:
    // 00: ALU, 01: MEM, 10: PC+4
    if (is_load)               WBSel = 2'b01;
    else if (is_jal || is_jalr) WBSel = 2'b10;
    else                        WBSel = 2'b00;

    // Immediate type select
    if (is_alui) begin
      if (funct3 == 3'b001)       Imm_Sel = IMM_SH;              // SLLI
      else if (funct3 == 3'b101)  Imm_Sel = funct7b30 ? IMM_SRA : IMM_SH; // SRAI/SRLI
      else                        Imm_Sel = IMM_I;               // I-type
    end else begin
      if (is_load || is_jalr)      Imm_Sel = IMM_I;
      else if (is_store)           Imm_Sel = IMM_S;
      else if (is_branch)          Imm_Sel = IMM_B;
      else if (is_lui || is_auipc) Imm_Sel = IMM_U;
      else if (is_jal)             Imm_Sel = IMM_J;
      else                         Imm_Sel = IMM_I;
    end

    // ALU select logic (khớp với encoding trong alu.sv)
    if (is_alu) begin
      unique case (funct3)
        3'b000: ALU_sel = funct7b30 ? 4'b0001 : 4'b0000; // SUB / ADD
        3'b001: ALU_sel = 4'b0111; // SLL
        3'b010: ALU_sel = 4'b0010; // SLT
        3'b011: ALU_sel = 4'b0011; // SLTU
        3'b100: ALU_sel = 4'b0100; // XOR
        3'b101: ALU_sel = funct7b30 ? 4'b1001 : 4'b1000; // SRA / SRL
        3'b110: ALU_sel = 4'b0101; // OR
        3'b111: ALU_sel = 4'b0110; // AND
        default: ALU_sel = 4'b0000;
      endcase
    end
    else if (is_alui) begin
      unique case (funct3)
        3'b000: ALU_sel = 4'b0000; // ADDI
        3'b001: ALU_sel = 4'b0111; // SLLI
        3'b010: ALU_sel = 4'b0010; // SLTI
        3'b011: ALU_sel = 4'b0011; // SLTIU
        3'b100: ALU_sel = 4'b0100; // XORI
        3'b101: ALU_sel = funct7b30 ? 4'b1001 : 4'b1000; // SRAI / SRLI
        3'b110: ALU_sel = 4'b0101; // ORI
        3'b111: ALU_sel = 4'b0110; // ANDI
        default: ALU_sel = 4'b0000;
      endcase
    end
    else if (is_lui) begin
      ALU_sel = 4'b1011; // pass imm (LUI path, opb_sel đưa imm)
    end
    else begin
      ALU_sel = 4'b0000; // default add (AUIPC/JALR/JAL/load/store)
    end

    // insn valid
    insn_vld = (instr != 32'h00000013);
  end
endmodule
