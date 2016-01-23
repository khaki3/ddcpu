`timescale 1ns/1ps

module tb_cache;

   localparam integer C_AXI_DATA_WIDTH = 32;
   localparam integer C_OFFSET_WIDTH = 29;
   localparam integer STEP = 8;

   // System Signals
   reg                ACLK;
   reg                ARESETN;

   always begin
      ACLK = 0; #(STEP/2);
      ACLK = 1; #(STEP/2);
   end

   /* ARST */
   reg [1:0]            arst_ff;

   always @( posedge ACLK ) begin
      arst_ff <= { arst_ff[0], ~ARESETN };
   end

   wire ARST = arst_ff[1];

   ///
   /// AXI connection
   ///
   wire               M_DRW_AWID;
   wire [31:0]        M_DRW_AWADDR;
   wire [7:0]         M_DRW_AWLEN;
   wire [2:0]         M_DRW_AWSIZE;
   wire [1:0]         M_DRW_AWBURST;
   wire [1:0]         M_DRW_AWLOCK;
   wire [3:0]         M_DRW_AWCACHE;
   wire [2:0]         M_DRW_AWPROT;
   wire [3:0]         M_DRW_AWQOS;
   wire               M_DRW_AWUSER;
   wire               M_DRW_AWVALID;
   wire               M_DRW_AWREADY;

   wire [C_AXI_DATA_WIDTH-1:0] M_DRW_WDATA;
   wire [C_AXI_DATA_WIDTH/8-1:0] M_DRW_WSTRB;
   wire                          M_DRW_WLAST;
   wire                          M_DRW_WUSER;
   wire                          M_DRW_WVALID;
   wire                          M_DRW_WREADY;

   wire                          M_DRW_BID;
   wire [1:0]                    M_DRW_BRESP;
   wire                          M_DRW_BUSER;
   wire                          M_DRW_BVALID;
   wire                          M_DRW_BREADY;

   wire                          M_DRW_ARID;
   wire [31:0]                   M_DRW_ARADDR;
   wire [7:0]                    M_DRW_ARLEN;
   wire [2:0]                    M_DRW_ARSIZE;
   wire [1:0]                    M_DRW_ARBURST;
   wire [1:0]                    M_DRW_ARLOCK;
   wire [3:0]                    M_DRW_ARCACHE;
   wire [2:0]                    M_DRW_ARPROT;
   wire [3:0]                    M_DRW_ARQOS;
   wire                          M_DRW_ARUSER;
   wire                          M_DRW_ARVALID;
   wire                          M_DRW_ARREADY;

   wire                          M_DRW_RID;
   wire [C_AXI_DATA_WIDTH-1:0]   M_DRW_RDATA;
   wire [1:0]                    M_DRW_RRESP;
   wire                          M_DRW_RLAST;
   wire                          M_DRW_RUSER;
   wire                          M_DRW_RVALID;
   wire                          M_DRW_RREADY;

   //
   // Thanks: http://marsee101.blog19.fc2.com/blog-entry-2875.html
   //
   axi_slave_bfm #
     (
      .READ_RANDOM_WAIT       (1),
      .C_S_AXI_DATA_WIDTH     (C_AXI_DATA_WIDTH),
      .READ_DATA_IS_INCREMENT (0),
      .C_OFFSET_WIDTH         (C_OFFSET_WIDTH)
      ) axi_slave_bfm
     (
      .ACLK           (ACLK),
      .ARESETN        (ARESETN),

      .S_AXI_AWID     (M_DRW_AWID),
      .S_AXI_AWADDR   ({3'b001, M_DRW_AWADDR[28:0]}), // 0x20000000~0x3FFFFFFF
      .S_AXI_AWLEN    (M_DRW_AWLEN),
      .S_AXI_AWSIZE   (M_DRW_AWSIZE),
      .S_AXI_AWBURST  (M_DRW_AWBURST),
      .S_AXI_AWLOCK   (M_DRW_AWLOCK),
      .S_AXI_AWCACHE  (M_DRW_AWCACHE),
      .S_AXI_AWPROT   (M_DRW_AWPROT),
      .S_AXI_AWQOS    (M_DRW_AWQOS),
      .S_AXI_AWUSER   (M_DRW_AWUSER),
      .S_AXI_AWVALID  (M_DRW_AWVALID),
      .S_AXI_AWREADY  (M_DRW_AWREADY),

      .S_AXI_WDATA    (M_DRW_WDATA),
      .S_AXI_WSTRB    (M_DRW_WSTRB),
      .S_AXI_WLAST    (M_DRW_WLAST),
      .S_AXI_WUSER    (M_DRW_WUSER),
      .S_AXI_WVALID   (M_DRW_WVALID),
      .S_AXI_WREADY   (M_DRW_WREADY),
      
      .S_AXI_BID      (M_DRW_BID),
      .S_AXI_BRESP    (M_DRW_BRESP),
      .S_AXI_BUSER    (M_DRW_BUSER),
      .S_AXI_BVALID   (M_DRW_BVALID),
      .S_AXI_BREADY   (M_DRW_BREADY),
      
      .S_AXI_ARID     (M_DRW_ARID),
      .S_AXI_ARADDR   ({3'b001, M_DRW_ARADDR[28:0]}), // 0x20000000~0x3FFFFFFF
      .S_AXI_ARLEN    (M_DRW_ARLEN),
      .S_AXI_ARSIZE   (M_DRW_ARSIZE),
      .S_AXI_ARBURST  (M_DRW_ARBURST),
      .S_AXI_ARLOCK   (M_DRW_ARLOCK),
      .S_AXI_ARCACHE  (M_DRW_ARCACHE),
      .S_AXI_ARPROT   (M_DRW_ARPROT),
      .S_AXI_ARQOS    (M_DRW_ARQOS),
      .S_AXI_ARUSER   (M_DRW_ARUSER),
      .S_AXI_ARVALID  (M_DRW_ARVALID),
      .S_AXI_ARREADY  (M_DRW_ARREADY),
      
      .S_AXI_RID      (M_DRW_RID),
      .S_AXI_RDATA    (M_DRW_RDATA),
      .S_AXI_RRESP    (M_DRW_RRESP),
      .S_AXI_RLAST    (M_DRW_RLAST),
      .S_AXI_RUSER    (M_DRW_RUSER),
      .S_AXI_RVALID   (M_DRW_RVALID),
      .S_AXI_RREADY   (M_DRW_RREADY));

   axi_config axi_config
     (
      .AWID    (M_DRW_AWID),
      .AWBURST (M_DRW_AWBURST),
      .AWLEN   (M_DRW_AWLEN),
      .AWSIZE  (M_DRW_AWSIZE),
      .AWLOCK  (M_DRW_AWLOCK),
      .AWCACHE (M_DRW_AWCACHE),
      .AWPROT  (M_DRW_AWPROT),
      .AWQOS   (M_DRW_AWQOS),
      .AWUSER  (M_DRW_AWUSER),

      .WSTRB   (M_DRW_WSTRB),
      .WUSER   (M_DRW_WUSER),

      .BREADY  (M_DRW_BREADY),

      .ARID    (M_DRW_ARID),
      .ARLEN   (M_DRW_ARLEN),
      .ARSIZE  (M_DRW_ARSIZE),
      .ARBURST (M_DRW_ARBURST),
      .ARLOCK  (M_DRW_ARLOCK),
      .ARCACHE (M_DRW_ARCACHE),
      .ARPROT  (M_DRW_ARPROT),
      .ARQOS   (M_DRW_ARQOS),
      .ARUSER  (M_DRW_ARUSER));

   reg RECEIVE_ADDR_VALID;
   reg [31:0] RECEIVE_ADDR;
   reg        RECEIVE_DATA_VALID;
   reg [31:0] RECEIVE_DATA;
   wire       RECEIVE_READY;

   wire        SEND_VALID;
   wire [31:0] SEND_DATA;
   reg         SEND_READY;

   cache cache
     (
      .CLK     (ACLK),
      .RST     (ARST),

      .RECEIVE_ADDR_VALID (RECEIVE_ADDR_VALID),
      .RECEIVE_ADDR       (RECEIVE_ADDR),
      .RECEIVE_DATA_VALID (RECEIVE_DATA_VALID),
      .RECEIVE_DATA       (RECEIVE_DATA),
      .RECEIVE_READY      (RECEIVE_READY),

      .SEND_VALID         (SEND_VALID),
      .SEND_DATA          (SEND_DATA),
      .SEND_READY         (SEND_READY),

      .ARADDR  (M_DRW_ARADDR),
      .ARVALID (M_DRW_ARVALID),
      .ARREADY (M_DRW_ARREADY),

      .RVALID  (M_DRW_RVALID),
      .RDATA   (M_DRW_RDATA),
      .RREADY  (M_DRW_RREADY),

      .AWREADY (M_DRW_AWREADY),
      .AWADDR  (M_DRW_AWADDR),
      .AWVALID (M_DRW_AWVALID),

      .WREADY  (M_DRW_WREADY),
      .WDATA   (M_DRW_WDATA),
      .WVALID  (M_DRW_WVALID),
      .WLAST   (M_DRW_WLAST));

   task raiseError(input integer stage);
      begin
         $display("ERROR: %x", stage);
         $stop;
      end
   endtask

   task send;
      begin
         RECEIVE_ADDR_VALID = 1;
         while (!(RECEIVE_ADDR_VALID && RECEIVE_READY))
           #STEP;
         #STEP;
         RECEIVE_ADDR_VALID = 0;
      end
   endtask

   task receive;
      begin
         SEND_READY = 1;
         while (!(SEND_VALID && SEND_READY))
           #STEP;
         #STEP;
         SEND_READY = 0;
      end
   endtask

   task initTest;
      begin
         ARESETN = 1;

         RECEIVE_ADDR_VALID = 1'b0;
         RECEIVE_ADDR       = 32'b0;
         RECEIVE_DATA_VALID = 1'b0;
         RECEIVE_DATA       = 32'b0;

         SEND_READY         = 1'b0;
         
         #STEP;
         ARESETN = 0;
         #(STEP*10);
         ARESETN = 1;
         #(STEP*100);
      end
   endtask

   reg [31:0] data;
   
   task pokePeekTest;
      begin
         RECEIVE_ADDR = {$random};
         data =         {$random};

         RECEIVE_DATA_VALID = 1;
         RECEIVE_DATA       = data;
         send;
         receive;

         RECEIVE_DATA_VALID = 0;
         send;
         receive;

         if (!(SEND_DATA === data))
           raiseError('h10);
      end
   endtask

   integer i;
   
   initial begin
      initTest;
      for (i = 0; i < 100; i = i + 1) begin
         pokePeekTest;
      end
      $display("finish");
      $stop;
   end

endmodule
