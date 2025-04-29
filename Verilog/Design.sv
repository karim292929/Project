module vending_machine (
    input clk,
    input reset,
    input [1:0] coin,   // 2'b01 = ₹5, 2'b10 = ₹10
    output reg product
);

    // State Encoding
    typedef enum reg [1:0] {
        S0 = 2'b00,  // ₹0
        S5 = 2'b01,  // ₹5
        S10 = 2'b10  // ₹10 or more
    } state_t;

    state_t current_state, next_state;

    // State Transition
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next State Logic and Output
    always @(*) begin
        product = 0;
        case (current_state)
            S0: begin
                if (coin == 2'b01)      next_state = S5;
                else if (coin == 2'b10) begin
                    next_state = S10;
                    product = 1;
                end
                else                    next_state = S0;
            end
            S5: begin
                if (coin == 2'b01) begin
                    next_state = S10;
                    product = 1;
                end
                else if (coin == 2'b10) begin
                    next_state = S10;
                    product = 1;
                end
                else                    next_state = S5;
            end
            S10: begin
                next_state = S0; // Reset after dispensing
                product = 0;
            end
            default: next_state = S0;
        endcase
    end

endmodule
