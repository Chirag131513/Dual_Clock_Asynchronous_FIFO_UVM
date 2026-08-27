// ============================================================================
// Module: Dual-Clock Asynchronous FIFO
// File: dual_clock_async_fifo_design.v
// ============================================================================
// Description:
//   This module implements a fully synchronous dual-clock asynchronous FIFO 
//   (First-In-First-Out) buffer that allows data transfer between two 
//   independent clock domains. The design uses Gray code pointers to safely 
//   cross clock domains and prevent metastability issues.
//
// Architecture:
//   - Memory array: 16 locations × 8 bits (configurable via parameters)
//   - Write clock domain (wclk): Handles write operations and full flag
//   - Read clock domain (rclk): Handles read operations and empty flag
//   - Pointer synchronization: 2-stage synchronizers for safe CDC
//   - Gray code encoding: Ensures only one bit changes during pointer updates
//
// Key Features:
//   • Asynchronous read, synchronous write memory architecture
//   • Full and empty flags generated in respective clock domains
//   • Active-low asynchronous reset for both clock domains
//   • Parameterizable data width (DSIZE) and address width (ASIZE)
//   • Safe clock domain crossing using Gray code pointers
//   • No data loss under normal operating conditions
//
// Parameters:
//   DSIZE - Data width in bits (default: 8)
//   ASIZE - Address width in bits (default: 4, giving 2^4 = 16 depth)
//
// Ports:
//   Output:
//     rdata[7:0]  - Read data output (asynchronous to rclk)
//     wfull       - Write full flag (synchronized to wclk)
//                   When high, FIFO is full; writes should be inhibited
//     rempty      - Read empty flag (synchronized to rclk)
//                   When high, FIFO is empty; reads should be inhibited
//   
//   Input:
//     wdata[7:0]  - Write data input
//     winc        - Write increment enable (active high)
//                   When asserted and !wfull, data is written to FIFO
//     wclk        - Write clock domain
//     wrst_n      - Write domain asynchronous reset (active low)
//     rinc        - Read increment enable (active high)
//                   When asserted and !rempty, data is read from FIFO
//     rclk        - Read clock domain (independent of wclk)
//     rrst_n      - Read domain asynchronous reset (active low)
//
// Operation:
//   1. Write Operation:
//      - When winc=1 and wfull=0, data on wdata is written to memory
//      - Write pointer increments and converts to Gray code
//      - Gray-coded pointer synchronized to read clock domain
//   
//   2. Read Operation:
//      - When rinc=1 and rempty=0, data appears on rdata
//      - Read pointer increments and converts to Gray code
//      - Gray-coded pointer synchronized to write clock domain
//   
//   3. Full/Empty Detection:
//      - Empty: Read Gray pointer equals synchronized write pointer
//      - Full: Write Gray pointer equals inverted MSBs of sync'd read pointer
//
// Design Notes:
//   - Both clock domains must have resets asserted simultaneously for 
//     proper initialization, though they can be released asynchronously
//   - Maximum throughput is one word per clock cycle in each domain
//   - Gray code ensures safe CDC by allowing only single-bit transitions
//   - Two flip-flop synchronizers provide adequate MTBF for most applications
//
// Author: [Your Name]
// Date: [Date]
// Version: 1.0
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
  .wfull_n(!wfull),
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
// Module: Read Pointer and Empty Flag Generator
// ============================================================================
// Description:
//   Generates the read pointer in Gray code format and the empty flag for
//   the asynchronous FIFO. The read pointer is incremented when rinc is
//   asserted and the FIFO is not empty.
//
// Architecture:
//   - Maintains binary pointer (rbin) for address generation
//   - Converts binary to Gray code for safe clock domain crossing
//   - Compares synchronized write pointer with current read pointer
//   - Generates empty flag when pointers match
//
// Parameters:
//   ADDRSIZE - Address width in bits (default: 4)
//              Determines FIFO depth as 2^ADDRSIZE
//
// Ports:
//   Output:
//     rempty            - Empty flag (active high, synchronized to rclk)
//                         High when FIFO is empty, no valid data to read
//     raddr[ADDRSIZE-1:0] - Memory read address (binary, MSB excluded)
//     rptr[ADDRSIZE:0]    - Read pointer in Gray code format
//   
//   Input:
//     rwptr2[ADDRSIZE:0]  - Synchronized write pointer from write clock domain
//     rinc                - Read increment enable (active high)
//     rclk                - Read clock domain
//     rrst_n              - Asynchronous reset (active low)
//
// Operation:
//   1. Binary pointer increments when rinc=1 and !rempty
//   2. Binary pointer converted to Gray code: G = (B>>1) ^ B
//   3. Gray-coded pointer sent to write domain via synchronizer
//   4. Empty detected when local Gray pointer equals synced write pointer
//
// Design Notes:
//   - Uses ADDRSIZE+1 bits for pointer to distinguish full vs empty
//   - MSB of raddr excludes the extra pointer bit
//   - Empty flag registered for clean timing
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

