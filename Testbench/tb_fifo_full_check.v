// Check full flag logic with proper read clock
`timescale 1ns/1ps

module tb_fifo_full_check;

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
  $display("FIFO Full Flag Check - Write 16, Read 1, Write more");
  $display("==============================================");
  
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  // Write exactly 16 items
  $display("\nWriting 16 items...");
  for (i = 0; i < 16; i = i + 1) begin
    @(posedge wclk);
    wdata = i + 1;
    winc = 1;
    #1;
    $display("Time=%0t | Write #%2d | data=%3d | wfull=%b", $time, i+1, wdata, wfull);
    winc = 0;
  end
  
  #50;
  
  // Try to write one more
  $display("\nTrying to write 17th item...");
  @(posedge wclk);
  wdata = 99;
  winc = 1;
  #1;
  $display("Time=%0t | Write #17 | data=%3d | wfull=%b (should be 1)", $time, wdata, wfull);
  winc = 0;
  
  #100;
  $finish;
end

endmodule
