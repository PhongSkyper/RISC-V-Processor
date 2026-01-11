// ============================================================================
// 1) ENGINE: BIN -> BCD (Double-Dabble)
// (giữ nguyên như bản cũ của bà, dán ở dưới cho đầy đủ file)
// ============================================================================
module bin2bcd #(
  parameter int unsigned WIDTH  = 32, // độ rộng nhị phân đầu vào
  parameter int unsigned DIGITS = 10  // tổng số digit BCD xuất ra (4b/digit)
)(
  input  logic                   i_clk,
  input  logic                   i_rstn,   // active-low
  input  logic                   i_start,
  input  logic [WIDTH-1:0]       i_bin,

  output logic                   o_busy,
  output logic                   o_done,   // pulse 1 clk khi hoàn tất
  output logic [4*DIGITS-1:0]    o_bcd     // [3:0]=units, [7:4]=tens, ...
);

  typedef enum logic [0:0] {S_IDLE=1'b0, S_RUN=1'b1} st_t;
  localparam int ITER_W = $clog2(WIDTH+1);

  st_t                 st;
  logic [WIDTH-1:0]    bin_reg, bin_next;
  logic [4*DIGITS-1:0] bcd_reg, bcd_add3, bcd_next;
  logic [ITER_W-1:0]   iter;

  assign o_busy = (st == S_RUN);

  genvar g;
  generate
    for (g = 0; g < DIGITS; g = g + 1) begin : G_ADD3
      wire [3:0] nib    = bcd_reg[4*g+3 : 4*g];
      wire [3:0] nib_a3 = (nib >= 4'd5) ? (nib + 4'd3) : nib;
      assign bcd_add3[4*g+3 : 4*g] = nib_a3;
    end
  endgenerate

  always_comb begin
    bcd_next = { bcd_add3[4*DIGITS-2:0], bin_reg[WIDTH-1] };
    if (WIDTH >= 2) bin_next = { bin_reg[WIDTH-2:0], 1'b0 };
    else            bin_next = { (WIDTH>0)?1'b0:1'b0 };
  end

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      st     <= S_IDLE;
      bin_reg<= '0;
      bcd_reg<= '0;
      iter   <= '0;
      o_bcd  <= '0;
      o_done <= 1'b0;
    end else begin
      o_done <= 1'b0;
      unique case (st)
        S_IDLE: if (i_start) begin
          bin_reg <= i_bin;
          bcd_reg <= '0;
          iter    <= ITER_W'(WIDTH);
          st      <= S_RUN;
        end
        S_RUN: begin
          if (iter == 1) begin
            o_bcd  <= bcd_next;
            o_done <= 1'b1;
            st     <= S_IDLE;
            iter   <= '0;
          end else begin
            bcd_reg <= bcd_next;
            bin_reg <= bin_next;
            iter    <= iter - 1'b1;
          end
        end
      endcase
    end
  end
endmodule

// ============================================================================
// 2) WRAPPER: BIN -> BCD -> 7-SEG (active-low, g..a = MSB..LSB) cho 8 HEX
// ============================================================================
module bin2bcd_hex #(
  parameter int unsigned WIDTH          = 32,
  parameter int unsigned B2B_DIGITS     = 10, // engine convert đủ 10 chữ số
  parameter int unsigned DISPLAY_DIGITS = 8,  // số digit show (<=8)
  parameter bit          ZERO_SUPPRESS  = 1,  // ẩn 0 đầu
  parameter bit          ACTIVE_LOW     = 1   // 1: DE2 active-low
)(
  input  logic                   i_clk,
  input  logic                   i_rstn,   // active-low
  input  logic                   i_start,
  input  logic [WIDTH-1:0]       i_bin,

  output logic                   o_busy,
  output logic                   o_done,

  output logic [6:0]             HEX0,
  output logic [6:0]             HEX1,
  output logic [6:0]             HEX2,
  output logic [6:0]             HEX3,
  output logic [6:0]             HEX4,
  output logic [6:0]             HEX5,
  output logic [6:0]             HEX6,
  output logic [6:0]             HEX7,

  output logic [7:0]             o_vis
);

  // ----- Engine BIN->BCD -----
  logic [4*B2B_DIGITS-1:0] bcd_full;
  bin2bcd #(.WIDTH(WIDTH), .DIGITS(B2B_DIGITS)) u_b2b (
    .i_clk, .i_rstn, .i_start, .i_bin,
    .o_busy, .o_done, .o_bcd(bcd_full)
  );

  // ----- Lấy ra DISPLAY_DIGITS chữ số thấp nhất -----
  localparam int unsigned DISP = (DISPLAY_DIGITS > 8) ? 8 : DISPLAY_DIGITS;
  logic [4*DISP-1:0] bcd_disp;
  assign bcd_disp = bcd_full[4*DISP-1:0];

  // Cắt nibble ra mảng d[i] bằng generate (hằng chỉ số)
  logic [3:0] d [0:DISP-1];
  genvar gn;
  generate
    for (gn = 0; gn < DISP; gn = gn + 1) begin : G_NIB
      assign d[gn] = bcd_disp[4*gn+3 : 4*gn];
    end
  endgenerate

    // ----- Zero-suppress -----
  logic [DISP-1:0] vis;
  logic            seen;  // moved out of always for Quartus compatibility

  always_comb begin
    if (!ZERO_SUPPRESS) begin
      vis  = {DISP{1'b1}};
      seen = 1'b0;
    end else begin
      vis  = '0;
      seen = 1'b0;
      for (integer i = DISP-1; i >= 0; i = i - 1) begin
        if (seen || (d[i] != 4'd0) || (i==0)) begin
          vis[i] = 1'b1;
          seen   = 1'b1;
        end
      end
    end
  end

  // Debug mask ra 8 bit
  always_comb begin
    o_vis = 8'h00;
    for (integer k = 0; k < DISP; k = k + 1) o_vis[k] = vis[k];
  end

  // ----- 7-seg encoder: bảng g..a (MSB..LSB) theo ACTIVE-LOW chuẩn DE2 -----
  function automatic logic [6:0] seg7_bcd_active_low (input logic [3:0] x);
    case (x)
      4'd0: seg7_bcd_active_low = 7'b1000000;
      4'd1: seg7_bcd_active_low = 7'b1111001;
      4'd2: seg7_bcd_active_low = 7'b0100100;
      4'd3: seg7_bcd_active_low = 7'b0110000;
      4'd4: seg7_bcd_active_low = 7'b0011001;
      4'd5: seg7_bcd_active_low = 7'b0010010;
      4'd6: seg7_bcd_active_low = 7'b0000010;
      4'd7: seg7_bcd_active_low = 7'b1111000;
      4'd8: seg7_bcd_active_low = 7'b0000000;
      4'd9: seg7_bcd_active_low = 7'b0010000;
      default: seg7_bcd_active_low = 7'b1111111; // blank
    endcase
  endfunction

  function automatic logic [6:0] blank_seg();
    return (ACTIVE_LOW) ? 7'b1111111 : 7'b0000000;
  endfunction

  function automatic logic [6:0] apply_active_mode(input logic [6:0] seg_low);
    // Nếu cần active-high thì đảo mẫu active-low
    return (ACTIVE_LOW) ? seg_low : ~seg_low;
  endfunction

  // Kết quả cho từng HEXi (HEX0 = units)
  logic [6:0] seg [0:7];

  // Mặc định tắt
  always_comb begin
    for (int i=0;i<8;i++) seg[i] = blank_seg();
  end

  // Điền các digit thực sự có (continuous assign để đơn giản)
  genvar gs;
  generate
    for (gs=0; gs<DISP; gs=gs+1) begin : G_SEG
      wire [6:0] seg_low = seg7_bcd_active_low(d[gs]);
      assign seg[gs] = vis[gs] ? apply_active_mode(seg_low) : blank_seg();
    end
  endgenerate

  // Xuất ra các cổng HEXx
  assign HEX0 = seg[0];
  assign HEX1 = seg[1];
  assign HEX2 = seg[2];
  assign HEX3 = seg[3];
  assign HEX4 = seg[4];
  assign HEX5 = seg[5];
  assign HEX6 = seg[6];
  assign HEX7 = seg[7];

endmodule


// ============================================================================
//  hex_auto_glue: bin -> BCD -> 8x7seg (active-low), zero-suppress
//  (giữ y chang bản bà đang dùng; không đổi interface)
// ============================================================================
module hex_auto_glue #(
  parameter bit          ZERO_SUPPRESS  = 1'b1,
  parameter int unsigned WIDTH          = 32,
  parameter int unsigned B2B_DIGITS     = 10,
  parameter int unsigned DISPLAY_DIGITS = 8
)(
  input  logic                   i_clk,
  input  logic                   i_rstn,   // active-low
  input  logic                   enable,   // 1 = hiển thị theo i_bin
  input  logic [WIDTH-1:0]       i_bin,

  output logic [6:0]             o_hex0,
  output logic [6:0]             o_hex1,
  output logic [6:0]             o_hex2,
  output logic [6:0]             o_hex3,
  output logic [6:0]             o_hex4,
  output logic [6:0]             o_hex5,
  output logic [6:0]             o_hex6,
  output logic [6:0]             o_hex7
);
  // ---- Quản lý engine ----
  logic [WIDTH-1:0] bin_q;
  logic             start;
  logic             busy, done;
  logic             have_valid;
  integer i, k;

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      bin_q      <= '0;
      have_valid <= 1'b0;
    end else begin
      bin_q      <= i_bin;
      if (done)        have_valid <= 1'b1;
      if (!enable)     have_valid <= 1'b0; // tắt enable -> mất hiệu lực
    end
  end

  always_comb begin
    start = 1'b0;
    if (enable && !busy && (!have_valid || (bin_q != i_bin)))
      start = 1'b1;
  end

  // ---- BIN -> BCD ----
  logic [4*B2B_DIGITS-1:0] bcd_full;

  bin2bcd #(.WIDTH(WIDTH), .DIGITS(B2B_DIGITS)) u_b2b (
    .i_clk   (i_clk),
    .i_rstn  (i_rstn),
    .i_start (start),
    .i_bin   (i_bin),
    .o_busy  (busy),
    .o_done  (done),
    .o_bcd   (bcd_full)
  );

  // ---- Window chữ số cần show ----
  localparam int unsigned DISP = (DISPLAY_DIGITS > 8) ? 8 : DISPLAY_DIGITS;

  logic [3:0] d [0:DISP-1];
  genvar gi;
  generate
    for (gi = 0; gi < DISP; gi = gi + 1) begin : G_NIB
      assign d[gi] = bcd_full[4*gi +: 4];
    end
  endgenerate

  // ---- Zero-suppress ----
  logic [DISP-1:0] vis;
  logic            seen;

  always_comb begin
    if (!ZERO_SUPPRESS) begin
      vis  = {DISP{1'b1}};
      seen = 1'b0;
    end else begin
      vis  = '0;
      seen = 1'b0;
      for (i = DISP-1; i >= 0; i = i - 1) begin
        if (seen || (d[i] != 4'd0) || (i == 0)) begin
          vis[i] = 1'b1;
          seen   = 1'b1;
        end
      end
    end
  end

  // ---- 7-seg ACTIVE-LOW (g..a) ----
  function automatic logic [6:0] seg7_al (input logic [3:0] x);
    case (x)
      4'd0: seg7_al = 7'b1000000;
      4'd1: seg7_al = 7'b1111001;
      4'd2: seg7_al = 7'b0100100;
      4'd3: seg7_al = 7'b0110000;
      4'd4: seg7_al = 7'b0011001;
      4'd5: seg7_al = 7'b0010010;
      4'd6: seg7_al = 7'b0000010;
      4'd7: seg7_al = 7'b1111000;
      4'd8: seg7_al = 7'b0000000;
      4'd9: seg7_al = 7'b0010000;
      default: seg7_al = 7'b1111111; // blank
    endcase
  endfunction

  function automatic logic [6:0] blank_al();
    return 7'b1111111;
  endfunction

  logic [6:0] seg [0:7];

  always_comb begin
    for (k = 0; k < 8; k = k + 1) seg[k] = blank_al();
    if (enable && have_valid) begin
      for (k = 0; k < DISP; k = k + 1)
        seg[k] = (vis[k]) ? seg7_al(d[k]) : blank_al();
    end
  end

  assign o_hex0 = seg[0];
  assign o_hex1 = seg[1];
  assign o_hex2 = seg[2];
  assign o_hex3 = seg[3];
  assign o_hex4 = seg[4];
  assign o_hex5 = seg[5];
  assign o_hex6 = seg[6];
  assign o_hex7 = seg[7];
endmodule


