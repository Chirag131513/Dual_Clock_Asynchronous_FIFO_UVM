// Test just the pointer logic - FIXED
`timescale 1ns/1ps

module tb_wptr_only;

localparam ASIZE = 4;

reg [ASIZE:0] wbin;
wire [ASIZE:0] wgnext, wbnext;
reg winc, wfull, wclk, wrst_n;

assign wbnext = wbin + 1'b1;
assign wgnext = (wbnext >> 1) ^ wbnext;

always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n) begin
    wbin <= 0;
  end else begin
    wbin <= wbnext;
  end
end

initial begin
  wclk = 0;
  forever #10 wclk = ~wclk;
end

integer i;

initial begin
  $display("Testing binary pointer increment");
  
  wrst_n = 0; 
  #30;
  wrst_n = 1;
  #20;
  
  for (i = 0; i < 20; i = i + 1) begin
    @(posedge wclk);
    #1;
    $display("Cycle %0d: wbin=%0d (%5b), wbnext=%0d (%5b), wgnext=%5b", 
             i, wbin, wbin, wbnext, wbnext, wgnext);
  end
  
  $finish;
end

endmodule
