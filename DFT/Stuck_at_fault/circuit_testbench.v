module tb_dft_stuck_at;

    reg a, b;
    wire y;
    reg stuck_at_fault_a0 = 0;
    reg stuck_at_fault_a1 = 0;
    reg stuck_at_fault_b0 = 0;
    reg stuck_at_fault_b1 = 0;

    // Faulty inputs
    wire a_faulty = (stuck_at_fault_a0) ? 1'b0 : (stuck_at_fault_a1 ? 1'b1 : a);
    wire b_faulty = (stuck_at_fault_b0) ? 1'b0 : (stuck_at_fault_b1 ? 1'b1 : b);

    // Instantiate circuit with faulty inputs
    comb_circuit uut (
        .a(a_faulty),
        .b(b_faulty),
        .y(y)
    );

    // Reference output
    reg expected;
    integer i;

    initial begin
        $display("Checking stuck-at faults...");

        // Iterate through all stuck-at faults
        for (i = 0; i < 4; i = i + 1) begin
            // Reset faults
            {stuck_at_fault_a0, stuck_at_fault_a1, stuck_at_fault_b0, stuck_at_fault_b1} = 4'b0000;

            // Inject a specific stuck-at fault
            case(i)
                0: stuck_at_fault_a0 = 1; // a stuck-at-0
                1: stuck_at_fault_a1 = 1; // a stuck-at-1
                2: stuck_at_fault_b0 = 1; // b stuck-at-0
                3: stuck_at_fault_b1 = 1; // b stuck-at-1
            endcase

            // Test all input combinations
            for (a = 0; a <= 1; a = a + 1) begin
                for (b = 0; b <= 1; b = b + 1) begin
                    #1;
                    expected = a ^ b;
                    if (y !== expected)
                        $display("Fault Detected | Fault: %0d | a=%b b=%b | y=%b (Expected: %b)",
                                 i, a, b, y, expected);
                end
            end
        end

        $display("DFT Testbench Complete.");
        $finish;
    end
endmodule
