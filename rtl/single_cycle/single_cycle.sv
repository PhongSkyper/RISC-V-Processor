`include "params.vh"

module single_cycle(
  input  logic        i_clk,
  input  logic        i_rstn,              
  input  logic [31:0] i_io_sw,
  input  logic [3:0]  i_io_key,  
  output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
                      o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_ledg,
  output logic [31:0] o_io_lcd,
  output logic [31:0] o_pc_debug,
  output logic        o_insn_vld
);

  // ===== PC / IMEM =====
  logic [31:0] r_pc, w_pc_next, w_instr, w_pc4;
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) r_pc <= 32'd0;
    else          r_pc <= w_pc_next;
  end

  inst_mem #(.BYTES(`IMEM_BYTES)) u_imem (
    .i_addr (r_pc),
    .o_rdata(w_instr)
  );

  // ===== LED bus (10b/8b nội bộ -> bọc ra 32b cho TB) =====
  logic [17:0] w_ledr;
  logic [8:0] w_ledg;
  assign o_io_ledr = {14'b0, w_ledr};
  assign o_io_ledg = {23'b0, w_ledg[8:0]};
  
  // ===== Decode signals =====
  logic        w_reg_we, w_br_un, w_use_imm_b;
  logic        w_mem_we, w_mem_re, w_is_jal, w_is_jalr, w_is_branch, w_wb_sel_mem;
  logic        w_is_lui, w_is_auipc, w_mem_unsigned;
  logic [3:0]  w_alu_op;
  logic [2:0]  w_br_funct3, w_mem_size;

  control_logic u_ctl(
    .i_instr       (w_instr),
    .o_reg_we      (w_reg_we),
    .o_alu_op      (w_alu_op),
    .o_br_un       (w_br_un),
    .o_br_funct3   (w_br_funct3),
    .o_use_imm_b   (w_use_imm_b),
    .o_mem_we      (w_mem_we),
    .o_mem_re      (w_mem_re),
    .o_mem_size    (w_mem_size),
    .o_is_jal      (w_is_jal),
    .o_is_jalr     (w_is_jalr),
    .o_is_branch   (w_is_branch),
    .o_wb_sel_mem  (w_wb_sel_mem),
    .o_is_lui      (w_is_lui),
    .o_is_auipc    (w_is_auipc),
    .o_mem_unsigned(w_mem_unsigned)
  );

  // ===== Regfile =====
  logic [4:0]  w_rs1, w_rs2, w_rd;
  logic [31:0] w_rs1_d, w_rs2_d, w_wd;
  assign w_rs1 = w_instr[19:15];
  assign w_rs2 = w_instr[24:20];
  assign w_rd  = w_instr[11:7];

  regfile #(.BYPASS_EN(1'b0)) u_regfile (
    .i_clk     (i_clk),
    .i_rstn    (i_rstn),
    .i_rd_wren (w_reg_we),
    .i_rd_addr (w_rd),
    .i_rd_data (w_wd),
    .i_rs1_addr(w_rs1),
    .i_rs2_addr(w_rs2),
    .o_rs1_data(w_rs1_d),
    .o_rs2_data(w_rs2_d)
  );

  // ===== Immediates =====
  logic [31:0] w_imm_I, w_imm_S, w_imm_B, w_imm_U, w_imm_J;
  immgen u_ig(
    .i_instr(w_instr),
    .o_imm_I(w_imm_I), .o_imm_S(w_imm_S), .o_imm_B(w_imm_B),
    .o_imm_U(w_imm_U), .o_imm_J(w_imm_J)
  );

  // ===== ALU =====
  logic [31:0] w_alu_a, w_alu_b, w_alu_y;
  assign w_alu_a = (w_is_branch | w_is_jal | w_is_auipc) ? r_pc : w_rs1_d;

  logic w_use_imm_b_eff; // chỉ dùng imm khi KHÔNG phải U/J/B/JALR
  assign w_use_imm_b_eff = w_use_imm_b & ~(w_is_lui | w_is_auipc | w_is_jal | w_is_branch | w_is_jalr);

  always_comb begin
    w_alu_b = w_rs2_d;  // default
    unique case (1'b1)
      w_is_lui        : w_alu_b = w_imm_U;                   // PASSB
      w_is_auipc      : w_alu_b = w_imm_U;                   // ADD với A=PC
      w_is_jal        : w_alu_b = w_imm_J;                   // A=PC
      w_is_branch     : w_alu_b = w_imm_B;                   // A=PC
      w_is_jalr       : w_alu_b = w_imm_I;                   // A=RS1
      w_use_imm_b_eff : w_alu_b = (w_mem_we ? w_imm_S : w_imm_I); // STORE vs I/LOAD
      default         : w_alu_b = w_rs2_d;
    endcase
  end

  alu u_alu(
    .i_op_a   (w_alu_a),
    .i_op_b   (w_alu_b),
    .i_alu_op (w_alu_op),
    .o_alu_data(w_alu_y)
  );

  // ===== Branch compare =====
  logic w_br_less, w_br_equal;
  brc u_brc(
    .i_rs1_data(w_rs1_d),
    .i_rs2_data(w_rs2_d),
    .i_br_un   (w_br_un),
    .o_br_less (w_br_less),
    .o_br_equal(w_br_equal)
  );

  // ===== Next PC =====
  logic w_take_branch;
  always_comb begin
    unique case (w_br_funct3)
      3'b000: w_take_branch =  w_br_equal;  // BEQ
      3'b001: w_take_branch = ~w_br_equal;  // BNE
      3'b100: w_take_branch =  w_br_less;   // BLT
      3'b101: w_take_branch = ~w_br_less;   // BGE
      3'b110: w_take_branch =  w_br_less;   // BLTU
      3'b111: w_take_branch = ~w_br_less;   // BGEU
      default: w_take_branch = 1'b0;
    endcase
  end

  add_sub u_pc_plus4(
    .i_a(r_pc), .i_b(32'd4), .i_sub(1'b0),
    .o_sum(w_pc4), .o_cout(), .o_ovf()
  );

  always_comb begin
    w_pc_next = w_pc4;
    if (w_is_branch && w_take_branch) w_pc_next = w_alu_y;            // PC + imm_B
    if (w_is_jal)                     w_pc_next = w_alu_y;            // PC + imm_J
    if (w_is_jalr)                    w_pc_next = (w_alu_y & ~32'd1); // (RS1+imm_I)&~1
  end

  // ===== LSU + MMIO =====
  logic        w_mmio_we;
  logic [31:0] w_mmio_addr, w_mmio_wdata, w_mmio_rdata;
  logic [31:0] w_lsu_rdata,  w_periph_rdata,  w_timer_rdata;

  lsu u_lsu(
    .i_clk          (i_clk),
    .i_mem_we       (w_mem_we),
    .i_mem_re       (w_mem_re),
    .i_mem_size     (w_mem_size),
    .i_mem_unsigned (w_mem_unsigned),
    .i_addr         (w_alu_y),
    .i_wdata        (w_rs2_d),
    .o_rdata        (w_lsu_rdata),
    .o_mmio_we      (w_mmio_we),
    .o_mmio_addr    (w_mmio_addr),
    .o_mmio_wdata   (w_mmio_wdata),
    .i_mmio_rdata   (w_mmio_rdata)
  );

  // ===== Peripherals =====
  // BẬT/TẮT auto-HEX từ SW ở đây:
  localparam bit AUTO_HEX_FROM_SW = 1'b0;   // 1 = demo không cần ROM; 0 = chuẩn MMIO

  output_peripherals #(
    .P_AUTO_HEX_FROM_SW(AUTO_HEX_FROM_SW)
  ) u_per (
    .i_clk   (i_clk),
    .i_rstn  (i_rstn),
    .i_we    (w_mmio_we),
    .i_addr  (w_mmio_addr),
    .i_wdata (w_mmio_wdata),
    .i_size  (w_mem_size),
    .i_sw    (i_io_sw),
	 .i_key   (i_io_key),
    .o_rdata (w_periph_rdata),
    .o_hex0  (o_io_hex0), .o_hex1(o_io_hex1), .o_hex2(o_io_hex2), .o_hex3(o_io_hex3),
    .o_hex4  (o_io_hex4), .o_hex5(o_io_hex5), .o_hex6(o_io_hex6), .o_hex7(o_io_hex7),
    .o_ledr  (w_ledr),
    .o_ledg  (w_ledg),
    .o_lcd   (o_io_lcd)
  );

  // (Tùy chọn) Timer – nếu không dùng, có thể bỏ instance này
  timer_wrapper u_tim0(
    .i_clk (i_clk), .i_rstn(i_rstn), .i_we(w_mmio_we),
    .i_addr(w_mmio_addr), .i_wdata(w_mmio_wdata), .o_rdata(w_timer_rdata)
  );

  // MMIO read mux: ưu tiên trang Timer
  localparam [31:0] PAGE_MASK = 32'hFFFF_F000;
  assign w_mmio_rdata =
    ((w_mmio_addr & PAGE_MASK) == `BASE_TIMER0) ? w_timer_rdata
                                                : w_periph_rdata;

  // ===== Write-back =====
  logic [31:0] w_wd_mux;
  assign w_wd_mux =
    (w_is_jalr)    ? w_pc4 :
    (w_is_jal)     ? w_pc4 :
    (w_wb_sel_mem) ? w_lsu_rdata :
                     w_alu_y;
  assign w_wd = w_wd_mux;

  // ===== Debug =====
  assign o_pc_debug = r_pc;
  assign o_insn_vld = 1'b1;


endmodule
