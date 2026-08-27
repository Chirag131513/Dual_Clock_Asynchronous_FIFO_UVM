// Test wptr_full with output declared as wire
`timescale 1ns/1ps

module tb_wptr_standalone;

localparam ASIZE = 4;

wire              wfull;
wire [ASIZE-1:0]  waddr;
wire [ASIZE:0]    wptr;
reg [ASIZE:0]     wrptr2;
reg               winc;
reg               wclk;
reg               wrst_n;

wptr_full #(ASIZE) uut (
  .wfull(wfull),
  .waddr(waddr),
  .wptr(wptr),
  .wrptr2(wrptr2),
  .winc(winc),
  .wclk(wclk),
  .wrst_n(wrst_n)
);

integer i;

initial begin
  wclk = 0;
  forever #5 wclk = ~wclk;
end

initial begin
  $display("==============================================");
  $display("wptr_full Standalone Test");
  $display("==============================================");
  
  winc = 0; wrst_n = 0; wrptr2 = 0;
  #20;
  wrst_n = 1;
  #50;
  
  $display("\nWriting with wrptr2=0...");
  for (i = 0; i < 18; i = i + 1) begin
    @(posedge wclk);
    winc = 1;
    #1;
    $display("Time=%0t | i=%2d | wbin=%0d | wptr=%b | wfull=%b | waddr=%0d",
             $time, i,
             uut.wbin,
             wptr,
             wfull,
             waddr);
    winc = 0;
  end
  
  #100;
  $finish;
end

endmodule
