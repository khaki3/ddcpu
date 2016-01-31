/*

 interconnect (1 way)
 ------------------------

       |    |    |
       |   data  |
       |    |    |
      \           /
       \         /
        \       /
         \     /
          \   /
           \ /

     ================
     | interconnect |
     ================

            |
            |
           \ /

 */

module interconnect #
  (
   parameter integer DATA_WIDTH  = 32,
   parameter integer CONNECT_NUM = 3
   )
  (
   input [CONNECT_NUM-1:0]            RECEIVE_VALID,
   input [DATA_WIDTH*CONNECT_NUM-1:0] RECEIVE_DATA,
   output reg [CONNECT_NUM-1:0]       RECEIVE_READY,

   output reg                         SEND_VALID,
   output reg [DATA_WIDTH-1:0]        SEND_DATA,
   input                              SEND_READY
   );

   reg [31:0] receive_index;

   integer i1, i2;
   
   // receive_index
   always @* begin
      receive_index = 0;
      for (i1 = 0; i1 < CONNECT_NUM; i1 = i1 + 1)
        if (RECEIVE_VALID[i1])
          receive_index = i1;
   end

   // SEND_VALID
   always @* begin
      SEND_VALID = 1'b0;
      for (i2 = 0; i2 < CONNECT_NUM; i2 = i2 + 1)
        if (RECEIVE_VALID[i2])
          SEND_VALID = 1'b1;
   end

   // SEND_DATA
   always @* begin
      SEND_DATA = RECEIVE_DATA[DATA_WIDTH * receive_index - 1 -: DATA_WIDTH];
   end

   genvar iG;
   generate
      for (iG = 0; iG < CONNECT_NUM; iG = iG + 1) begin : receive_ready_block
         always @* begin
            if (RECEIVE_VALID[iG] && receive_index == iG)
              RECEIVE_READY[iG] = SEND_READY;
            else
              RECEIVE_READY[iG] = 1'b0;
         end
      end
   endgenerate

endmodule
