module forward_control(
    input logic [31:0] inst_EX_fwd,
    input logic [4:0]  rd_MEM, rd_WB,
    input logic        regWEn_MEM, regWEn_WB,
    output logic [1:0] forwardA_EX, forwardB_EX
);

    logic [4:0] rs1_EX, rs2_EX;
    assign rs1_EX = inst_EX_fwd[19:15];
    assign rs2_EX = inst_EX_fwd[24:20];

    always_comb begin
        forwardA_EX = 2'b00;
        forwardB_EX = 2'b00;

        // 2'b10: forward from MEM (alu_mem), 2'b01: forward from WB (wb_data)
        if ((rd_MEM != 0) && (rd_MEM == rs1_EX) && regWEn_MEM) forwardA_EX = 2'b10;
        else if ((rd_WB != 0) && (rd_WB == rs1_EX) && regWEn_WB) forwardA_EX = 2'b01;

        if ((rd_MEM != 0) && (rd_MEM == rs2_EX) && regWEn_MEM) forwardB_EX = 2'b10;
        else if ((rd_WB != 0) && (rd_WB == rs2_EX) && regWEn_WB) forwardB_EX = 2'b01;
    end
endmodule
