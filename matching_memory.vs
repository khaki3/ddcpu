/*

 Matching memory for waiting 2 operands
 ---------------------------------------

           |
    [worker-result]
           |
          \ /

  ===================
  | matching_memory |
  ===================

           |
    [packet-request]
           |
          \ /

   =================
   | packet_loader |
   =================
 
*/

module matching_memory #
  (
   <SCM>
     (define-constant MEM_SIZE 1024)
     (print #"parameter integer MEM_SIZE = ~MEM_SIZE,")
   </SCM>
   parameter integer SEARCH_DELAY = 4,
   `include "include/param.vh"
   )
  (
   input                             CLK,
   input                             RST,

   input                             RECEIVE_WR_VALID,
   input [WORKER_RESULT_WIDTH-1:0]   RECEIVE_WR_DATA,
   output reg                        RECEIVE_WR_READY,

   output reg                        SEND_PR_VALID,
   output [PACKET_REQUEST_WIDTH-1:0] SEND_PR_DATA,
   input                             SEND_PR_READY
   );

   reg [WORKER_RESULT_WIDTH-1:0] current_wr_data;

   `include "include/macro.vh"
   `include "include/construct.vh"
   `extract_worker_result(current_wr_data)

   reg [MEM_SIZE-1:0] valid;
   reg [WORKER_RESULT_WIDTH-1:0] mem [MEM_SIZE-1:0];
   reg [MEM_SIZE-1:0] match;
   reg [WORKER_RESULT_WIDTH-1:0] match_wr;

   wire               find;
   wire [31:0]        match_index,  invalid_index;
   wire [32:0]        match_search, invalid_search;

   assign find          = match_search[32];
   assign match_index   = match_search[31:0];
   assign invalid_index = invalid_search[31:0];

   reg [1:0] STATE;

   reg [4:0] clk_count;

   localparam
     S_RECEIVE = 2'b00,
     S_SEARCH  = 2'b01,
     S_UPDATE  = 2'b10,
     S_SEND    = 2'b11;

   // clk_count
   always @ (posedge CLK) begin
      if (RST)
        clk_count <= 0;
      else if (STATE == S_SEARCH)
        clk_count <= clk_count + 1;
      else
        clk_count <= 0;
   end

   // STATE
   always @ (posedge CLK) begin
      if (RST)
        STATE <= 0;
      else
        case (STATE)
          S_RECEIVE:
            if (RECEIVE_WR_VALID && RECEIVE_WR_READY)
              STATE <= S_SEARCH;

          S_SEARCH:
            if (clk_count == SEARCH_DELAY - 1)
              STATE <= S_UPDATE;

          S_UPDATE:
            if (find)
              STATE <= S_SEND;

            else
              STATE <= S_RECEIVE;

          S_SEND:
            if (SEND_PR_VALID && SEND_PR_READY)
              STATE <= S_RECEIVE;
        endcase
   end

   genvar i;
   generate
      for (i = 0; i < MEM_SIZE; i = i + 1) begin : cam
         always @ (posedge CLK) begin
            if (RST) begin
               mem[i]   <= 0;
               valid[i] <= 0;
            end

            else if (STATE == S_SEARCH)
              if (valid[i] &&
                  mem[i][63:48] == worker_result_dest_addr &&
                  mem[i][47:32] == worker_result_color)
                match[i] <= 1;
              else
                match[i] <= 0;

            else if (STATE == S_UPDATE)
              if (find) begin
                if (match_index == i)
                  valid[i] <= 0;
              end

              else if (invalid_index == i) begin
                 mem[i]   <= current_wr_data;
                 valid[i] <= 1;
              end
         end
      end
   endgenerate

   function [32:0] select_search;
      input [32:0] a, b;
      select_search = a[32] ? a : b[32] ? b : 33'b0;
   endfunction

   <SCM>
     ;;;
     ;;; pyramid-like assignment
     ;;;

     (use srfi-11)

     (define (match-search-term1 i)
       #"{match[~i], 32'd~i}")

     (define (match-search-term2 a b)
       #"select_search(~a, ~b)")

     (define (invalid-search-term1 i)
       #"{~~valid[~i], 32'd~i}")

     (define invalid-search-term2 match-search-term2)

     (define (split-in-half lst)
       (let ([len (length lst)])
         (split-at lst (floor (/ len 2)))))

     (define (pyramid term1-proc term2-proc lst)
       (define (recur lst) (pyramid term1-proc term2-proc lst))
       (if (= (length lst) 1)
           (term1-proc (~ lst 0))

           (let-values ([(fst snd) (split-in-half lst)])
             (term2-proc (recur fst) (recur snd)))))

     (print #"assign match_search   = ~(pyramid match-search-term1   match-search-term2   (iota MEM_SIZE));")
     (print #"assign invalid_search = ~(pyramid invalid-search-term1 invalid-search-term2 (iota MEM_SIZE));")
   </SCM>

   // match_wr
   always @ (posedge CLK) begin
      if (RST)
        match_wr <= 0;
      else if (STATE == S_UPDATE)
        match_wr <= mem[match_index];
   end

   assign SEND_PR_DATA = make_packet_request_merge(match_wr, current_wr_data);

   // SEND_PR_VALID
   `sendAlways(posedge CLK, RST, STATE == S_SEND, SEND_PR_VALID, SEND_PR_READY)

   // RECEIVE_WR_READY
   `receiveAlways(posedge CLK, RST, STATE == S_RECEIVE, RECEIVE_WR_VALID, RECEIVE_WR_READY)

   // current_wr_data
   always @ (posedge CLK) begin
      if (RST)
        current_wr_data <= 0;
      else if (RECEIVE_WR_VALID && RECEIVE_WR_READY)
        current_wr_data <= RECEIVE_WR_DATA;
   end

endmodule

/*
 Local variables:
 mode: verilog
 end:
*/
