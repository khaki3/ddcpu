module echo #
  (
   parameter integer DATA_WIDTH = 32
   )
  (
   input                       CLK,
   input                       RST,
   
   input                       RECEIVE_VALID,
   input [DATA_WIDTH-1:0]      RECEIVE_DATA,
   output reg                  RECEIVE_READY,
   
   output reg                  SEND_VALID,
   output reg [DATA_WIDTH-1:0] SEND_DATA,
   input                       SEND_READY
   );

   `include "include/macro.vh"
   
   reg STATE;

   localparam
     S_RECEIVE = 1'b0,
     S_SEND    = 1'b1;

   // SEND_DATA
   always @ (posedge CLK) begin
      if (RECEIVE_VALID && RECEIVE_READY)
        SEND_DATA <= RECEIVE_DATA;
   end

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_RECEIVE;
      else
        case (STATE)
          S_RECEIVE:
            if (RECEIVE_VALID && RECEIVE_READY)
              STATE <= S_SEND;

          S_SEND:
            if (SEND_VALID && SEND_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   // RECEIVE_READY
   `receiveAlways(posedge CLK, RST, STATE == S_RECEIVE, RECEIVE_VALID, RECEIVE_READY)

   // SEND_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_VALID, SEND_READY)

endmodule
