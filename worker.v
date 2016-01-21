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
   `include "param.vh"
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

   `include "construct.vh"

   wire [1:0]  packet_opmode      = current_pc_data[174:173];
   wire [9:0]  packet_opcode      = current_pc_data[172:163];
   wire [31:0] packet_data1       = current_pc_data[162:131];
   wire [31:0] packet_data2       = current_pc_data[130:99];
   wire [31:0] packet_data3       = current_pc_data[98:67];
   wire [31:0] packet_data4       = current_pc_data[66:35];
   wire [2:0]  packet_dest_option = current_pc_data[34:32];
   wire [15:0] packet_dest_addr   = current_pc_data[31:16];
   wire [15:0] packet_color       = current_pc_data[15:0];

   reg [1:0]   STATE;
   reg [PACKET_WIDTH-1:0] current_pc_data;
   
   wire insn_distribute = (packet_opcode == INSN_DISTRIBUTE);
   wire insn_switch     = (packet_opcode == INSN_SWITCH);
   wire insn_set_color  = (packet_opcode == INSN_SET_COLOR);
   wire insn_sync       = (packet_opcode == INSN_SYNC);
   wire insn_plus       = (packet_opcode == INSN_PLUS);

   localparam
     S_READ             = 2'b00,
     S_WRITE1           = 2'b01,
     S_WRITE2           = 2'b10;

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= S_READ;
      else
        case (STATE)
          S_READ:
            if (PC_VALID && PC_READY)
              STATE <= S_WRITE1;

          S_WRITE1:
            if (WR_VALID && WR_READY) begin
               if (insn_distribute || insn_sync)
                 STATE <= S_WRITE2;
               else
                 STATE <= S_READ;
            end

          S_WRITE2:
            if (WR_VALID && WR_READY)
              STATE <= S_READ;
        endcase
   end

   // WR_DATA
   always @ (posedge CLK) begin
      if (RST)
        WR_DATA <= 0;
      else if (STATE == S_WRITE1 || STATE == S_WRITE2) begin
         case (packet_opcode)
           INSN_DISTRIBUTE:
              if (STATE == S_WRITE1)
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
             if (STATE == S_WRITE1)
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
      else if (STATE == S_WRITE1 || STATE == S_WRITE2)
        if (WR_VALID && WR_READY)
          WR_VALID <= 0;
        else
          WR_VALID <= 1;
   end

   // PC_READY
   always @ (posedge CLK) begin
      if (RST)
        PC_READY <= 0;
      else if (STATE == S_READ) begin
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
