/*

 function expander
 ----------------
                   
             |
          [packet]
             |
            \ /
                                                 |
    =====================        =========       |
    | function_expander |  <---> | cache | <---> | MEMORY
    =====================        =========       |
                                                 |
             |
      [packet-request]
             |
            \ /
 
*/

module function_expander #
  (
   `include "include/param.vh"
   )
  (
    input                             CLK,
    input                             RST,

    input [31:0]                      FNADDR,
  
    output reg                        MEM_SEND_ADDR_VALID,
    output [31:0]                     MEM_SEND_ADDR,
    output                            MEM_SEND_DATA_VALID,
    output [31:0]                     MEM_SEND_DATA,
    input                             MEM_SEND_READY,

    input                             MEM_RECEIVE_VALID,
    input [31:0]                      MEM_RECEIVE_DATA,
    output                            MEM_RECEIVE_READY,

    input                             RECEIVE_PC_VALID,
    input [PACKET_WIDTH-1:0]          RECEIVE_PC_DATA,
    output reg                        RECEIVE_PC_READY, 

    output reg                        SEND_PR_VALID,
    output [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA,
    input                             SEND_PR_READY
   );

   localparam
     S_IN_RECEIVE     = 2'b00,
     S_IN_MEM_SEND    = 2'b01,
     S_IN_MEM_RECEIVE = 2'b10,
     S_IN_WAIT        = 2'b11;

   localparam
     S_OUT_RECEIVE    = 2'b00,
     S_OUT_WAIT       = 2'b01,
     S_OUT_SEND       = 2'b10;

   reg [1:0] STATE_IN;
   reg [1:0] STATE_OUT;

   reg [PACKET_WIDTH-1:0] current_pc_data;
   reg [FUNCTION_WIDTH-1:0] current_fn_data;

   `include "include/macro.vh"
   `include "include/construct.vh"
   `extract_packet(current_pc_data)
   `extract_function(current_fn_data)
   `extract_packet_request(SEND_PR_DATA)

   reg [1:0] mem_count; // 0 ~ 2
   reg [2:0] send_count; // 0 ~ 4

   reg [15:0] new_color;

   assign MEM_SEND_ADDR       = FNADDR + packet_opcode + mem_count * 4 ; // (32/8) = 4
   assign MEM_SEND_DATA       = 0;
   assign MEM_SEND_DATA_VALID = 1'b0;
   assign MEM_RECEIVE_READY   = 1'b1;

   wire pr_valid = (packet_request_dest_option != DEST_OPTION_NOP);
   wire sended   = ((STATE_OUT == S_OUT_SEND && !pr_valid) + // In here, '|' doesn't work correctly..
                    (SEND_PR_VALID && SEND_PR_READY));

   wire [PACKET_REQUEST_WIDTH-1:0]

     coloring_pr  = make_packet_request(function_coloring[18:16], // Mostly this has DEST_OPTION_RIGHT
                                        function_coloring[15:0],  // Mostly this addr contains an INSN_SET_COLOR operation
                                        new_color,
                                        packet_color,
                                        32'b0),

     returning_pr = make_packet_request(function_returning[18:16], // DEST_OPTION_RIGHT
                                        function_returning[15:0],  // INSN_DISTRIBUTE
                                        packet_color,
                                        {packet_dest_option, packet_dest_addr},
                                        32'b0),

     arg1_pr      = make_packet_request(function_arg1[18:16], // DEST_OPTION_ONE
                                        function_arg1[15:0],
                                        new_color,
                                        packet_data1,
                                        32'b0),

     arg2_pr      = make_packet_request(function_arg2[18:16], // DEST_OPTION_ONE
                                        function_arg2[15:0],
                                        new_color,
                                        packet_data2,
                                        32'b0),

     exec_pr      = make_packet_request(function_exec[18:16], // DEST_OPTION_EXEC
                                        function_exec[15:0],
                                        new_color,
                                        32'b0,
                                        32'b0);
   
   assign SEND_PR_DATA = ((send_count == 3'd0) ? coloring_pr  :
                          (send_count == 3'd1) ? returning_pr :
                          (send_count == 3'd2) ? arg1_pr      :
                          (send_count == 3'd3) ? arg2_pr      :
                          (send_count == 3'd4) ? exec_pr      : 32'b0);

   // new_color
   always @ (posedge CLK) begin
      if (RST)
        new_color <= 0;
      else if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
        new_color <= new_color + 1;
   end

   // mem_count
   always @ (posedge CLK) begin
      if (RST)
        mem_count <= 2'b0;

      else if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY) begin
        if (mem_count != 2'd2)
          mem_count <= mem_count + 1;
      end

      else if (sended && send_count == 3'd4)
        mem_count <= 2'b0;
   end

   // send_count
   always @ (posedge CLK) begin
      if (RST)
        send_count <= 3'b0;
      else if (sended)
        if (send_count == 3'd4)
          send_count <= 3'b0;
        else
          send_count <= send_count + 1;
   end

   // STATE_IN
   always @ (posedge CLK) begin
      if (RST)
        STATE_IN <= S_IN_RECEIVE;
      else
        case (STATE_IN)
          S_IN_RECEIVE:
            if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
              STATE_IN <= S_IN_MEM_SEND;

          S_IN_MEM_SEND:
            if (MEM_SEND_ADDR_VALID && MEM_SEND_READY)
              STATE_IN <= S_IN_MEM_RECEIVE;

          S_IN_MEM_RECEIVE:
            if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
              if (mem_count == 2'd2)
                STATE_IN <= S_IN_WAIT;
              else
                STATE_IN <= S_IN_MEM_SEND;

          S_IN_WAIT:
            if (sended && send_count == 3'd4)
              STATE_IN <= S_IN_RECEIVE;
        endcase
   end

   // STATE_OUT
   always @ (posedge CLK) begin
      if (RST)
        STATE_OUT <= S_OUT_RECEIVE;
      else
        case (STATE_OUT)
          S_OUT_RECEIVE:
            if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
              STATE_OUT <= S_OUT_WAIT;

          S_OUT_WAIT:
            if (mem_count == 2'd2 || mem_count > send_count)
              STATE_OUT <= S_OUT_SEND;

          S_OUT_SEND:
            if (sended)
              if (send_count == 3'd4)
                STATE_OUT <= S_OUT_RECEIVE;

              else
                STATE_OUT <= S_OUT_WAIT;
        endcase
   end

   // MEM_SEND_ADDR_VALID
   `sendAlways(posedge CLK, RST, STATE_IN == S_IN_MEM_SEND, MEM_SEND_ADDR_VALID, MEM_SEND_READY)

   // current_fn_data
   always @ (posedge CLK) begin
      if (RST)
        current_fn_data <= 0;
      else if (MEM_RECEIVE_VALID && MEM_RECEIVE_READY)
        if (mem_count == 2'd2)
          current_fn_data[30:0] <= MEM_RECEIVE_DATA[30:0];
        else
          current_fn_data[FUNCTION_WIDTH - 1 - mem_count * 32 -: 32]
            <= MEM_RECEIVE_DATA;
   end

   // SEND_PR_VALID
   `sendAlways(posedge CLK, RST, STATE_OUT == S_OUT_SEND && pr_valid, SEND_PR_VALID, SEND_PR_READY)

   // RECEIVE_PC_READY
   `receiveAlways(posedge CLK, RST, STATE_IN == S_IN_RECEIVE, RECEIVE_PC_VALID, RECEIVE_PC_READY)

   // current_pc_data
   always @ (posedge CLK) begin
      if (RST)
        current_pc_data <= 0;
      else if (RECEIVE_PC_VALID && RECEIVE_PC_READY)
        current_pc_data <= RECEIVE_PC_DATA;
   end
    
endmodule
