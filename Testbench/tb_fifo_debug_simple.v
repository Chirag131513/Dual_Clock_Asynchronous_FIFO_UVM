// Simple debug testbench for Dual-Clock Async FIFO
`timescale 1ns/1ps

module tb_fifo_debug_simple;

localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 20;
localparam RCLK_PERIOD = 30;

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

integer i;

initial begin
  $display("============================================");
  $display("Simple Debug Test");
  $display("============================================\n");
  
  // Reset
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  $display("After reset: rempty=%b, wfull=%b", rempty, wfull);
  
  // Write 5 items one by one
  $display("\n--- Writing 5 items ---");
  for (i = 1; i <= 5; i = i + 1) begin
    @(posedge wclk);
    wdata = i;
    winc = 1;
    #1;
    $display("Write cycle %0d: wdata=%0d, winc=%b, wfull=%b, waddr should update", i, wdata, winc, wfull);
    winc = 0;
    #10;
    $display("  After write %0d: rempty=%b", i, rempty);
  end
  
  #100;
  $display("\nAfter all writes: rempty=%b, wfull=%b", rempty, wfull);
  
  // Now try to read
  $display("\n--- Reading 5 items ---");
  for (i = 1; i <= 5; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    $display("Read cycle %0d: rinc=%b, rempty=%b, rdata=%0d", i, rinc, rempty, rdata);
    rinc = 0;
    #10;
  end
  
  #50;
  $display("\nFinal: rempty=%b", rempty);
  
  $finish;
end

endmodule
