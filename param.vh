//
// SIZE
//

/*
 opmode = 2
 opcode = 10
 data1  = 32
 data2  = 32
 data3  = 32
 data4  = 32
 dest_option = 3
 dest_addr   = 16
 color       = 16
 */
parameter integer PACKET_WIDTH = 175,

/*
 dest_option = 3
 dest_addr   = 16
 color       = 16
 result      = 32
 */
parameter integer WORKER_RESULT_WIDTH = 67,

/*
 dest_option = 3
 dest_addr   = 16
 color       = 16
 args1       = 32
 args2       = 32
*/
parameter integer PACKT_REQUEST_WIDTH = 99,

/*
 coloring  = 19
 returning = 19
 arg1      = 19
 arg2      = 19
 exec      = 19
 sum => 95 -> 96 ; (* 32 3)
*/
parameter integer FUNCTION_WIDTH = 96,

// 
// instructions number
//
parameter INSN_DISTRIBUTE = 10'h000,
parameter INSN_SWITCH     = 10'h001,
parameter INSN_SET_COLOR  = 10'h002,
parameter INSN_SYNC       = 10'h003,
parameter INSN_PLUS       = 10'h100
