module Load_encode(
    input  logic [31:0] load_data,
    input  logic [2:0]  load_type,
    output logic [31:0] load_result
);
    always_comb begin
        case (load_type)
            3'b000: load_result = {{24{load_data[7]}},  load_data[7:0]};   // LB
            3'b001: load_result = {{16{load_data[15]}}, load_data[15:0]};  // LH
            3'b010: load_result = load_data;                               // LW
            3'b100: load_result = {24'b0, load_data[7:0]};                 // LBU
            3'b101: load_result = {16'b0, load_data[15:0]};                // LHU
            default: load_result = load_data;
        endcase
    end
endmodule