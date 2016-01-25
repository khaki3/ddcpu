/*

 worker
 ----------------
                   
        |
     [packet]
        |
       \ /

    ==========
    | worker |
    ==========
 
        |
  [worker-result]
        |
       \ /
 
*/

module worker #
  (
   `include "include/param.vh"
   )
  (
    input                                CLK,
    input                                RST,

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

   wire insn_distribute = (packet_opcode == INSN_DISTRIBUTE);
   wire insn_switch     = (packet_opcode == INSN_SWITCH);
   wire insn_set_color  = (packet_opcode == INSN_SET_COLOR);
   wire insn_sync       = (packet_opcode == INSN_SYNC);
   wire insn_plus       = (packet_opcode == INSN_PLUS);

   localparam
     S_RECEIVE = 2'b00,
     S_SEND1   = 2'b01,
     S_SEND2   = 2'b10;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_RECEIVE;
      else
        case (STATE)
          S_RECEIVE:
            if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
              STATE <= S_SEND1;

          S_SEND1:
            if (SEND_WR_VALID && SEND_WR_READY) begin
               if (insn_distribute || insn_sync)
                 STATE <= S_SEND2;
               else
                 STATE <= S_RECEIVE;
            end

          S_SEND2:
            if (SEND_WR_VALID && SEND_WR_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   // SEND_WR_DATA
   always @ (posedge CLK) begin
      if (RST)
        SEND_WR_DATA <= 0;
      else if (STATE == S_SEND1 || STATE == S_SEND2) begin
         case (packet_opcode)
           INSN_DISTRIBUTE:
              if (STATE == S_SEND1)
                SEND_WR_DATA <= make_worker_result_direct(packet_data2,
                                                          packet_color,
                                                          packet_data1);
              else
                SEND_WR_DATA <= make_worker_result_direct(packet_data3,
                                                          packet_color,
                                                          packet_data1);

           INSN_SWITCH:
             if (packet_data2)
               SEND_WR_DATA <= make_worker_result_direct(packet_data3,
                                                         packet_color,
                                                         packet_data1);
             else
               SEND_WR_DATA <= make_worker_result_direct(packet_data4,
                                                         packet_color,
                                                         packet_data1);

           INSN_SET_COLOR:
             SEND_WR_DATA <= make_worker_result(packet_dest_option,
                                                packet_dest_addr,
                                                packet_data2[15:0],
                                                packet_data1);

           INSN_SYNC:
             if (STATE == S_SEND1)
               SEND_WR_DATA <= make_worker_result_direct(packet_data3,
                                                         packet_color,
                                                         packet_data1);
             else
               SEND_WR_DATA <= make_worker_result_direct(packet_data4,
                                                         packet_color,
                                                         packet_data2);

           INSN_PLUS:
             SEND_WR_DATA <= make_worker_result(packet_dest_option,
                                                packet_dest_addr,
                                                packet_color,
                                                packet_data1 + packet_data2);
         endcase
      end
   end

   // SEND_WR_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND1 || STATE == S_SEND2, SEND_WR_VALID, SEND_WR_READY)

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
