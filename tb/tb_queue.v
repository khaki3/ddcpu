`timescale 1ns/10ps

module tb_queue #
  (
   `include "include/param.vh"
   );
      
   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   reg  RECEIVE_PC_VALID;
   wire RECEIVE_PC_READY;
   reg  [PACKET_WIDTH-1:0] RECEIVE_PC_DATA;

   wire SEND_PC_VALID;
   reg  SEND_PC_READY;
   wire [PACKET_WIDTH-1:0] SEND_PC_DATA;

   `include "include/macro.vh"

   queue q0 (.CLK(CLK), .RST(RST),
             .RECEIVE_PC_VALID (RECEIVE_PC_VALID),
             .RECEIVE_PC_DATA  (RECEIVE_PC_DATA),
             .RECEIVE_PC_READY (RECEIVE_PC_READY),
             .SEND_PC_VALID (SEND_PC_VALID),
             .SEND_PC_DATA  (SEND_PC_DATA),
             .SEND_PC_READY (SEND_PC_READY));

   always #(CYCLE/2)
     CLK = ~CLK;

   task raiseError(input integer stage);
      begin
         $display("ERROR: %x", stage);
         $stop;
      end
   endtask

   task initTest;
      begin
         CLK = 1;
         RST = 1;
         RECEIVE_PC_VALID = 0;
         RECEIVE_PC_DATA  = 0;
         SEND_PC_READY    = 0;

         #CYCLE;
         if (!(RECEIVE_PC_READY === 0 && SEND_PC_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   task sendPC;
      `sendTask(CYCLE, RECEIVE_PC_VALID, RECEIVE_PC_READY)
   endtask

   task receivePC;
      `receiveTask(CYCLE, SEND_PC_VALID, SEND_PC_READY)
   endtask

   task randomPC;
      output [PACKET_WIDTH-1:0] pc;
      pc = {$random, $random, $random, $random, $random};
   endtask

   reg [PACKET_WIDTH-1:0] pc [1023:0];

   integer di, ds;
   
   task queueTest;
      begin
         ds = {$random} % 1024;

         for (di = 0; di <= ds; di = di + 1) begin
            pc[di] = randomPC;
            RECEIVE_PC_DATA = pc[di];

            sendPC;
         end

         for (di = 0; di <= ds; di = di + 1) begin
            receiveWR;
            if (!(SEND_WR_DATA === pc[di]))
              raiseError('h10);
         end
      end
   endtask

   integer i;

   initial begin
      initTest;
      for (i = 0; i < 100; i = i + 1)
        queueTest1;
      $display("finish");
      $stop;
   end

endmodule
