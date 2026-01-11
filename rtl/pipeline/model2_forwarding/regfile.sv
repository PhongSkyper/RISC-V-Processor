module regfile (
    input  logic        clk,
    input  logic        i_reset,   // active-low
    input  logic        regWEn,
    input  logic [31:0] data_W,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rsW,
    output logic [31:0] data_1,
    output logic [31:0] data_2
);

    logic [31:0] reg_mem [0:31];

    integer i;
    always_ff @(posedge clk or negedge i_reset) begin
        if (!i_reset) begin
            for (i = 0; i < 32; i++) begin
                reg_mem[i] <= 32'b0;
            end
        end else begin
            if (regWEn && (rsW != 5'd0))
                reg_mem[rsW] <= data_W;
        end
    end
    
    assign data_1 = (rs1 == 5'd0) ? 32'b0 :
                    (regWEn && (rsW == rs1)) ? data_W :
                    reg_mem[rs1];

    assign data_2 = (rs2 == 5'd0) ? 32'b0 :
                    (regWEn && (rsW == rs2)) ? data_W :
                    reg_mem[rs2];

endmodule
