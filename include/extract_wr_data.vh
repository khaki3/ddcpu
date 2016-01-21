wire [2:0]  worker_result_dest_option = current_wr_data[66:64];
wire [15:0] worker_result_dest_addr   = current_wr_data[63:48];
wire [15:0] worker_result_color       = current_wr_data[47:32];
wire [31:0] worker_result_data        = current_wr_data[31:0];
