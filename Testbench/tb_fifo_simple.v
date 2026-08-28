// ============================================================================
// Simple Testbench for Dual-Clock Asynchronous FIFO
// For Icarus Verilog (iverilog) Simulation
// ============================================================================
`timescale 1ns/1ps

module tb_fifo_simple;

// Parameters
localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 10;  // 100 MHz
localparam RCLK_PERIOD = 15;  // ~66.67 MHz

// Signals
reg [DSIZE-1:0] wdata;
reg             winc;
reg             wclk;
reg             wrst_n;
reg             rinc;
reg             rclk;
reg             rrst_n;

wire [DSIZE-1:0] rdata;
wire             wfull;
wire             rempty;

// Instantiate FIFO
fifo1 uut (
  .rdata(rdata),
  .wfull(wfull),
  .rempty(rempty),
  .wdata(wdata),
  .winc(winc),
  .wclk(wclk),
  .wrst_n(wrst_n),
  .rinc(rinc),
  .rclk(rclk),
  .rrst_n(rrst_n)
);

// Clock generation
initial begin
  wclk = 0;
  forever #(WCLK_PERIOD/2) wclk = ~wclk;
end

initial begin
  rclk = 0;
  forever #(RCLK_PERIOD/2) rclk = ~rclk;
end

// Test sequence
integer write_count = 0;
integer read_count = 0;
integer errors = 0;
reg [DSIZE-1:0] data_queue[0:20];
integer queue_head = 0;
integer queue_tail = 0;
integer fill_count = 0;
integer empty_count = 0;

initial begin
  $display("==============================================");
  $display("Dual-Clock Asynchronous FIFO Simulation");
  $display("==============================================");
  $display("Write Clock Period: %0t ns", WCLK_PERIOD);
  $display("Read Clock Period:  %0t ns", RCLK_PERIOD);
  $display("FIFO Depth: %0d", 1<<ASIZE);
  $display("Data Width: %0d bits", DSIZE);
  $display("==============================================");
  
  // Initialize signals
  wdata = 0;
  winc = 0;
  wrst_n = 0;
  rinc = 0;
  rrst_n = 0;
  
  // Apply reset
  $display("\n[%0t] Asserting resets...", $time);
  #20;
  wrst_n = 1;
  rrst_n = 1;
  $display("[%0t] Releases resets", $time);
  
  // Wait for clocks to stabilize
  #50;
  
  // Test 1: Write some data
  $display("\n[%0t] TEST 1: Writing data to FIFO...", $time);
  repeat (8) begin
    @(posedge wclk);
    wdata = write_count;
    winc = 1;
    if (!wfull) begin
      data_queue[queue_tail] = write_count;
      queue_tail = queue_tail + 1;
      $display("[%0t] WRITE: data=%0d, wfull=%b", $time, write_count, wfull);
      write_count = write_count + 1;
    end else begin
      $display("[%0t] WRITE: FIFO full, skipping", $time);
    end
    winc = 0;
  end
  
  // Wait for read domain to catch up
  #100;
  
  // Test 2: Read data back
  $display("\n[%0t] TEST 2: Reading data from FIFO...", $time);
  repeat (8) begin
    @(posedge rclk);
    rinc = 1;
    if (!rempty) begin
      $display("[%0t] READ:  data=%0d (expected %0d), rempty=%b", 
               $time, rdata, data_queue[queue_head], rempty);
      if (rdata !== data_queue[queue_head]) begin
        $display("  ERROR: Data mismatch!");
        errors = errors + 1;
      end
      queue_head = queue_head + 1;
      read_count = read_count + 1;
    end else begin
      $display("[%0t] READ:  FIFO empty, skipping", $time);
    end
    rinc = 0;
  end
  
  // Test 3: Fill FIFO completely
  $display("\n[%0t] TEST 3: Filling FIFO to capacity...", $time);
  fill_count = 0;
  while (fill_count < 20 && !wfull) begin
    @(posedge wclk);
    wdata = write_count;
    winc = 1;
    if (!wfull) begin
      data_queue[queue_tail] = write_count;
      queue_tail = queue_tail + 1;
      write_count = write_count + 1;
    end
    winc = 0;
    fill_count = fill_count + 1;
  end
  if (wfull) begin
    $display("[%0t] FIFO FULL after %0d writes", $time, write_count);
  end
  
  // Verify full flag
  #20;
  if (wfull) begin
    $display("[%0t] ✓ Full flag correctly asserted", $time);
  end else begin
    $display("[%0t] ✗ ERROR: Full flag not asserted!", $time);
    errors = errors + 1;
  end
  
  // Test 4: Read all data
  $display("\n[%0t] TEST 4: Emptying FIFO completely...", $time);
  empty_count = 0;
  while (empty_count < 20 && !rempty) begin
    @(posedge rclk);
    rinc = 1;
    if (!rempty) begin
      $display("[%0t] READ: data=%0d (expected %0d)", 
               $time, rdata, data_queue[queue_head]);
      if (rdata !== data_queue[queue_head]) begin
        $display("  ERROR: Data mismatch!");
        errors = errors + 1;
      end
      queue_head = queue_head + 1;
      read_count = read_count + 1;
    end
    rinc = 0;
    empty_count = empty_count + 1;
  end
  if (rempty) begin
    $display("[%0t] FIFO EMPTY after %0d reads", $time, read_count);
  end
  
  // Verify empty flag
  #20;
  if (rempty) begin
    $display("[%0t] ✓ Empty flag correctly asserted", $time);
  end else begin
    $display("[%0t] ✗ ERROR: Empty flag not asserted!", $time);
    errors = errors + 1;
  end
  
  // Final summary
  #50;
  $display("\n==============================================");
  $display("SIMULATION SUMMARY");
  $display("==============================================");
  $display("Total Writes: %0d", write_count);
  $display("Total Reads:  %0d", read_count);
  $display("Errors:       %0d", errors);
  if (errors == 0) begin
    $display("STATUS: ✓ PASS - All tests passed!");
  end else begin
    $display("STATUS: ✗ FAIL - %0d error(s) detected", errors);
  end
  $display("==============================================");
  
  $finish;
end

// Monitor for unexpected behavior
always @(posedge wfull) begin
  if (winc && !wfull) begin
    $display("[%0t] WARNING: Write attempted while FIFO becoming full", $time);
  end
end

always @(posedge rempty) begin
  if (rinc && !rempty) begin
    $display("[%0t] WARNING: Read attempted while FIFO becoming empty", $time);
  end
end

endmodule
