`timescale 1ns/10ps

module tb_mc_connect #
  (
   parameter integer ADDR_WIDTH = 32,
   parameter integer DATA_WIDTH = 32,
   parameter integer CONNECT_NUM = 3
   );

   parameter CYCLE = 100;

   reg  CLK;
   reg  RST;

   always #(CYCLE/2)
     CLK = ~CLK;

   reg [ADDR_WIDTH-1:0] ADDR [CONNECT_NUM-1:0];
   reg [DATA_WIDTH-1:0] DATA [CONNECT_NUM-1:0];

   reg  [CONNECT_NUM-1:0] SLAVE_READ_RECEIVE_ADDR_VALID;
   reg  [ADDR_WIDTH-1:0]  SLAVE_READ_RECEIVE_ADDR [CONNECT_NUM-1:0];
   reg  [CONNECT_NUM-1:0] SLAVE_READ_RECEIVE_DATA_VALID;
   reg  [DATA_WIDTH-1:0]  SLAVE_READ_RECEIVE_DATA [CONNECT_NUM-1:0];
   wire [CONNECT_NUM-1:0] SLAVE_READ_RECEIVE_READY;

   wire [CONNECT_NUM-1:0] SLAVE_READ_SEND_ADDR_VALID;
   wire [ADDR_WIDTH-1:0]  SLAVE_READ_SEND_ADDR [CONNECT_NUM-1:0];
   wire [CONNECT_NUM-1:0] SLAVE_READ_SEND_DATA_VALID;
   wire [DATA_WIDTH-1:0]  SLAVE_READ_SEND_DATA [CONNECT_NUM-1:0];
   wire [CONNECT_NUM-1:0] SLAVE_READ_SEND_READY;

   wire [CONNECT_NUM-1:0] SLAVE_WRITE_RECEIVE_VALID;
   reg  [DATA_WIDTH-1:0]  SLAVE_WRITE_RECEIVE_DATA [CONNECT_NUM-1:0];
   wire [CONNECT_NUM-1:0] SLAVE_WRITE_RECEIVE_READY;

   wire [CONNECT_NUM-1:0] SLAVE_WRITE_SEND_VALID;
   wire [DATA_WIDTH-1:0]  SLAVE_WRITE_SEND_DATA [CONNECT_NUM-1:0];
   reg  [CONNECT_NUM-1:0] SLAVE_WRITE_SEND_READY;

   wire                   MASTER_READ_RECEIVE_ADDR_VALID;
   wire [DATA_WIDTH-1:0]  MASTER_READ_RECEIVE_ADDR;
   wire                   MASTER_READ_RECEIVE_DATA_VALID;
   wire [ADDR_WIDTH-1:0]  MASTER_READ_RECEIVE_DATA;
   wire                   MASTER_READ_RECEIVE_READY;

   wire                   MASTER_READ_SEND_ADDR_VALID;
   wire [DATA_WIDTH-1:0]  MASTER_READ_SEND_ADDR;
   wire                   MASTER_READ_SEND_DATA_VALID;
   wire [ADDR_WIDTH-1:0]  MASTER_READ_SEND_DATA;
   reg                    MASTER_READ_SEND_READY;

   reg                    MASTER_WRITE_RECEIVE_VALID;
   reg [DATA_WIDTH-1:0]   MASTER_WRITE_RECEIVE_DATA;
   wire                   MASTER_WRITE_RECEIVE_READY;

   wire                   MASTER_WRITE_SEND_VALID;
   wire [DATA_WIDTH-1:0]  MASTER_WRITE_SEND_DATA;
   wire                   MASTER_WRITE_SEND_READY;

   reg  [ADDR_WIDTH*CONNECT_NUM-1:0] entire_slave_read_send_addr;
   reg  [DATA_WIDTH*CONNECT_NUM-1:0] entire_slave_read_send_data;
   wire [DATA_WIDTH*CONNECT_NUM-1:0] entire_slave_write_receive_data;

   integer i_en;
   always @* begin
      for (i_en = 0; i_en < CONNECT_NUM; i_en = i_en + 1) begin
         entire_slave_read_send_addr[ADDR_WIDTH * (i_en + 1) - 1 -: ADDR_WIDTH] = SLAVE_READ_SEND_ADDR[i_en];
         entire_slave_read_send_data[DATA_WIDTH * (i_en + 1) - 1 -: DATA_WIDTH] = SLAVE_READ_SEND_DATA[i_en];
         SLAVE_WRITE_RECEIVE_DATA[i_en] = entire_slave_write_receive_data[DATA_WIDTH * (i_en + 1) - 1 -: DATA_WIDTH];
      end
   end

   genvar iG;
   generate
      for (iG = 0; iG < CONNECT_NUM; iG = iG + 1) begin : slave_connection
         echo_mem slave
          (.CLK(CLK), .RST(RST),

           .READ_RECEIVE_ADDR_VALID (SLAVE_READ_RECEIVE_ADDR_VALID[iG]),
           .READ_RECEIVE_ADDR       (SLAVE_READ_RECEIVE_ADDR[iG]),
           .READ_RECEIVE_DATA_VALID (SLAVE_READ_RECEIVE_DATA_VALID[iG]),
           .READ_RECEIVE_DATA       (SLAVE_READ_RECEIVE_DATA[iG]),
           .READ_RECEIVE_READY      (SLAVE_READ_RECEIVE_READY[iG]),

           .READ_SEND_ADDR_VALID (SLAVE_READ_SEND_ADDR_VALID[iG]),
           .READ_SEND_ADDR       (SLAVE_READ_SEND_ADDR[iG]),
           .READ_SEND_DATA_VALID (SLAVE_READ_SEND_DATA_VALID[iG]),
           .READ_SEND_DATA       (SLAVE_READ_SEND_DATA[iG]),
           .READ_SEND_READY      (SLAVE_READ_SEND_READY[iG]),

           .WRITE_RECEIVE_VALID (SLAVE_WRITE_RECEIVE_VALID[iG]),
           .WRITE_RECEIVE_DATA  (SLAVE_WRITE_RECEIVE_DATA[iG]),
           .WRITE_RECEIVE_READY (SLAVE_WRITE_RECEIVE_READY[iG]),

           .WRITE_SEND_VALID (SLAVE_WRITE_SEND_VALID[iG]),
           .WRITE_SEND_DATA  (SLAVE_WRITE_SEND_DATA[iG]),
           .WRITE_SEND_READY (SLAVE_WRITE_SEND_READY[iG]));
      end
   endgenerate

   mc_connect #
     (
      .DATA_WIDTH(DATA_WIDTH),
      .CONNECT_NUM(CONNECT_NUM)
      ) m0
     (.CLK(CLK), .RST(RST),
      .SLAVE_RECEIVE_ADDR_VALID (SLAVE_READ_SEND_ADDR_VALID),
      .SLAVE_RECEIVE_ADDR       (entire_slave_read_send_addr),
      .SLAVE_RECEIVE_DATA_VALID (SLAVE_READ_SEND_DATA_VALID),
      .SLAVE_RECEIVE_DATA       (entire_slave_read_send_data),
      .SLAVE_RECEIVE_READY      (SLAVE_READ_SEND_READY),

      .SLAVE_SEND_VALID (SLAVE_WRITE_RECEIVE_VALID),
      .SLAVE_SEND_DATA  (entire_slave_write_receive_data),
      .SLAVE_SEND_READY (SLAVE_WRITE_RECEIVE_READY),

      .MASTER_SEND_ADDR_VALID (MASTER_READ_RECEIVE_ADDR_VALID),
      .MASTER_SEND_ADDR       (MASTER_READ_RECEIVE_ADDR),
      .MASTER_SEND_DATA_VALID (MASTER_READ_RECEIVE_DATA_VALID),
      .MASTER_SEND_DATA       (MASTER_READ_RECEIVE_DATA),
      .MASTER_SEND_READY      (MASTER_READ_RECEIVE_READY),

      .MASTER_RECEIVE_VALID (MASTER_WRITE_SEND_VALID),
      .MASTER_RECEIVE_DATA  (MASTER_WRITE_SEND_DATA),
      .MASTER_RECEIVE_READY (MASTER_WRITE_SEND_READY));

   echo_mem master
     (.CLK(CLK), .RST(RST),

      .READ_RECEIVE_ADDR_VALID (MASTER_READ_RECEIVE_ADDR_VALID),
      .READ_RECEIVE_ADDR       (MASTER_READ_RECEIVE_ADDR),
      .READ_RECEIVE_DATA_VALID (MASTER_READ_RECEIVE_DATA_VALID),
      .READ_RECEIVE_DATA       (MASTER_READ_RECEIVE_DATA),
      .READ_RECEIVE_READY      (MASTER_READ_RECEIVE_READY),

      .READ_SEND_ADDR_VALID (MASTER_READ_SEND_ADDR_VALID),
      .READ_SEND_ADDR       (MASTER_READ_SEND_ADDR),
      .READ_SEND_DATA_VALID (MASTER_READ_SEND_DATA_VALID),
      .READ_SEND_DATA       (MASTER_READ_SEND_DATA),
      .READ_SEND_READY      (MASTER_READ_SEND_READY),

      .WRITE_RECEIVE_VALID (MASTER_WRITE_RECEIVE_VALID),
      .WRITE_RECEIVE_DATA  (MASTER_WRITE_RECEIVE_DATA),
      .WRITE_RECEIVE_READY (MASTER_WRITE_RECEIVE_READY),

      .WRITE_SEND_VALID (MASTER_WRITE_SEND_VALID),
      .WRITE_SEND_DATA  (MASTER_WRITE_SEND_DATA),
      .WRITE_SEND_READY (MASTER_WRITE_SEND_READY));

   task raiseError(input integer stage);
      begin
         $display("ERROR: %x", stage);
         $stop;
      end
   endtask

   integer i_init;

   task initTest;
      begin
         CLK = 1;
         RST = 1;

         for (i_init = 0; i_init < CONNECT_NUM; i_init = i_init + 1) begin
            SLAVE_READ_RECEIVE_ADDR_VALID[i_init] = 0;
            SLAVE_READ_RECEIVE_DATA_VALID[i_init] = 0;
            SLAVE_WRITE_SEND_READY[i_init]        = 0;

            ADDR[i_init] = $random;
            DATA[i_init] = $random;
            SLAVE_READ_RECEIVE_ADDR[i_init] = ADDR[i_init];
            SLAVE_READ_RECEIVE_DATA[i_init] = DATA[i_init];
         end
         MASTER_READ_SEND_READY     = 0;
         MASTER_WRITE_RECEIVE_VALID = 0;

         #CYCLE;

         if(!(MASTER_READ_SEND_ADDR_VALID === 0 &&
              MASTER_WRITE_RECEIVE_READY  === 0 &&
              SLAVE_READ_RECEIVE_READY    === 0 &&
              SLAVE_WRITE_SEND_VALID      === 0))
           raiseError('h00);

         RST = 0;
      end
   endtask
   
   `include "include/macro.vh"

   task automatic sendSlave;
      input [31:0] index;
      input        data_valid;
      begin
         SLAVE_READ_RECEIVE_DATA_VALID = data_valid;
         `sendTask(CYCLE, SLAVE_READ_RECEIVE_ADDR_VALID[index], SLAVE_READ_RECEIVE_READY[index])
      end
   endtask

   task automatic receiveSlave;
      input [31:0] index;
      `receiveTask(CYCLE, SLAVE_WRITE_SEND_VALID[index], SLAVE_WRITE_SEND_READY[index])
   endtask

   task automatic receiveMaster;
      `receiveTask(CYCLE, MASTER_READ_SEND_ADDR_VALID, MASTER_READ_SEND_READY)
   endtask

   task automatic sendMaster;
      `sendTask(CYCLE, MASTER_WRITE_RECEIVE_VALID, MASTER_WRITE_RECEIVE_READY)
   endtask

   task receiveTest;
      input [31:0] index;
      input        data_valid;
      begin
         receiveMaster;

         if (!(MASTER_READ_RECEIVE_DATA_VALID === data_valid  &&
               MASTER_READ_RECEIVE_ADDR       === ADDR[index] &&
               MASTER_READ_RECEIVE_DATA       === DATA[index]))
           raiseError('h10);

         MASTER_WRITE_RECEIVE_DATA = DATA[index];
         fork
            sendMaster;
            receiveSlave(index);
         join

         if (!(SLAVE_WRITE_SEND_DATA[index] === DATA[index]))
           raiseError('h11);
      end
   endtask

   reg data_valid;
   
   task icTest;
      fork
         data_valid = $random;
         sendSlave(2, data_valid);
         sendSlave(1, data_valid);
         sendSlave(0, data_valid);
         begin
            receiveTest(2, data_valid);
            receiveTest(1, data_valid);
            receiveTest(0, data_valid);
         end
      join
   endtask

   integer i_main;

   initial begin
      initTest;
      for (i_main = 0; i_main < 100; i_main = i_main + 1)
        icTest;
      $display("finish");
      $stop;
   end

endmodule
