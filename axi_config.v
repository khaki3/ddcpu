module axi_config #
  (
   parameter integer C_AXI_DATA_WIDTH = 32
   )
  (
   output                          AWID,
   output [7:0]                    AWLEN,
   output [2:0]                    AWBURST,
   output [2:0]                    AWSIZE,
   output [1:0]                    AWLOCK,
   output [3:0]                    AWCACHE,
   output [2:0]                    AWPROT,
   output [3:0]                    AWQOS,
   output                          AWUSER,

   output [C_AXI_DATA_WIDTH/8-1:0] WSTRB,
   output                          WUSER,

   output                          BREADY,

   output                          ARID,
   output [7:0]                    ARLEN,
   output [2:0]                    ARSIZE,
   output [1:0]                    ARBURST,
   output [1:0]                    ARLOCK,
   output [3:0]                    ARCACHE,
   output [2:0]                    ARPROT,
   output [3:0]                    ARQOS,
   output                          ARUSER
   );

   assign ARID    = 1'b0;
   assign AWLEN   = 3'b0;   // currently, 1 - 1 = 0
   assign ARBURST = 2'b01;
   assign ARSIZE  = 3'b010;
   assign ARLOCK  = 1'b0;
   assign ARCACHE = 4'b0011;
   assign ARPROT  = 3'h0;
   assign ARQOS   = 4'h0;
   assign ARUSER  = 1'b0;

   assign AWID    = 1'b0;
   assign AWLEN   = 3'b0;   // currently, 1 - 1 = 0
   assign AWBURST = 2'b01;
   assign AWSIZE  = 3'b010; // 4 byte => 32bit
   assign AWLOCK  = 2'b00;
   assign AWCACHE = 4'b0011;
   assign AWPROT  = 3'h0;
   assign AWQOS   = 4'h0;
   assign AWUSER  = 1'b0;
   
   assign WSTRB   = 8'hff; // byte enable
   assign WUSER   = 1'b0;

   assign BREADY  = 1'b1;

endmodule
