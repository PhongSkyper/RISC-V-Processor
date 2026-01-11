// -------------------------------------------------------------
// inst_mem.sv — Instruction ROM (RV32I), synth-friendly (Cyclone II)
//  - Kích thước đặt bằng tham số BYTES (mặc định 8 KiB)
//  - Dùng attribute: ram_init_file = "isa_4b.hex"
//  - Đọc theo byte-address i_addr, tự quy về word index [31:2]
// ------------------------------------------------------------- 
module inst_mem #(
  parameter int unsigned BYTES = 8192  // 8 KiB = 2048 words
)(
  input  logic [31:0] i_addr,          // byte address từ PC
  output logic [31:0] o_rdata          // 1 chu kỳ "gần như" async (UNREG)
);
  // Số word và độ rộng địa chỉ
  localparam int unsigned WORDS = BYTES/4;
  localparam int unsigned ADDRW = (WORDS <= 1) ? 1 : $clog2(WORDS);

  // Word index từ byte address (bỏ 2 LSB). Nếu WORDS không là lũy thừa 2,
  // phần cao hơn tự bị cắt — hợp lệ vì ROM không vượt kích thước BYTES.
  wire [ADDRW-1:0] w_idx = i_addr[ADDRW+1:2];

  // === ROM array + init-file attribute cho Quartus ===
  // Chọn một trong hai dòng attribute, cái nào cũng được (để lại cả hai cũng ok)
  (* ram_init_file = "isa_4b.hex" *)
  logic [31:0] rom [0:WORDS-1];
  // logic [31:0] rom [0:WORDS-1];  // synthesis ram_init_file = "isa_4b.hex"

`ifndef SYNTHESIS
  // Cho mô phỏng: vẫn $readmemh để chạy trên simulator
  initial begin
    $display("[IMEM] init from isa_4b.hex, WORDS=%0d", WORDS);
    $readmemh("isa_4b.hex", rom);
  end
`endif

  // Đọc ROM (unregistered) — Quartus sẽ infer M4K ROM.
  assign o_rdata = rom[w_idx];

endmodule
