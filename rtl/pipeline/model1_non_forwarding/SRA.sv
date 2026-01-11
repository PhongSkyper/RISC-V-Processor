module SRA (
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amt,
    output logic [31:0] data_out
);
    always_comb begin
        case (shift_amt)
            5'd0:  data_out = data_in;
            5'd1:  data_out = {data_in[31], data_in[31:1]};
            5'd2:  data_out = {{2{data_in[31]}}, data_in[31:2]};
            5'd3:  data_out = {{3{data_in[31]}}, data_in[31:3]};
            5'd4:  data_out = {{4{data_in[31]}}, data_in[31:4]};
            5'd5:  data_out = {{5{data_in[31]}}, data_in[31:5]};
            5'd6:  data_out = {{6{data_in[31]}}, data_in[31:6]};
            5'd7:  data_out = {{7{data_in[31]}}, data_in[31:7]};
            5'd8:  data_out = {{8{data_in[31]}}, data_in[31:8]};
            5'd9:  data_out = {{9{data_in[31]}}, data_in[31:9]};
            5'd10: data_out = {{10{data_in[31]}}, data_in[31:10]};
            5'd11: data_out = {{11{data_in[31]}}, data_in[31:11]};
            5'd12: data_out = {{12{data_in[31]}}, data_in[31:12]};
            5'd13: data_out = {{13{data_in[31]}}, data_in[31:13]};
            5'd14: data_out = {{14{data_in[31]}}, data_in[31:14]};
            5'd15: data_out = {{15{data_in[31]}}, data_in[31:15]};
            5'd16: data_out = {{16{data_in[31]}}, data_in[31:16]};
            5'd17: data_out = {{17{data_in[31]}}, data_in[31:17]};
            5'd18: data_out = {{18{data_in[31]}}, data_in[31:18]};
            5'd19: data_out = {{19{data_in[31]}}, data_in[31:19]};
            5'd20: data_out = {{20{data_in[31]}}, data_in[31:20]};
            5'd21: data_out = {{21{data_in[31]}}, data_in[31:21]};
            5'd22: data_out = {{22{data_in[31]}}, data_in[31:22]};
            5'd23: data_out = {{23{data_in[31]}}, data_in[31:23]};
            5'd24: data_out = {{24{data_in[31]}}, data_in[31:24]};
            5'd25: data_out = {{25{data_in[31]}}, data_in[31:25]};
            5'd26: data_out = {{26{data_in[31]}}, data_in[31:26]};
            5'd27: data_out = {{27{data_in[31]}}, data_in[31:27]};
            5'd28: data_out = {{28{data_in[31]}}, data_in[31:28]};
            5'd29: data_out = {{29{data_in[31]}}, data_in[31:29]};
            5'd30: data_out = {{30{data_in[31]}}, data_in[31:30]};
            5'd31: data_out = {{31{data_in[31]}}, data_in[31]};
            default: data_out = 32'b0;
        endcase
    end
endmodule