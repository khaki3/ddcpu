`timescale 1ns/10ps

module tb_worker #
  (
   `include "include/param.vh"
   );
      
   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   reg  RECEIVE_PC_VALID;
   wire RECEIVE_PC_READY;
   reg  [PACKET_WIDTH-1:0] RECEIVE_PC_DATA;

   wire SEND_WR_VALID;
   reg  SEND_WR_READY;
   wire [WORKER_RESULT_WIDTH-1:0] SEND_WR_DATA;

   `include "include/macro.vh"
   `include "include/construct.vh"

   worker w0 (.CLK(CLK), .RST(RST),
              .RECEIVE_PC_VALID (RECEIVE_PC_VALID),
              .RECEIVE_PC_DATA  (RECEIVE_PC_DATA),
              .RECEIVE_PC_READY (RECEIVE_PC_READY),
              .SEND_WR_VALID (SEND_WR_VALID),
              .SEND_WR_DATA  (SEND_WR_DATA),
              .SEND_WR_READY (SEND_WR_READY));

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
         SEND_WR_READY    = 0;

         #CYCLE;
         if (!(RECEIVE_PC_READY === 0 && SEND_WR_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   reg [2:0]  dest_option1, dest_option2, dest_option3;
   reg [15:0] dest_addr1, dest_addr2, dest_addr3;
   reg [15:0] color, old_color, new_color;
   reg [31:0] data1, data2, data3, data4;

   task sendPC;
      `sendTask(CYCLE, RECEIVE_PC_VALID, RECEIVE_PC_READY)
   endtask

   task receiveWR;
      `receiveTask(CYCLE, SEND_WR_VALID, SEND_WR_READY)
   endtask

   task distributeTest;
      begin
         dest_option1 = 3'b010;
         dest_addr1   = 16'hdead;
         dest_option2 = 3'b101;
         dest_addr2   = 16'hbeef;
         color        = 16'h0f0f;

         data1 = 32'hdead_beef;
         data2 = {dest_option1, dest_addr1};
         data3 = {dest_option2, dest_addr2};

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_DISTRIBUTE,
                                       data1,
                                       data2,
                                       data3,
                                       32'b0,
                                       3'b0,
                                       16'b0,
                                       color);
         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option1,
                                                   dest_addr1,
                                                   color,
                                                   data1)))
           raiseError('h10);

         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option2,
                                                   dest_addr2,
                                                   color,
                                                   data1)))
           raiseError('h11);
      end
   endtask

   task switchTest;
      begin
         //
         dest_option1 = 3'b000;
         dest_addr1   = 16'h0f0f;
         dest_option2 = 3'b111;
         dest_addr2   = 16'hf0f0;
         color        = 16'habcd;

         data1 = 32'h1234_abcd;
         data2 = 32'h1; // true
         data3 = {dest_option1, dest_addr1};
         data4 = {dest_option2, dest_addr2};

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_SWITCH,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       3'b0,
                                       16'b0,
                                       color);

         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option1,
                                                   dest_addr1,
                                                   color,
                                                   data1)))
           raiseError('h20);

         data2 = 32'h0; // false

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_SWITCH,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       3'b0,
                                       16'b0,
                                       color);

         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option2,
                                                   dest_addr2,
                                                   color,
                                                   data1)))
           raiseError('h21);
      end
   endtask

   task setColorTest;
      begin
         dest_option1 = 3'b001;
         dest_addr1   = 16'h0a0a;
         old_color    = 16'habcd;
         new_color    = 16'hbadc;

         data1 = 32'habcd_1234;
         data2 = new_color;

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_SET_COLOR,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       dest_option1,
                                       dest_addr1,
                                       old_color);

         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option1,
                                                   dest_addr1,
                                                   new_color,
                                                   data1)))
           raiseError('h30);
      end
   endtask

   task syncTest;
      begin
         dest_option1 = 3'b100;
         dest_addr1   = 16'h8776;
         dest_option2 = 3'b011;
         dest_addr2   = 16'h2030;
         color        = 16'h0f0f;

         data1 = 32'hdead_beef;
         data2 = 32'h4321_5678;
         data3 = {dest_option1, dest_addr1};
         data4 = {dest_option2, dest_addr2};

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_SYNC,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       3'b0,
                                       16'b0,
                                       color);
         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option1,
                                                   dest_addr1,
                                                   color,
                                                   data1)))
           raiseError('h40);

         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option2,
                                                   dest_addr2,
                                                   color,
                                                   data2)))
           raiseError('h41);
      end
   endtask
   
   task plusTest;
      begin
         //
         dest_option1 = 3'b110;
         dest_addr1   = 16'h00ff;
         color        = 16'heeee;

         data1 = 32'hdead_0000;
         data2 = 32'h0000_beef;

         RECEIVE_PC_DATA = make_packet(OPCODE_EI,
                                       INSN_PLUS,
                                       data1,
                                       data2,
                                       data3,
                                       data4,
                                       dest_option1,
                                       dest_addr1,
                                       color);

         sendPC;
         receiveWR;

         if (!(SEND_WR_DATA === make_worker_result(dest_option1,
                                                   dest_addr1,
                                                   color,
                                                   data1 + data2)))
           raiseError('h50);
      end
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 10; i = i + 1) begin
         distributeTest;
         switchTest;
         setColorTest;
         syncTest;
         plusTest;
      end
      $display("finish");
      $stop;
   end

endmodule
