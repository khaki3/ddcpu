`timescale 1ns/10ps

module tb_worker #
  (
   `include "param.vh"
   );
      
   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   reg  PC_VALID;
   wire PC_READY;
   reg  [PACKET_WIDTH-1:0] PC_DATA;

   wire WR_VALID;
   reg  WR_READY;
   wire [WORKER_RESULT_WIDTH-1:0] WR_DATA;

   `include "construct.vh"

   worker w0 (.CLK(CLK), .RST(RST),
              .PC_VALID(PC_VALID), .PC_DATA(PC_DATA), .PC_READY(PC_READY),
              .WR_VALID(WR_VALID), .WR_DATA(WR_DATA), .WR_READY(WR_READY));

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
         CLK =01;
         RST = 1;
         PC_VALID = 0;
         PC_DATA  = 0;
         WR_READY = 0;

         #CYCLE;
         if (!(PC_READY == 0 && WR_VALID == 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   reg [2:0]  dest_option1, dest_option2, dest_option3;
   reg [15:0] dest_addr1, dest_addr2, dest_addr3;
   reg [15:0] color, old_color, new_color;
   reg [31:0] data1, data2, data3, data4;

   task send;
      begin
         PC_VALID = 1;
         while (!(PC_VALID && PC_READY))
        #CYCLE;
         #CYCLE;
         PC_VALID = 0;
      end
   endtask

   task receive;
      begin
         WR_READY = 1;
         while (!(WR_VALID && WR_READY))
        #CYCLE;
         #CYCLE;
         WR_READY = 0;
      end
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

         PC_DATA = make_packet(2'b00,
                               INSN_DISTRIBUTE,
                               data1,
                               data2,
                               data3,
                               32'b0,
                               3'b0,
                               16'b0,
                               color);
         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option1, dest_addr1, color, data1)))
           raiseError('h10);

         receive;

         if (!(WR_DATA == make_worker_result(dest_option2, dest_addr2, color, data1)))
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

         PC_DATA = make_packet(2'b00,
                               INSN_SWITCH,
                               data1,
                               data2,
                               data3,
                               data4,
                               3'b0,
                               16'b0,
                               color);

         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option1, dest_addr1, color, data1)))
           raiseError('h20);

         data2 = 32'h0; // false

         PC_DATA = make_packet(2'b00,
                               INSN_SWITCH,
                               data1,
                               data2,
                               data3,
                               data4,
                               3'b0,
                               16'b0,
                               color);

         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option2, dest_addr2, color, data1)))
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

         PC_DATA = make_packet(2'b00,
                               INSN_SET_COLOR,
                               data1,
                               data2,
                               data3,
                               data4,
                               dest_option1,
                               dest_addr1,
                               old_color);

         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option1, dest_addr1, new_color, data1)))
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

         PC_DATA = make_packet(2'b00,
                               INSN_SYNC,
                               data1,
                               data2,
                               data3,
                               data4,
                               3'b0,
                               16'b0,
                               color);
         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option1, dest_addr1, color, data1)))
           raiseError('h40);

         receive;

         if (!(WR_DATA == make_worker_result(dest_option2, dest_addr2, color, data2)))
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

         PC_DATA = make_packet(2'b00,
                               INSN_PLUS,
                               data1,
                               data2,
                               data3,
                               data4,
                               dest_option1,
                               dest_addr1,
                               color);

         send;
         receive;

         if (!(WR_DATA == make_worker_result(dest_option1, dest_addr1, color, data1 + data2)))
           raiseError('h50);
      end
   endtask

   integer i;
   
   initial begin
      for (i = 0; i < 10; i = i + 1) begin
         initTest;
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
