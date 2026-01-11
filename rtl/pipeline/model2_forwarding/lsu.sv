// 64KB data memory (word-addressable), tách ra khỏi LSU
module dmem (
    input  logic        i_clk,
    input  logic        i_reset,    // active-low
    input  logic        i_we,       // write enable
    input  logic [31:0] i_addr,     // byte address
    input  logic [31:0] i_st_data,  // store data (rs2)
    input  logic [1:0]  i_size,     // 00: byte, 01: half, 10: word

    output logic [31:0] o_rdata     // raw 32-bit word at aligned address
);

    // 64KB: 16k words * 4 bytes
    logic [31:0] mem [0:2047]; //[0:16383];

    /*integer idx1;
    initial begin
        for (idx1 = 0; idx1 < 16384; idx1 = idx1 + 1) begin
            mem[idx1] = 32'b0;
        end
    end*/

    // Async read
    assign o_rdata = mem[i_addr[15:2]];

    // Sync write
    integer idx2;
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            /*for (idx2 = 0; idx2 < 16384; idx2 = idx2 + 1) begin
                mem[idx2] <= 32'b0;
            end*/
        end else if (i_we) begin
            unique case (i_size)
                2'b00: begin // SB
                    unique case (i_addr[1:0])
                        2'b00: mem[i_addr[15:2]][7:0]   <= i_st_data[7:0];
                        2'b01: mem[i_addr[15:2]][15:8]  <= i_st_data[7:0];
                        2'b10: mem[i_addr[15:2]][23:16] <= i_st_data[7:0];
                        default: mem[i_addr[15:2]][31:24] <= i_st_data[7:0];
                    endcase
                end

                2'b01: begin // SH
                    if (i_addr[1] == 1'b0) begin
                        // lower half-word
                        mem[i_addr[15:2]][7:0]   <= i_st_data[7:0];
                        mem[i_addr[15:2]][15:8]  <= i_st_data[15:8];
                    end else begin
                        // upper half-word
                        mem[i_addr[15:2]][23:16] <= i_st_data[7:0];
                        mem[i_addr[15:2]][31:24] <= i_st_data[15:8];
                    end
                end

                default: begin // SW
                    mem[i_addr[15:2]] <= i_st_data;
                end
            endcase
        end
    end

endmodule

//============== LSU ===============
module lsu (
    input  logic        i_clk,
    input  logic        i_reset,       // active-low
    input  logic [31:0] i_lsu_addr,
    input  logic [31:0] i_st_data,
    input  logic        i_lsu_wren,    // store enable
    input  logic [1:0]  i_lsu_size,    // 00:byte, 01:half, 10:word
    input  logic        i_lsu_unsigned,
    input  logic [31:0] i_io_sw,

    output logic [31:0] o_ld_data,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [31:0] o_io_lcd,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7
);

    // Address map (giữ nguyên)
    localparam logic [31:0] ADDR_LED_R  = 32'h1000_0000;
    localparam logic [31:0] ADDR_LED_G  = 32'h1000_1000;
    localparam logic [31:0] ADDR_HEX0_3 = 32'h1000_2000;
    localparam logic [31:0] ADDR_HEX4_7 = 32'h1000_3000;
    localparam logic [31:0] ADDR_LCD    = 32'h1000_4000;
    localparam logic [31:0] ADDR_SW     = 32'h1001_0000;

    // DMem raw read data
    logic [31:0] dmem_rdata;

    // Chỉ ghi vào RAM khi địa chỉ thuộc vùng 0x0000_0000 ~ 0x0000_FFFF
    wire dmem_region = (i_lsu_addr < 32'h0001_0000);

    dmem u_dmem (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .i_we     (i_lsu_wren && dmem_region),
        .i_addr   (i_lsu_addr),
        .i_st_data(i_st_data),
        .i_size   (i_lsu_size),
        .o_rdata  (dmem_rdata)
    );

    // ===================== MMIO write =====================
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_io_ledr <= 32'b0;
            o_io_ledg <= 32'b0;
            o_io_lcd  <= 32'b0;
            o_io_hex0 <= 7'b0; o_io_hex1 <= 7'b0; o_io_hex2 <= 7'b0; o_io_hex3 <= 7'b0;
            o_io_hex4 <= 7'b0; o_io_hex5 <= 7'b0; o_io_hex6 <= 7'b0; o_io_hex7 <= 7'b0;
        end else if (i_lsu_wren && !dmem_region) begin
            // Memory-mapped outputs
            unique case (i_lsu_addr)
                ADDR_LED_R:  o_io_ledr <= i_st_data;
                ADDR_LED_G:  o_io_ledg <= i_st_data;

                ADDR_HEX0_3: begin
                    o_io_hex0 <= i_st_data[6:0];
                    o_io_hex1 <= i_st_data[14:8];
                    o_io_hex2 <= i_st_data[22:16];
                    o_io_hex3 <= i_st_data[30:24];
                end

                ADDR_HEX4_7: begin
                    o_io_hex4 <= i_st_data[6:0];
                    o_io_hex5 <= i_st_data[14:8];
                    o_io_hex6 <= i_st_data[22:16];
                    o_io_hex7 <= i_st_data[30:24];
                end

                ADDR_LCD:    o_io_lcd  <= i_st_data;
                default: ; // ignore unmapped stores
            endcase
        end
    end

    // ===================== LOAD path =====================
    logic [7:0]  ld_byte;
    logic [15:0] ld_half;

    // Chọn byte / half-word từ dmem_rdata
    always_comb begin
        case (i_lsu_addr[1:0])
            2'b00: ld_byte = dmem_rdata[7:0];
            2'b01: ld_byte = dmem_rdata[15:8];
            2'b10: ld_byte = dmem_rdata[23:16];
            default: ld_byte = dmem_rdata[31:24];
        endcase

        if (i_lsu_addr[1] == 1'b0)
            ld_half = dmem_rdata[15:0];
        else
            ld_half = dmem_rdata[31:16];
    end

    // Kết quả load, kèm sign/zero-extend
    always_comb begin
        if (i_lsu_addr == ADDR_SW) begin
            // read switch
            o_ld_data = i_io_sw;
        end else if (dmem_region) begin
            unique case (i_lsu_size)
                2'b00: begin // byte
                    o_ld_data = i_lsu_unsigned
                              ? {24'b0, ld_byte}
                              : {{24{ld_byte[7]}}, ld_byte};
                end

                2'b01: begin // half
                    o_ld_data = i_lsu_unsigned
                              ? {16'b0, ld_half}
                              : {{16{ld_half[15]}}, ld_half};
                end

                default: begin // word
                    o_ld_data = dmem_rdata;
                end
            endcase
        end else begin
            // unmapped region (không có read cho LED / HEX / LCD)
            o_ld_data = 32'hdead_beef;
        end
    end

endmodule
