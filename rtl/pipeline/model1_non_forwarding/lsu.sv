module lsu (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic [31:0] i_lsu_addr,
    input  logic [31:0] i_st_data,
    input  logic        i_lsu_wren,
    input  logic [1:0]  i_lsu_size,
    input  logic        i_lsu_unsigned,
    input  logic [31:0] i_io_sw,

    output logic [31:0] o_ld_data,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [31:0] o_io_lcd,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7
);

    logic is_mem;
    assign is_mem = ~(|i_lsu_addr[31:16]);

    logic is_ledr, is_ledg, is_hex03, is_hex47, is_lcd, is_sw;
    assign is_ledr  = ~(|(i_lsu_addr[31:12] ^ 20'h10000));
    assign is_ledg  = ~(|(i_lsu_addr[31:12] ^ 20'h10001));
    assign is_hex03 = ~(|(i_lsu_addr[31:12] ^ 20'h10002));
    assign is_hex47 = ~(|(i_lsu_addr[31:12] ^ 20'h10003));
    assign is_lcd   = ~(|(i_lsu_addr[31:12] ^ 20'h10004));
    assign is_sw    = ~(|(i_lsu_addr[31:12] ^ 20'h10010));

    logic [31:0] ledr_reg, ledg_reg, lcd_reg;
    logic [6:0]  hex_reg [0:7];
    logic [31:0] out_ledr, out_ledg, out_lcd;
    logic [6:0]  out_hex [0:7];

    logic [3:0]  bram_we;
    logic [31:0] bram_wdata;
    logic [31:0] bram_rdata;

    always_comb begin
        bram_we = 4'b0000;
        if (is_mem && i_lsu_wren) begin
            unique case (i_lsu_size)
                2'b00: begin
                    unique case (i_lsu_addr[1:0])
                        2'b00: bram_we = 4'b0001;
                        2'b01: bram_we = 4'b0010;
                        2'b10: bram_we = 4'b0100;
                        default: bram_we = 4'b1000;
                    endcase
                end
                2'b01: bram_we = i_lsu_addr[1] ? 4'b1100 : 4'b0011;
                default: bram_we = 4'b1111;
            endcase
        end
    end

    always_comb begin
        unique case (i_lsu_size)
            2'b00: bram_wdata = {4{i_st_data[7:0]}};
            2'b01: bram_wdata = {2{i_st_data[15:0]}};
            default: bram_wdata = i_st_data;
        endcase
    end

    bram_wrapper inst_dmem (
        .clk   (i_clk),
        .we    (bram_we),
        .addr  (i_lsu_addr),
        .wdata (bram_wdata),
        .rdata (bram_rdata)
    );

    always_comb begin
        o_ld_data = 32'b0;
        if (is_mem) begin
            unique case (i_lsu_size)
                2'b00: begin
                    unique case (i_lsu_addr[1:0])
                        2'b00: o_ld_data = i_lsu_unsigned ? {24'b0, bram_rdata[7:0]}   : {{24{bram_rdata[7]}},  bram_rdata[7:0]};
                        2'b01: o_ld_data = i_lsu_unsigned ? {24'b0, bram_rdata[15:8]}  : {{24{bram_rdata[15]}}, bram_rdata[15:8]};
                        2'b10: o_ld_data = i_lsu_unsigned ? {24'b0, bram_rdata[23:16]} : {{24{bram_rdata[23]}}, bram_rdata[23:16]};
                        default: o_ld_data = i_lsu_unsigned ? {24'b0, bram_rdata[31:24]} : {{24{bram_rdata[31]}}, bram_rdata[31:24]};
                    endcase
                end
                2'b01: begin
                    if (i_lsu_addr[1])
                        o_ld_data = i_lsu_unsigned ? {16'b0, bram_rdata[31:16]} : {{16{bram_rdata[31]}}, bram_rdata[31:16]};
                    else
                        o_ld_data = i_lsu_unsigned ? {16'b0, bram_rdata[15:0]}  : {{16{bram_rdata[15]}}, bram_rdata[15:0]};
                end
                default: o_ld_data = bram_rdata;
            endcase
        end
        else if (is_sw) o_ld_data = i_io_sw;
    end

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            ledr_reg <= 32'b0;
            ledg_reg <= 32'b0;
            lcd_reg  <= 32'b0;
            for (int i = 0; i < 8; i++) hex_reg[i] <= 7'b1111111;
        end
        else if (i_lsu_wren) begin
            if (is_ledr) ledr_reg <= i_st_data;
            if (is_ledg) ledg_reg <= i_st_data;
            if (is_lcd)  lcd_reg  <= i_st_data;
            if (is_hex03) begin
                unique case (i_lsu_addr[3:2])
                    2'b00: hex_reg[0] <= i_st_data[6:0];
                    2'b01: hex_reg[1] <= i_st_data[6:0];
                    2'b10: hex_reg[2] <= i_st_data[6:0];
                    default: hex_reg[3] <= i_st_data[6:0];
                endcase
            end
            if (is_hex47) begin
                unique case (i_lsu_addr[3:2])
                    2'b00: hex_reg[4] <= i_st_data[6:0];
                    2'b01: hex_reg[5] <= i_st_data[6:0];
                    2'b10: hex_reg[6] <= i_st_data[6:0];
                    default: hex_reg[7] <= i_st_data[6:0];
                endcase
            end
        end
    end

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            out_ledr <= 32'b0;
            out_ledg <= 32'b0;
            out_lcd  <= 32'b0;
            for (int i = 0; i < 8; i++) out_hex[i] <= 7'b1111111;
        end
        else begin
            out_ledr <= ledr_reg;
            out_ledg <= ledg_reg;
            out_lcd  <= lcd_reg;
            for (int i = 0; i < 8; i++) out_hex[i] <= hex_reg[i];
        end
    end

    assign o_io_ledr = out_ledr;
    assign o_io_ledg = out_ledg;
    assign o_io_lcd  = out_lcd;
    assign o_io_hex0 = out_hex[0];
    assign o_io_hex1 = out_hex[1];
    assign o_io_hex2 = out_hex[2];
    assign o_io_hex3 = out_hex[3];
    assign o_io_hex4 = out_hex[4];
    assign o_io_hex5 = out_hex[5];
    assign o_io_hex6 = out_hex[6];
    assign o_io_hex7 = out_hex[7];

endmodule