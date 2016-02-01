module echo_mem #
  (
   parameter integer DATA_WIDTH = 32,
   parameter integer ADDR_WIDTH = 32
   )
  (
   input                       CLK,
   input                       RST,

   input                       READ_RECEIVE_ADDR_VALID,
   input [ADDR_WIDTH-1:0]      READ_RECEIVE_ADDR,
   input                       READ_RECEIVE_DATA_VALID,
   input [DATA_WIDTH-1:0]      READ_RECEIVE_DATA,
   output                      READ_RECEIVE_READY,

   output                      READ_SEND_ADDR_VALID,
   output reg [ADDR_WIDTH-1:0] READ_SEND_ADDR,
   output reg                  READ_SEND_DATA_VALID,
   output [DATA_WIDTH-1:0]     READ_SEND_DATA,
   input                       READ_SEND_READY,

   input                       WRITE_RECEIVE_VALID,
   input [DATA_WIDTH-1:0]      WRITE_RECEIVE_DATA,
   output                      WRITE_RECEIVE_READY,
   
   output                      WRITE_SEND_VALID,
   output [DATA_WIDTH-1:0]     WRITE_SEND_DATA,
   input                       WRITE_SEND_READY
   );

   `include "include/macro.vh"
   
   reg STATE;

   localparam
     S_READ  = 1'b0,
     S_WRITE = 1'b1;

   // READ_SEND_DATA_VALID, READ_SEND_ADDR
   always @ (posedge CLK) begin
      if (READ_RECEIVE_ADDR_VALID && READ_RECEIVE_READY) begin
         READ_SEND_DATA_VALID <= READ_RECEIVE_DATA_VALID;
         READ_SEND_ADDR       <= READ_RECEIVE_ADDR;
      end
   end

   echo #
     (
      .DATA_WIDTH(DATA_WIDTH)
      ) e0
     (.CLK(CLK), .RST(RST),

      .RECEIVE_VALID (READ_RECEIVE_ADDR_VALID),
      .RECEIVE_DATA  (READ_RECEIVE_DATA),
      .RECEIVE_READY (READ_RECEIVE_READY),

      .SEND_VALID (READ_SEND_ADDR_VALID),
      .SEND_DATA  (READ_SEND_DATA),
      .SEND_READY (READ_SEND_READY));

   echo #
     (
      .DATA_WIDTH(DATA_WIDTH)
      ) e1
     (.CLK(CLK), .RST(RST),

      .RECEIVE_VALID (WRITE_RECEIVE_VALID),
      .RECEIVE_DATA  (WRITE_RECEIVE_DATA),
      .RECEIVE_READY (WRITE_RECEIVE_READY),

      .SEND_VALID (WRITE_SEND_VALID),
      .SEND_DATA  (WRITE_SEND_DATA),
      .SEND_READY (WRITE_SEND_READY));

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_READ;
      else
        case (STATE)
          S_READ:
            if (READ_SEND_ADDR_VALID && READ_SEND_READY)
              STATE <= S_WRITE;

          S_WRITE:
            if (WRITE_SEND_VALID && WRITE_SEND_READY)
              STATE <= S_READ;
        endcase
   end

endmodule
