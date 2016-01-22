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

    input                                PC_VALID,
    input [PACKET_WIDTH-1:0]             PC_DATA,
    output reg                           PC_READY, 

    output reg                           WR_VALID,
    output reg [WORKER_RESULT_WIDTH-1:0] WR_DATA,
    input                                WR_READY
   );

   reg [1:0]   STATE;
   reg [PACKET_WIDTH-1:0] current_pc_data;
   
   `include "include/construct.vh"
   `include "include/extract_pc_data.vh"

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
            if (PC_VALID && PC_READY)
              STATE <= S_SEND1;

          S_SEND1:
            if (WR_VALID && WR_READY) begin
               if (insn_distribute || insn_sync)
                 STATE <= S_SEND2;
               else
                 STATE <= S_RECEIVE;
            end

          S_SEND2:
            if (WR_VALID && WR_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   // WR_DATA
   always @ (posedge CLK) begin
      if (RST)
        WR_DATA <= 0;
      else if (STATE == S_SEND1 || STATE == S_SEND2) begin
         case (packet_opcode)
           INSN_DISTRIBUTE:
              if (STATE == S_SEND1)
                WR_DATA <= make_worker_result_direct(packet_data2, packet_color, packet_data1);
              else
                WR_DATA <= make_worker_result_direct(packet_data3, packet_color, packet_data1);

           INSN_SWITCH:
             if (packet_data2)
               WR_DATA <= make_worker_result_direct(packet_data3, packet_color, packet_data1);
             else
               WR_DATA <= make_worker_result_direct(packet_data4, packet_color, packet_data1);

           INSN_SET_COLOR:
             WR_DATA <= make_worker_result(packet_dest_option, packet_dest_addr, packet_data2[15:0], packet_data1);

           INSN_SYNC:
             if (STATE == S_SEND1)
               WR_DATA <= make_worker_result_direct(packet_data3, packet_color, packet_data1);
             else
               WR_DATA <= make_worker_result_direct(packet_data4, packet_color, packet_data2);

           INSN_PLUS:
             WR_DATA <= make_worker_result(packet_dest_option, packet_dest_addr, packet_color, packet_data1 + packet_data2);
         endcase
      end
   end

   // WR_VALID
   always @ (posedge CLK) begin
      if (RST)
        WR_VALID <= 0;
      else if (STATE == S_SEND1 || STATE == S_SEND2)
        if (WR_VALID && WR_READY)
          WR_VALID <= 0;
        else
          WR_VALID <= 1;
   end

   // PC_READY
   always @ (posedge CLK) begin
      if (RST)
        PC_READY <= 0;
      else if (STATE == S_RECEIVE) begin
         if (PC_VALID && PC_READY)
           PC_READY <= 0;
         else
           PC_READY <= 1;
      end
   end

   // current_pc_data
   always @ (posedge CLK) begin
      if (RST)
        current_pc_data <= 0;
      else if (PC_VALID && PC_READY)
        current_pc_data <= PC_DATA;
   end
    
endmodule
