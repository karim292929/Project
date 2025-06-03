module comb_circuit (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a ^ b;  // XOR gate
endmodule
