// Probe internal signals
`timescale 1ns/1ps

module tb_internal_probe;

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
  $display("Internal Signal Probe");
  $display("==============================================");
  
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  for (i = 0; i < 17; i = i + 1) begin
    @(posedge wclk);
    wdata = i + 1;
    winc = 1;
    #1;
    
    // Access internal signals
    $display("Time=%0t | Write #%2d | wbin=%0d | wptr(gray)=%b | rwptr2=%b | wfull_val=%b | wfull=%b", 
             $time, i+1,
             uut.wptr_full_inst.wbin,
             uut.wptr,
             uut.rwptr2,
             uut.wptr_full_inst.wfull_val,
             wfull);
    winc = 0;
  end
  
  #100;
  $finish;
end

endmodule
