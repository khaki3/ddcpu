`define handshakeTask(cycle, a, b) \
   begin\
     b = 1;\
     while (!(a && b)) #cycle;\
       #cycle;\
     b = 0;\
   end

`define sendTask(cycle, valid, ready)    `handshakeTask(cycle, ready, valid)
`define receiveTask(cycle, valid, ready) `handshakeTask(cycle, valid, ready)

`define handshakeAlways(sen, rst, cond, a, b) \
   always @ (sen)\
   begin\
     if (rst)\
       b <= 0;\
     else if (cond)\
       if (a && b)\
         b <= 0;\
       else\
         b <= 1;\
   end

`define sendAlways(sen, rst, cond, valid, ready)    `handshakeAlways(sen, rst, cond, ready, valid)
`define receiveAlways(sen, rst, cond, valid, ready) `handshakeAlways(sen, rst, cond, valid, ready)
