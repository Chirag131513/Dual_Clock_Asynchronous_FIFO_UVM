// ============================================================================
// Top Level FIFO Module
// ============================================================================
module fifo1 (
  output [7:0] rdata,
  output       wfull,
  output       rempty,
  input  [7:0] wdata,
  input        winc,
  input        wclk,
  input        wrst_n,
  input        rinc,
  input        rclk,
  input        rrst_n
);

parameter DSIZE = 8;
parameter ASIZE = 4;

wire [ASIZE-1:0] waddr, raddr;
wire [ASIZE:0] wptr, rptr, wrptr2, rwptr2;

sync_r2w #(ASIZE) sync_r2w_inst (
  .wrptr2(wrptr2),
  .rptr(rptr),
  .wclk(wclk),
  .wrst_n(wrst_n)
);

sync_w2r #(ASIZE) sync_w2r_inst (
  .rwptr2(rwptr2),
  .wptr(wptr),
  .rclk(rclk),
  .rrst_n(rrst_n)
);

fifomem #(DSIZE, ASIZE) fifomem_inst (
  .rdata(rdata),
  .wdata(wdata),
  .waddr(waddr),
  .raddr(raddr),
  .wclken(winc),
  .wfull_n(~wfull),
  .wclk(wclk)
);

rptr_empty #(ASIZE) rptr_empty_inst (
  .rempty(rempty),
  .raddr(raddr),
  .rptr(rptr),
  .rwptr2(rwptr2),
  .rinc(rinc),
  .rclk(rclk),
  .rrst_n(rrst_n)
);

wptr_full #(ASIZE) wptr_full_inst (
  .wfull(wfull),
  .waddr(waddr),
  .wptr(wptr),
  .wrptr2(wrptr2),
  .winc(winc),
  .wclk(wclk),
  .wrst_n(wrst_n)
);

endmodule

// ============================================================================
// Read Pointer and Empty Generation Module
// ============================================================================
module rptr_empty #(
  parameter ADDRSIZE = 4
) (
  output reg              rempty,
  output [ADDRSIZE-1:0]   raddr,
  output reg [ADDRSIZE:0] rptr,
  input  [ADDRSIZE:0]     rwptr2,
  input                   rinc,
  input                   rclk,
  input                   rrst_n
);

reg [ADDRSIZE:0] rbin;
wire [ADDRSIZE:0] rgnext, rbnext;

// Memory read-address pointer
assign raddr = rbin[ADDRSIZE-1:0];

// Generate next binary and Gray values
assign rbnext = rbin + (rinc & ~rempty);
assign rgnext = (rbnext >> 1) ^ rbnext;

// Update pointers
always @(posedge rclk or negedge rrst_n) begin
  if (!rrst_n) begin
    rbin <= {(ADDRSIZE+1){1'b0}};
    rptr <= {(ADDRSIZE+1){1'b0}};
  end else begin
    rbin <= rbnext;
    rptr <= rgnext;
  end
end

// Empty detection
wire rempty_val;
assign rempty_val = (rgnext == rwptr2);

always @(posedge rclk or negedge rrst_n) begin
  if (!rrst_n)
    rempty <= 1'b1;
  else
    rempty <= rempty_val;
end

endmodule

// ============================================================================
// Synchronizer Read to Write Clock Domain
// ============================================================================
module sync_r2w #(
  parameter ADDRSIZE = 4
) (
  output reg [ADDRSIZE:0] wrptr2,
  input  [ADDRSIZE:0]     rptr,
  input                   wclk,
  input                   wrst_n
);

reg [ADDRSIZE:0] wrptr1;

always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n) begin
    wrptr2 <= {(ADDRSIZE+1){1'b0}};
    wrptr1 <= {(ADDRSIZE+1){1'b0}};
  end else begin
    wrptr1 <= rptr;
    wrptr2 <= wrptr1;
  end
end

endmodule

// ============================================================================
// Synchronizer Write to Read Clock Domain
// ============================================================================
module sync_w2r #(
  parameter ADDRSIZE = 4
) (
  output reg [ADDRSIZE:0] rwptr2,
  input  [ADDRSIZE:0]     wptr,
  input                   rclk,
  input                   rrst_n
);

reg [ADDRSIZE:0] rwptr1;

always @(posedge rclk or negedge rrst_n) begin
  if (!rrst_n) begin
    rwptr2 <= {(ADDRSIZE+1){1'b0}};
    rwptr1 <= {(ADDRSIZE+1){1'b0}};
  end else begin
    rwptr1 <= wptr;
    rwptr2 <= rwptr1;
  end
end

endmodule

// ============================================================================
// Write Pointer and Full Generation Module
// ============================================================================
module wptr_full #(
  parameter ADDRSIZE = 4
) (
  output reg              wfull,
  output [ADDRSIZE-1:0]   waddr,
  output reg [ADDRSIZE:0] wptr,
  input  [ADDRSIZE:0]     wrptr2,
  input                   winc,
  input                   wclk,
  input                   wrst_n
);

reg [ADDRSIZE:0] wbin;
wire [ADDRSIZE:0] wgnext, wbnext;

// Memory write-address pointer
assign waddr = wbin[ADDRSIZE-1:0];

// Generate next binary and Gray values
assign wbnext = wbin + (winc & ~wfull);
assign wgnext = (wbnext >> 1) ^ wbnext;

// Update pointers
always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n) begin
    wbin <= {(ADDRSIZE+1){1'b0}};
    wptr <= {(ADDRSIZE+1){1'b0}};
  end else begin
    wbin <= wbnext;
    wptr <= wgnext;
  end
end

wire wfull_val;
assign wfull_val = (wgnext == {~wrptr2[ADDRSIZE:ADDRSIZE-1], wrptr2[ADDRSIZE-2:0]});

always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n)
    wfull <= 1'b0;
  else
    wfull <= wfull_val;
end

endmodule

// ============================================================================
// FIFO Memory Array Module
// ============================================================================
module fifomem #(
  parameter DATASIZE = 8,
  parameter ADDRSIZE = 4
) (
  output [DATASIZE-1:0] rdata,
  input  [DATASIZE-1:0] wdata,
  input  [ADDRSIZE-1:0] waddr,
  input  [ADDRSIZE-1:0] raddr,
  input                 wclken,
  input                 wfull_n,
  input                 wclk
);

localparam DEPTH = 1 << ADDRSIZE;

// Memory array
reg [DATASIZE-1:0] MEM [0:DEPTH-1];

// Asynchronous read
assign rdata = MEM[raddr];

// Synchronous write
always @(posedge wclk) begin
  if (wclken && wfull_n) begin
    MEM[waddr] <= wdata;
  end
end

endmodule
