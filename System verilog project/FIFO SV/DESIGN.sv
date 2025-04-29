module fifo (
    input logic clk,             // ADD clock input
    input logic write,           // Write enable
    input logic read,            // Read enable
    input logic [7:0] data_in,    // Data input
    output logic [7:0] data_out,  // Data output
    output logic full,           // FIFO full signal
    output logic empty           // FIFO empty signal
);
    parameter DEPTH = 8;
    logic [7:0] fifo_mem [0:DEPTH-1];
    logic [3:0] write_ptr = 0;
    logic [3:0] read_ptr = 0;
    logic [3:0] fifo_count = 0;

    assign full = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);
    assign data_out = (empty) ? 8'bz : fifo_mem[read_ptr];

    always_ff @(posedge clk) begin
        if (write && !full) begin
            fifo_mem[write_ptr] <= data_in;
            write_ptr <= (write_ptr + 1) % DEPTH;
            fifo_count <= fifo_count + 1;
        end
        if (read && !empty) begin
            read_ptr <= (read_ptr + 1) % DEPTH;
            fifo_count <= fifo_count - 1;
        end
    end
endmodule
