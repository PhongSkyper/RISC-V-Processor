// params.vh — Quartus 13.1 friendly, dùng macro
`ifndef __M2_PARAMS_VH__
`define __M2_PARAMS_VH__

// ===== Memory sizes (canonical: BYTES) =====
`define IMEM_BYTES   8192
`define DMEM_BYTES   2048

// Nếu code cũ cần "depth theo word 32-bit"
`define IMEM_DEPTH_WORDS   (`IMEM_BYTES/4)
`define DMEM_DEPTH_WORDS   (`DMEM_BYTES/4)

// ===== MMIO base map =====
`define BASE_LEDR      32'h1000_0000
`define BASE_LEDG      32'h1000_1000
`define BASE_HEX_LO    32'h1000_2000
`define BASE_HEX_HI    32'h1000_3000
`define BASE_TIMER0    32'h1000_5000
`define BASE_SW        32'h1001_0000
`define BASE_LCD       32'h1000_4000
`define BASE_KEY       32'h1000_6000
`define BASE_KEY_EV    32'h1000_7000   // event: KEY release
`define BASE_HEX_BIN   32'h1000_8000   // ghi số nhị phân thô
`define BASE_HEX_CTRL  32'h1000_9000   // điều khiển mode

`endif // __M2_PARAMS_VH__
