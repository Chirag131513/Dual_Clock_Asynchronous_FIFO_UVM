// Final comprehensive testbench for Dual-Clock Async FIFO
`timescale 1ns/1ps

module tb_fifo_final;

localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 20;
localparam RCLK_PERIOD = 30;
localparam FIFO_DEPTH = 16;

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

initial begin
  wclk = 0;
  forever #(WCLK_PERIOD/2) wclk = ~wclk;
end

initial begin
  rclk = 0;
  forever #(RCLK_PERIOD/2) rclk = ~rclk;
end

integer i, errors, read_count, write_count;
reg [7:0] expected_data[0:50];
integer head, tail;
reg full_flag_seen;
reg empty_flag_seen;

initial begin
  $display("============================================");
  $display("Dual-Clock Asynchronous FIFO Test");
  $display("============================================");
  $display("FIFO Depth: %0d", FIFO_DEPTH);
  $display("Data Width: %0d bits", DSIZE);
  $display("============================================\n");
  
  errors = 0;
  head = 0;
  tail = 0;
  write_count = 0;
  read_count = 0;
  full_flag_seen = 0;
  empty_flag_seen = 0;
  
  // Reset
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  // Check initial empty
  if (!rempty) begin
    $display("[FAIL] FIFO not empty after reset!");
    errors = errors + 1;
  end else begin
    $display("[PASS] FIFO empty after reset");
  end
  
  // Test 1: Write 10 items
  $display("\n--- Test 1: Writing 10 items ---");
  for (i = 0; i < 10; i = i + 1) begin
    @(posedge wclk);
    wdata = i + 1;
    winc = 1;
    #1;
    if (!wfull) begin
      expected_data[tail] = i + 1;
      tail = tail + 1;
      write_count = write_count + 1;
      $display("Write #%0d: data=%0d", write_count, i+1);
    end
    winc = 0;
  end
  
  #50;
  
  // Test 2: Read 5 items
  $display("\n--- Test 2: Reading 5 items ---");
  for (i = 0; i < 5; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    if (!rempty) begin
      $display("Read #%0d: data=%0d (expected %0d)", read_count+1, rdata, expected_data[head]);
      if (rdata !== expected_data[head]) begin
        $display("[FAIL] Data mismatch!");
        errors = errors + 1;
      end
      head = head + 1;
      read_count = read_count + 1;
    end
    rinc = 0;
  end
  
  #50;
  
  // Test 3: Fill to capacity (should write 11 more to fill 16-deep FIFO)
  $display("\n--- Test 3: Filling FIFO to capacity ---");
  for (i = 10; i < 30; i = i + 1) begin
    @(posedge wclk);
    wdata = i + 1;
    winc = 1;
    #1;
    if (!wfull) begin
      expected_data[tail] = i + 1;
      tail = tail + 1;
      write_count = write_count + 1;
    end
    winc = 0;
    if (wfull && !full_flag_seen) begin
      full_flag_seen = 1;
      $display("FIFO FULL at write #%0d (total written: %0d)", i+1, write_count);
    end
  end
  
  if (full_flag_seen) begin
    $display("[PASS] Full flag asserted correctly");
  end else begin
    $display("[FAIL] Full flag not asserted!");
    errors = errors + 1;
  end
  
  #50;
  
  // Test 4: Read all remaining
  $display("\n--- Test 4: Emptying FIFO completely ---");
  for (i = 0; i < 50; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    if (!rempty) begin
      $display("Read #%0d: data=%0d (expected %0d)", read_count+1, rdata, expected_data[head]);
      if (rdata !== expected_data[head]) begin
        $display("[FAIL] Data mismatch!");
        errors = errors + 1;
      end
      head = head + 1;
      read_count = read_count + 1;
    end
    rinc = 0;
    if (rempty && read_count > 0 && !empty_flag_seen) begin
      empty_flag_seen = 1;
      $display("FIFO EMPTY after %0d reads", read_count);
    end
  end
  
  if (empty_flag_seen) begin
    $display("[PASS] Empty flag asserted correctly");
  end else begin
    $display("[FAIL] Empty flag not asserted!");
    errors = errors + 1;
  end
  
  // Summary
  #50;
  $display("\n============================================");
  $display("SIMULATION SUMMARY");
  $display("============================================");
  $display("Total Writes: %0d", write_count);
  $display("Total Reads: %0d", read_count);
  $display("Total Errors: %0d", errors);
  if (errors == 0) begin
    $display("RESULT: ALL TESTS PASSED!");
  end else begin
    $display("RESULT: TESTS FAILED!");
  end
  $display("============================================");
  
  $finish;
end

endmodule
