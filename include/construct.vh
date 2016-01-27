function [PACKET_WIDTH-1:0] make_packet;
   input [1:0]  opmode;
   input [9:0]  opcode;
   input [31:0] data1;
   input [31:0] data2;
   input [31:0] data3;
   input [31:0] data4;
   input [2:0]  dest_option;
   input [15:0] dest_addr;
   input [15:0] color;
   make_packet = {opmode, opcode, data1, data2, data3, data4,
                  dest_option, dest_addr, color};
endfunction

function [PACKET_WIDTH-1:0] make_packet_from_request;
   input [PACKET_WIDTH-1:0]         template_packet;
   input [PACKET_REQUEST_WIDTH-1:0] packet_request;
   make_packet_from_request
     = {template_packet[174:163],
        (packet_request[98:96] != DEST_OPTION_EXEC)
        ? packet_request[63:32] : template_packet[162:131],
        (packet_request[98:96] == DEST_OPTION_RIGHT)
        ? packet_request[31:0] : template_packet[130:99],
        template_packet[98:0]};
endfunction

function [WORKER_RESULT_WIDTH-1:0] make_worker_result;
   input [2:0]  dest_option;
   input [15:0] dest_addr;
   input [15:0] color;
   input [31:0] data;
   make_worker_result = {dest_option, dest_addr, color, data};
endfunction

function [WORKER_RESULT_WIDTH-1:0] make_worker_result_direct;
   input [32:0] dest;
   input [15:0] color;
   input [31:0] data;
   make_worker_result_direct = {dest[18:16], dest[15:0], color, data};
endfunction

function [PACKET_REQUEST_WIDTH-1:0] make_packet_request;
   input [2:0]  dest_option;
   input [15:0] dest_addr;
   input [15:0] color;
   input [31:0] arg1;
   input [31:0] arg2;
   make_packet_request = {dest_option, dest_addr, color, arg1, arg2};
endfunction

function [FUNCTION_WIDTH-1:0] make_function;
   input [18:0] coloring;
   input [18:0] returning;
   input [18:0] arg1;
   input [18:0] arg2;
   input [18:0] exec;
   make_function = {coloring, returning, arg1, arg2, exec};
endfunction
