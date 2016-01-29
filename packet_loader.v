/*

 packet loader
 ----------------
                   
         |
  [packet-request]
         |
        \ /
                                                      |
  =================       =====================       |
  | packet_loader | <---> | memory_controller | <---> | MEMORY
  =================       =====================       |
                                                      |
          |
      [packet]
          |
      ----------------------------------------------
     |                     |                        |
     |                     |                        |
     |                     |                        |
    \ /                   \ /                      \ /
  
  =========       ===================      =====================
  | queue |       | memory_accessor |      | function_expander |
  =========       ===================      =====================
 
*/

module packet_loader #
  (
   `include "include/param.vh"
   )
  (
   input                            CLK,
   input                            RST,

   input [31:0]                     OPADDR, 

   output reg                       MEM_SEND_ADDR_VALID,
   output [31:0]                    MEM_SEND_ADDR,
   output                           MEM_SEND_DATA_VALID,
   output [31:0]                    MEM_SEND_DATA,
   input                            MEM_SEND_READY,

   input                            MEM_RECEIVE_VALID,
   input [31:0]                     MEM_RECEIVE_DATA,
   output                           MEM_RECEIVE_READY,

   input                            RECEIVE_PR_VALID,
   input [PACKET_REQUEST_WIDTH-1:0] RECEIVE_PR_DATA,
   output reg                       RECEIVE_PR_READY,

   output                           SEND_PC_TO_QU_VALID,
   output [PACKET_WIDTH-1:0]        SEND_PC_TO_QU_DATA,
   input                            SEND_PC_TO_QU_READY,

   output                           SEND_PC_TO_FE_VALID,
   output [PACKET_WIDTH-1:0]        SEND_PC_TO_FE_DATA,
   input                            SEND_PC_TO_FE_READY,

   output                           SEND_PC_TO_MA_VALID,
   output [PACKET_WIDTH-1:0]        SEND_PC_TO_MA_DATA,
   input                            SEND_PC_TO_MA_READY
   );

   reg [PACKET_REQUEST_WIDTH-1:0] current_pr_data;
   reg [PACKET_WIDTH-1:0]         current_pc_data;

   `include "include/construct.vh"
   `extract_packet_request(current_pr_data)
   `extract_packet(current_pc_data)

   reg [2:0] mem_count; // 0 ~ 5
   assign MEM_SEND_ADDR       = OPADDR + packet_request_dest_addr + mem_count * 4; // (32/8) = 4
   assign MEM_SEND_DATA_VALID = 1'b0;
   assign MEM_SEND_DATA       = 32'b0;
   assign MEM_RECEIVE_READY   = 1'b1;

   wire [PACKET_WIDTH-1:0]
     next_pc_data = make_packet_from_request(current_pc_data, current_pr_data);

   assign SEND_PC_TO_QU_DATA = next_pc_data;
   assign SEND_PC_TO_FE_DATA = next_pc_data;
   assign SEND_PC_TO_MA_DATA = next_pc_data;

   reg  SEND_PC_VALID;
   wire SEND_PC_READY;

   assign SEND_PC_TO_QU_VALID = (packet_opmode == OPCODE_EI) ? SEND_PC_VALID : 1'b0;
   assign SEND_PC_TO_FE_VALID = (packet_opmode == OPCODE_FN) ? SEND_PC_VALID : 1'b0;
   assign SEND_PC_TO_MA_VALID = (packet_opmode == OPCODE_MA) ? SEND_PC_VALID : 1'b0;

   assign SEND_PC_READY = (packet_opmode == OPCODE_EI) ? SEND_PC_TO_QU_READY :
                          (packet_opmode == OPCODE_FN) ? SEND_PC_TO_FE_READY :
                          (packet_opmode == OPCODE_MA) ? SEND_PC_TO_MA_READY : 1'b0;

   localparam
     S_RECEIVE     = 2'b00,
     S_MEM_SEND    = 2'b01,
     S_MEM_RECEIVE = 2'b10,
     S_SEND        = 2'b11;

   reg [1:0] STATE;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_RECEIVE;
      else
        case(STATE)
          S_RECEIVE:
            if (RECEIVE_PR_VALID && RECEIVE_PR_READY)
              STATE <= S_MEM_SEND;

          S_MEM_SEND:
            if (MEM_SEND_ADDR_VALID && MEM_SEND_READY)
              STATE <= S_MEM_RECEIVE;

          S_MEM_RECEIVE:
            if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
              if (mem_count == 3'd5)
                STATE <= S_SEND;
              else
                STATE <= S_MEM_SEND;

          S_SEND:
            if (SEND_PC_VALID && SEND_PC_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   // mem_count
   always @ (posedge CLK) begin
      if (RST)
        mem_count <= 3'd0;
      else if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
        if (mem_count == 3'd5)
          mem_count <= 3'd0;
        else
          mem_count <= mem_count + 1;
   end

   // current_pr_data
   always @ (posedge CLK) begin
      if (RST)
        current_pr_data <= 0;
      else if (RECEIVE_PR_VALID && RECEIVE_PR_READY)
        current_pr_data <= RECEIVE_PR_DATA;
   end

   // current_pc_data
   always @ (posedge CLK) begin
      if (RST)
        current_pc_data <= 0;
      else if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
        if (mem_count == 3'd5)
          current_pc_data[14:0] <= MEM_RECEIVE_DATA[14:0];
        else
          current_pc_data[PACKET_WIDTH - 1 - mem_count * 32 -: 32]
            <= MEM_RECEIVE_DATA;
   end

   // RECEIVE_PR_READY
   `receiveAlways(posedge CLK, RST, STATE == S_RECEIVE, RECEIVE_PR_VALID, RECEIVE_PR_READY)

   // MEM_SEND_ADDR_VALID
   `sendAlways(posedge CLK, RST, STATE == S_MEM_SEND, MEM_SEND_ADDR_VALID, MEM_SEND_READY)

   // SEND_PC_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_PC_VALID, SEND_PC_READY)

endmodule
