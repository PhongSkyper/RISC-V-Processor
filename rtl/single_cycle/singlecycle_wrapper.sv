`include "params.vh"

module singlecycle_wrapper (
  input  logic        CLOCK_50,
  input  logic [3:0]  KEY,
  input  logic [17:0] SW,
  output logic [17:0] LEDR,
  output logic [8:0]  LEDG,
  output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
  output logic [7:0]  LCD_DATA,
  output logic        LCD_RW, LCD_RS, LCD_EN, LCD_ON
);

  // ===== /2 to 25MHz (free-running) =====
  (* keep = "true", preserve = "true" *)
  logic clk25 /* synthesis keep preserve */ = 1'b0;
  always_ff @(posedge CLOCK_50) begin
    clk25 <= ~clk25;
  end

  // ===== Reset: KEY0 (pressed=0), async assert / sync deassert vào clk25 =====
  wire  rstn_async = KEY[3];
  logic [1:0] rst_sync;
  always_ff @(posedge clk25 or negedge rstn_async) begin
    if (!rstn_async) rst_sync <= 2'b00;
    else             rst_sync <= {rst_sync[0], 1'b1};
  end
  wire i_rstn = rst_sync[1];

  // ===== Wires ra từ core =====
  logic [31:0] io_ledr_w, io_ledg_w, io_lcd_w;
  logic [6:0]  io_hex0, io_hex1, io_hex2, io_hex3, io_hex4, io_hex5, io_hex6, io_hex7;

  // ===== Core single-cycle =====
  // LƯU Ý: dùng clk25 làm clock cho core
  single_cycle u_core (
    .i_clk      (clk25),
    .i_rstn     (i_rstn),
    .i_io_sw    ({14'd0, SW[17:0]}),
    .i_io_key   (~KEY[3:0]),           // pressed = 1
    .o_io_hex0  (io_hex0), .o_io_hex1(io_hex1), .o_io_hex2(io_hex2), .o_io_hex3(io_hex3),
    .o_io_hex4  (io_hex4), .o_io_hex5(io_hex5), .o_io_hex6(io_hex6), .o_io_hex7(io_hex7),
    .o_io_ledr  (io_ledr_w),
    .o_io_ledg  (io_ledg_w),
    .o_io_lcd   (io_lcd_w),
    .o_pc_debug (), .o_insn_vld ()
  );

  // ===== Map I/O ra DE2 =====
  assign LEDR = io_ledr_w[17:0];
  assign LEDG = io_ledg_w[8:0];

  assign HEX0 = io_hex0;  assign HEX1 = io_hex1;  assign HEX2 = io_hex2;  assign HEX3 = io_hex3;
  assign HEX4 = io_hex4;  assign HEX5 = io_hex5;  assign HEX6 = io_hex6;  assign HEX7 = io_hex7;

  // LCD ký tự DE2
  assign LCD_ON   = 1'b1;
  assign LCD_EN   = io_lcd_w[10];
  assign LCD_RS   = io_lcd_w[9];
  assign LCD_RW   = io_lcd_w[8];
  assign LCD_DATA = io_lcd_w[7:0];

endmodule
