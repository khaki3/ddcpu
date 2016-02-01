`timescale 1ns/10ps

module tb_connect_fork #
  (
   parameter integer DATA_WIDTH  = PACKET_WIDTH,
   parameter integer CONNECT_NUM = 3,
   `include "include/param.vh"
   );

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   always #(CYCLE/2)
     CLK = ~CLK;

   reg  MASTER_RECEIVE_VALID;
   wire MASTER_RECEIVE_READY;
   reg  [DATA_WIDTH-1:0] MASTER_RECEIVE_DATA;

   wire MASTER_SEND_VALID;
   wire MASTER_SEND_READY;
   wire [DATA_WIDTH-1:0] MASTER_SEND_DATA;

   wire [CONNECT_NUM-1:0] SLAVE_RECEIVE_VALID;
   wire [CONNECT_NUM-1:0] SLAVE_RECEIVE_READY;
   reg  [DATA_WIDTH-1:0]  SLAVE_RECEIVE_DATA [CONNECT_NUM-1:0];

   wire [CONNECT_NUM-1:0] SLAVE_SEND_VALID;
   reg  [CONNECT_NUM-1:0] SLAVE_SEND_READY;
   wire [DATA_WIDTH-1:0]  SLAVE_SEND_DATA [CONNECT_NUM-1:0];

   wire [DATA_WIDTH*CONNECT_NUM-1:0] INTERCONNECT_DATA;

   integer i_id;
   
   // INTERCONNECT_DATA
   always @*
     for (i_id = 0; i_id < CONNECT_NUM; i_id = i_id + 1)
       SLAVE_RECEIVE_DATA[i_id] = INTERCONNECT_DATA[DATA_WIDTH * (i_id + 1) - 1 -: DATA_WIDTH];

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

   connect_fork # (
      .DATA_WIDTH(DATA_WIDTH),
      .CONNECT_NUM(CONNECT_NUM)
      ) i0
     (.RECEIVE_VALID (MASTER_SEND_VALID),
      .RECEIVE_READY (MASTER_SEND_READY),
      .RECEIVE_DATA  (MASTER_SEND_DATA),
      .SEND_VALID (SLAVE_RECEIVE_VALID),
      .SEND_READY (SLAVE_RECEIVE_READY),
      .SEND_DATA  (INTERCONNECT_DATA));

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

         MASTER_RECEIVE_VALID = 0;
         for (i_init = 0; i_init < CONNECT_NUM; i_init = i_init + 1)
           SLAVE_SEND_READY[i_init] = 0;

         #CYCLE;

         for (i_init = 0; i_init < CONNECT_NUM; i_init = i_init + 1)
           if(!(SLAVE_SEND_VALID[i_init] === 0))
             raiseError('h00);

         if (!(MASTER_RECEIVE_READY === 0))
           raiseError('h01);

         RST = 0;
      end
   endtask

   `include "include/macro.vh"

   task automatic sendPC;
      `sendTask(CYCLE, MASTER_RECEIVE_VALID, MASTER_RECEIVE_READY)
   endtask

   task automatic receivePC;
      input [31:0] index;
      `receiveTask(CYCLE, SLAVE_SEND_VALID[index], SLAVE_SEND_READY[index])
   endtask

   task automatic icTestSend;
      sendPC;
   endtask

   task automatic icTestReceive;
      input [31:0] index;
      begin
         randomPC(MASTER_RECEIVE_DATA);
         receivePC(index);

         if(!(MASTER_RECEIVE_DATA === SLAVE_SEND_DATA[index]))
           raiseError('h10);
      end
   endtask

   task icTestEntire1;
      fork
         begin
            icTestSend;
            icTestSend;
            icTestSend;
         end
         begin
            icTestReceive(2);
            icTestReceive(1);
            icTestReceive(0);
         end
      join
   endtask

   task icTestEntire2;
      fork
         begin
            icTestSend;
            icTestSend;
            icTestSend;
         end
         begin
            icTestReceive(2);
            icTestReceive(1);
            icTestReceive(0);
         end
      join
   endtask

   task icTestEntire3;
      fork
         begin
            icTestSend;
            icTestSend;
         end
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
