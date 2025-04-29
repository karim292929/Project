`timescale 1ns / 1ps
module up_down_counter (
    input logic clk,            // Clock input
    input logic reset,          // Reset input
    input logic up_down,        // Control input: 1 for up, 0 for down
    output logic [3:0] count    // 4-bit counter output
);
    // Counter logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            count <= 4'b0000;  // Reset counter to 0
        else if (up_down)
            count <= count + 1; // Increment for up
        else
            count <= count - 1; // Decrement for down
    end
endmodule
