module Imm_Gen (
    input  logic [31:0] instr,      // instruction từ I$
    input  logic [2:0]  Imm_Sel,    // chọn loại immediate (từ control_unit)
    output logic [31:0] imm_out     // immediate giải mã ra
);

    // Các loại immediate
    logic [31:0] imm_i;   // I-type (load, ALUI, jalr)
    logic [31:0] imm_s;   // S-type (store)
    logic [31:0] imm_b;   // B-type (branch)
    logic [31:0] imm_u;   // U-type (LUI, AUIPC)
    logic [31:0] imm_j;   // J-type (JAL)
    logic [31:0] imm_sh;  // Shift immediate (SLLI, SRLI, SRAI)
    logic [31:0] imm_sra; // SRAI immediate (toán học)

    // ------------------------------------------------------------
    // Giải mã từng loại immediate
    // ------------------------------------------------------------
    always_comb begin
        imm_i = {{20{instr[31]}}, instr[31:20]};
        imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        imm_b = {{19{instr[31]}}, instr[31], instr[7],
                 instr[30:25], instr[11:8], 1'b0};
        imm_u = {instr[31:12], 12'b0};
        imm_j = {{11{instr[31]}}, instr[31],
                 instr[19:12], instr[20], instr[30:21], 1'b0};
        // shift-imm lấy 5 bit shamt [24:20], zero-extend
        imm_sh = {27'b0, instr[24:20]};
        imm_sra = {21'b0,1'b1,5'b0, instr[24:20]};
        unique case (Imm_Sel)
            3'b000: imm_out = imm_i;  // I-type (ALUI/LOAD/JALR)
            3'b001: imm_out = imm_s;  // S-type (STORE)
            3'b010: imm_out = imm_b;  // B-type (BRANCH)
            3'b011: imm_out = imm_u;  // U-type (LUI/AUIPC)
            3'b100: imm_out = imm_j;  // J-type (JAL)
            3'b101: imm_out = imm_sh; // SHIFT-IMM (SLLI/SRLI/SRAI)
            3'b110: imm_out = imm_sra; // SRAI
            default: imm_out = 32'b0;
        endcase
    end

endmodule
