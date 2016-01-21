/*

 dispatcher
 ----------------
                   
        |
  [worker-result]
        |
       \ /

  ==============
  | dispatcher | --------------------------> EXECUTION_END
  ==============              |
                              |
        |                     |
  [packet-request]    [worker-result]
        |                     |
       \ /                   \ /
  
 =================    ===================
 | packet_loader |    | matching_memory |
 =================    ===================
 
*/

module dispatcher #
  (
   `include "include/param.vh"
   )
  (
   input                             CLK,
   input                             RST,

   output reg                        EXECUTION_END,

   input                             RECEIVE_WR_VALID,
   input [WORKER_RESULT_WIDTH-1:0]   RECEIVE_WR_DATA,
   output reg                        RECEIVE_WR_READY,

   output reg                        SEND_WR_VALID,
   output [WORKER_RESULT_WIDTH-1:0]  SEND_WR_DATA,
   input                             SEND_WR_READY,

   output reg                        SEND_PR_VALID,
   output [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA,
   input                             SEND_PR_READY
   );
   
   reg [1:0] STATE;
   reg [WORKER_RESULT_WIDTH-1:0] current_wr_data;
   wire [2:0] receive_wr_data_dest_option = RECEIVE_WR_DATA[WORKER_RESULT_WIDTH-1:WORKER_RESULT_WIDTH-1-2];

   `include "include/construct.vh"
   `include "include/extract_wr_data.vh"
     
   localparam
     S_READ     = 2'b00,
     S_WR_WRITE = 2'b01,
     S_PR_WRITE = 2'b10;

   // SEND_PR_VALID
   always @ (posedge CLK) begin
      if (RST)
        SEND_PR_VALID <= 0;
      else if (STATE == S_PR_WRITE)
        if (SEND_PR_VALID && SEND_PR_READY)
          SEND_PR_VALID <= 0;
        else
          SEND_PR_VALID <= 1;
   end

   assign SEND_PR_DATA = make_packet_request(worker_result_dest_option,
                                             worker_result_dest_addr,
                                             worker_result_color,
                                             worker_result_data,
                                             32'b0);

   // SEND_WR_VALID
   always @ (posedge CLK) begin
      if (RST)
        SEND_WR_VALID <= 0;
      else if (STATE == S_WR_WRITE)
        if (SEND_WR_VALID && SEND_WR_READY)
          SEND_WR_VALID <= 0;
        else
          SEND_WR_VALID <= 1;
   end

   assign SEND_WR_DATA = current_wr_data;

   // EXECUTION_END
   always @ (posedge CLK) begin
      if (RST)
        EXECUTION_END <= 0;
      else if (RECEIVE_WR_VALID && RECEIVE_WR_READY &&
               receive_wr_data_dest_option == DEST_OPTION_END)
        EXECUTION_END <= 1;
      else
        EXECUTION_END <= 0;
   end

   // RECEIVE_WR_READY
   always @ (posedge CLK) begin
      if (RST)
        RECEIVE_WR_READY <= 0;
      else if (STATE == S_READ) begin
         if (RECEIVE_WR_VALID && RECEIVE_WR_READY)
           RECEIVE_WR_READY <= 0;
         else
           RECEIVE_WR_READY <= 1;
      end
   end

   // current_wr_data
   always @ (posedge CLK) begin
      if (RST)
        current_wr_data <= 0;
      else if (RECEIVE_WR_VALID && RECEIVE_WR_READY)
        current_wr_data <= RECEIVE_WR_DATA;
   end

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_READ;
      else
        case (STATE)
          S_READ:
            if (RECEIVE_WR_VALID && RECEIVE_WR_READY)
              if (receive_wr_data_dest_option == DEST_OPTION_EXEC ||
                  receive_wr_data_dest_option == DEST_OPTION_ONE)
                STATE <= S_PR_WRITE;

              else if (receive_wr_data_dest_option == DEST_OPTION_LEFT ||
                       receive_wr_data_dest_option == DEST_OPTION_RIGHT)
                STATE <= S_WR_WRITE;

          S_PR_WRITE:
            if (SEND_PR_VALID && SEND_PR_READY)
              STATE <= S_READ;

          S_WR_WRITE:
            if (SEND_WR_VALID && SEND_WR_READY)
              STATE <= S_READ;
        endcase
   end

endmodule
