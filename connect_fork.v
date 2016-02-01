/*

 connect_fork (1 way)
 ------------------------

            |
            |
           \ /

     ================
     | connect_fork |
     ================

       |    |    |
       |   data  |
       |    |    |
      \           /
       \         /
        \       /
         \     /
          \   /
           \ /

 */

module connect_fork #
  (
   parameter integer DATA_WIDTH  = 32,
   parameter integer CONNECT_NUM = 3
   )
  (
   input                                   RECEIVE_VALID,
   input [DATA_WIDTH-1:0]                  RECEIVE_DATA,
   output                                  RECEIVE_READY,

   output reg [CONNECT_NUM-1:0]            SEND_VALID,
   output reg [DATA_WIDTH*CONNECT_NUM-1:0] SEND_DATA,
   input [CONNECT_NUM-1:0]                 SEND_READY
   );

   reg [31:0] send_index;

   integer i1, i2;
   
   // send_index
   always @* begin
      send_index = 0;
      for (i1 = 0; i1 < CONNECT_NUM; i1 = i1 + 1)
        if (SEND_READY[i1])
          send_index = i1;
   end

   assign RECEIVE_READY = SEND_READY[send_index];

   genvar iG;
   generate
      for (iG = 0; iG < CONNECT_NUM; iG = iG + 1) begin : send_block
         always @* begin
            SEND_DATA[DATA_WIDTH * (iG + 1) - 1 -: DATA_WIDTH] = RECEIVE_DATA;

            if (SEND_READY[iG] && send_index == iG)
              SEND_VALID[iG] = RECEIVE_VALID;
            else
              SEND_VALID[iG] = 1'b0;
         end
      end
   endgenerate

endmodule
