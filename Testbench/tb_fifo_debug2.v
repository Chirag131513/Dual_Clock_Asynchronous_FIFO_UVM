// Debug testbench for FIFO - checking full flag behavior
`timescale 1ns/1ps

module tb_fifo_debug2;

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
  $display("==============================================");
  $display("FIFO Full Flag Debug Test");
  $display("==============================================");
  
  // Initialize
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  $display("\nWriting 16 items to fill the FIFO...");
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge wclk);
    wdata = i;
    winc = 1;
    #1;
    $display("Time=%0t, Write #%0d, wfull=%b, rempty=%b", $time, i, wfull, rempty);
    winc = 0;
    if (wfull) begin
      $display("FIFO became FULL at write #%0d", i);
      break;
    end
  end
  
  #200;
  
  $display("\nReading all items from FIFO...");
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    $display("Time=%0t, Read #%0d, data=%0d, wfull=%b, rempty=%b", $time, i, rdata, wfull, rempty);
    rinc = 0;
    if (rempty && i > 0) begin
      $display("FIFO became EMPTY at read #%0d", i);
      break;
    end
  end
  
  #100;
  $finish;
end

endmodule
