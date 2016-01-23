wire [2:0]  packet_request_dest_option = current_pr_data[98:96];
wire [15:0] packet_request_dest_addr   = current_pr_data[95:80];
wire [15:0] packet_request_color       = current_pr_data[79:64];
wire [31:0] packet_request_arg1        = current_pr_data[63:32];
wire [31:0] packet_request_arg2        = current_pr_data[31:0];
