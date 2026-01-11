module compare (
    input  logic [31:0] i_a,
    input  logic [31:0] i_b,
    input  logic        i_unsigned,  // 0: signed (SLT), 1: unsigned (SLTU)
    output logic [31:0] o_y          // 1 nếu a < b, ngược lại 0
);
    logic [31:0] diff;
    logic        cout;
    logic        ovf_dummy;

    // diff = a - b
    add_sub_32bit u_sub (
        .a         (i_a),
        .b         (i_b),
        .add_sub   (1'b1),     // SUB
        .y         (diff),
        .carry_out (cout),
        .overflow  (ovf_dummy)
    );

    logic sign_a, sign_b, sign_d;
    logic lt_signed, lt_unsigned;

    assign sign_a = i_a[31];
    assign sign_b = i_b[31];
    assign sign_d = diff[31];

    // Signed compare: nếu khác dấu -> a<0 ?; nếu cùng dấu -> nhìn sign kết quả
    assign lt_signed   = (sign_a ^ sign_b) ? sign_a : sign_d;
    // Unsigned compare: dùng carry_out từ phép a-b
    assign lt_unsigned = ~cout;

    always_comb begin
        if (i_unsigned ? lt_unsigned : lt_signed)
            o_y = 32'd1;
        else
            o_y = 32'd0;
    end
endmodule
