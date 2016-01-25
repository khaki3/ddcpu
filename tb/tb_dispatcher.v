`timescale 1ns/10ps

module tb_dispatcher #
  (
   `include "include/param.vh"
   );

   `include "include/construct.vh"
   `include "include/macro.vh"
   
   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   wire EXECUTION_END;

   reg  RECEIVE_WR_VALID;
   reg [WORKER_RESULT_WIDTH-1:0] RECEIVE_WR_DATA;
   wire RECEIVE_WR_READY;

   wire SEND_WR_VALID;
   wire [WORKER_RESULT_WIDTH-1:0] SEND_WR_DATA;
   reg SEND_WR_READY;

   wire SEND_PR_VALID;
   wire [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA;
   reg SEND_PR_READY;

   dispatcher d0 (.CLK(CLK), .RST(RST),
                  .RECEIVE_WR_VALID(RECEIVE_WR_VALID),
                  .RECEIVE_WR_DATA(RECEIVE_WR_DATA),
                  .RECEIVE_WR_READY(RECEIVE_WR_READY),

                  .SEND_WR_VALID(SEND_WR_VALID),
                  .SEND_WR_DATA(SEND_WR_DATA),
                  .SEND_WR_READY(SEND_WR_READY),

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
         SEND_WR_READY    = 0;
         SEND_PR_READY    = 0;

         #CYCLE;
         if (!(RECEIVE_WR_READY === 0 && SEND_WR_VALID === 0 && SEND_PR_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   task sendWR;
      `sendTask(CYCLE, RECEIVE_WR_VALID, RECEIVE_WR_READY)
   endtask

   task receiveWR;
      `receiveTask(CYCLE, SEND_WR_VALID, SEND_WR_READY)
   endtask

   task receivePR;
      `receiveTask(CYCLE, SEND_PR_VALID, SEND_PR_READY)
   endtask

   reg [15:0] dest_addr, color;
   reg [31:0] data;
   
   task execTest;
      begin
         dest_addr = 16'h1111;
         color     = 16'h2222;
         data      = 32'h3333_4444;
         
         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_EXEC, dest_addr, color, data);

         sendWR;
         receivePR;

         if (!(SEND_PR_DATA === make_packet_request(DEST_OPTION_EXEC, dest_addr, color, data, 32'h0)))
           raiseError('h10);
      end
   endtask

   task oneTest;
      begin
         dest_addr = 16'h5555;
         color     = 16'h6666;
         data      = 32'h7777_8888;
         
         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_ONE, dest_addr, color, data);

         sendWR;
         receivePR;

         if (!(SEND_PR_DATA === make_packet_request(DEST_OPTION_ONE, dest_addr, color, data, 32'h0)))
           raiseError('h20);
      end
   endtask

   task leftTest;
      begin
         dest_addr = 16'h9999;
         color     = 16'haaaa;
         data      = 32'hbbbb_cccc;
         
         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_LEFT, dest_addr, color, data);

         sendWR;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(DEST_OPTION_LEFT, dest_addr, color, data)))
           raiseError('h30);
      end
   endtask

   task rightTest;
      begin
         dest_addr = 16'hdddd;
         color     = 16'heeee;
         data      = 32'hffff_0000;
         
         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_RIGHT, dest_addr, color, data);

         sendWR;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(DEST_OPTION_RIGHT, dest_addr, color, data)))
           raiseError('h30);
      end
   endtask

   task nopTest;
      begin
         dest_addr = 16'h1111;
         color     = 16'h2222;
         data      = 32'h3333_4444;

         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_NOP, dest_addr, color, data);
         sendWR;
      end
   endtask

   task endTest;
      begin
         dest_addr = 16'h5555;
         color     = 16'h6666;
         data      = 32'h7777_8888;

         RECEIVE_WR_DATA = make_worker_result(DEST_OPTION_END, dest_addr, color, data);
         sendWR;

         if (!EXECUTION_END)
           raiseError('h50);
      end
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 10; i = i + 1) begin
         execTest;
         oneTest;
         leftTest;
         rightTest;
         nopTest;
         endTest;
      end
      $display("finish");
      $stop;
   end

endmodule
