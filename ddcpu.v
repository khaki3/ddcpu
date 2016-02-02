module ddcpu #
  (
    parameter integer C_M_AXI_THREAD_ID_WIDTH = 1,
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_M_AXI_AWUSER_WIDTH = 1,
    parameter integer C_M_AXI_ARUSER_WIDTH = 1,
    parameter integer C_M_AXI_WUSER_WIDTH = 1,
    parameter integer C_M_AXI_RUSER_WIDTH = 1,
    parameter integer C_M_AXI_BUSER_WIDTH = 1,
    parameter integer WORKER_NUM = 3,
    `include "include/param.vh"
    )
  (
   input                                CLK,
   input                                RST,

   // COMMAND SIGNAL
   input                                START,
   output reg                           STOP, 

   // PROGRAM ADDR
   input [31:0]                         OPADDR,
   input [31:0]                         FNADDR,

   // AXI
   output [C_M_AXI_THREAD_ID_WIDTH-1:0] M_AXI_AWID,
   output [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_AWADDR,
   output [8-1:0]                       M_AXI_AWLEN,
   output [3-1:0]                       M_AXI_AWSIZE,
   output [2-1:0]                       M_AXI_AWBURST,
   output [2-1:0]                       M_AXI_AWLOCK,
   output [4-1:0]                       M_AXI_AWCACHE,
   output [3-1:0]                       M_AXI_AWPROT,
   output [4-1:0]                       M_AXI_AWQOS,
   output [C_M_AXI_AWUSER_WIDTH-1:0]    M_AXI_AWUSER,
   output                               M_AXI_AWVALID,
   input                                M_AXI_AWREADY,

   output [C_M_AXI_DATA_WIDTH-1:0]      M_AXI_WDATA,
   output [C_M_AXI_DATA_WIDTH/8-1:0]    M_AXI_WSTRB,
   output                               M_AXI_WLAST,
   output [C_M_AXI_WUSER_WIDTH-1:0]     M_AXI_WUSER,
   output                               M_AXI_WVALID,
   input                                M_AXI_WREADY,

   input [C_M_AXI_THREAD_ID_WIDTH-1:0]  M_AXI_BID,
   input [2-1:0]                        M_AXI_BRESP,
   input [C_M_AXI_BUSER_WIDTH-1:0]      M_AXI_BUSER,
   input                                M_AXI_BVALID,
   output                               M_AXI_BREADY,
  
   output [C_M_AXI_THREAD_ID_WIDTH-1:0] M_AXI_ARID,
   output [C_M_AXI_ADDR_WIDTH-1:0]      M_AXI_ARADDR,
   output [8-1:0]                       M_AXI_ARLEN,
   output [3-1:0]                       M_AXI_ARSIZE,
   output [2-1:0]                       M_AXI_ARBURST,
   output [2-1:0]                       M_AXI_ARLOCK,
   output [4-1:0]                       M_AXI_ARCACHE,
   output [3-1:0]                       M_AXI_ARPROT,
   output [4-1:0]                       M_AXI_ARQOS,
   output [C_M_AXI_ARUSER_WIDTH-1:0]    M_AXI_ARUSER,
   output                               M_AXI_ARVALID,
   input                                M_AXI_ARREADY,

   input [C_M_AXI_THREAD_ID_WIDTH-1:0]  M_AXI_RID,
   input [C_M_AXI_DATA_WIDTH-1:0]       M_AXI_RDATA,
   input [2-1:0]                        M_AXI_RRESP,
   input                                M_AXI_RLAST,
   input [C_M_AXI_RUSER_WIDTH-1:0]      M_AXI_RUSER,
   input                                M_AXI_RVALID,
   output                               M_AXI_RREADY
   );

   //
   // memory controller
   //
   wire mc_receive_addr_valid;
   wire [31:0] mc_receive_addr;
   wire mc_receive_data_valid;
   wire [31:0] mc_receive_data;
   wire mc_receive_ready;

   wire mc_send_valid;
   wire [31:0] mc_send_data;
   wire mc_send_ready;

   // Address restriction
   wire [31:0] ARADDR;
   wire [31:0] AWADDR;
   assign M_AXI_ARADDR = {3'b001, ARADDR[28:0]};
   assign M_AXI_AWADDR = {3'b001, AWADDR[28:0]};

   memory_controller memory_controller
     (
      .CLK     (CLK),
      .RST     (RST),

      .RECEIVE_ADDR_VALID (mc_receive_addr_valid),
      .RECEIVE_ADDR       (mc_receive_addr),
      .RECEIVE_DATA_VALID (mc_receive_data_valid),
      .RECEIVE_DATA       (mc_receive_data),
      .RECEIVE_READY      (mc_receive_ready),

      .SEND_VALID         (mc_send_valid),
      .SEND_DATA          (mc_send_data),
      .SEND_READY         (mc_send_ready),

      .ARADDR  (ARADDR),
      .ARVALID (M_AXI_ARVALID),
      .ARREADY (M_AXI_ARREADY),

      .RVALID  (M_AXI_RVALID),
      .RDATA   (M_AXI_RDATA),
      .RREADY  (M_AXI_RREADY),

      .AWREADY (M_AXI_AWREADY),
      .AWADDR  (AWADDR),
      .AWVALID (M_AXI_AWVALID),

      .WREADY  (M_AXI_WREADY),
      .WDATA   (M_AXI_WDATA),
      .WVALID  (M_AXI_WVALID),
      .WLAST   (M_AXI_WLAST));

   axi_config axi_config
     (
      .AWID    (M_AXI_AWID),
      .AWBURST (M_AXI_AWBURST),
      .AWLEN   (M_AXI_AWLEN),
      .AWSIZE  (M_AXI_AWSIZE),
      .AWLOCK  (M_AXI_AWLOCK),
      .AWCACHE (M_AXI_AWCACHE),
      .AWPROT  (M_AXI_AWPROT),
      .AWQOS   (M_AXI_AWQOS),
      .AWUSER  (M_AXI_AWUSER),

      .WSTRB   (M_AXI_WSTRB),
      .WUSER   (M_AXI_WUSER),

      .BREADY  (M_AXI_BREADY),

      .ARID    (M_AXI_ARID),
      .ARLEN   (M_AXI_ARLEN),
      .ARSIZE  (M_AXI_ARSIZE),
      .ARBURST (M_AXI_ARBURST),
      .ARLOCK  (M_AXI_ARLOCK),
      .ARCACHE (M_AXI_ARCACHE),
      .ARPROT  (M_AXI_ARPROT),
      .ARQOS   (M_AXI_ARQOS),
      .ARUSER  (M_AXI_ARUSER));

   
   //
   // startup
   //
   wire EXECUTION_END;

   // STOP
   always @ (posedge CLK) begin
      if (RST)
        STOP <= 1;
      else if (EXECUTION_END)
        STOP <= 1;
      else if (START && STOP)
        STOP <= 0;
   end

   wire startup_send_pr_valid;
   wire [PACKET_REQUEST_WIDTH-1:0] startup_send_pr_data;
   wire startup_send_pr_ready;
   
   startup startup
     (.CLK(CLK), .RST(RST),

      .START(START),
      .STOP(STOP),

      .SEND_PR_VALID (startup_send_pr_valid),
      .SEND_PR_DATA  (startup_send_pr_data),
      .SEND_PR_READY (startup_send_pr_ready)
      );

   //
   // QUEUE
   //
   wire qu_receive_pc_valid;
   wire [PACKET_WIDTH-1:0] qu_receive_pc_data;
   wire qu_receive_pc_ready;

   wire qu_send_pc_valid;
   wire [PACKET_WIDTH-1:0] qu_send_pc_data;
   wire qu_send_pc_ready;

   queue queue
     (.CLK(CLK), .RST(RST),

      .RECEIVE_PC_VALID (qu_receive_pc_valid),
      .RECEIVE_PC_DATA  (qu_receive_pc_data),
      .RECEIVE_PC_READY (qu_receive_pc_ready),

      .SEND_PC_VALID (qu_send_pc_valid),
      .SEND_PC_DATA  (qu_send_pc_data),
      .SEND_PC_READY (qu_send_pc_ready));

   //
   // WORKER
   //
   wire [WORKER_NUM-1:0] wk_receive_pc_valid;
   wire [PACKET_WIDTH-1:0] wk_receive_pc_data [WORKER_NUM-1:0];
   wire [WORKER_NUM-1:0] wk_receive_pc_ready;

   wire [WORKER_NUM-1:0] wk_send_wr_valid;
   reg  [WORKER_RESULT_WIDTH-1:0] wk_send_wr_data [WORKER_NUM-1:0];
   wire [WORKER_NUM-1:0] wk_send_wr_ready;

   wire [PACKET_WIDTH*WORKER_NUM-1:0] entire_wk_receive_pc_data;

   integer i_ewk;
   always @*
      for (i_ewk = 0; i_ewk < WORKER_NUM; i_ewk = i_ewk + 1)
        wk_send_wr_data[i_ewk]
          = entire_wk_receive_pc_data[PACKET_WIDTH * (i_ewk + 1) - 1 -: PACKET_WIDTH];

   // queue -> workers
   connect_fork #
     (
      .DATA_WIDTH(PACKET_WIDTH),
      .CONNECT_NUM(WORKER_NUM)
      ) cfToWK
     (.RECEIVE_VALID (qu_send_pc_valid),
      .RECEIVE_DATA  (qu_send_pc_data),
      .RECEIVE_READY (qu_send_pc_ready),

      .SEND_VALID (wk_receive_pc_valid),
      .SEND_DATA  (entire_wk_receive_pc_data),
      .SEND_READY (wk_receive_pc_ready));

   genvar wi;
   generate
      for (wi = 0; wi < WORKER_NUM; wi = wi + 1) begin : worker_block
         worker wk
           (.CLK(CLK), .RST(RST),

            .RECEIVE_PC_VALID (wk_receive_pc_valid),
            .RECEIVE_PC_DATA  (wk_receive_pc_data),
            .RECEIVE_PC_READY (wk_receive_pc_ready),

            .SEND_WR_VALID (wk_send_wr_valid),
            .SEND_WR_DATA  (wk_send_wr_data),
            .SEND_WR_READY (wk_send_wr_ready));
      end
   endgenerate

   //
   // memory accessor
   //
   wire ma_receive_pc_valid;
   wire [PACKET_WIDTH-1:0] ma_receive_pc_data;
   wire ma_receive_pc_ready;

   wire ma_send_wr_valid;
   wire [WORKER_RESULT_WIDTH-1:0] ma_send_wr_data;
   wire ma_send_wr_ready;

   wire ma_mem_send_addr_valid;
   wire [31:0] ma_mem_send_addr;
   wire ma_mem_send_data_valid;
   wire [31:0] ma_mem_send_data;
   wire ma_mem_send_ready;

   wire ma_mem_receive_valid;
   wire [31:0] ma_mem_receive_data;
   wire ma_mem_receive_ready;

   memory_accessor ma
     (
      .CLK(CLK), .RST(RST),

      .MEM_SEND_ADDR_VALID (ma_mem_send_addr_valid),
      .MEM_SEND_ADDR       (ma_mem_send_addr),
      .MEM_SEND_DATA_VALID (ma_mem_send_data_valid),
      .MEM_SEND_DATA       (ma_mem_send_data),
      .MEM_SEND_READY      (ma_mem_send_ready),

      .MEM_RECEIVE_VALID (ma_mem_receive_valid),
      .MEM_RECEIVE_DATA  (ma_mem_receive_data),
      .MEM_RECEIVE_READY (ma_mem_receive_ready),

      .RECEIVE_PC_VALID (ma_receive_pc_valid),
      .RECEIVE_PC_DATA  (ma_receive_pc_data),
      .RECEIVE_PC_READY (ma_receive_pc_ready),

      .SEND_WR_VALID (ma_send_wr_valid),
      .SEND_WR_DATA  (ma_send_wr_data),
      .SEND_WR_READY (ma_send_wr_ready));

   //
   // DISPATCHER
   //
   wire dp_receive_pr_valid;
   wire [WORKER_RESULT_WIDTH-1:0] dp_receive_pr_data;
   wire dp_receive_pr_ready;

   wire pl_receive_pr_valid_from_dp;
   wire [PACKET_REQUEST-1:0] pl_receive_pr_data_from_dp;
   wire pl_receive_pr_ready_from_dp;

   // WORKER_NUM-1 + 1
   wire [WORKER_NUM:0] ic_to_dp_receive_valid;
   wire [(WORKER_NUM+1)*WORKER_RESULT_WIDTH-1:0] ic_to_dp_receive_data;
   wire [WORKER_NUM:0] ic_to_dp_receive_ready;

   integer i_ic;

   always @* begin
      ic_to_dp_receive_valid[0] = ma_send_wr_valid;
      ic_to_dp_receive_data[WORKER_RESULT_WIDTH-1:0] = ma_send_wr_data;
      ic_to_dp_receive_ready[0] = ma_send_wr_ready;
      for (i_ic = 0; i_ic < WORKER_NUM; i_ic = i_ic + 1) begin
         ic_to_dp_receive_valid[i_ic+1] = wk_send_wr_valid[i_ic];
         ic_to_dp_receive_data[WORKER_RESULT_WIDTH * (i_ic + 2) - 1 -: WORKER_RESULT_WIDTH]
           = wk_send_wr_data[i_ic];
         ic_to_dp_receive_ready[i_ic+1] = wk_send_wr_ready[i_ic];
      end
   end

   // [workers, memory_accessor] -> dispatcher
   connect_join #
     (
      .DATA_WIDTH(WORKER_RESULT_WIDTH),
      .CONNECT_NUM(WORKER_NUM + 1)
      ) cjToDP
     (.RECEIVE_VALID (ic_to_dp_receive_valid),
      .RECEIVE_DATA  (ic_to_dp_receive_data),
      .RECEIVE_READY (ic_to_dp_receive_ready),

      .SEND_VALID (dp_receive_pr_valid),
      .SEND_DATA  (dp_receive_pr_data),
      .SEND_READY (dp_receive_pr_ready)
      );

   dispatcher dp
     (.CLK(CLK), .RST(RST),

      .EXECUTION_END (EXECUTION_END),

      .RECEIVE_WR_VALID (dp_receive_pr_valid),
      .RECEIVE_WR_DATA  (dp_receive_pr_data),
      .RECEIVE_WR_READY (dp_receive_pr_ready),

      .SEND_WR_VALID (mm_receive_wr_valid),
      .SEND_WR_DATA  (mm_receive_wr_data),
      .SEND_WR_READY (mm_receive_wr_ready),

      .SEND_PR_VALID (pl_receive_pr_valid_from_dp),
      .SEND_PR_DATA  (pl_receive_pr_data_from_dp),
      .SEND_PR_READY (pl_receive_pr_ready_from_dp));

   //
   // matching memory
   //
   wire mm_receive_wr_valid;
   wire [WORKER_RESULT_WIDTH-1:0] mm_receive_wr_data;
   wire mm_receive_wr_ready;

   wire pl_receive_pr_valid_from_mm;
   wire [PACKET_REQUEST-1:0] pl_receive_pr_data_from_mm;
   wire pl_receive_pr_ready_from_mm;

   matching_memory mm
     (.CLK(CLK), .RST(RST),
      .RECEIVE_WR_VALID (mm_receive_wr_valid),
      .RECEIVE_WR_DATA  (mm_receive_wr_data),
      .RECEIVE_WR_READY (mm_receive_wr_ready),

      .SEND_PR_VALID (pl_receive_pr_valid_from_mm),
      .SEND_PR_DATA  (pl_receive_pr_data_from_mm),
      .SEND_PR_READY (pl_receive_pr_ready_from_mm)
      );

   //
   // function expander
   //
   wire fe_mem_send_addr_valid;
   wire [31:0] fe_mem_send_addr;
   wire fe_mem_send_data_valid;
   wire [31:0] fe_mem_send_data;
   wire fe_mem_send_ready;

   wire fe_mem_receive_valid;
   wire [31:0] fe_mem_receive_data;
   wire fe_mem_receive_ready;

   wire fe_receive_pc_valid;
   wire [PACKET_WIDTH-1:0] fe_receive_pc_data;
   wire fe_receive_pc_ready;

   wire pl_receive_pr_valid_from_fe;
   wire [PACKET_REQUEST-1:0] pl_receive_pr_data_from_fe;
   wire pl_receive_pr_ready_from_fe;

   function_expander fe
     (.CLK(CLK), .RST(RST),
      .FNADDR(FNADDR),

      .MEM_SEND_ADDR_VALID (fe_mem_send_addr_valid),
      .MEM_SEND_ADDR       (fe_mem_send_addr),
      .MEM_SEND_DATA_VALID (fe_mem_send_data_valid),
      .MEM_SEND_DATA       (fe_mem_send_data),
      .MEM_SEND_READY      (fe_mem_send_ready),

      .MEM_RECEIVE_VALID (fe_mem_receive_valid),
      .MEM_RECEIVE_DATA  (fe_mem_receive_data),
      .MEM_RECEIVE_READY (fe_mem_receive_ready),

      .RECEIVE_PC_VALID (fe_receive_pc_valid),
      .RECEIVE_PC_DATA  (fe_receive_pc_data),
      .RECEIVE_PC_READY (fe_receive_pc_ready), 

      .SEND_PR_VALID (pl_receive_pr_valid_from_fe),
      .SEND_PR_DATA  (pl_receive_pr_data_from_fe),
      .SEND_PR_READY (pl_receive_pr_ready_from_fe));

   //
   // packet loader
   //
   wire pl_receive_pr_valid;
   wire [PACKET_REQUEST_WIDTH-1:0] pl_receive_pr_data;
   wire pl_receive_pr_ready;

   wire pl_mem_send_addr_valid;
   wire [31:0] pl_mem_send_addr;
   wire pl_mem_send_data_valid;
   wire [31:0] pl_mem_send_data;
   wire pl_mem_send_ready;

   wire pl_mem_receive_valid;
   wire [31:0] pl_mem_receive_data;
   wire pl_mem_receive_ready;

   // [dispatcher, matching_memory, function_expander, startup]
   // -> packet_loader
   connect_join #
     (
      .DATA_WIDTH  (PACKET_REQUEST_WIDTH),
      .CONNECT_NUM (4)
      ) cjToPC
     (.RECEIVE_VALID ({pl_receive_pr_valid_from_dp,
                       pl_receive_pr_valid_from_mm,
                       pl_receive_pr_valid_from_fe,
                       startup_send_pr_valid}),

      .RECEIVE_DATA  ({pl_receive_pr_data_from_dp,
                       pl_receive_pr_data_from_mm,
                       pl_receive_pr_data_from_fe,
                       startup_send_pr_data}),

      .RECEIVE_READY ({pl_receive_pr_ready_from_dp,
                       pl_receive_pr_ready_from_mm,
                       pl_receive_pr_ready_from_fe,
                       startup_send_pr_ready}),

      .SEND_VALID (pl_receive_pr_valid),
      .SEND_DATA  (pl_receive_pr_data),
      .SEND_READY (pl_receive_pr_ready));
   
   packet_loader pl
     (.CLK(CLK), .RST(RST),

      .OPADDR(OPADDR),

      .MEM_SEND_ADDR_VALID (pl_mem_send_addr_valid),
      .MEM_SEND_ADDR       (pl_mem_send_addr),
      .MEM_SEND_DATA_VALID (pl_mem_send_data_valid),
      .MEM_SEND_DATA       (pl_mem_send_data),
      .MEM_SEND_READY      (pl_mem_send_ready),

      .MEM_RECEIVE_VALID (pl_mem_receive_valid),
      .MEM_RECEIVE_DATA  (pl_mem_receive_data),
      .MEM_RECEIVE_READY (pl_mem_receive_ready),

      .RECEIVE_PR_VALID (pl_receive_pr_valid),
      .RECEIVE_PR_DATA  (pl_receive_pr_data),
      .RECEIVE_PR_READY (pl_receive_pr_ready),

      .SEND_PC_TO_QU_VALID (qu_receive_pc_valid),
      .SEND_PC_TO_QU_DATA  (qu_receive_pc_data),
      .SEND_PC_TO_QU_READY (qu_receive_pc_ready),

      .SEND_PC_TO_FE_VALID (fe_receive_pc_valid),
      .SEND_PC_TO_FE_DATA  (fe_receive_pc_data),
      .SEND_PC_TO_FE_READY (fe_receive_pc_ready),

      .SEND_PC_TO_MA_VALID (ma_receive_pc_valid),
      .SEND_PC_TO_MA_DATA  (ma_receive_pc_data),
      .SEND_PC_TO_MA_READY (ma_receive_pc_ready)
      );

   //
   // connect_mc
   //
   connect_mc #
     (
      .CONNECT_NUM (3)
      ) cm
     (
      .CLK(CLK), .RST(RST),

      .SLAVE_RECEIVE_ADDR_VALID ({ma_mem_send_addr_valid,
                                  pl_mem_send_addr_valid,
                                  fe_mem_send_addr_valid}),

      .SLAVE_RECEIVE_ADDR       ({ma_mem_send_addr,
                                  pl_mem_send_addr,
                                  fe_mem_send_addr}),

      .SLAVE_RECEIVE_DATA_VALID ({ma_mem_send_data_valid,
                                  pl_mem_send_data_valid,
                                  fe_mem_send_data_valid}),

      .SLAVE_RECEIVE_DATA       ({ma_mem_send_data,
                                  pl_mem_send_data,
                                  fe_mem_send_data}),                                  

      .SLAVE_RECEIVE_READY      ({ma_mem_send_ready,
                                  pl_mem_send_ready,
                                  fe_mem_send_ready}),

      .SLAVE_SEND_VALID ({ma_mem_receive_valid,
                          pl_mem_receive_valid,
                          fe_mem_receive_valid}),

      .SLAVE_SEND_DATA  ({ma_mem_receive_data,
                          pl_mem_receive_data,
                          fe_mem_receive_data}),

      .SLAVE_SEND_READY ({ma_mem_receive_ready,
                          pl_mem_receive_ready,
                          fe_mem_receive_ready}),

      .MASTER_SEND_ADDR_VALID (mc_receive_addr_valid),
      .MASTER_SEND_ADDR       (mc_receive_addr),
      .MASTER_SEND_DATA_VALID (mc_receive_data_valid),
      .MASTER_SEND_DATA       (mc_receive_data),
      .MASTER_SEND_READY      (mc_receive_ready),

      .MASTER_RECEIVE_VALID (mc_send_valid),
      .MASTER_RECEIVE_DATA  (mc_send_data),
      .MASTER_RECEIVE_READY (mc_send_ready));

endmodule
