// Debug testbench with VCD waveform output
`timescale 1ns/1ps

module tb_fifo_wave_debug;

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

// Internal signals for debugging
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
wire [ASIZE:0] wgnext_internal, rgnext_internal;

initial begin
  $dumpfile("fifo_debug.vcd");
  $dumpvars(0, tb_fifo_wave_debug);
end

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
  $display("Waveform Debug Test");
  $display("============================================\n");
  
  // Reset
  wdata = 0; winc = 0; wrst_n = 0; rinc = 0; rrst_n = 0;
  #20;
  wrst_n = 1; rrst_n = 1;
  #100;
  
  $display("After reset: rempty=%b, wfull=%b", rempty, wfull);
  
  // Write 16 items to fill FIFO
  $display("\n--- Writing up to 16 items ---");
  for (i = 1; i <= 20; i = i + 1) begin
    @(posedge wclk);
    wdata = i;
    winc = 1;
    #1;
    $display("Time=%0t: Write attempt %0d - wdata=%0d, wfull=%b, rempty=%b", 
             $time, i, wdata, wfull, rempty);
    winc = 0;
    #15;
  end
  
  #200;
  
  // Read all items
  $display("\n--- Reading items ---");
  for (i = 1; i <= 20; i = i + 1) begin
    @(posedge rclk);
    rinc = 1;
    #1;
    $display("Time=%0t: Read attempt %0d - rdata=%0d, rempty=%b, wfull=%b", 
             $time, i, rdata, rempty, wfull);
    rinc = 0;
    #25;
  end
  
  #100;
  $display("\nFinal: rempty=%b, wfull=%b", rempty, wfull);
  $display("Simulation complete. Check fifo_debug.vcd for waveforms.");
  
  $finish;
end

endmodule
