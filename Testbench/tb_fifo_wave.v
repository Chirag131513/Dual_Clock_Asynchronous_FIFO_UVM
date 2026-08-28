// Waveform testbench for FIFO debugging
`timescale 1ns/1ps

module tb_fifo_wave;

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

initial begin
  $dumpfile("fifo_waveform.vcd");
  $dumpvars(0, tb_fifo_wave);
  
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  // Write exactly 16 items
  repeat (16) begin
    @(posedge wclk);
    wdata = wdata + 1;
    winc = 1;
    #1;
    winc = 0;
  end
  
  #200;
  
  // Read all items
  repeat (16) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    rinc = 0;
  end
  
  #100;
  $finish;
end

endmodule
