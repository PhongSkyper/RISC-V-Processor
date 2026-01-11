module comparator_1bit (
    input  logic a,        // Bit input A
    input  logic b,        // Bit input B
    input  logic prev_less,// Less result from previous bits
    input  logic prev_equal,// Equal result from previous bits  
    output logic less,     // 1 if A < B considering previous
    output logic equal     // 1 if A == B considering previous
);

    // So sánh bằng: chỉ đúng khi tất cả các bit trước bằng VÀ bit hiện tại bằng
    assign equal = prev_equal & ~(a ^ b);
    
    // So sánh nhỏ hơn: 
    // - Hoặc kết quả từ các bit trước đã nhỏ hơn
    // - Hoặc các bit trước bằng nhau và bit hiện tại A=0, B=1
    assign less = prev_less | (prev_equal & ~a & b);

endmodule