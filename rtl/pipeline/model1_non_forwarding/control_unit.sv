module control_unit (
    input  logic [31:0] instr,
    input  logic        br_less,
    input  logic        br_equal,

    output logic        pc_sel,
    output logic        i_rd_wren,
    output logic        BrUn,
    output logic        opa_sel,
    output logic        opb_sel,
    output logic [3:0]  i_alu_op,
    output logic        MemRW,
    output logic [1:0]  wb_sel,
    output logic [2:0]  load_type,
    output logic [1:0]  store_type,
    output logic [2:0]  Imm_Sel,
    output logic        insn_vld
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_bit30;

    assign opcode       = instr[6:0];
    assign funct3       = instr[14:12];
    assign funct7_bit30 = instr[30];

    logic is_load, is_store, is_branch, is_jal, is_jalr;
    logic is_alui, is_alu, is_lui, is_auipc;

    assign is_load   = (opcode == 7'b0000011); /// 1 cái
    assign is_store  = (opcode == 7'b0100011);
    assign is_branch = (opcode == 7'b1100011);
    assign is_jal    = (opcode == 7'b1101111);
    assign is_jalr   = (opcode == 7'b1100111);
    assign is_alui   = (opcode == 7'b0010011);
    assign is_alu    = (opcode == 7'b0110011);
    assign is_lui    = (opcode == 7'b0110111);
    assign is_auipc  = (opcode == 7'b0010111);

    assign insn_vld  = is_load | is_store | is_branch | is_jal | is_jalr 
                     | is_alui | is_alu | is_lui | is_auipc;

    assign i_rd_wren = !(is_store || is_branch) &&
                       (is_load || is_alui || is_alu || is_lui || is_auipc || is_jal || is_jalr);

    // ------------------------------------------------------------
    // ALU operation
    // ------------------------------------------------------------
    always_comb begin
        i_alu_op = 4'b0000;

        if (is_alu) begin
            unique case (funct3)
                3'b000: i_alu_op = (funct7_bit30) ? 4'b0001 : 4'b0000; // SUB / ADD
                3'b001: i_alu_op = 4'b0111; // SLL
                3'b010: i_alu_op = 4'b0010; // SLT
                3'b011: i_alu_op = 4'b0011; // SLTU
                3'b100: i_alu_op = 4'b0100; // XOR
                3'b101: i_alu_op = (funct7_bit30) ? 4'b1001 : 4'b1000; // SRA / SRL
                3'b110: i_alu_op = 4'b0101; // OR
                3'b111: i_alu_op = 4'b0110; // AND
                default: i_alu_op = 4'b0000;
            endcase
        end
        else if (is_alui) begin
            unique case (funct3)
                3'b000: i_alu_op = 4'b0000; // ADDI
                3'b001: i_alu_op = 4'b0111; // SLLI
                3'b010: i_alu_op = 4'b0010; // SLTI
                3'b011: i_alu_op = 4'b0011; // SLTIU
                3'b100: i_alu_op = 4'b0100; // XORI
                3'b101: i_alu_op = (funct7_bit30) ? 4'b1001 : 4'b1000; // SRAI / SRLI
                3'b110: i_alu_op = 4'b0101; // ORI
                3'b111: i_alu_op = 4'b0110; // ANDI
                default: i_alu_op = 4'b0000;
            endcase
        end
        else if( is_lui) i_alu_op = 4'b1011;
         else if (is_load || is_store || is_jalr  || is_auipc || is_jal)
            i_alu_op = 4'b0000;
    end

    // ------------------------------------------------------------
    // Immediate selection
    // ------------------------------------------------------------
    always_comb begin
        Imm_Sel = 3'b000;
        if (is_alui) begin
            unique case (funct3)
                3'b001: Imm_Sel = 3'b101; // Shift immediate
                3'b101: if(funct7_bit30) Imm_Sel = 3'b110; // SRAI
                        else  Imm_Sel = 3'b101; // Shift immediate
                default:        Imm_Sel = 3'b000; // I-type
            endcase
        end
        else begin
            unique case (1'b1)
                is_load, is_jalr: Imm_Sel = 3'b000; // I-type
                is_store:         Imm_Sel = 3'b001; // S-type
                is_branch:        Imm_Sel = 3'b010; // B-type
                is_lui, is_auipc: Imm_Sel = 3'b011; // U-type
                is_jal:           Imm_Sel = 3'b100; // J-type
                default:          Imm_Sel = 3'b000;
            endcase
        end
    end

    // ------------------------------------------------------------
    // Load/Store type
    // ------------------------------------------------------------
    always_comb begin
        load_type  = 3'b010;
        store_type = 2'b10;

        if (is_load) begin
            unique case (funct3)
                3'b000: load_type = 3'b000; // LB
                3'b001: load_type = 3'b001; // LH
                3'b100: load_type = 3'b100; // LBU
                3'b101: load_type = 3'b101; // LHU
                default: load_type = 3'b010; //LW
            endcase
        end
        if (is_store) begin
            unique case (funct3)
                3'b000: store_type = 2'b00; // SB
                3'b001: store_type = 2'b01; // SH
                default: store_type = 2'b10;
            endcase
        end
    end

    // ------------------------------------------------------------
    // Branch logic
    // ------------------------------------------------------------
    assign BrUn = is_branch && (funct3 == 3'b110 || funct3 == 3'b111); // bltu, bgeu

    logic branch_taken;
    always_comb begin
        if (is_branch) begin
            unique case (funct3)
                3'b000: branch_taken =  br_equal;
                3'b001: branch_taken = ~br_equal;
                3'b100: branch_taken =  br_less;
                3'b101: branch_taken = ~br_less;
                3'b110: branch_taken =  br_less;
                3'b111: branch_taken = ~br_less;
                default: branch_taken = 1'b0;
            endcase
        end else branch_taken = 1'b0;
    end

    assign pc_sel   = (is_branch && branch_taken) || is_jal || is_jalr;
    assign opa_sel  = (is_auipc || is_jal || is_branch);
    assign opb_sel  = (is_alui || is_load || is_store || is_lui || is_auipc || is_jal || is_jalr || is_branch);
    assign MemRW    = is_store;

    always_comb begin
        unique case (1'b1)
            is_load:         wb_sel = 2'b01;
            is_jal, is_jalr: wb_sel = 2'b10;
            default:         wb_sel = 2'b00;
        endcase
    end

endmodule
