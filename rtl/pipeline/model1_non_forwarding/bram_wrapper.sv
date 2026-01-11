module bram_wrapper (
    input  logic        clk,
    input  logic [3:0]  we,    // Write Enable
    input  logic [31:0] addr,  // Address
    input  logic [31:0] wdata, // Write Data
    output logic [31:0] rdata  // Read Data
);
    // 64KB Memory
    logic [31:0] mem [0:2047]; //[0:16383];

    initial begin
        // Khởi tạo bộ nhớ về 0 để tránh 'x'
        //for (int i = 0; i < 6143; i++) begin mem[i] = 32'b0; end
        // Load file hex (đảm bảo đường dẫn file đúng)
        $readmemh("../02_test/isa_4b.hex", mem); 
    end

    // Synchronous Write (Ghi đồng bộ theo Clock)
    always_ff @(posedge clk) begin
        if (we[0]) mem[addr[15:2]][7:0]   <= wdata[7:0];
        if (we[1]) mem[addr[15:2]][15:8]  <= wdata[15:8];
        if (we[2]) mem[addr[15:2]][23:16] <= wdata[23:16];
        if (we[3]) mem[addr[15:2]][31:24] <= wdata[31:24];
    end
    assign rdata = mem[addr[15:2]];

endmodule