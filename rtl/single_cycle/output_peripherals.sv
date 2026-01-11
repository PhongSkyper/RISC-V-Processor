// - Decode theo page [31:12]
// - Ghi SB/SH/SW dùng store_merge (NO-SHIFT)
// - Đọc trả 32-bit word; cắt/extend do LSU xử lý
`include "params.vh"

module output_peripherals #(
  parameter bit P_AUTO_HEX_FROM_SW = 1'b0  // để tương thích; không dùng nữa
)(
  input  logic        i_clk,
  input  logic        i_rstn,
  input  logic        i_we,
  input  logic [31:0] i_sw,      // dùng SW[17:0], bit cao reserved
  input  logic [3:0]  i_key,     // mức 1 = đang nhấn (đã đảo ở wrapper)
  input  logic [31:0] i_addr,
  input  logic [31:0] i_wdata,
  input  logic [2:0]  i_size,    // 0=BYTE,1=HALF,2=WORD
  output logic [31:0] o_rdata,

  // 7-seg active-LOW (g f e d c b a)
  output logic [6:0]  o_hex0, o_hex1, o_hex2, o_hex3,
                      o_hex4, o_hex5, o_hex6, o_hex7,

  // LED bus rút gọn; wrapper sẽ map ra DE2 18/9
  output logic [17:0] o_ledr,
  output logic [8:0]  o_ledg,

  // LCD: ON[31], EN[10], RS[9], RW[8], DATA[7:0]
  output logic [31:0] o_lcd
);

  // ------------------------
  // Thanh ghi hiển thị/MMIO
  // ------------------------
  logic [31:0] r_hex_lo, r_hex_hi;   // mỗi byte = 1 digit (7b dùng, 1b bỏ)
  logic [31:0] r_ledr32, r_ledg32;
  logic [31:0] r_lcd;

  // Số nhị phân thô do CPU ghi (mode=2: AUTO_CPU)
  logic [31:0] r_hex_bin;

  // Mode hiển thị HEX:
  //   0 = MANUAL (ghi pattern vào HEX_LO/HEX_HI)
  //   1 = AUTO_SW  (đọc SW → BCD → 7-seg)
  //   2 = AUTO_CPU (đọc r_hex_bin → BCD → 7-seg)
  typedef enum logic [1:0] {HEX_MANUAL=2'd0, HEX_AUTO_SW=2'd1, HEX_AUTO_CPU=2'd2} hex_mode_e;
  hex_mode_e r_hex_mode;

  // Bit SIGN (HEX_CTRL[8]): 1 = hiển thị dấu "−" ở HEX7; phần số là |value|
  logic r_signed_en;

  // ------------------------
  // Decode page theo spec
  // ------------------------
  localparam [31:0] PAGE_MASK = 32'hFFFF_F000;

  wire hit_ledr     = ((i_addr & PAGE_MASK) == `BASE_LEDR);
  wire hit_ledg     = ((i_addr & PAGE_MASK) == `BASE_LEDG);
  wire hit_hex_lo   = ((i_addr & PAGE_MASK) == `BASE_HEX_LO);
  wire hit_hex_hi   = ((i_addr & PAGE_MASK) == `BASE_HEX_HI);
  wire hit_lcd      = ((i_addr & PAGE_MASK) == `BASE_LCD);
  wire hit_sw       = ((i_addr & PAGE_MASK) == `BASE_SW);
  wire hit_key      = ((i_addr & PAGE_MASK) == `BASE_KEY);
  wire hit_key_ev   = ((i_addr & PAGE_MASK) == `BASE_KEY_EV);
  wire hit_hex_bin  = ((i_addr & PAGE_MASK) == `BASE_HEX_BIN);
  wire hit_hex_ctrl = ((i_addr & PAGE_MASK) == `BASE_HEX_CTRL);

  // Byte offset trong word
  wire [1:0] ofs = i_addr[1:0];

  // ------------------------
  // store_merge (NO-SHIFT)
  // ------------------------
  function automatic [31:0] store_merge(
    input [31:0] oldw, input [31:0] wd, input [2:0] size, input [1:0] ofs
  );
    logic [31:0] mask, data;
    begin
      unique case (size)
        3'd0: begin // SB
          unique case (ofs)
            2'd0: begin mask=32'h000000FF; data={24'd0,wd[7:0]}; end
            2'd1: begin mask=32'h0000FF00; data={16'd0,wd[7:0],8'd0}; end
            2'd2: begin mask=32'h00FF0000; data={8'd0,wd[7:0],16'd0}; end
            default: begin mask=32'hFF000000; data={wd[7:0],24'd0}; end
          endcase
        end
        3'd1: begin // SH (ofs[1])
          if (ofs[1]==1'b0) begin
            mask=32'h0000FFFF; data={16'd0,wd[15:0]};
          end else begin
            mask=32'hFFFF0000; data={wd[15:0],16'd0};
          end
        end
        default: begin // SW
          mask=32'hFFFF_FFFF; data=wd;
        end
      endcase
      store_merge = (oldw & ~mask) | (data & mask);
    end
  endfunction

  // ------------------------
  // KEY sync + event (W1C)
  // ------------------------
  logic [3:0] key_m, key_s, key_sd;
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      key_m <= '0; key_s <= '0; key_sd <= '0;
    end else begin
      key_m  <= i_key;
      key_s  <= key_m;
      key_sd <= key_s;    // giữ giá trị chu kỳ trước
    end
  end

  wire [3:0] key_rise =  key_s & ~key_sd;   // nhấn
  wire [3:0] key_fall = ~key_s &  key_sd;   // nhả

  logic [3:0] press_seen, key_rel_event;    // event = 1 lần nhấn→nhả (sticky)

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      press_seen    <= '0;
      key_rel_event <= '0;
    end else begin
      press_seen    <= (press_seen | key_rise);
      key_rel_event <= key_rel_event | (key_fall & press_seen);
      if (i_we && hit_key_ev) begin
        press_seen    <= press_seen    & ~i_wdata[3:0]; // W1C
        key_rel_event <= key_rel_event & ~i_wdata[3:0];
      end
    end
  end

  // ------------------------
  // Ghi thanh ghi MMIO
  // ------------------------
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      r_hex_lo    <= 32'b0;
      r_hex_hi    <= 32'b0;
      r_ledr32     <= 32'b0;
      r_ledg32     <= 32'b0;
      r_lcd        <= 32'b0;
      r_hex_bin    <= 32'd0;
      r_hex_mode   <= HEX_MANUAL;   // mặc định manual
      r_signed_en  <= 1'b0;         // mặc định không dấu
    end else if (i_we) begin
      if (hit_ledr)     r_ledr32 <= store_merge(r_ledr32, i_wdata, i_size, ofs);
      if (hit_ledg)     r_ledg32 <= store_merge(r_ledg32, i_wdata, i_size, ofs);
      if (hit_hex_lo)   r_hex_lo <= store_merge(r_hex_lo, i_wdata, i_size, ofs);
      if (hit_hex_hi)   r_hex_hi <= store_merge(r_hex_hi, i_wdata, i_size, ofs);
      if (hit_lcd)      r_lcd    <= store_merge(r_lcd,    i_wdata, i_size, ofs);
      if (hit_hex_bin)  r_hex_bin<= store_merge(r_hex_bin,i_wdata, i_size, ofs);

      // HEX_CTRL (WORD write):
      //   i_wdata[1:0] = MODE (0/1/2)
      //   i_wdata[8]   = SIGN (1 = hiển thị "−" ở HEX7 + show |value|)
      if (hit_hex_ctrl && (i_size==3'd2)) begin
        unique case (i_wdata[1:0])
          2'd0: r_hex_mode <= HEX_MANUAL;
          2'd1: r_hex_mode <= HEX_AUTO_SW;
          2'd2: r_hex_mode <= HEX_AUTO_CPU;
          default: r_hex_mode <= HEX_MANUAL;
        endcase
        r_signed_en <= i_wdata[8];
      end
    end
  end

  // ------------------------
  // Đọc MMIO (word-level)
  // ------------------------
  always_comb begin
    unique case (1'b1)
      hit_ledr:      o_rdata = r_ledr32;
      hit_ledg:      o_rdata = r_ledg32;
      hit_hex_lo:    o_rdata = r_hex_lo;
      hit_hex_hi:    o_rdata = r_hex_hi;
      hit_lcd:       o_rdata = r_lcd;
      hit_sw:        o_rdata = i_sw;
      hit_key:       o_rdata = {28'd0, key_s};          // mức hiện tại (đã sync)
      hit_key_ev:    o_rdata = {28'd0, key_rel_event};  // event nhả (W1C)
      hit_hex_bin:   o_rdata = r_hex_bin;
      hit_hex_ctrl:  o_rdata = {23'd0, 1'b0, r_signed_en, 7'd0, r_hex_mode};
      default:       o_rdata = 32'b0;
    endcase
  end

  // ==========================================================
  // ĐƯỜNG RA 7-SEG: CHUẨN + 2 AUTO MODE + SIGN
  // ==========================================================
  // CHUẨN: mỗi byte của r_hex_lo/hi lái 1 digit (7b thấp, ACTIVE-LOW)
  wire [6:0] hex0_mmio = r_hex_lo[ 6: 0];
  wire [6:0] hex1_mmio = r_hex_lo[14: 8];
  wire [6:0] hex2_mmio = r_hex_lo[22:16];
  wire [6:0] hex3_mmio = r_hex_lo[30:24];
  wire [6:0] hex4_mmio = r_hex_hi[ 6: 0];
  wire [6:0] hex5_mmio = r_hex_hi[14: 8];
  wire [6:0] hex6_mmio = r_hex_hi[22:16];
  wire [6:0] hex7_mmio = r_hex_hi[30:24];

  localparam logic [6:0] HEX_BLANK     = 7'b1111111; // tắt
  localparam logic [6:0] SEG_MINUS_AL  = 7'b0111111; // dấu "−" (active-low): chỉ g

  // Nguồn auto:
  wire        auto_en      = (r_hex_mode != HEX_MANUAL);
  wire [31:0] auto_src_raw = (r_hex_mode == HEX_AUTO_SW)  ? {14'b0, i_sw[17:0]} :
                             (r_hex_mode == HEX_AUTO_CPU) ? r_hex_bin : 32'd0;

  // Dùng trị tuyệt đối nếu bật SIGN (để phần số là |value|)
  function automatic [31:0] abs32(input [31:0] x);
    abs32 = x[31] ? (32'd0 - x) : x;  // two’s complement magnitude
  endfunction
  wire        neg      = auto_src_raw[31];
  wire [31:0] auto_src = (auto_en && r_signed_en && neg) ? abs32(auto_src_raw) : auto_src_raw;

  // AUTO-DEC: bin -> BCD -> 7seg (active-low), ẩn 0 đầu
  logic [6:0] hex0_auto, hex1_auto, hex2_auto, hex3_auto;
  logic [6:0] hex4_auto, hex5_auto, hex6_auto, hex7_auto;

  hex_auto_glue #(
    .ZERO_SUPPRESS  (1),
    .WIDTH          (32),
    .B2B_DIGITS     (10),
    .DISPLAY_DIGITS (8)
  ) u_hex_auto (
    .i_clk  (i_clk),
    .i_rstn (i_rstn),
    .enable (auto_en),
    .i_bin  (auto_src),

    .o_hex0 (hex0_auto), .o_hex1 (hex1_auto), .o_hex2 (hex2_auto), .o_hex3 (hex3_auto),
    .o_hex4 (hex4_auto), .o_hex5 (hex5_auto), .o_hex6 (hex6_auto), .o_hex7 (hex7_auto)
  );

  // Chọn nguồn cuối (AUTO vs MMIO)
  wire [6:0] hex0_sel = auto_en ? hex0_auto : hex0_mmio;
  wire [6:0] hex1_sel = auto_en ? hex1_auto : hex1_mmio;
  wire [6:0] hex2_sel = auto_en ? hex2_auto : hex2_mmio;
  wire [6:0] hex3_sel = auto_en ? hex3_auto : hex3_mmio;
  wire [6:0] hex4_sel = auto_en ? hex4_auto : hex4_mmio;
  wire [6:0] hex5_sel = auto_en ? hex5_auto : hex5_mmio;
  wire [6:0] hex6_sel = auto_en ? hex6_auto : hex6_mmio;

  // HEX7: nếu auto_en & SIGN=1 → ép hiển thị dấu “−”, ngược lại theo dữ liệu
  wire [6:0] hex7_core = auto_en ? hex7_auto : hex7_mmio;
  wire [6:0] hex7_sel  = (auto_en && r_signed_en && neg) ? 7'b0111111 : hex7_core;

  // Lớp blank theo reset (chặn “toàn số 8” lúc reset)
  assign o_hex0 = i_rstn ? hex0_sel : HEX_BLANK;
  assign o_hex1 = i_rstn ? hex1_sel : HEX_BLANK;
  assign o_hex2 = i_rstn ? hex2_sel : HEX_BLANK;
  assign o_hex3 = i_rstn ? hex3_sel : HEX_BLANK;
  assign o_hex4 = i_rstn ? hex4_sel : HEX_BLANK;
  assign o_hex5 = i_rstn ? hex5_sel : HEX_BLANK;
  assign o_hex6 = i_rstn ? hex6_sel : HEX_BLANK;
  assign o_hex7 = i_rstn ? hex7_sel : HEX_BLANK;

  // ==========================================================
  // LED & LCD ra chân (cắt đúng số bit)
  // ==========================================================
  assign o_ledr = r_ledr32[17:0];
  assign o_ledg = r_ledg32[8:0];
  assign o_lcd  = r_lcd;

endmodule


