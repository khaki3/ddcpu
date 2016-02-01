/*

 startup
 ----------------
                   
         |
       START
         |
        \ /

    ===========
    | startup |
    ===========
 
         |
  [packet-request]
         |
        \ /
  
  =================
  | packet_loader |
  =================
 
*/

module startup #
  (
   `include "include/param.vh"
   )
  (
   input                             CLK,
   input                             RST,

   input                             START,
   input                             STOP,

   output reg                        SEND_PR_VALID,
   output [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA,
   input                             SEND_PR_READY
   );

   `include "include/macro.vh"
   `include "include/construct.vh"

   assign SEND_PR_DATA
     = make_packet_request(DEST_OPTION_EXEC, 16'b0, 16'b0, 32'b0, 32'b0);

   reg STATE;

   localparam
     S_WAIT = 1'b0,
     S_SEND = 1'b1;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_WAIT;
      else
        case (STATE)
          S_WAIT:
            if (START && STOP)
              STATE <= S_SEND;

          S_SEND:
            if (SEND_PR_VALID && SEND_PR_READY)
              STATE <= S_WAIT;
        endcase
   end

   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_PR_VALID, SEND_PR_READY)

endmodule
