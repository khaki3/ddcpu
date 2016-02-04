///
/// SIZE
///

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
parameter integer PACKET_REQUEST_WIDTH = 99,

/*
 coloring  = 19
 returning = 19
 arg1      = 19
 arg2      = 19
 exec      = 19
 padding   = 1
*/
parameter integer FUNCTION_WIDTH = 96,

/// 
/// instructions number
///
parameter INSN_DISTRIBUTE = 10'h000,
parameter INSN_SWITCH     = 10'h001,
parameter INSN_SET_COLOR  = 10'h002,
parameter INSN_SYNC       = 10'h003,
parameter INSN_PLUS       = 10'h100,
parameter INSN_AND        = 10'h101,
parameter INSN_NZ         = 10'h102,

// MA
parameter MA_REF = 10'h000,
parameter MA_SET = 10'h001,

///
/// opcode
///
parameter OPCODE_EI = 2'b00,
parameter OPCODE_FN = 2'b01,
parameter OPCODE_MA = 2'b10,

///
/// dest option
///
parameter DEST_OPTION_EXEC  = 3'b000,
parameter DEST_OPTION_ONE   = 3'b001,
parameter DEST_OPTION_LEFT  = 3'b010,
parameter DEST_OPTION_RIGHT = 3'b011,
parameter DEST_OPTION_NOP   = 3'b100,
parameter DEST_OPTION_END   = 3'b101
