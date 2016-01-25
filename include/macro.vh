`define handshakeTask(A, B) \
   begin\
     B = 1;\
     while (!(A && B)) #CYCLE;\
       #CYCLE;\
     B = 0;\
   end

`define sendTask(VALID, READY)   `handshakeTask(READY, VALID)
`define receiveTask(VALID,READY) `handshakeTask(VALID, READY)
