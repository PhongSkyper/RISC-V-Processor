module decoder5to32 (
  input  logic        i_rd_wren,
  input  logic [4:0]  i_rd_addr,
  output logic [31:0] Y
);
  always_comb begin
    Y = 32'd0;
    if (i_rd_wren) begin
      // one-hot; nếu addr có X, cả Y vẫn chủ yếu là 0, hạn chế lan X
      unique case (i_rd_addr)
        5'd0  : Y[0]  = 1'b1;
        5'd1  : Y[1]  = 1'b1;
        5'd2  : Y[2]  = 1'b1;
        5'd3  : Y[3]  = 1'b1;
        5'd4  : Y[4]  = 1'b1;
        5'd5  : Y[5]  = 1'b1;
        5'd6  : Y[6]  = 1'b1;
        5'd7  : Y[7]  = 1'b1;
        5'd8  : Y[8]  = 1'b1;
        5'd9  : Y[9]  = 1'b1;
        5'd10 : Y[10] = 1'b1;
        5'd11 : Y[11] = 1'b1;
        5'd12 : Y[12] = 1'b1;
        5'd13 : Y[13] = 1'b1;
        5'd14 : Y[14] = 1'b1;
        5'd15 : Y[15] = 1'b1;
        5'd16 : Y[16] = 1'b1;
        5'd17 : Y[17] = 1'b1;
        5'd18 : Y[18] = 1'b1;
        5'd19 : Y[19] = 1'b1;
        5'd20 : Y[20] = 1'b1;
        5'd21 : Y[21] = 1'b1;
        5'd22 : Y[22] = 1'b1;
        5'd23 : Y[23] = 1'b1;
        5'd24 : Y[24] = 1'b1;
        5'd25 : Y[25] = 1'b1;
        5'd26 : Y[26] = 1'b1;
        5'd27 : Y[27] = 1'b1;
        5'd28 : Y[28] = 1'b1;
        5'd29 : Y[29] = 1'b1;
        5'd30 : Y[30] = 1'b1;
        5'd31 : Y[31] = 1'b1;
        default: ; // giữ 0
      endcase
    end
  end
endmodule
