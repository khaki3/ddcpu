///
/// handshake
///
`define handshakeTask(cycle, a, b) \
   begin\
     b = 1;\
     while (!(a && b)) #cycle;\
       #cycle;\
     b = 0;\
   end

`define sendTask(cycle, valid, ready)    `handshakeTask(cycle, ready, valid)
`define receiveTask(cycle, valid, ready) `handshakeTask(cycle, valid, ready)

`define handshakeAlways(sen, rst, cond, a, b) \
   always @ (sen)\
   begin\
     if (rst)\
       b <= 0;\
     else if (cond)\
       if (a && b)\
         b <= 0;\
       else\
         b <= 1;\
   end

`define sendAlways(sen, rst, cond, valid, ready)    `handshakeAlways(sen, rst, cond, ready, valid)
`define receiveAlways(sen, rst, cond, valid, ready) `handshakeAlways(sen, rst, cond, valid, ready)

///
/// extraction
///
`define extract_packet(packet) \
   wire [1:0]  packet_opmode      = packet[174:173];\
   wire [9:0]  packet_opcode      = packet[172:163];\
   wire [31:0] packet_data1       = packet[162:131];\
   wire [31:0] packet_data2       = packet[130:99];\
   wire [31:0] packet_data3       = packet[98:67];\
   wire [31:0] packet_data4       = packet[66:35];\
   wire [2:0]  packet_dest_option = packet[34:32];\
   wire [15:0] packet_dest_addr   = packet[31:16];\
   wire [15:0] packet_color       = packet[15:0];

`define extract_packet_request(packet_request) \
   wire [2:0]  packet_request_dest_option = packet_request[98:96];\
   wire [15:0] packet_request_dest_addr   = packet_request[95:80];\
   wire [15:0] packet_request_color       = packet_request[79:64];\
   wire [31:0] packet_request_arg1        = packet_request[63:32];\
   wire [31:0] packet_request_arg2        = packet_request[31:0];

`define extract_worker_result(worker_result) \
   wire [2:0]  worker_result_dest_option = worker_result[66:64];\
   wire [15:0] worker_result_dest_addr   = worker_result[63:48];\
   wire [15:0] worker_result_color       = worker_result[47:32];\
   wire [31:0] worker_result_data        = worker_result[31:0];

`define extract_function(fn) \
   wire [18:0] function_coloring  = fn[19 * 4 - 1 -: 19];\
   wire [18:0] function_returning = fn[19 * 3 - 1 -: 19];\
   wire [18:0] function_arg1      = fn[19 * 3 - 1 -: 19];\
   wire [18:0] function_arg2      = fn[19 * 2 - 1 -: 19];\
   wire [18:0] function_exec      = fn[19 * 1 - 1 -: 19];
