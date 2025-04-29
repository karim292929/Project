`timescale 1ns / 1ps
class transaction;
   randc logic up_down;        // Control bit: up or down
   logic [3:0] expected_count; // Expected counter value

   function transaction copy();
      transaction t = new();
      t.up_down = this.up_down;
      t.expected_count = this.expected_count;
      return t;
   endfunction
endclass

class generator;
   event done;
   event next;
   transaction t;
   mailbox #(transaction) mbx;
   
   function new(mailbox #(transaction) mbx);
      this.mbx = mbx;
      t = new();
   endfunction
   
   task run();
      for (int i = 0; i < 16; i++) begin
         t.up_down = $random % 2; // Random up or down (0 or 1)
         t.expected_count = (t.up_down) ? (i + 1) : (i - 1); // Calculate expected value
         mbx.put(t.copy()); // Send transaction to driver
         ->next;
      end
      ->done;
   endtask
endclass

interface counter_if();
   logic clk;
   logic reset;
   logic up_down;
   logic [3:0] count;
endinterface

class driver;
   event next;
   mailbox #(transaction) mbx;
   transaction data;
   virtual counter_if intf;

   function new(mailbox #(transaction) mbx, event next);
      this.mbx = mbx;
      this.next = next;
   endfunction

   task run();
      forever begin
         mbx.get(data); 
         intf.up_down = data.up_down; // Apply up/down control signal
         $display("[DRV] Applying up_down: %0d, Expected count: %0d", data.up_down, data.expected_count);
         ->next;
      end
   endtask
endclass

class monitor;
   virtual counter_if intf;
   transaction data;
   mailbox #(transaction) mbx;
   
   function new(mailbox #(transaction) mbx);
      this.mbx = mbx;
   endfunction

   task run();
      forever begin
         #1; // Delay for next observation
         data = new();
         data.up_down = intf.up_down;
         data.expected_count = intf.count;  // Read the count value from DUT
         $display("[MON] Count: %0d, Up/Down: %0d", intf.count, intf.up_down);
         mbx.put(data);  // Send observed data to scoreboard
      end
   endtask
endclass

class scoreboard;
   transaction data;
   mailbox #(transaction) mbx;
   logic [3:0] expected_count;

   function new(mailbox #(transaction) mbx);
      this.mbx = mbx;
   endfunction

   task run();
      forever begin
         mbx.get(data); // Get the observed data
         $display("[SCO] Expected Count: %0d, Observed Count: %0d", data.expected_count, data.expected_count);
         if (data.expected_count == data.expected_count) begin
            $display("[SCO] Passed: Expected Count = Observed Count");
         end else begin
            $display("[SCO] Failed: Expected Count != Observed Count");
         end
      end
   endtask
endclass

module up_down_counter_tb;
   generator gnr;
   driver drv;
   monitor mon;
   scoreboard sco;
   counter_if intf();
   mailbox #(transaction) mbx;
   mailbox #(transaction) mbx2;
   event done;
   event next;

   up_down_counter dut (
      .clk(intf.clk),
      .reset(intf.reset),
      .up_down(intf.up_down),
      .count(intf.count)
   );

   initial begin
      mbx = new();
      mbx2 = new();
      gnr = new(mbx);
      mon = new(mbx2);
      sco = new(mbx2);
      drv = new(mbx, next);

      gnr.done = done;
      gnr.next = next;
      drv.intf = intf;
      mon.intf = intf;

      // Generate the clock
      forever #5 intf.clk = ~intf.clk;
   end

   initial begin
      gnr.run();
      drv.run();
      mon.run();
      sco.run();
      @(done);
      $finish;
   end
endmodule
