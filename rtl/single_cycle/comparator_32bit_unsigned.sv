module comparator_32bit_unsigned (
    input  logic [31:0] a,
    input  logic [31:0] b, 
    output logic        less,
    output logic        equal
);
    logic [32:0] less_chain;
    logic [32:0] equal_chain;
    
    // Khởi tạo (trước MSB)
    assign less_chain[32]  = 1'b0;
    assign equal_chain[32] = 1'b1;
    
    // So sánh từ MSB -> LSB bằng index đảo
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : GEN
            // Dùng bit (31-i) để đi từ MSB về LSB
            comparator_1bit u_cmp1b (
                .a         (a[31 - i]),
                .b         (b[31 - i]), 
                .prev_less (less_chain [32 - i]),
                .prev_equal(equal_chain[32 - i]),
                .less      (less_chain [31 - i]),
                .equal     (equal_chain[31 - i])
            );
        end
    endgenerate
    
    assign less  = less_chain[0];
    assign equal = equal_chain[0];
endmodule
