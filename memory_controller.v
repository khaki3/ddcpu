/*
 memory controller
 ------------------

       |           / \
  [memory addr]     |
       |          [data]
       |            |
      \ /          \ /
 
    =====================
    | memory controller |
    =====================

             / \
              |    AXI
             \ /

      ----------------
           MEMORY

 */

module memory_controller
  (
   input             CLK,
   input             RST,

   input             RECEIVE_ADDR_VALID,
   input [31:0]      RECEIVE_ADDR,
   input             RECEIVE_DATA_VALID,
   input [31:0]      RECEIVE_DATA,
   output reg        RECEIVE_READY,

   output reg        SEND_VALID,
   output reg [31:0] SEND_DATA,
   input             SEND_READY,

   // AXI READ
   output reg [31:0] ARADDR,
   output reg        ARVALID,
   input             ARREADY,

   input             RVALID,
   input [31:0]      RDATA,
   output            RREADY, 

   // AXI WRITE
   input             AWREADY,
   output reg [31:0] AWADDR,
   output reg        AWVALID,

   input             WREADY,
   output reg [31:0] WDATA,
   output reg        WVALID,
   output reg        WLAST
   );

   `include "include/macro.vh"

   localparam
     S_RECEIVE   = 3'b000,
     S_AXI_AR    = 3'b001,
     S_AXI_R     = 3'b010,
     S_AXI_AW    = 3'b011,
     S_AXI_W     = 3'b100,
     S_SEND      = 3'b101;

   reg [2:0] STATE;

   assign RREADY = 1;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_RECEIVE;
      else
         case (STATE)
           S_RECEIVE:
             if (RECEIVE_ADDR_VALID && RECEIVE_READY)
               if (RECEIVE_DATA_VALID)
                 STATE <= S_AXI_AW;
               else
                 STATE <= S_AXI_AR;

           S_AXI_AR:
             if (ARVALID && ARREADY)
               STATE <= S_AXI_R;

           S_AXI_R:
             if (RVALID && RREADY)
               STATE <= S_SEND;

           S_AXI_AW:
             if (AWVALID && AWREADY)
               STATE <= S_AXI_W;

           S_AXI_W:
             if (WVALID && WREADY)
               STATE <= S_SEND;

           S_SEND:
             if (SEND_VALID && SEND_READY)
               STATE <= S_RECEIVE;
         endcase
   end

   // ARADDR, AWADDR
   always @ (posedge CLK) begin
      if (RST) begin
         ARADDR <= 32'b0;
         AWADDR <= 32'b0;
      end
      else if (RECEIVE_ADDR_VALID && RECEIVE_READY) begin
         ARADDR <= RECEIVE_ADDR;
         AWADDR <= RECEIVE_ADDR;
      end         
   end

   // WVALID
   always @ (posedge CLK) begin
      if (RST)
        WVALID <= 0;
      else if (STATE != S_AXI_W)
        WVALID <= 0;
      else if (WVALID && WREADY)
        WVALID <= 0;
      else
        WVALID <= 1;
   end

   // WDATA
   always @ (posedge CLK) begin
      if (RECEIVE_ADDR_VALID && RECEIVE_READY)
        WDATA <= RECEIVE_DATA;
   end

   // WLAST
   always @ (posedge CLK) begin
      WLAST <= 1;
   end

   // AWVALID
   always @ (posedge CLK) begin
      if (RST)
        AWVALID <= 0;
      else if (AWVALID && !AWREADY)
        AWVALID <= 1;
      else if (AWVALID && AWREADY)
        AWVALID <= 0;
      else if (STATE == S_AXI_AW)
        AWVALID <= 1;
      else
        AWVALID <= 0;
   end

   // ARVALID
   always @ (posedge CLK) begin
      if (RST)
        ARVALID <= 0;
      else if (ARVALID && !ARREADY)
        ARVALID <= 1;
      else if (ARVALID && ARREADY)
        ARVALID <= 0;
      else if (STATE == S_AXI_AR)
        ARVALID <= 1;
      else
        ARVALID <= 0;
   end

   // RECEIVE_READY
   `receiveAlways(posedge CLK, RST, STATE == S_RECEIVE, RECEIVE_ADDR_VALID, RECEIVE_READY)

   // SEND_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_VALID, SEND_READY)

   // SEND_DATA
   always @ (posedge CLK) begin
      if (RVALID && RREADY)
        SEND_DATA <= RDATA;
      else if (WVALID && WREADY)
        SEND_DATA <= WDATA;
   end

endmodule
