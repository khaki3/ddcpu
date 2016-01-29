/*

 memory accessor
 ----------------
                   
            |
         [packet]
            |
           \ /
                                                           |
    ===================        =====================       |
    | memory_accessor |  <---> | memory_controller | <---> | MEMORY
    ===================        =====================       |
                                                           |
            |
     [worker-result]
            |
           \ /
 
*/

module memory_accessor #
  (
   `include "include/param.vh"
   )
  (
    input                                CLK,
    input                                RST,

    output reg                           MEM_SEND_ADDR_VALID,
    output [31:0]                        MEM_SEND_ADDR,
    output                               MEM_SEND_DATA_VALID,
    output [31:0]                        MEM_SEND_DATA,
    input                                MEM_SEND_READY,

    input                                MEM_RECEIVE_VALID,
    input [31:0]                         MEM_RECEIVE_DATA,
    output                               MEM_RECEIVE_READY,

    input                                RECEIVE_PC_VALID,
    input [PACKET_WIDTH-1:0]             RECEIVE_PC_DATA,
    output reg                           RECEIVE_PC_READY, 

    output reg                           SEND_WR_VALID,
    output reg [WORKER_RESULT_WIDTH-1:0] SEND_WR_DATA,
    input                                SEND_WR_READY
   );

   reg [1:0]   STATE;
   reg [PACKET_WIDTH-1:0] current_pc_data;

   `include "include/macro.vh"
   `include "include/construct.vh"
   `extract_packet(current_pc_data)

   wire ma_peek = (packet_opcode == MA_PEEK);
   wire ma_poke = (packet_opcode == MA_POKE);

   assign MEM_SEND_ADDR       = packet_data1;
   assign MEM_SEND_DATA       = packet_data2;
   assign MEM_SEND_DATA_VALID = ma_poke;
   assign MEM_RECEIVE_READY   = 1'b1;

   localparam
     S_RECEIVE     = 2'b00,
     S_MEM_SEND    = 2'b01,
     S_MEM_RECEIVE = 2'b10,
     S_SEND        = 2'b11;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_RECEIVE;
      else
        case (STATE)
          S_RECEIVE:
            if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
              STATE <= S_MEM_SEND;

          S_MEM_SEND:
            if (MEM_SEND_ADDR_VALID && MEM_SEND_READY)
              STATE <= S_MEM_RECEIVE;

          S_MEM_RECEIVE:
            if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
              STATE <= S_SEND;

          S_SEND:
            if (SEND_WR_VALID && SEND_WR_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   // MEM_SEND_ADDR_VALID
   `sendAlways(posedge CLK, RST, STATE == S_MEM_SEND, MEM_SEND_ADDR_VALID, MEM_SEND_READY)

   // SEND_WR_DATA
   always @ (posedge CLK) begin
      if (RST)
        SEND_WR_DATA <= 0;
      else if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
         SEND_WR_DATA <= make_worker_result(packet_dest_option,
                                            packet_dest_addr,
                                            packet_color,
                                            MEM_RECEIVE_DATA);
   end

   // SEND_WR_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_WR_VALID, SEND_WR_READY)

   // RECEIVE_PC_READY
   `receiveAlways(posedge CLK, RST, STATE == S_RECEIVE, RECEIVE_PC_VALID, RECEIVE_PC_READY)

   // current_pc_data
   always @ (posedge CLK) begin
      if (RST)
        current_pc_data <= 0;
      else if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
        current_pc_data <= RECEIVE_PC_DATA;
   end
    
endmodule
