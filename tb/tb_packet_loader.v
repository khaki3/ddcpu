`timescale 1ns/10ps

module tb_packet_loader #
  (
   `include "include/param.vh"
   );

   `include "include/macro.vh"

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   wire [31:0] PCADDR = 32'h2000_0000;
   wire        MEM_SEND_ADDR_VALID;
   wire [31:0] MEM_SEND_ADDR;
   wire        MEM_SEND_DATA_VALID;
   wire [31:0] MEM_SEND_DATA;
   reg         MEM_SEND_READY;

   reg        MEM_RECEIVE_VALID;
   reg [31:0] MEM_RECEIVE_DATA;
   wire       MEM_RECEIVE_READY;

   reg                            RECEIVE_PR_VALID;
   reg [PACKET_REQUEST_WIDTH-1:0] RECEIVE_PR_DATA;
   wire                           RECEIVE_PR_READY;

   wire                    SEND_PC_TO_QU_VALID;
   wire [PACKET_WIDTH-1:0] SEND_PC_TO_QU_DATA;
   reg                     SEND_PC_TO_QU_READY;

   wire                    SEND_PC_TO_FE_VALID;
   wire [PACKET_WIDTH-1:0] SEND_PC_TO_FE_DATA;
   reg                     SEND_PC_TO_FE_READY;

   wire                    SEND_PC_TO_MA_VALID;
   wire [PACKET_WIDTH-1:0] SEND_PC_TO_MA_DATA;
   reg                     SEND_PC_TO_MA_READY;

   `include "include/construct.vh"

   packet_loader p0
     (.CLK(CLK), .RST(RST),

      .PCADDR (PCADDR),

      .MEM_SEND_ADDR_VALID (MEM_SEND_ADDR_VALID),
      .MEM_SEND_ADDR       (MEM_SEND_ADDR),
      .MEM_SEND_DATA_VALID (MEM_SEND_DATA_VALID),
      .MEM_SEND_DATA       (MEM_SEND_DATA),
      .MEM_SEND_READY      (MEM_SEND_READY),

      .MEM_RECEIVE_VALID   (MEM_RECEIVE_VALID),
      .MEM_RECEIVE_DATA    (MEM_RECEIVE_DATA),
      .MEM_RECEIVE_READY   (MEM_RECEIVE_READY),

      .RECEIVE_PR_VALID (RECEIVE_PR_VALID),
      .RECEIVE_PR_DATA  (RECEIVE_PR_DATA),
      .RECEIVE_PR_READY (RECEIVE_PR_READY),

      .SEND_PC_TO_QU_VALID (SEND_PC_TO_QU_VALID),
      .SEND_PC_TO_QU_DATA  (SEND_PC_TO_QU_DATA),
      .SEND_PC_TO_QU_READY (SEND_PC_TO_QU_READY),

      .SEND_PC_TO_FE_VALID (SEND_PC_TO_FE_VALID),
      .SEND_PC_TO_FE_DATA  (SEND_PC_TO_FE_DATA),
      .SEND_PC_TO_FE_READY (SEND_PC_TO_FE_READY),

      .SEND_PC_TO_MA_VALID (SEND_PC_TO_MA_VALID),
      .SEND_PC_TO_MA_DATA  (SEND_PC_TO_MA_DATA),
      .SEND_PC_TO_MA_READY (SEND_PC_TO_MA_READY));

   always #(CYCLE/2)
     CLK = ~CLK;

   task raiseError(input integer stage);
      begin
         $display("ERROR: %b", stage);
         $stop;
      end
   endtask

   task sendPR;
      `sendTask(CYCLE, RECEIVE_PR_VALID, RECEIVE_PR_READY)
   endtask

   task receiveMEM;
      `receiveTask(CYCLE, MEM_SEND_ADDR_VALID, MEM_SEND_READY)
   endtask

   task sendMEM;
      `sendTask(CYCLE, MEM_RECEIVE_VALID, MEM_RECEIVE_READY)
   endtask

   task receivePcAsQU;
      `receiveTask(CYCLE, SEND_PC_TO_QU_VALID, SEND_PC_TO_QU_READY)
   endtask

   task receivePcAsFE;
      `receiveTask(CYCLE, SEND_PC_TO_FE_VALID, SEND_PC_TO_FE_READY)
   endtask

   task receivePcAsMA;
      `receiveTask(CYCLE, SEND_PC_TO_MA_VALID, SEND_PC_TO_MA_READY)
   endtask
   
   task initTest;
      begin
         CLK = 1'b0;
         RST = 1'b1;

         RECEIVE_PR_VALID    = 1'b0;
         MEM_SEND_READY      = 1'b0;
         MEM_RECEIVE_VALID   = 1'b0;
         SEND_PC_TO_QU_READY = 1'b0;
         SEND_PC_TO_FE_READY = 1'b0;
         SEND_PC_TO_MA_READY = 1'b0;

         #CYCLE;

         if (!(RECEIVE_PR_READY    === 0 &&
               MEM_SEND_ADDR_VALID === 0 &&
               SEND_PC_TO_QU_VALID === 0 &&
               SEND_PC_TO_FE_VALID === 0 &&
               SEND_PC_TO_MA_VALID === 0))
           raiseError('h00);
         RST = 0;
      end
   endtask

   reg [PACKET_WIDTH-1:0] template_packet;
   reg [PACKET_REQUEST_WIDTH-1:0] packet_request;
   reg [PACKET_WIDTH-1:0] SEND_PC_DATA, correct_pc;

   reg [15:0] dest_addr;
   reg [2:0]  mem_count;
   
   task loadTest;
      input [1:0] opmode;
      input [2:0] dest_option;
      begin
         dest_addr = $random;
         
         packet_request = make_packet_request(dest_option,
                                              dest_addr,
                                              $random,
                                              $random,
                                              $random);

         template_packet = make_packet(opmode,
                                       $random,
                                       $random, $random, $random, $random,
                                       $random,
                                       $random,
                                       $random);

         RECEIVE_PR_DATA = packet_request;
         sendPR;

         for (mem_count = 0; mem_count <= 3'h4; mem_count = mem_count + 1) begin
            receiveMEM;

            if (!(MEM_SEND_ADDR === PCADDR + dest_addr + mem_count * 4))
              raiseError({3'b100, mem_count, opmode, dest_option});

            MEM_RECEIVE_DATA = template_packet[PACKET_WIDTH - 1 - mem_count * 32 -: 32];
            sendMEM;
         end

         case (opmode)
           OPCODE_EI:
             begin
                receivePcAsQU;
                SEND_PC_DATA = SEND_PC_TO_QU_DATA;
             end
                
           OPCODE_FN:
             begin
                receivePcAsFE;
                SEND_PC_DATA = SEND_PC_TO_FE_DATA;
             end

           OPCODE_MA:
             begin
                receivePcAsMA;
                SEND_PC_DATA = SEND_PC_TO_MA_DATA;
             end

           default:
             raiseError({3'b101, opmode, dest_option});
         endcase

         correct_pc = make_packet_from_request(template_packet, packet_request);
         if (!(SEND_PC_DATA[PACKET_WIDTH-1:16] === correct_pc[PACKET_WIDTH-1:16]))
           raiseError({3'b110, opmode, dest_option});
      end
   endtask

   integer i;

   reg [1:0] oc;
   reg [2:0] dopt;

   initial begin
      initTest;
      for (i = 0; i < 10; i = i + 1)
        for (oc = OPCODE_EI; oc <= OPCODE_MA; oc = oc + 1)
          for (dopt = DEST_OPTION_EXEC; dopt <= DEST_OPTION_RIGHT; dopt = dopt + 1)
            loadTest(oc, dopt);
      $display("finish");
      $stop;
   end

endmodule
