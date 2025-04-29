module tb_vending_machine;

    reg clk, reset;
    reg [1:0] coin;
    wire product;

    vending_machine uut (
        .clk(clk),
        .reset(reset),
        .coin(coin),
        .product(product)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $monitor("Time=%0t, Coin=%b, Product=%b", $time, coin, product);
        clk = 0;
        reset = 1; coin = 2'b00; #10;
        reset = 0;

        // Insert ₹5
        coin = 2'b01; #10;
        // Insert ₹5 again (total ₹10)
        coin = 2'b01; #10;

        // Reset & test direct ₹10
        coin = 2'b00; #10;
        coin = 2'b10; #10;

        $finish;
    end

endmodule
