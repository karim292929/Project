`timescale 1ns / 1ps
// 1. TRANSACTION CLASS
class transaction;
  randc logic [3:0] a, b;
  logic [2:0] op;
  logic [7:0] y;

  function transaction copy();
    transaction t = new();
    t.a = this.a;
    t.b = this.b;
    t.op = this.op;
    t.y = this.y;
    return t;
  endfunction
endclass

// 2. GENERATOR CLASS
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
    for (t.op = 0; t.op <= 3; t.op++) begin
      t.randomize();
      $display("[GEN] op: %0d a: %0d b: %0d", t.op, t.a, t.b);
      mbx.put(t.copy());
      @(next); // wait until driver drives
    end
    ->done; // tell environment that generator finished
  endtask
endclass

// 3. INTERFACE
interface aif();
  logic [3:0] a, b;
  logic [2:0] op;
  logic [7:0] y;
endinterface

// 4. DRIVER CLASS
class driver;
  event next;
  mailbox #(transaction) mbx;
  transaction data;
  virtual aif intf;

  function new(mailbox #(transaction) mbx, event next);
    this.mbx = mbx;
    this.next = next;
  endfunction

  task run();
    forever begin
      mbx.get(data);
      intf.a = data.a;
      intf.b = data.b;
      intf.op = data.op;
      #1; // Important: give time to DUT to compute
      $display("[DRV] op: %0d a: %0d b: %0d", data.op, data.a, data.b);
      ->next; // inform generator to continue
    end
  endtask
endclass

// 5. MONITOR CLASS
class monitor;
  virtual aif intf;
  transaction data;
  mailbox #(transaction) mbx;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      #1; // wait after driver
      data = new();
      data.a = intf.a;
      data.b = intf.b;
      data.op = intf.op;
      data.y = intf.y;
      $display("[MON] op: %0d a: %0d b: %0d y: %0d", data.op, data.a, data.b, data.y);
      mbx.put(data);
    end
  endtask
endclass

// 6. SCOREBOARD CLASS
class scoreboard;
  transaction data;
  mailbox #(transaction) mbx;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      logic [7:0] Expected;
      mbx.get(data);
      $display("[SCO] op: %0d a: %0d b: %0d y: %0d", data.op, data.a, data.b, data.y);

      case (data.op)
        3'b000: Expected = data.a + data.b;
        3'b001: Expected = data.a - data.b;
        3'b010: Expected = data.a & data.b;
        3'b011: Expected = data.a | data.b;
        default: Expected = 8'b00000000;
      endcase

      if (Expected == data.y) begin
        $display("[PASS] Correct: a=%0d, b=%0d, y=%0d (Expected=%0d)", data.a, data.b, data.y, Expected);
      end else begin
        $display("[FAIL] Incorrect: a=%0d, b=%0d, y=%0d (Expected=%0d)", data.a, data.b, data.y, Expected);
      end
    end
  endtask
endclass

// 7. TOP MODULE
module dv;
  generator gnr;
  driver drv;
  monitor mon;
  scoreboard sco;
  aif intf();
  mailbox #(transaction) mbx;
  mailbox #(transaction) mbx2;
  event done;
  event next;

  Design dut(.a(intf.a), .b(intf.b), .y(intf.y), .op(intf.op));

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

    @(done); // wait until generator signals done
    $finish();
  end
endmodule
