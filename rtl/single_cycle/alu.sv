// -----------------------------------------------------------------------------
// Milestone-2 compliant ALU (SystemVerilog)
// - Ripple-carry adder/subtractor built from full adders (no '+'/'-' datapath)
// - Barrel shifter via staged MUXes (no << >> >>> operators)
// - SLT/SLTU derived from subtractor flags
// - Opcode matches {funct7[5], funct3} style (RV32I-like)
// Ports follow i_/o_ naming convention
// -----------------------------------------------------------------------------
module alu(
  input  logic [31:0] i_op_a,
  input  logic [31:0] i_op_b,
  input  logic [3:0]  i_alu_op,   // {funct7[5], funct3}
  output logic [31:0] o_alu_data
);
  // ---- Operation codes ----
  localparam logic [3:0]
    ADD   = 4'b0000,
    SLL   = 4'b0001,
    SLT   = 4'b0010,
    SLTU  = 4'b0011,
    XOROP = 4'b0100,
    SRL   = 4'b0101,
    OROP  = 4'b0110,
    ANDOP = 4'b0111,
    SUB   = 4'b1000,
    PASSB = 4'b1001,  // pass i_op_b (e.g., LUI/AUIPC flows)
    SRA   = 4'b1101;

  // ---------- Adder/Subtractor ----------
  logic [31:0] add_sum;
  logic [31:0] sub_sum;
  logic        add_cout, add_ovf;
  logic        sub_cout, sub_ovf;

  add_sub u_add(
    .i_a(i_op_a), .i_b(i_op_b), .i_sub(1'b0),
    .o_sum(add_sum), .o_cout(add_cout), .o_ovf(add_ovf)
  );

  add_sub u_sub(
    .i_a(i_op_a), .i_b(i_op_b), .i_sub(1'b1),
    .o_sum(sub_sum), .o_cout(sub_cout), .o_ovf(sub_ovf)
  );

  // ---------- Logic ops ----------
  logic [31:0] and_res, or_res, xor_res;
  logic_ops u_logic(.i_a(i_op_a), .i_b(i_op_b), .o_and(and_res), .o_or(or_res), .o_xor(xor_res));

  // ---------- Shifter ----------
  logic [31:0] sll_out, srl_out, sra_out;
  shifter u_shifter(.i_data(i_op_a), .i_shamt(i_op_b[4:0]), .o_sll(sll_out), .o_srl(srl_out), .o_sra(sra_out));

  // ---------- Compare (from subtract flags) ----------
  logic less_s, less_u, is_eq;
  compare u_cmp(
    .i_a(i_op_a), .i_b(i_op_b),
    .i_sub_sum(sub_sum), .i_cout(sub_cout), .i_ovf(sub_ovf),
    .o_less_s(less_s), .o_less_u(less_u), .o_equal(is_eq)
  );

  // ---------- Result MUX ----------
  always_comb begin
    unique case (i_alu_op)
      ADD   : o_alu_data = add_sum;
      SUB   : o_alu_data = sub_sum;
      SLT   : o_alu_data = {31'b0, less_s};
      SLTU  : o_alu_data = {31'b0, less_u};
      XOROP : o_alu_data = xor_res;
      OROP  : o_alu_data = or_res;
      ANDOP : o_alu_data = and_res;
      SLL   : o_alu_data = sll_out;
      SRL   : o_alu_data = srl_out;
      SRA   : o_alu_data = sra_out;
      PASSB : o_alu_data = i_op_b;
      default: o_alu_data = 32'h0000_0000;
    endcase
  end
endmodule
