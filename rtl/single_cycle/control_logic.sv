module control_logic(
  input  logic [31:0] i_instr,
  output logic        o_reg_we,
  output logic [3:0]  o_alu_op,
  output logic        o_br_un,
  output logic [2:0]  o_br_funct3,
  output logic        o_use_imm_b,
  output logic        o_mem_we,
  output logic        o_mem_re,
  output logic [2:0]  o_mem_size,
  output logic        o_is_jal,
  output logic        o_is_jalr,
  output logic        o_is_branch,
  output logic        o_wb_sel_mem,
  output logic        o_is_lui,     // write imm_U
  output logic        o_is_auipc,    // write pc + imm_U
  output logic        o_mem_unsigned
);
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
	assign opcode = i_instr[6:0];
	assign funct3 = i_instr[14:12];
	assign funct7 = i_instr[31:25];
	
  // defaults
  always_comb begin
    o_reg_we       = 1'b0;
    o_alu_op       = 4'b0000;
    o_br_un        = 1'b0;
    o_br_funct3    = 3'b000;
    o_use_imm_b    = 1'b0;
    o_mem_we       = 1'b0;
    o_mem_re       = 1'b0;
    o_mem_size     = 3'd2;
    o_is_jal       = 1'b0;
    o_is_jalr      = 1'b0;
    o_is_branch    = 1'b0;
    o_wb_sel_mem   = 1'b0;
    o_is_lui       = 1'b0;
    o_is_auipc     = 1'b0;
    o_mem_unsigned = 1'b0;

    unique case (opcode)
      7'b0110011: begin // R
        o_reg_we = 1'b1;
        unique case ({funct7,funct3})
          {7'b0000000,3'b000}: o_alu_op = 4'b0000; // ADD
          {7'b0100000,3'b000}: o_alu_op = 4'b1000; // SUB
          {7'b0000000,3'b111}: o_alu_op = 4'b0111; // AND
          {7'b0000000,3'b110}: o_alu_op = 4'b0110; // OR
          {7'b0000000,3'b100}: o_alu_op = 4'b0100; // XOR
          {7'b0000000,3'b001}: o_alu_op = 4'b0001; // SLL
          {7'b0000000,3'b101}: o_alu_op = 4'b0101; // SRL
          {7'b0100000,3'b101}: o_alu_op = 4'b1101; // SRA
          {7'b0000000,3'b010}: o_alu_op = 4'b0010; // SLT
          {7'b0000000,3'b011}: o_alu_op = 4'b0011; // SLTU
          default: o_alu_op = 4'b0000;
        endcase
      end
      7'b0010011: begin // I-ALU
        o_reg_we = 1'b1;
        o_use_imm_b = 1'b1;
        unique case (funct3)
          3'b000: o_alu_op = 4'b0000; // ADDI
          3'b111: o_alu_op = 4'b0111; // ANDI
          3'b110: o_alu_op = 4'b0110; // ORI
          3'b100: o_alu_op = 4'b0100; // XORI
          3'b001: o_alu_op = 4'b0001; // SLLI
          3'b101: o_alu_op = (funct7==7'b0100000) ? 4'b1101 : 4'b0101; // SRAI/SRLI
          3'b010: o_alu_op = 4'b0010; // SLTI
          3'b011: o_alu_op = 4'b0011; // SLTIU
          default: o_alu_op = 4'b0000;
        endcase
      end
      7'b0000011: begin // LOAD
        o_reg_we = 1'b1; o_use_imm_b = 1'b1; o_mem_re = 1'b1; o_wb_sel_mem = 1'b1;
        unique case (funct3)
          3'b000: begin o_mem_size=3'd0; o_mem_unsigned=1'b0; end // LB
          3'b001: begin o_mem_size=3'd1; o_mem_unsigned=1'b0; end // LH
          3'b010: begin o_mem_size=3'd2; o_mem_unsigned=1'b0; end // LW
          3'b100: begin o_mem_size=3'd0; o_mem_unsigned=1'b1; end // LBU
          3'b101: begin o_mem_size=3'd1; o_mem_unsigned=1'b1; end // LHU
          default: o_mem_size=3'd2;
        endcase
      end
      7'b0100011: begin // STORE
        o_use_imm_b = 1'b1; o_mem_we = 1'b1;
        unique case (funct3)
          3'b000: o_mem_size = 3'd0; // SB
          3'b001: o_mem_size = 3'd1; // SH
          3'b010: o_mem_size = 3'd2; // SW
          default: o_mem_size = 3'd2;
        endcase
      end
      7'b1100011: begin // BRANCH
        o_is_branch = 1'b1;
        o_br_funct3 = funct3;
        o_br_un = (funct3==3'b110 || funct3==3'b111);
      end
      7'b1101111: begin // JAL
        o_is_jal = 1'b1; o_reg_we = 1'b1;
      end
      7'b1100111: begin // JALR
        o_is_jalr = 1'b1; o_reg_we = 1'b1; o_use_imm_b = 1'b1;
      end

      7'b0110111: begin // LUI
        o_is_lui     = 1'b1; 
        o_reg_we     = 1'b1;
        o_alu_op     = 4'b1001;   // PASSB
      end
      7'b0010111: begin // AUIPC
        o_is_auipc  = 1'b1; 
        o_reg_we    = 1'b1;
        o_alu_op    = 4'b0000;   // ADD
      end   
      default: ;
    endcase
  end
endmodule
