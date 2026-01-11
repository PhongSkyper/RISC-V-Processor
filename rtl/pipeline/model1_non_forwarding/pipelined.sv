module pipelined1 (
    input  logic        i_clk,
    input  logic        i_reset,   // active-low from testbench
    input  logic [31:0] i_io_sw,

    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [31:0] o_io_lcd,
    output logic [6:0]  o_io_hex0,
    output logic [6:0]  o_io_hex1,
    output logic [6:0]  o_io_hex2,
    output logic [6:0]  o_io_hex3,
    output logic [6:0]  o_io_hex4,
    output logic [6:0]  o_io_hex5,
    output logic [6:0]  o_io_hex6,
    output logic [6:0]  o_io_hex7,

    output logic        o_ctrl,
    output logic        o_mispred,
    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld
);

    // IF / ID wires
    logic [31:0] pc_if, inst_if;
    logic [31:0] pc_id, inst_id;

    // Decode outputs
    logic [31:0] rs1_id_data, rs2_id_data, imm_id;
    logic [31:0] pc_id_dec, inst_id_dec;
    logic [3:0]  alu_sel_id;
    logic        bru_id, memrw_id, asel_id, bsel_id, regwen_id;
    logic [2:0]  load_type_id;
    logic [1:0]  store_type_id;
    logic [1:0]  wb_sel_id;
    logic [4:0]  rs1_id, rs2_id;
    logic        insn_vld_id, is_ctrl_id;

    // ID / EX wires
    logic [31:0] pc_ex, inst_ex, rs1_ex, rs2_ex, imm_ex;
    logic [3:0]  alu_sel_ex;
    logic        bru_ex, memrw_ex, asel_ex, bsel_ex, regwen_ex;
    logic [2:0]  load_type_ex;
    logic [1:0]  store_type_ex;
    logic [1:0]  wb_sel_ex;

    // Execute outputs
    logic [31:0] alu_ex;
    logic [31:0] rs2_fwd_ex;
    logic [31:0] pc_target_ex;
    logic        pc_sel_ex;
    logic        branch_taken_ex;
    logic [31:0] rs1_ex_fwd_data, rs2_ex_fwd_data;
    logic [1:0]  forwardA_ex, forwardB_ex;
    logic [1:0]  branch_fwd_a_ex, branch_fwd_b_ex;

    // EX / MEM wires
    logic [31:0] pc_mem, inst_mem, alu_mem, rs2_mem;
    logic        memrw_mem;
    logic [2:0]  load_type_mem;
    logic [1:0]  store_type_mem;
    logic [1:0]  wb_sel_mem;
    logic        regwen_mem;

    // MEM outputs
    logic [31:0] mem_data_mem;

    // MEM / WB wires
    logic [31:0] pc_wb, inst_wb, alu_wb, mem_wb;
    logic [1:0]  wb_sel_wb;
    logic        regwen_wb;

    // WB outputs
    logic [31:0] wb_data;
    logic [4:0]  rd_wb;
    logic        wb_en;

    // Hazard (no forwarding)
    logic       id_ex_flush;
    logic       pc_en, if_id_en;

    logic flush_branch;
    logic rst;
    logic flush_id_ex_comb;
    logic stall_if, stall_id;
    logic pc_sel_if;
    logic [31:0] pc_target_if;
    logic is_branch_ex, is_jal_ex, is_jalr_ex;
    logic ctrl_redirect_actual;

    assign rst            = ~i_reset; // convert to active-high internally
    assign is_branch_ex   = (inst_ex[6:0] == 7'b1100011);
    assign is_jal_ex      = (inst_ex[6:0] == 7'b1101111);
    assign is_jalr_ex     = (inst_ex[6:0] == 7'b1100111);

    // Non-predictive: only redirect on actual taken control flow.
    assign ctrl_redirect_actual = is_jal_ex || is_jalr_ex || (is_branch_ex && branch_taken_ex);
    assign flush_branch         = ctrl_redirect_actual;
    // Flush ID/EX khi load-use hoac khi redirect.
    assign flush_id_ex_comb     = flush_branch | id_ex_flush;
    assign stall_if       = ~pc_en;
    assign stall_id       = ~if_id_en;
    assign pc_sel_if      = pc_sel_ex;
    assign pc_target_if   = pc_target_ex;

    // ============================================================
    // IF STAGE
    // ============================================================
    fetch_stage IFU (
        .i_clk      (i_clk),
        .i_rst      (rst),
        .i_pc_sel   (pc_sel_if),
        .i_pc_target(pc_target_if),
        .i_stall    (stall_if),
        .i_flush    (flush_branch),
        .o_pc       (pc_if),
        .o_inst     (inst_if)
    );

    // ============================================================
    // IF/ID PIPELINE REGISTER (RENAMED)
    // ============================================================
    stage_IF_ID IF_ID (
        .i_clk  (i_clk),
        .i_rst  (rst),
        .i_flush(flush_branch),
        .i_stall(stall_id),
        .i_pc   (pc_if),
        .i_inst (inst_if),
        .o_pc   (pc_id),
        .o_inst (inst_id)
    );

    // ============================================================
    // ID STAGE
    // ============================================================
    decode_stage IDU (
        .i_clk     (i_clk),
        .i_rst     (rst),
        .i_pc      (pc_id),
        .i_inst    (inst_id),
        .i_wb_data (wb_data),
        .i_rd_wb   (rd_wb),
        .i_wb_en   (wb_en),
        .o_pc      (pc_id_dec),
        .o_inst    (inst_id_dec),
        .o_rs1_data(rs1_id_data),
        .o_rs2_data(rs2_id_data),
        .o_imm     (imm_id),
        .o_alu_sel (alu_sel_id),
        .o_bru     (bru_id),
        .o_memrw   (memrw_id),
        .o_load_type(load_type_id),
        .o_store_type(store_type_id),
        .o_wb_sel  (wb_sel_id),
        .o_regwen  (regwen_id),
        .o_asel    (asel_id),
        .o_bsel    (bsel_id),
        .o_rs1     (rs1_id),
        .o_rs2     (rs2_id),
        .o_insn_vld(insn_vld_id),
        .o_is_ctrl (is_ctrl_id)
    );

    // ============================================================
    // ID/EX PIPELINE REGISTER (RENAMED)
    // ============================================================
    stage_ID_EX ID_EX (
        .i_clk      (i_clk),
        .i_rst      (rst),
        .i_flush    (flush_id_ex_comb),
        .i_stall    (1'b0),
        .i_pc       (pc_id_dec),
        .i_inst     (inst_id_dec),
        .i_rs1      (rs1_id_data),
        .i_rs2      (rs2_id_data),
        .i_imm      (imm_id),
        .i_alu_sel  (alu_sel_id),
        .i_bru      (bru_id),
        .i_memrw    (memrw_id),
        .i_load_type(load_type_id),
        .i_store_type(store_type_id),
        .i_wb_sel   (wb_sel_id),
        .i_regwen   (regwen_id),
        .i_asel     (asel_id),
        .i_bsel     (bsel_id),
        .o_pc       (pc_ex),
        .o_inst     (inst_ex),
        .o_rs1      (rs1_ex),
        .o_rs2      (rs2_ex),
        .o_imm      (imm_ex),
        .o_alu_sel  (alu_sel_ex),
        .o_bru      (bru_ex),
        .o_memrw    (memrw_ex),
        .o_load_type(load_type_ex),
        .o_store_type(store_type_ex),
        .o_wb_sel   (wb_sel_ex),
        .o_regwen   (regwen_ex),
        .o_asel     (asel_ex),
        .o_bsel     (bsel_ex)
    );

    // ============================================================
    // EX STAGE + forwarding
    forward_control FWD (
        .inst_EX_fwd    (inst_ex),
        .rd_MEM         (inst_mem[11:7]),
        .rd_WB          (rd_wb),
        .regWEn_MEM     (regwen_mem),
        .regWEn_WB      (wb_en),
        .forwardA_EX    (forwardA_ex),
        .forwardB_EX    (forwardB_ex)
    );

    always_comb begin
        rs1_ex_fwd_data = rs1_ex;
        rs2_ex_fwd_data = rs2_ex;

        case (forwardA_ex)
            2'b10: rs1_ex_fwd_data = alu_mem;
            2'b01: rs1_ex_fwd_data = wb_data;
            default: ;
        endcase

        case (forwardB_ex)
            2'b10: rs2_ex_fwd_data = alu_mem;
            2'b01: rs2_ex_fwd_data = wb_data;
            default: ;
        endcase
    end

    execute_stage EXU (
        .i_pc        (pc_ex),
        .i_inst      (inst_ex),
        .i_rs1       (rs1_ex_fwd_data),
        .i_rs2       (rs2_ex_fwd_data),
        .i_imm       (imm_ex),
        .i_asel      (asel_ex),
        .i_bsel      (bsel_ex),
        .i_bru       (bru_ex),
        .i_alu_sel   (alu_sel_ex),
        .o_alu       (alu_ex),
        .o_rs2_fwd   (rs2_fwd_ex),
        .o_pc_target (pc_target_ex),
        .o_pc_sel    (pc_sel_ex),
        .o_branch_taken(branch_taken_ex)
    );

    // ============================================================
    // EX/MEM PIPELINE REGISTER (RENAMED)
    // ============================================================
    stage_EX_MEM EX_MEM (
        .i_clk      (i_clk),
        .i_rst      (rst),
        .i_flush    (1'b0),
        .i_pc       (pc_ex),
        .i_inst     (inst_ex),
        .i_alu      (alu_ex),
        .i_rs2      (rs2_fwd_ex),
        .i_memrw    (memrw_ex),
        .i_load_type(load_type_ex),
        .i_store_type(store_type_ex),
        .i_wb_sel   (wb_sel_ex),
        .i_regwen   (regwen_ex),
        .o_pc       (pc_mem),
        .o_inst     (inst_mem),
        .o_alu      (alu_mem),
        .o_rs2      (rs2_mem),
        .o_memrw    (memrw_mem),
        .o_load_type(load_type_mem),
        .o_store_type(store_type_mem),
        .o_wb_sel   (wb_sel_mem),
        .o_regwen   (regwen_mem)
    );

    // ============================================================
    // MEM STAGE
    // ============================================================
    mem_stage MEMU (
        .i_clk     (i_clk),
        .i_rst     (rst),
        .i_addr    (alu_mem),
        .i_rs2     (rs2_mem),
        .i_memrw   (memrw_mem),
        .i_load_type(load_type_mem),
        .i_store_type(store_type_mem),
        .i_io_sw   (i_io_sw),
        .i_pc      (pc_mem),
        .o_ld_data (mem_data_mem),
        .o_io_ledr (o_io_ledr),
        .o_io_ledg (o_io_ledg),
        .o_io_hex0 (o_io_hex0),
        .o_io_hex1 (o_io_hex1),
        .o_io_hex2 (o_io_hex2),
        .o_io_hex3 (o_io_hex3),
        .o_io_hex4 (o_io_hex4),
        .o_io_hex5 (o_io_hex5),
        .o_io_hex6 (o_io_hex6),
        .o_io_hex7 (o_io_hex7),
        .o_io_lcd  (o_io_lcd)
    );

    // ============================================================
    // MEM/WB PIPELINE REGISTER (RENAMED)
    // ============================================================
    stage_MEM_WB MEM_WB (
        .i_clk    (i_clk),
        .i_rst    (rst),
        .i_flush  (1'b0),
        .i_pc     (pc_mem),
        .i_inst   (inst_mem),
        .i_alu    (alu_mem),
        .i_mem    (mem_data_mem),
        .i_wb_sel (wb_sel_mem),
        .i_regwen (regwen_mem),
        .o_pc     (pc_wb),
        .o_inst   (inst_wb),
        .o_alu    (alu_wb),
        .o_mem    (mem_wb),
        .o_wb_sel (wb_sel_wb),
        .o_regwen (regwen_wb)
    );

    // ============================================================
    // WB STAGE
    // ============================================================
    wb_stage WBU (
        .i_pc     (pc_wb),
        .i_alu    (alu_wb),
        .i_mem    (mem_wb),
        .i_inst   (inst_wb),
        .i_wb_sel (wb_sel_wb),
        .i_regwen (regwen_wb),
        .o_wb_data(wb_data),
        .o_rd     (rd_wb),
        .o_wb_en  (wb_en)
    );

    // ------------------ Hazard (non-forwarding) ------------------
    hazard_detection_load HZD (
        .inst_EX_i   (inst_ex),
        .inst_MEM_i  (inst_mem),
        .regWEn_EX_i (regwen_ex),
        .regWEn_MEM_i(regwen_mem),
        .rs1_ID      (rs1_id),
        .rs2_ID      (rs2_id),
        .uses_rs2    ((inst_id[6:0] == 7'b0110011) || // R-type
                      (inst_id[6:0] == 7'b0100011) || // STORE
                      (inst_id[6:0] == 7'b1100011)),  // BRANCH
        .ID_EX_flush (id_ex_flush),
        .pc_en       (pc_en),
        .IF_ID_en    (if_id_en)
    );

    // ------------------ Debug ------------------
    // Expose PC/valid at WB (retire) for scoreboard/trace.
    assign o_pc_debug = pc_wb;
    assign o_insn_vld = (inst_wb != 32'b0); // ignore reset/flush bubbles
    assign o_ctrl     = (inst_wb[6:0] == 7'b1100011) || // Branch
                        (inst_wb[6:0] == 7'b1101111) || // JAL
                        (inst_wb[6:0] == 7'b1100111);   // JALR
    // Mispred: chi khi branch khong duoc lay.
    assign o_mispred  = ctrl_redirect_actual; 

endmodule
