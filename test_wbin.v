// Minimal test to check wbin increment
module test;

reg [4:0] wbin = 0;
reg       winc = 0;
reg       wfull = 0;
reg       wclk = 0;
reg       wrst_n = 1;

wire [4:0] wbnext = wbin + (winc & ~wfull);

always #5 wclk = ~wclk;

integer i;

initial begin
  $display("Testing wbin increment logic...");
  
  for (i = 0; i < 10; i = i + 1) begin
    @(posedge wclk);
    winc = 1;
    #1;
    $display("i=%d, wbin=%d, wbnext=%d, winc&~wfull=%b", i, wbin, wbnext, (winc & ~wfull));
    wbin <= wbnext;
    winc = 0;
  end
  
  $finish;
end

endmodule
