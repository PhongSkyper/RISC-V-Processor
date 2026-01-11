// mux32to1_32bit.sv
`timescale 1ns/1ps
module mux32to1_32bit (
    input  logic [31:0] D0,
    input  logic [31:0] D1,
    input  logic [31:0] D2,
    input  logic [31:0] D3,
    input  logic [31:0] D4,
    input  logic [31:0] D5,
    input  logic [31:0] D6,
    input  logic [31:0] D7,
    input  logic [31:0] D8,
    input  logic [31:0] D9,
    input  logic [31:0] D10,
    input  logic [31:0] D11,
    input  logic [31:0] D12,
    input  logic [31:0] D13,
    input  logic [31:0] D14,
    input  logic [31:0] D15,
    input  logic [31:0] D16,
    input  logic [31:0] D17,
    input  logic [31:0] D18,
    input  logic [31:0] D19,
    input  logic [31:0] D20,
    input  logic [31:0] D21,
    input  logic [31:0] D22,
    input  logic [31:0] D23,
    input  logic [31:0] D24,
    input  logic [31:0] D25,
    input  logic [31:0] D26,
    input  logic [31:0] D27,
    input  logic [31:0] D28,
    input  logic [31:0] D29,
    input  logic [31:0] D30,
    input  logic [31:0] D31,
    input  logic [4:0]  i_rs_addr,
    output logic [31:0] o_rs_data
);

    // instantiate decoder5to32 as selector (enable tied to 1)
    logic [31:0] sel;
    decoder5to32 u_sel_dec (
        .i_rd_wren (1'b1),
        .i_rd_addr (i_rs_addr),
        .Y         (sel)
    );

    always_comb begin
        o_rs_data = (D0  & {32{sel[0]}})  |
                    (D1  & {32{sel[1]}})  |
                    (D2  & {32{sel[2]}})  |
                    (D3  & {32{sel[3]}})  |
                    (D4  & {32{sel[4]}})  |
                    (D5  & {32{sel[5]}})  |
                    (D6  & {32{sel[6]}})  |
                    (D7  & {32{sel[7]}})  |
                    (D8  & {32{sel[8]}})  |
                    (D9  & {32{sel[9]}})  |
                    (D10 & {32{sel[10]}}) |
                    (D11 & {32{sel[11]}}) |
                    (D12 & {32{sel[12]}}) |
                    (D13 & {32{sel[13]}}) |
                    (D14 & {32{sel[14]}}) |
                    (D15 & {32{sel[15]}}) |
                    (D16 & {32{sel[16]}}) |
                    (D17 & {32{sel[17]}}) |
                    (D18 & {32{sel[18]}}) |
                    (D19 & {32{sel[19]}}) |
                    (D20 & {32{sel[20]}}) |
                    (D21 & {32{sel[21]}}) |
                    (D22 & {32{sel[22]}}) |
                    (D23 & {32{sel[23]}}) |
                    (D24 & {32{sel[24]}}) |
                    (D25 & {32{sel[25]}}) |
                    (D26 & {32{sel[26]}}) |
                    (D27 & {32{sel[27]}}) |
                    (D28 & {32{sel[28]}}) |
                    (D29 & {32{sel[29]}}) |
                    (D30 & {32{sel[30]}}) |
                    (D31 & {32{sel[31]}}) ;
    end

endmodule
