// Debug testbench for FIFO - No break statements
`timescale 1ns/1ps

module tb_fifo_debug;

localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 10;
localparam RCLK_PERIOD = 15;

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
  $display("Starting debug test...");
  
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  // Write items until full (max 20)
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge wclk);
    wdata = i;
    winc = 1;
    #1;
    $display("Time=%0t: Write i=%0d, wfull=%b", $time, i, wfull);
    winc = 0;
    if (wfull) begin
      $display("FIFO FULL at i=%0d", i);
      i = 20; // Exit loop
    end
  end
  
  #100;
  
  // Read all items
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    $display("Time=%0t: Read i=%0d, rdata=%0d, rempty=%b", $time, i, rdata, rempty);
    rinc = 0;
    if (rempty && i > 0) begin
      $display("FIFO EMPTY after %0d reads", i);
      i = 20; // Exit loop
    end
  end
  
  $finish;
end

endmodule
