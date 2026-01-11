// ============================================================================
// 32x32 RegFile - 2R1W, sync write, async read
// - Reset đồng bộ, active-low (i_rstn); x0 hard-wired 0
// - BYPASS_EN=1: write-through cho đọc-ngay-sau-ghi (khuyên bật)
// ============================================================================
module regfile #(
  parameter bit BYPASS_EN = 1'b0
)(
  input  logic        i_clk,
  input  logic        i_rstn,     // active-low sync reset

  // Write port
  input  logic        i_rd_wren,
  input  logic [4:0]  i_rd_addr,
  input  logic [31:0] i_rd_data,

  // Read ports
  input  logic [4:0]  i_rs1_addr,
  input  logic [4:0]  i_rs2_addr,
  output logic [31:0] o_rs1_data,
  output logic [31:0] o_rs2_data
);

  // One-hot enables
  logic [31:0] Y;
  decoder5to32 u_write_dec (
    .i_rd_wren (i_rd_wren),
    .i_rd_addr (i_rd_addr),
    .Y         (Y)
  );

  // Bank
  logic [31:0] reg_q [0:31];
  assign reg_q[0] = 32'd0; // x0 = 0

  genvar r;
  generate
    for (r = 1; r < 32; r = r + 1) begin : GPR
      reg32 u_reg (
        .i_clk  (i_clk),
        .i_rstn (i_rstn),
        .i_en   (Y[r] & (i_rd_addr != 5'd0)), // chặn ghi x0
        .i_d    (i_rd_data),
        .o_q    (reg_q[r])
      );
    end
  endgenerate

  // Async read raw
  logic [31:0] rs1_raw, rs2_raw;
  mux32to1_32bit u_mux_rs1 (
    .D0(reg_q[0]),  .D1(reg_q[1]),  .D2(reg_q[2]),  .D3(reg_q[3]),
    .D4(reg_q[4]),  .D5(reg_q[5]),  .D6(reg_q[6]),  .D7(reg_q[7]),
    .D8(reg_q[8]),  .D9(reg_q[9]),  .D10(reg_q[10]),.D11(reg_q[11]),
    .D12(reg_q[12]),.D13(reg_q[13]),.D14(reg_q[14]),.D15(reg_q[15]),
    .D16(reg_q[16]),.D17(reg_q[17]),.D18(reg_q[18]),.D19(reg_q[19]),
    .D20(reg_q[20]),.D21(reg_q[21]),.D22(reg_q[22]),.D23(reg_q[23]),
    .D24(reg_q[24]),.D25(reg_q[25]),.D26(reg_q[26]),.D27(reg_q[27]),
    .D28(reg_q[28]),.D29(reg_q[29]),.D30(reg_q[30]),.D31(reg_q[31]),
    .i_rs_addr(i_rs1_addr),
    .o_rs_data(rs1_raw)
  );
  mux32to1_32bit u_mux_rs2 (
    .D0(reg_q[0]),  .D1(reg_q[1]),  .D2(reg_q[2]),  .D3(reg_q[3]),
    .D4(reg_q[4]),  .D5(reg_q[5]),  .D6(reg_q[6]),  .D7(reg_q[7]),
    .D8(reg_q[8]),  .D9(reg_q[9]),  .D10(reg_q[10]),.D11(reg_q[11]),
    .D12(reg_q[12]),.D13(reg_q[13]),.D14(reg_q[14]),.D15(reg_q[15]),
    .D16(reg_q[16]),.D17(reg_q[17]),.D18(reg_q[18]),.D19(reg_q[19]),
    .D20(reg_q[20]),.D21(reg_q[21]),.D22(reg_q[22]),.D23(reg_q[23]),
    .D24(reg_q[24]),.D25(reg_q[25]),.D26(reg_q[26]),.D27(reg_q[27]),
    .D28(reg_q[28]),.D29(reg_q[29]),.D30(reg_q[30]),.D31(reg_q[31]),
    .i_rs_addr(i_rs2_addr),
    .o_rs_data(rs2_raw)
  );

  // Bypass option (tránh đọc cũ/X ngay sau ghi)
  generate if (BYPASS_EN) begin : BYP
    always_comb begin
      // rs1
      if (i_rs1_addr == 5'd0) o_rs1_data = 32'd0;
      else if (i_rd_wren && (i_rd_addr == i_rs1_addr) && (i_rd_addr != 5'd0))
        o_rs1_data = i_rd_data;
      else
        o_rs1_data = rs1_raw;
      // rs2
      if (i_rs2_addr == 5'd0) o_rs2_data = 32'd0;
      else if (i_rd_wren && (i_rd_addr == i_rs2_addr) && (i_rd_addr != 5'd0))
        o_rs2_data = i_rd_data;
      else
        o_rs2_data = rs2_raw;
    end
  end else begin : NOBYP
    assign o_rs1_data = (i_rs1_addr == 5'd0) ? 32'd0 : rs1_raw;
    assign o_rs2_data = (i_rs2_addr == 5'd0) ? 32'd0 : rs2_raw;
  end endgenerate

endmodule
