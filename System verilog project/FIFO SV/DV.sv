// --------------------------------------
// Interface
// --------------------------------------
interface fifo_if();
    logic clk;
    logic write;
    logic read;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic full;
    logic empty;
endinterface

// --------------------------------------
// Transaction
// --------------------------------------
class fifo_transaction;
    randc logic [7:0] data;
    logic write_en;
    logic read_en;

    function fifo_transaction copy();
        fifo_transaction t = new();
        t.data = this.data;
        t.write_en = this.write_en;
        t.read_en = this.read_en;
        return t;
    endfunction
endclass

// --------------------------------------
// Generator
// --------------------------------------
class fifo_generator;
    event done;
    event next;
    fifo_transaction t;
    mailbox #(fifo_transaction) mbx;

    function new(mailbox #(fifo_transaction) mbx);
        this.mbx = mbx;
        t = new();
    endfunction

    task run();
        for (int i = 0; i < 10; i++) begin
            t.randomize();
            t.write_en = 1;
            t.read_en = 0;
            $display("[GEN] Writing data: %0d", t.data);
            mbx.put(t.copy());
            @(next);

            t.write_en = 0;
            t.read_en = 1;
            $display("[GEN] Reading data");
            mbx.put(t.copy());
            @(next);
        end
        -> done;
    endtask
endclass

// --------------------------------------
// Driver
// --------------------------------------
class fifo_driver;
    event next;
    mailbox #(fifo_transaction) mbx;
    fifo_transaction data;
    virtual fifo_if intf;

    function new(mailbox #(fifo_transaction) mbx, event next);
        this.mbx = mbx;
        this.next = next;
    endfunction

    task run();
        forever begin
            mbx.get(data);
            @(posedge intf.clk);
            intf.write = data.write_en;
            intf.read = data.read_en;
            if (data.write_en)
                intf.data_in = data.data;
            else
                intf.data_in = 8'd0;
            $display("[DRV] write=%0d read=%0d data_in=%0d", intf.write, intf.read, intf.data_in);
            -> next;
        end
    endtask
endclass

// --------------------------------------
// Monitor
// --------------------------------------
class fifo_monitor;
    virtual fifo_if intf;
    fifo_transaction data;
    mailbox #(fifo_transaction) mbx;

    function new(mailbox #(fifo_transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            @(posedge intf.clk);
            if (intf.read && !intf.empty) begin
                data = new();
                data.data = intf.data_out;
                $display("[MON] Read data: %0d", data.data);
                mbx.put(data);
            end
        end
    endtask
endclass

// --------------------------------------
// Scoreboard
// --------------------------------------
class fifo_scoreboard;
    fifo_transaction data;
    mailbox #(fifo_transaction) mbx;
    logic [7:0] ref_mem[$]; // Dynamic queue

    function new(mailbox #(fifo_transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            mbx.get(data);
            if (ref_mem.size() > 0) begin
                logic [7:0] expected = ref_mem.pop_front();
                $display("[SCO] Expected: %0d, Got: %0d", expected, data.data);
                if (expected == data.data) begin
                    $display("[SCO] PASS");
                end else begin
                    $display("[SCO] FAIL - Mismatch!");
                end
            end else begin
                $display("[SCO] Warning: Unexpected data received: %0d", data.data);
            end
        end
    endtask

    // Additional task to push expected data during write
    task push_expected(logic [7:0] data_in);
        ref_mem.push_back(data_in);
    endtask
endclass

// --------------------------------------
// Testbench Top
// --------------------------------------
module fifo_tb;
    fifo_generator gnr;
    fifo_driver drv;
    fifo_monitor mon;
    fifo_scoreboard sco;
    fifo_if intf();
    mailbox #(fifo_transaction) mbx;
    mailbox #(fifo_transaction) mbx2;
    event done;
    event next;

    fifo dut(
        .clk(intf.clk),
        .write(intf.write),
        .read(intf.read),
        .data_in(intf.data_in),
        .data_out(intf.data_out),
        .full(intf.full),
        .empty(intf.empty)
    );

    initial begin
        mbx = new();
        mbx2 = new();
        gnr = new(mbx);
        drv = new(mbx, next);
        mon = new(mbx2);
        sco = new(mbx2);

        gnr.done = done;
        gnr.next = next;
        drv.intf = intf;
        mon.intf = intf;

        fork
            gnr.run();
            drv.run();
            mon.run();
            sco.run();
        join_none

        @(done);
        $finish();
    end

    // Clock generation
    initial begin
        intf.clk = 0;
        forever #5 intf.clk = ~intf.clk; // Clock with 10ns period
    end

    // Push expected data to scoreboard during writes
    initial begin
        forever begin
            @(posedge intf.clk);
            if (intf.write && !intf.full) begin
                sco.push_expected(intf.data_in);
            end
        end
    end
endmodule
