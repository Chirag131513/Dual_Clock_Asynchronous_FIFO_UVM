// Standalone test for wptr_full module - FIXED timing
`timescale 1ns/1ps

module tb_fifo_standalone;

localparam ASIZE = 4;

wire            wfull;
wire [ASIZE-1:0] waddr;
wire [ASIZE:0] wptr;
reg  [ASIZE:0] wrptr2;
reg             winc;
reg             wclk;
reg             wrst_n;

wptr_full #(ASIZE) uut (
  .wfull(wfull),
  .waddr(waddr),
  .wptr(wptr),
  .wrptr2(wrptr2),
  .winc(winc),
  .wclk(wclk),
  .wrst_n(wrst_n)
);

initial begin
  wclk = 0;
  forever #10 wclk = ~wclk;
end

integer i;

initial begin
  $display("Testing wptr_full module standalone");
  
  // Initialize
  wrst_n = 0; wrptr2 = 0; winc = 0;
  #30;
  wrst_n = 1;
  wrptr2 = 5'b00000;  // Keep read pointer at 0
  #20;
  
  $display("After reset: wfull=%b, wptr=%b, waddr=%b", wfull, wptr, waddr);
  
  // Write 20 items to see when full triggers
  for (i = 1; i <= 20; i = i + 1) begin
    @(posedge wclk);
    winc = 1;
    #1;
    $display("Write %0d: wptr=%b, wrptr2=%b, waddr=%b, wfull=%b", 
             i, wptr, wrptr2, waddr, wfull);
    winc = 0;
    #19;
  end
  
  $finish;
end

endmodule
