`timescale 1ns/10ps

module tb_connect_join #
  (
   `include "include/param.vh"
   ,
   parameter integer DATA_WIDTH  = PACKET_WIDTH,
   parameter integer CONNECT_NUM = 3
   );

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   always #(CYCLE/2)
     CLK = ~CLK;

   reg  [CONNECT_NUM-1:0] SLAVE_RECEIVE_VALID;
   wire [CONNECT_NUM-1:0] SLAVE_RECEIVE_READY;
   reg  [DATA_WIDTH-1:0]  SLAVE_RECEIVE_DATA [CONNECT_NUM-1:0];

   wire [CONNECT_NUM-1:0] SLAVE_SEND_VALID;
   wire [CONNECT_NUM-1:0] SLAVE_SEND_READY;
   wire [DATA_WIDTH-1:0]  SLAVE_SEND_DATA [CONNECT_NUM-1:0];

   reg [DATA_WIDTH*CONNECT_NUM-1:0] INTERCONNECT_DATA;

   wire MASTER_RECEIVE_VALID;
   wire MASTER_RECEIVE_READY;
   wire [DATA_WIDTH-1:0] MASTER_RECEIVE_DATA;

   wire MASTER_SEND_VALID;
   reg  MASTER_SEND_READY;
   wire [DATA_WIDTH-1:0] MASTER_SEND_DATA;

   genvar iG;
   generate
      for (iG = 0; iG < CONNECT_NUM; iG = iG + 1) begin : slave_connection
         echo #
          (
           .DATA_WIDTH(DATA_WIDTH)
           )
          slave
          (.CLK(CLK), .RST(RST),
           .RECEIVE_VALID (SLAVE_RECEIVE_VALID[iG]),
           .RECEIVE_READY (SLAVE_RECEIVE_READY[iG]),
           .RECEIVE_DATA  (SLAVE_RECEIVE_DATA[iG]),

           .SEND_VALID (SLAVE_SEND_VALID[iG]),
           .SEND_READY (SLAVE_SEND_READY[iG]),
           .SEND_DATA  (SLAVE_SEND_DATA[iG]));
      end
   endgenerate

   integer i_id;

   // INTERCONNECT_DATA
   always @*
     for (i_id = 0; i_id < CONNECT_NUM; i_id = i_id + 1)
       INTERCONNECT_DATA[DATA_WIDTH * (i_id + 1) - 1 -: DATA_WIDTH] = SLAVE_RECEIVE_DATA[i_id];

   connect_join # (
      .DATA_WIDTH(DATA_WIDTH),
      .CONNECT_NUM(CONNECT_NUM)
      ) i0
     (.RECEIVE_VALID (SLAVE_SEND_VALID),
      .RECEIVE_READY (SLAVE_SEND_READY),
      .RECEIVE_DATA  (INTERCONNECT_DATA),
      .SEND_VALID (MASTER_RECEIVE_VALID),
      .SEND_READY (MASTER_RECEIVE_READY),
      .SEND_DATA  (MASTER_RECEIVE_DATA));

   echo #
     (
      .DATA_WIDTH(DATA_WIDTH)
      )
     master
     (.CLK(CLK), .RST(RST),
      .RECEIVE_VALID (MASTER_RECEIVE_VALID),
      .RECEIVE_READY (MASTER_RECEIVE_READY),
      .RECEIVE_DATA  (MASTER_RECEIVE_DATA),

      .SEND_VALID (MASTER_SEND_VALID),
      .SEND_READY (MASTER_SEND_READY),
      .SEND_DATA  (MASTER_SEND_DATA));

   task raiseError(input integer stage);
      begin
         $display("ERROR: %x", stage);
         $stop;
      end
   endtask

   task randomPC;
      output [PACKET_WIDTH-1:0] pc;
      pc = {$random, $random, $random, $random, $random, $random};
   endtask

   integer i_init;

   task initTest;
      begin
         CLK = 1;
         RST = 1;

         for (i_init = 0; i_init < CONNECT_NUM; i_init = i_init + 1) begin
            SLAVE_RECEIVE_VALID[i_init] = 0;
            randomPC(SLAVE_RECEIVE_DATA[i_init]);
         end
         MASTER_SEND_READY = 0;

         #CYCLE;

         if(!(MASTER_SEND_VALID === 0))
           raiseError('h00);

         RST = 0;
      end
   endtask

   `include "include/macro.vh"

   task automatic sendPC;
      input [31:0] index;
      `sendTask(CYCLE, SLAVE_RECEIVE_VALID[index], SLAVE_RECEIVE_READY[index])
   endtask

   task automatic receivePC;
      `receiveTask(CYCLE, MASTER_SEND_VALID, MASTER_SEND_READY)
   endtask

   task automatic icTestSend;
      input [31:0] index;
      sendPC(index);
   endtask

   task automatic icTestReceive;
      input [31:0] index;
      begin
         receivePC;

         if(!(MASTER_SEND_DATA === SLAVE_RECEIVE_DATA[index]))
           raiseError('h10);
      end
   endtask

   task icTestEntire1;
      fork
         icTestSend(0);
         icTestSend(1);
         icTestSend(2);
         begin
            icTestReceive(2);
            icTestReceive(1);
            icTestReceive(0);
         end
      join
   endtask

   task icTestEntire2;
      fork
         icTestSend(2);
         icTestSend(1);
         icTestSend(0);
         begin
            icTestReceive(2);
            icTestReceive(1);
            icTestReceive(0);
         end
      join
   endtask

   task icTestEntire3;
      fork
         icTestSend(0);
         icTestSend(1);
         begin
            icTestReceive(1);
            icTestReceive(0);
         end
      join
   endtask

   integer i_main;

   initial begin
      initTest;
      for (i_main = 0; i_main < 100; i_main = i_main + 1) begin
         icTestEntire1;
         icTestEntire2;
         icTestEntire3;
      end
      $display("finish");
      $stop;
   end

endmodule
