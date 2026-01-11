module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        regWEn,
    input  logic [31:0] data_W,     // write-back data
    input  logic [4:0]  rs1,        // rs1 address
    input  logic [4:0]  rs2,        // rs2 address
    input  logic [4:0]  rsW,        // rd address
    output logic [31:0] data_1,     // rs1 data
    output logic [31:0] data_2      // rs2 data
);

    logic [31:0] reg_mem [0:31];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 32; i++)
                reg_mem[i] <= 32'b0;
        end
        else begin
            if (regWEn && (rsW != 5'd0)) reg_mem[rsW] <= data_W;
             reg_mem[0] <= 32'b0;
        end
    end
                
    assign data_1 = (rs1 == 5'd0) ? reg_mem[0] :
                    (regWEn && (rsW == rs1)) ? data_W : reg_mem[rs1];

    assign data_2 = (rs2 == 5'd0) ? reg_mem[0] : (regWEn && (rsW == rs2)) ? data_W : reg_mem[rs2];

endmodule