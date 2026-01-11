
module full_adder (
    input  logic a,     // input bit A
    input  logic b,     // input bit B
    input  logic cin,   // carry in
    output logic s,     // sum
    output logic cout   // carry out
);

    assign s    = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule 
