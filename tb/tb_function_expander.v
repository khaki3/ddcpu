`timescale 1ns/10ps

module tb_function_expander #
  (
   `include "include/param.vh"
   );

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   reg [31:0] FNADDR;

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

   wire SEND_PR_VALID;
   reg  SEND_PR_READY;
   wire [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA;

   `include "include/macro.vh"
   `include "include/construct.vh"

   function_expander f0
     (.CLK(CLK), .RST(RST),
      .FNADDR(FNADDR),

      .RECEIVE_PC_VALID (RECEIVE_PC_VALID),
      .RECEIVE_PC_DATA  (RECEIVE_PC_DATA),
      .RECEIVE_PC_READY (RECEIVE_PC_READY),

      .SEND_PR_VALID (SEND_PR_VALID),
      .SEND_PR_DATA  (SEND_PR_DATA),
      .SEND_PR_READY (SEND_PR_READY),

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
         SEND_PR_READY     = 0;
         MEM_SEND_READY    = 0;
         MEM_RECEIVE_VALID = 0;
         RECEIVE_PC_VALID  = 0;
         RECEIVE_PC_DATA   = 0;

         #CYCLE;
         if (!(RECEIVE_PC_READY === 0 &&
               MEM_SEND_ADDR_VALID === 0 &&
               SEND_PR_VALID === 0))
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

   reg [PACKET_REQUEST_WIDTH-1:0] current_pr_data;

   task receivePR;
      `receiveTask2(CYCLE, SEND_PR_VALID, SEND_PR_READY, SEND_PR_DATA, current_pr_data)
   endtask

   reg [9:0]  pc_opcode;
   reg [31:0] pc_data1, pc_data2, pc_data3, pc_data4;
   reg [2:0]  pc_dest_option;
   reg [15:0] pc_dest_addr;
   reg [15:0] pc_color;

   reg [FUNCTION_WIDTH-1:0] fn;
   reg [15:0] new_color;

   reg [1:0]  mem_count;
   reg [18:0] fn_coloring, fn_returning, fn_arg1, fn_arg2, fn_exec;

   function isNOP;
      input [18:0] dest;
      isNOP = (dest[18:16] === DEST_OPTION_NOP);
   endfunction

   task feSend;
      begin
         FNADDR = $random;

         pc_opcode = $random;
         pc_data1  = $random;
         pc_data2  = $random;
         pc_data3  = $random;
         pc_data4  = $random;
         pc_dest_option = $random;
         pc_dest_addr   = $random;
         pc_color       = $random;

         RECEIVE_PC_DATA
            = make_packet(OPCODE_FN, pc_opcode,
                          pc_data1, pc_data2, pc_data3, pc_data4,
                          pc_dest_option, pc_dest_addr, pc_color);

         fn_coloring  = {DEST_OPTION_RIGHT, INSN_SET_COLOR};
         fn_returning = {DEST_OPTION_RIGHT, INSN_DISTRIBUTE};
         fn_arg1      = $random;
         fn_arg2      = $random;
         fn_exec      = $random;

         fn = make_function(fn_coloring, fn_returning, fn_arg1, fn_arg2, fn_exec);
         sendPC;

         for (mem_count = 0; mem_count <= 2'h2; mem_count = mem_count + 1) begin
            receiveMEM;
            if (!(MEM_SEND_ADDR === FNADDR + pc_opcode + mem_count * 4))
              raiseError(8'h10);

            MEM_RECEIVE_DATA = fn[FUNCTION_WIDTH - 1 - mem_count * 32 -: 32];
            sendMEM;
         end
      end
   endtask

   task feReceive;
      begin
         // coloring
         receivePR;
         new_color = f0.new_color;
         if (!(current_pr_data === make_packet_request(fn_coloring[18:16], fn_coloring[15:0],
                                                       new_color,
                                                       pc_color,
                                                       32'b0)))
           raiseError({8'h11, 4'h0});

         // returning
         receivePR;
         if (!(current_pr_data === make_packet_request(fn_returning[18:16], fn_returning[15:0],
                                                       pc_color,
                                                       {pc_dest_option, pc_dest_addr},
                                                       32'b0)))
           raiseError({8'h11, 4'h1});

         // arg1
         if (!isNOP(fn_arg1)) begin
            receivePR;
            if (!(current_pr_data === make_packet_request(fn_arg1[18:16], fn_arg1[15:0],
                                                          new_color,
                                                          pc_data1,
                                                          32'b0)))
              raiseError({8'h11, 4'h2});
         end

         // arg2
         if (!isNOP(fn_arg2)) begin
            receivePR;
            if (!(current_pr_data === make_packet_request(fn_arg2[18:16], fn_arg2[15:0],
                                                          new_color,
                                                          pc_data2,
                                                          32'b0)))
              raiseError({8'h11, 4'h3});
         end

         // exec
         if (!isNOP(fn_exec)) begin
            receivePR;
            if (!(current_pr_data === make_packet_request(fn_exec[18:16], fn_exec[15:0],
                                                          new_color,
                                                          32'b0,
                                                          32'b0)))
              raiseError({8'h11, 4'h4});
         end
      end
   endtask

   task feTest1;
      begin
         feSend;
         feReceive;
      end
   endtask

   task feTest2;
      fork
         feSend;
         feReceive;
      join
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 100; i = i + 1) begin
         feTest1();
         feTest2();
      end
      $display("finish");
      $stop;
   end

endmodule
