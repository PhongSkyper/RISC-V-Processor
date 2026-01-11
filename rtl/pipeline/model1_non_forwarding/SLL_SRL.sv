module SLL_SRL (
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amt,
    input  logic        dir, // 0=SLL,1=SRL
    output logic [31:0] data_out
);
    logic [31:0] stage1, stage2, stage3, stage4, stage5;
    always_comb begin
        if (shift_amt[0])
            stage1 = (dir) ? {1'b0, data_in[31:1]}  : {data_in[30:0], 1'b0};
        else
            stage1 = data_in;
        if (shift_amt[1])
            stage2 = (dir) ? {2'b00, stage1[31:2]} : {stage1[29:0], 2'b00};
        else
            stage2 = stage1;
        if (shift_amt[2])
            stage3 = (dir) ? {4'b0000, stage2[31:4]} : {stage2[27:0], 4'b0000};
        else
            stage3 = stage2;
        if (shift_amt[3])
            stage4 = (dir) ? {8'b00000000, stage3[31:8]} : {stage3[23:0], 8'b00000000};
        else
            stage4 = stage3;
        if (shift_amt[4])
            stage5 = (dir) ? {16'b0, stage4[31:16]} : {stage4[15:0], 16'b0};
        else
            stage5 = stage4;
        data_out = stage5;
    end
endmodule