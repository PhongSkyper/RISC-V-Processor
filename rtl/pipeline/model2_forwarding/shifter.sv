module shifter (
    input  logic [31:0] i_data,
    input  logic [4:0]  i_shamt,
    output logic [31:0] o_sll,   // shift left logical
    output logic [31:0] o_srl,   // shift right logical
    output logic [31:0] o_sra    // shift right arithmetic
);
    // SLL pipeline
    logic [31:0] sll_stage1, sll_stage2, sll_stage3, sll_stage4, sll_stage5;
    // SRL pipeline
    logic [31:0] srl_stage1, srl_stage2, srl_stage3, srl_stage4, srl_stage5;
    // SRA pipeline
    logic [31:0] sra_stage1, sra_stage2, sra_stage3, sra_stage4, sra_stage5;

    always_comb begin
        // ===== SLL path (barrel shift trái) =====
        if (i_shamt[0])
            sll_stage1 = {i_data[30:0], 1'b0};
        else
            sll_stage1 = i_data;

        if (i_shamt[1])
            sll_stage2 = {sll_stage1[29:0], 2'b00};
        else
            sll_stage2 = sll_stage1;

        if (i_shamt[2])
            sll_stage3 = {sll_stage2[27:0], 4'b0000};
        else
            sll_stage3 = sll_stage2;

        if (i_shamt[3])
            sll_stage4 = {sll_stage3[23:0], 8'b00000000};
        else
            sll_stage4 = sll_stage3;

        if (i_shamt[4])
            sll_stage5 = {sll_stage4[15:0], 16'b0};
        else
            sll_stage5 = sll_stage4;

        // ===== SRL path (barrel shift phải logical) =====
        if (i_shamt[0])
            srl_stage1 = {1'b0, i_data[31:1]};
        else
            srl_stage1 = i_data;

        if (i_shamt[1])
            srl_stage2 = {2'b00, srl_stage1[31:2]};
        else
            srl_stage2 = srl_stage1;

        if (i_shamt[2])
            srl_stage3 = {4'b0000, srl_stage2[31:4]};
        else
            srl_stage3 = srl_stage2;

        if (i_shamt[3])
            srl_stage4 = {8'b00000000, srl_stage3[31:8]};
        else
            srl_stage4 = srl_stage3;

        if (i_shamt[4])
            srl_stage5 = {16'b0, srl_stage4[31:16]};
        else
            srl_stage5 = srl_stage4;

        // ===== SRA path (barrel shift phải arithmetic, sign-extend) =====
        if (i_shamt[0])
            sra_stage1 = {i_data[31], i_data[31:1]};
        else
            sra_stage1 = i_data;

        if (i_shamt[1])
            sra_stage2 = {{2{sra_stage1[31]}}, sra_stage1[31:2]};
        else
            sra_stage2 = sra_stage1;

        if (i_shamt[2])
            sra_stage3 = {{4{sra_stage2[31]}}, sra_stage2[31:4]};
        else
            sra_stage3 = sra_stage2;

        if (i_shamt[3])
            sra_stage4 = {{8{sra_stage3[31]}}, sra_stage3[31:8]};
        else
            sra_stage4 = sra_stage3;

        if (i_shamt[4])
            sra_stage5 = {{16{sra_stage4[31]}}, sra_stage4[31:16]};
        else
            sra_stage5 = sra_stage4;

        // ===== Outputs =====
        o_sll = sll_stage5;
        o_srl = srl_stage5;
        o_sra = sra_stage5;
    end
endmodule
