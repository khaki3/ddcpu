`timescale 1ns/10ps

module tb_memory_accessor #
  (
   `include "include/param.vh"
   );

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   wire        MEM_SEND_ADDR_VALID;
   wire [31:0] MEM_SEND_ADDR;
   wire        MEM_SEND_DATA_VALID;
   wire [31:0] MEM_SEND_DATA;
   reg         MEM_SEND_READY;

   reg         MEM_RECEIVE_VALID;
   reg  [31:0] MEM_RECEIVE_DATA;
   wire        MEM_RECEIVE_READY;

   reg  RECEIVE_PC_VALID;
   wire RECEIVE_PC_READY;
   reg  [PACKET_WIDTH-1:0] RECEIVE_PC_DATA;

   wire SEND_WR_VALID;
   reg  SEND_WR_READY;
   wire [WORKER_RESULT_WIDTH-1:0] SEND_WR_DATA;

   `include "include/macro.vh"
   `include "include/construct.vh"

   memory_accessor m0
     (.CLK(CLK), .RST(RST),
      .RECEIVE_PC_VALID (RECEIVE_PC_VALID),
      .RECEIVE_PC_DATA  (RECEIVE_PC_DATA),
      .RECEIVE_PC_READY (RECEIVE_PC_READY),

      .SEND_WR_VALID (SEND_WR_VALID),
      .SEND_WR_DATA  (SEND_WR_DATA),
      .SEND_WR_READY (SEND_WR_READY),

      .MEM_SEND_ADDR_VALID (MEM_SEND_ADDR_VALID),
      .MEM_SEND_ADDR       (MEM_SEND_ADDR),
      .MEM_SEND_DATA_VALID (MEM_SEND_DATA_VALID),
      .MEM_SEND_DATA       (MEM_SEND_DATA),
      .MEM_SEND_READY      (MEM_SEND_READY),

      .MEM_RECEIVE_VALID   (MEM_RECEIVE_VALID),
      .MEM_RECEIVE_DATA    (MEM_RECEIVE_DATA),
      .MEM_RECEIVE_READY   (MEM_RECEIVE_READY));

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
         SEND_WR_READY     = 0;
         MEM_SEND_READY    = 0;
         MEM_RECEIVE_VALID = 0;
         RECEIVE_PC_VALID  = 0;
         RECEIVE_PC_DATA   = 0;

         #CYCLE;
         if (!(RECEIVE_PC_READY === 0 &&
               MEM_SEND_ADDR_VALID === 0 &&
               SEND_WR_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   task sendPC;
      `sendTask(CYCLE, RECEIVE_PC_VALID, RECEIVE_PC_READY)
   endtask
   
   task receiveMEM;
      `receiveTask(CYCLE, MEM_SEND_ADDR_VALID, MEM_SEND_READY)
   endtask

   task sendMEM;
      `sendTask(CYCLE, MEM_RECEIVE_VALID, MEM_RECEIVE_READY)
   endtask

   task receiveWR;
      `receiveTask(CYCLE, SEND_WR_VALID, SEND_WR_READY)
   endtask

   reg [2:0]  dest_option;
   reg [15:0] dest_addr;
   reg [15:0] color;
   reg [31:0] data1, data2, data3, data4, mem;

   task maTest;
      input [9:0] opcode;
      begin
         dest_option = $random;
         dest_addr   = $random;
         data1       = $random;
         color       = $random;
         mem         = $random;

         RECEIVE_PC_DATA = make_packet(OPCODE_MA,
                                       opcode,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       dest_option,
                                       dest_addr,
                                       color);
         sendPC;

         receiveMEM;
         if (!(MEM_SEND_ADDR === data1 &&
               (opcode == MA_REF) ? MEM_SEND_DATA_VALID === 1'b0 :
               (opcode == MA_SET) ? MEM_SEND_DATA_VALID === 1'b1 : 1'b0))
           raiseError('h10);

         MEM_RECEIVE_DATA = mem;
         sendMEM;

         receiveWR;
         if (!(SEND_WR_DATA === make_worker_result(dest_option,
                                                   dest_addr,
                                                   color,
                                                   mem)))
           raiseError('h11);
      end
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 100; i = i + 1) begin
         maTest(MA_REF);
         maTest(MA_SET);
      end
      $display("finish");
      $stop;
   end

endmodule
