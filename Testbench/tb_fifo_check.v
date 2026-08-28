// Simple test to check if writes are actually happening
`timescale 1ns/1ps

module tb_fifo_check;

localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 10;

reg [DSIZE-1:0] wdata;
reg             winc;
reg             wclk;
reg             wrst_n;

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
  .rinc(1'b0),  // No reads
  .rclk(1'b0),
  .rrst_n(1'b1)
);

integer i;

initial begin
  wclk = 0;
  forever #(WCLK_PERIOD/2) wclk = ~wclk;
end

initial begin
  $display("==============================================");
  $display("FIFO Write Check");
  $display("==============================================");
  
  wdata = 0; winc = 0; wrst_n = 0;
  #20;
  wrst_n = 1;
  #50;
  
  $display("\nWriting with winc=1 continuously...");
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge wclk);
    wdata = i * 16;  // Distinct pattern
    winc = 1;
    #1;
    $display("Time=%0t | i=%2d | wdata=%3d | wfull=%b", $time, i, wdata, wfull);
  end
  
  #100;
  
  $display("\nChecking memory content by reading...");
  // Now toggle rclk and read
  for (i = 0; i < 20; i = i + 1) begin
    #7;  // Small delay for read
    $display("Time=%0t | Read data=%3d", $time, rdata);
  end
  
  #100;
  $finish;
end

endmodule