// Update pointers - use current pointer for comparison, not next
always @(posedge rclk or negedge rrst_n) begin
  if (!rrst_n) begin
    rbin <= {(ADDRSIZE+1){1'b0}};
    rptr <= {(ADDRSIZE+1){1'b0}};
  end else begin
    rbin <= rbnext;
    rptr <= rgnext;
  end
end

// Empty detection - compare current Gray pointer with synchronized write pointer
wire rempty_val;
assign rempty_val = (rptr == rwptr2);

always @(posedge rclk or negedge rrst_n) begin
  if (!rrst_n)
    rempty <= 1'b1;
  else
    rempty <= rempty_val;
end

endmodule

// ============================================================================
// Module: Read-to-Write Clock Domain Synchronizer
// ============================================================================
// Description:
//   Two-stage synchronizer that safely transfers the read pointer (in Gray
//   code) from the read clock domain to the write clock domain. This is
//   critical for full flag generation in the write domain.
//
// Architecture:
//   - Uses two flip-flops in series for metastability resolution
//   - Input is Gray-coded pointer ensuring single-bit transitions
//   - Single-bit changes guarantee safe synchronization even if sampled
//     during metastable event
//
// Parameters:
//   ADDRSIZE - Address width in bits (default: 4)
//              Pointer width is ADDRSIZE+1 bits
//
// Ports:
//   Output:
//     wrptr2[ADDRSIZE:0] - Synchronized read pointer in write clock domain
//                          (2nd stage of synchronizer)
//   
//   Input:
//     rptr[ADDRSIZE:0]   - Read pointer in Gray code from read domain
//     wclk               - Write clock domain
//     wrst_n             - Asynchronous reset (active low)
//
// Operation:
//   1. On each wclk edge, rptr is sampled into wrptr1 (1st stage)
//   2. On next wclk edge, wrptr1 is transferred to wrptr2 (2nd stage)
//   3. wrptr2 is used by write domain for full flag comparison
//
// Design Notes:
//   - CRITICAL: Input must be Gray-coded to ensure only one bit changes
//   - Two stages provide adequate MTBF for most practical applications
//   - Reset must be asynchronous to handle power-up conditions
//   - For higher reliability requirements, consider 3+ stage synchronizers
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
// Module: Write-to-Read Clock Domain Synchronizer
// ============================================================================
// Description:
//   Two-stage synchronizer that safely transfers the write pointer (in Gray
//   code) from the write clock domain to the read clock domain. This is
//   critical for empty flag generation in the read domain.
//
// Architecture:
//   - Uses two flip-flops in series for metastability resolution
//   - Input is Gray-coded pointer ensuring single-bit transitions
//   - Single-bit changes guarantee safe synchronization even if sampled
//     during metastable event
//
// Parameters:
//   ADDRSIZE - Address width in bits (default: 4)
//              Pointer width is ADDRSIZE+1 bits
//
// Ports:
//   Output:
//     rwptr2[ADDRSIZE:0] - Synchronized write pointer in read clock domain
//                          (2nd stage of synchronizer)
//   
//   Input:
//     wptr[ADDRSIZE:0]   - Write pointer in Gray code from write domain
//     rclk               - Read clock domain
//     rrst_n             - Asynchronous reset (active low)
//
// Operation:
//   1. On each rclk edge, wptr is sampled into rwptr1 (1st stage)
//   2. On next rclk edge, rwptr1 is transferred to rwptr2 (2nd stage)
//   3. rwptr2 is used by read domain for empty flag comparison
//
// Design Notes:
//   - CRITICAL: Input must be Gray-coded to ensure only one bit changes
//   - Two stages provide adequate MTBF for most practical applications
//   - Reset must be asynchronous to handle power-up conditions
//   - For higher reliability requirements, consider 3+ stage synchronizers
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
// Module: Write Pointer and Full Flag Generator
// ============================================================================
// Description:
//   Generates the write pointer in Gray code format and the full flag for
//   the asynchronous FIFO. The write pointer is incremented when winc is
//   asserted and the FIFO is not full.
//
// Architecture:
//   - Maintains binary pointer (wbin) for address generation
//   - Converts binary to Gray code for safe clock domain crossing
//   - Compares synchronized read pointer with current write pointer
//   - Generates full flag when pointers match with MSB inversion
//
// Parameters:
//   ADDRSIZE - Address width in bits (default: 4)
//              Determines FIFO depth as 2^ADDRSIZE
//
// Ports:
//   Output:
//     wfull             - Full flag (active high, synchronized to wclk)
//                         High when FIFO is full, writes should be inhibited
//     waddr[ADDRSIZE-1:0] - Memory write address (binary, MSB excluded)
//     wptr[ADDRSIZE:0]    - Write pointer in Gray code format
//   
//   Input:
//     wrptr2[ADDRSIZE:0]  - Synchronized read pointer from read clock domain
//     winc                - Write increment enable (active high)
//     wclk                - Write clock domain
//     wrst_n              - Asynchronous reset (active low)
//
// Operation:
//   1. Binary pointer increments when winc=1 and !wfull
//   2. Binary pointer converted to Gray code: G = (B>>1) ^ B
//   3. Gray-coded pointer sent to read domain via synchronizer
//   4. Full detected when: wptr[MSB:MSB-1] == ~rwptr[MSB:MSB-1] AND
//                          wptr[MSB-2:0] == rwptr[MSB-2:0]
//
// Full Detection Logic:
//   - For a FIFO of depth 2^n, the full condition occurs when:
//     * The two MSBs of write pointer are opposite of read pointer's MSBs
//     * All remaining lower bits are equal
//   - This distinguishes "full" from "empty" condition using extra pointer bit
//
// Design Notes:
//   - Uses ADDRSIZE+1 bits for pointer to distinguish full vs empty
//   - MSB of waddr excludes the extra pointer bit
//   - Full flag registered for clean timing
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
// Fix: Use direct increment without conditional
assign wbnext = wbin + 1'b1;
assign wgnext = (wbnext >> 1) ^ wbnext;

// Update pointers - use current pointer for comparison, not next
always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n) begin
    wbin <= {(ADDRSIZE+1){1'b0}};
    wptr <= {(ADDRSIZE+1){1'b0}};
  end else if (winc & ~wfull) begin
    wbin <= wbnext;
    wptr <= wgnext;
  end
end

// Full detection - compare current Gray pointer with synchronized read pointer
wire wfull_val;
assign wfull_val = (wptr == {~wrptr2[ADDRSIZE:ADDRSIZE-1], wrptr2[ADDRSIZE-2:0]});

always @(posedge wclk or negedge wrst_n) begin
  if (!wrst_n)
    wfull <= 1'b0;
  else if (winc & ~wfull)
    wfull <= wfull_val;
end

endmodule

// ============================================================================
// Module: FIFO Memory Array
// ============================================================================
// Description:
//   Implements the storage array for the asynchronous FIFO with synchronous
//   write and asynchronous read operations. This is a standard implementation
//   for dual-clock FIFOs where read data appears combinationally.
//
// Architecture:
//   - Single-port memory array with synchronous writes
//   - Asynchronous (combinational) reads
//   - Write enable controlled by wclken and wfull_n signals
//
// Parameters:
//   DATASIZE - Data width in bits (default: 8)
//   ADDRSIZE - Address width in bits (default: 4)
//              Memory depth = 2^ADDRSIZE locations
//
// Ports:
//   Output:
//     rdata[DATASIZE-1:0] - Read data output (asynchronous)
//                           Changes immediately when raddr changes
//   
//   Input:
//     wdata[DATASIZE-1:0] - Write data input
//     waddr[ADDRSIZE-1:0] - Write address input
//     raddr[ADDRSIZE-1:0] - Read address input
//     wclken              - Write clock enable (active high)
//                           When high with wfull_n, write occurs on wclk edge
//     wfull_n             - Write full flag (active low)
//                           Prevents writes when FIFO is full
//     wclk                - Write clock domain
//
// Operation:
//   - Write: On posedge wclk, if wclken && wfull_n, MEM[waddr] <= wdata
//   - Read:  Continuously drives rdata = MEM[raddr] (asynchronous)
//
// Design Notes:
//   - Asynchronous read means rdata changes as soon as raddr changes
//   - This is acceptable for FIFO operation since raddr only changes on rclk
//   - For synchronous read applications, consider adding output register
//   - Memory depth is 2^ADDRSIZE (e.g., ASIZE=4 gives 16 locations)
//   - No initialization specified; simulation starts with unknown values
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
