// Debug testbench - checking internal signals
`timescale 1ns/1ps

module tb_fifo_full_debug;

localparam DSIZE = 8;
localparam ASIZE = 4;
localparam WCLK_PERIOD = 10;

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

// Internal wires
wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0] wptr, rptr, wrptr2, rwptr2;

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

// Probe internal signals by instantiating submodules directly
wire [ASIZE:0] wbin_internal, rbin_internal;

initial begin
  wclk = 0;
  forever #(WCLK_PERIOD/2) wclk = ~wclk;
end

initial begin
  rclk = 0;
  forever #7 rclk = ~rclk;  // Slightly different frequency
end

integer i;

initial begin
  $display("==============================================");
  $display("FIFO Full Flag Debug - Internal Signals");
  $display("==============================================");
  
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #50;
  
  $display("\nWriting 20 items (FIFO depth is 16)...");
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge wclk);
    wdata = i;
    winc = 1;
    #1;
    
    // Access internal signals through hierarchical reference
    $display("Time=%0t | Write #%2d | wfull=%b | waddr=%0d | wptr(bin)=%0d | wptr(gray)=%b | rwptr2=%b", 
             $time, i, wfull, 
             uut.waddr, 
             uut.wptr_full_inst.wbin,
             uut.wptr,
             uut.rwptr2);
    
    winc = 0;
  end
  
  #200;
  $finish;
end

endmodule
