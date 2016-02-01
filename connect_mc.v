/*

 memory-controller connect
 ------------------------

           / \
          /   \
         /     \
        /       \
       /         \
      /           \
       |    |    |
       |   data  |
       |    |    |
      \           /
       \         /
        \       /
         \     /
          \   /
           \ /

      ==============
      | connect_mc |
      ==============

           / \
            |
            |
           \ /

 */

module connect_mc #
  (
   parameter integer ADDR_WIDTH = 32,
   parameter integer DATA_WIDTH = 32,
   parameter integer CONNECT_NUM = 3
   )
  (
   input                                   CLK,
   input                                   RST,

   input [CONNECT_NUM-1:0]                 SLAVE_RECEIVE_ADDR_VALID,
   input [ADDR_WIDTH*CONNECT_NUM-1:0]      SLAVE_RECEIVE_ADDR,
   input [CONNECT_NUM-1:0]                 SLAVE_RECEIVE_DATA_VALID,
   input [DATA_WIDTH*CONNECT_NUM-1:0]      SLAVE_RECEIVE_DATA,
   output reg [CONNECT_NUM-1:0]            SLAVE_RECEIVE_READY,

   output reg [CONNECT_NUM-1:0]            SLAVE_SEND_VALID,
   output reg [DATA_WIDTH*CONNECT_NUM-1:0] SLAVE_SEND_DATA,
   input [CONNECT_NUM-1:0]                 SLAVE_SEND_READY,

   output reg                              MASTER_SEND_ADDR_VALID,
   output [DATA_WIDTH-1:0]                 MASTER_SEND_ADDR,
   output                                  MASTER_SEND_DATA_VALID,
   output [ADDR_WIDTH-1:0]                 MASTER_SEND_DATA,
   input                                   MASTER_SEND_READY,

   input                                   MASTER_RECEIVE_VALID,
   input [DATA_WIDTH-1:0]                  MASTER_RECEIVE_DATA,
   output                                  MASTER_RECEIVE_READY
   );

   reg STATE;
   reg [31:0] selected_slave_index;

   localparam
     S_SLAVE_TO_MASTER = 1'b0,
     S_MASTER_TO_SLAVE = 1'b1;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_SLAVE_TO_MASTER;
      else
        case (STATE)
          S_SLAVE_TO_MASTER:
            if (SLAVE_RECEIVE_ADDR_VALID[selected_slave_index] &&
                SLAVE_RECEIVE_READY[selected_slave_index])
              STATE <= S_MASTER_TO_SLAVE;

          S_MASTER_TO_SLAVE:
            if (SLAVE_SEND_VALID[selected_slave_index] &&
                SLAVE_SEND_READY[selected_slave_index])
              STATE <= S_SLAVE_TO_MASTER;
        endcase
   end

   integer i1, i2;

   // selected_slave_index
   always @*
     if (STATE == S_SLAVE_TO_MASTER)
       for (i1 = 0; i1 < CONNECT_NUM; i1 = i1 + 1)
         if (SLAVE_RECEIVE_ADDR_VALID[i1])
           selected_slave_index = i1;

   // MASTER_SEND_ADDR_VALID
   always @* begin
      MASTER_SEND_ADDR_VALID = 1'b0;
      if (STATE == S_SLAVE_TO_MASTER)
        for (i2 = 0; i2 < CONNECT_NUM; i2 = i2 + 1)
          if (SLAVE_RECEIVE_ADDR_VALID[i2])
            MASTER_SEND_ADDR_VALID = 1'b1;
   end

   assign MASTER_SEND_ADDR       = SLAVE_RECEIVE_ADDR[ADDR_WIDTH * (selected_slave_index + 1) - 1 -: ADDR_WIDTH];
   assign MASTER_SEND_DATA       = SLAVE_RECEIVE_DATA[DATA_WIDTH * (selected_slave_index + 1) - 1 -: DATA_WIDTH];
   assign MASTER_SEND_DATA_VALID = SLAVE_RECEIVE_DATA_VALID[selected_slave_index];
   assign MASTER_RECEIVE_READY   = SLAVE_SEND_READY[selected_slave_index];

   genvar iG;
   generate
      for (iG = 0; iG < CONNECT_NUM; iG = iG + 1) begin : slave_signal_block
         always @* begin
            if (SLAVE_RECEIVE_ADDR_VALID[iG] && selected_slave_index == iG && STATE == S_SLAVE_TO_MASTER)
              SLAVE_RECEIVE_READY[iG] = MASTER_SEND_READY;
            else
              SLAVE_RECEIVE_READY[iG] = 1'b0;

            if (STATE == S_MASTER_TO_SLAVE && selected_slave_index == iG) begin
               SLAVE_SEND_VALID[iG] = MASTER_RECEIVE_VALID;
               SLAVE_SEND_DATA[DATA_WIDTH * (iG + 1) - 1 -: DATA_WIDTH] = MASTER_RECEIVE_DATA;
            end
            else begin
               SLAVE_SEND_VALID[iG] = 0;
            end
         end
      end
   endgenerate

endmodule
