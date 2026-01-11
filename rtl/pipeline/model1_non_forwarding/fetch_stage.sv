module fetch_stage (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_pc_sel,
    input  logic [31:0] i_pc_target,
    input  logic        i_stall,
    input  logic        i_flush,
    output logic [31:0] o_pc,
    output logic [31:0] o_inst
);

    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;
    logic [31:0] inst_raw;

    // Next PC selection between sequential and branch/jump target
    Add_Sub_32bit pc_add4 (
        .A(pc_current),
        .B(32'd4),
        .Sel(1'b0),
        .Y(pc_plus4),
        .Carry_out(),
        .overflow()
    );

    Mux2to1 pc_mux (
        .in0(pc_plus4),
        .in1(i_pc_target),
        .sel(i_pc_sel),
        .out(pc_next)
    );

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pc_current <= 32'd0;
        end else if (!i_stall) begin
            pc_current <= {pc_next[31:2], 2'b00};
        end
    end

    // Increment PC by 4 (RISC-V aligned fetch)
    
    bram_wrapper IMEM (
        .clk   (i_clk),
        .we    (4'b0000),
        .addr  (pc_current),
        .wdata (32'b0),
        .rdata (inst_raw)
    );

    assign o_pc   = pc_current;
    assign o_inst = (i_flush) ? 32'h00000013 : inst_raw; // inject NOP on flush

endmodule
