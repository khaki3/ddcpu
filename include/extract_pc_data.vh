wire [1:0]  packet_opmode      = current_pc_data[174:173];
wire [9:0]  packet_opcode      = current_pc_data[172:163];
wire [31:0] packet_data1       = current_pc_data[162:131];
wire [31:0] packet_data2       = current_pc_data[130:99];
wire [31:0] packet_data3       = current_pc_data[98:67];
wire [31:0] packet_data4       = current_pc_data[66:35];
wire [2:0]  packet_dest_option = current_pc_data[34:32];
wire [15:0] packet_dest_addr   = current_pc_data[31:16];
wire [15:0] packet_color       = current_pc_data[15:0];
