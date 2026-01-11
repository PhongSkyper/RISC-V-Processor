// lsu.sv — NO-SHIFT + misaligned LW support + IO pass-through
`include "params.vh"
module lsu(
  input  logic        i_clk,
  input  logic        i_mem_we,
  input  logic        i_mem_re,
  input  logic [2:0]  i_mem_size,      // 000:BYTE, 001:HALF, 010:WORD from function3
  input  logic        i_mem_unsigned,  // 1: LBU/LHU
  input  logic [31:0] i_addr,
  input  logic [31:0] i_wdata,
  output logic [31:0] o_rdata,
  // MMIO bus
  output logic        o_mmio_we,
  output logic [31:0] o_mmio_addr,
  output logic [31:0] o_mmio_wdata,
  input  logic [31:0] i_mmio_rdata
);

  // --- MMIO detect ---
  localparam [31:0] PAGE_MASK = 32'hFFFF_F000;

  wire page_ledr     = ((i_addr & PAGE_MASK) == `BASE_LEDR);
  wire page_ledg     = ((i_addr & PAGE_MASK) == `BASE_LEDG);
  wire page_hex_lo   = ((i_addr & PAGE_MASK) == `BASE_HEX_LO);
  wire page_hex_hi   = ((i_addr & PAGE_MASK) == `BASE_HEX_HI);
  wire page_lcd      = ((i_addr & PAGE_MASK) == `BASE_LCD);
  wire page_timer0   = ((i_addr & PAGE_MASK) == `BASE_TIMER0);
  wire page_sw       = ((i_addr & PAGE_MASK) == `BASE_SW);
  wire page_key      = ((i_addr & PAGE_MASK) == `BASE_KEY);
  wire page_key_ev   = ((i_addr & PAGE_MASK) == `BASE_KEY_EV);
  wire page_hex_bin  = ((i_addr & PAGE_MASK) == `BASE_HEX_BIN);
  wire page_hex_ctrl = ((i_addr & PAGE_MASK) == `BASE_HEX_CTRL);

  wire is_mmio = page_ledr | page_ledg | page_hex_lo | page_hex_hi
              | page_lcd  | page_timer0 | page_sw    | page_key  | page_key_ev | page_hex_bin | page_hex_ctrl;

  // --- Word-align cho DMEM + offset byte ---
  wire [31:0] mem_addr_al = {i_addr[31:2], 2'b00};
  wire [1:0]  off         = i_addr[1:0];

  // --- DMEM primitive (word access) ---
  logic [31:0] dmem_r, dmem_wdata;
  memory #(
    .BYTES   (`DMEM_BYTES)
  ) u_dmem (
    .i_clk       (i_clk),
    .i_we        (i_mem_we & ~is_mmio),
    .i_re        ((i_mem_re | i_mem_we) & ~is_mmio), // STORE cũng đọc để merge
    .i_addr      (mem_addr_al),
    .i_wdata     (dmem_wdata),
    .o_rdata_mem (dmem_r)
  );

  // --- Đọc word kế tiếp cho LW lệch ---
  logic [31:0] mem_addr_p4, dmem_r_hi;
  add_sub u_mem_addr_p4(.i_a(mem_addr_al), .i_b(32'd4), .i_sub(1'b0),
                        .o_sum(mem_addr_p4), .o_cout(), .o_ovf());
  memory #(
    .BYTES   (`DMEM_BYTES)
  ) u_dmem_hi (
    .i_clk       (i_clk),
    .i_we        (1'b0),
    .i_re        ( (i_mem_re & ~is_mmio) &
                 ( ((i_mem_size==3'd2) & (off!=2'd0)) |
                   ((i_mem_size==3'd1) & (off==2'd3)) ) ),

    .i_addr      (mem_addr_p4),
    .i_wdata     (32'd0),
    .o_rdata_mem (dmem_r_hi)
  );

  // --- STORE merge (NO-SHIFT) ---
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
        3'd1: begin // SH
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

  // --- Data ghi DMEM sau merge ---
  always_comb begin
    dmem_wdata = store_merge(dmem_r, i_wdata, i_mem_size, off);
  end

  // --- IO write: pass-through (peripheral tự merge) ---
  assign o_mmio_wdata = i_wdata;
  assign o_mmio_we    = i_mem_we &  is_mmio;
  assign o_mmio_addr  = i_addr;
  
  
   // --- LOAD extract (NO-SHIFT) ---
  function automatic [31:0] load_x(
    input [31:0] word, input [2:0] size, input [1:0] ofs, input is_unsigned
  );
    logic [7:0]  b; logic [15:0] h;
    begin
      unique case (size)
        3'd0: begin // BYTE
          unique case (ofs)
            2'd0: b = word[7:0];
            2'd1: b = word[15:8];
            2'd2: b = word[23:16];
            default: b = word[31:24];
          endcase
          load_x = is_unsigned ? {24'd0,b} : {{24{b[7]}},b};
        end
        3'd1: begin // HALF
          h = ofs[1] ? word[31:16] : word[15:0];
          load_x = is_unsigned ? {16'd0,h} : {{16{h[15]}},h};
        end
        default: load_x = word; // WORD aligned
      endcase
    end
  endfunction

  // --- Lắp WORD lệch từ 2 word (NO-SHIFT, chỉ concat slice) ---
  function automatic [31:0] assemble_word_misaligned(
    input [31:0] lo, input [31:0] hi, input [1:0] ofs
  );
    begin
      unique case (ofs)
        2'd1: assemble_word_misaligned = { hi[7:0],   lo[31:8]  };
        2'd2: assemble_word_misaligned = { hi[15:0],  lo[31:16] };
        default: assemble_word_misaligned = { hi[23:0], lo[31:24] }; // ofs=3
      endcase
    end
  endfunction

  // --- LOAD output (áp dụng misaligned LW ở DMEM; còn lại dùng load_x) ---
  always_comb begin
  o_rdata = 32'd0;                 // default, tránh latch
  if (i_mem_re) begin
    logic [15:0] h2;               // khai báo trước trong block
    if (~is_mmio) begin
      if ((i_mem_size==3'd2) && (off!=2'd0))       o_rdata = assemble_word_misaligned(dmem_r, dmem_r_hi, off);
      else if ((i_mem_size==3'd1) && (off==2'd3))  begin
        h2 = { dmem_r_hi[7:0], dmem_r[31:24] };    // LH lệch @off=3
        o_rdata = i_mem_unsigned ? {16'd0, h2} : {{16{h2[15]}}, h2};
           end
           else                                     o_rdata = load_x(dmem_r, i_mem_size, off, i_mem_unsigned);
    end else begin
      o_rdata = load_x(i_mmio_rdata, i_mem_size, off, i_mem_unsigned);
    end
    end
  end

endmodule
