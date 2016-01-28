/*

 queue
 ----------------

        |
     [packet]
        |
       \ /

    =========
    | queue |
    =========
 
        |
     [packet]
        |
       \ /
 
*/

module queue #
  (
   `include "include/param.vh"
   )
  (
    input                         CLK,
    input                         RST,

    input                         RECEIVE_PC_VALID,
    input [PACKET_WIDTH-1:0]      RECEIVE_PC_DATA,
    output reg                    RECEIVE_PC_READY, 

    output reg                    SEND_PC_VALID,
    output reg [PACKET_WIDTH-1:0] SEND_PC_DATA,
    input                         SEND_PC_READY
   );

   `include "include/macro.vh"

   reg  rd_en;
   wire [PACKET_WIDTH-1:0] dout;
   wire empty, valid, full;

   // RECEIVE_PC_READY
   always @ (posedge CLK) begin
      if (RST)
        RECEIVE_PC_READY <= 1'b0;
      else if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
        RECEIVE_PC_READY <= 1'b0;
      else if (RECEIVE_PC_VALID && !full)
        RECEIVE_PC_READY <= 1'b1;
      else
        RECEIVE_PC_READY <= 1'b0;
   end

   fifo_175in175out_1024depth fifo_175in175out_1024depth (
      .rst           (RST),
      .clk           (CLK),
      .din           (RECEIVE_PC_DATA),
      .wr_en         (RECEIVE_PC_VALID && RECEIVE_PC_READY), // valid holds '1' until ready will be sent.
      .rd_en         (rd_en),
      .dout          (dout),
      .full          (full),
      .empty         (empty),
      .valid         (valid)
      );

   reg STATE;

   localparam
     S_READ = 1'b0,
     S_SEND = 1'b1;

   // SEND_PC_DATA
   always @ (posedge CLK) begin
      if (RST)
        SEND_PC_DATA <= 0;      
      else if (valid)
        SEND_PC_DATA <= dout;
   end

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_READ;
      else
        case (STATE)
          S_READ:
            if (valid)
              STATE <= S_SEND;

          S_SEND:
            if (SEND_PC_VALID && SEND_PC_READY)
              STATE <= S_READ;
        endcase
   end

   // rd_en
   always @ (posedge CLK) begin
      if (RST)
        rd_en <= 1'b0;
      else if (rd_en || valid)
        rd_en <= 1'b0;
      else if (STATE == S_READ && !full)
        rd_en <= 1'b1;
   end

   // SEND_PC_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_PC_VALID, SEND_PC_READY)

endmodule
