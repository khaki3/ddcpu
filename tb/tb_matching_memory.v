`timescale 1ns/10ps

module tb_matching_memory #
  (
   `include "include/param.vh"
   );

   `include "include/construct.vh"
   `include "include/macro.vh"
   
   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   reg  RECEIVE_WR_VALID;
   reg [WORKER_RESULT_WIDTH-1:0] RECEIVE_WR_DATA;
   wire RECEIVE_WR_READY;

   wire SEND_PR_VALID;
   wire [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA;
   reg SEND_PR_READY;

   matching_memory m0
     (.CLK(CLK), .RST(RST),
      .RECEIVE_WR_VALID(RECEIVE_WR_VALID),
      .RECEIVE_WR_DATA(RECEIVE_WR_DATA),
      .RECEIVE_WR_READY(RECEIVE_WR_READY),

      .SEND_PR_VALID(SEND_PR_VALID),
      .SEND_PR_DATA(SEND_PR_DATA),
      .SEND_PR_READY(SEND_PR_READY));

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
         RECEIVE_WR_VALID = 0;
         RECEIVE_WR_DATA  = 0;
         SEND_PR_READY    = 0;

         #CYCLE;
         if (!(RECEIVE_WR_READY === 0 && SEND_PR_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   task sendWR;
      `sendTask(CYCLE, RECEIVE_WR_VALID, RECEIVE_WR_READY)
   endtask

   task receivePR;
      `receiveTask(CYCLE, SEND_PR_VALID, SEND_PR_READY)
   endtask

   reg [WORKER_RESULT_WIDTH-1:0] wr1 [1023:0], wr2 [1023:0];
   reg [15:0] dest_addr [1023:0], color [1023:0];
   reg [31:0] data1 [1023:0], data2 [1023:0];

   integer rec_count, rec_depth;

   task mmTest;
      begin
         dest_addr[rec_count] = $random;
         color[rec_count]     = $random;
         data1[rec_count]     = $random;
         data2[rec_count]     = $random;
         
         wr1[rec_count]
           = make_worker_result(DEST_OPTION_LEFT,  dest_addr[rec_count], color[rec_count], data1[rec_count]);
         wr2[rec_count]
           = make_worker_result(DEST_OPTION_RIGHT, dest_addr[rec_count], color[rec_count], data2[rec_count]);

         RECEIVE_WR_DATA = wr1[rec_count];
         sendWR;

         if (rec_count < rec_depth) begin
            $display("in:  %d", rec_count);
            rec_count = rec_count + 1;
            mmTest;
            rec_count = rec_count - 1;
            $display("out: %d", rec_count);
         end

         RECEIVE_WR_DATA = wr2[rec_count];
         sendWR;

         receivePR;
         if (!(SEND_PR_DATA === make_packet_request(DEST_OPTION_LEFT,
                                                    dest_addr[rec_count],
                                                    color[rec_count],
                                                    data1[rec_count],
                                                    data2[rec_count])))
           raiseError('h10);
      end
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 10; i = i + 1) begin
         $display("[%d]", i);
         rec_depth = {$random} % 100;
         rec_count = 0;
         mmTest;
      end
      $display("finish");
      $stop;
   end

endmodule
