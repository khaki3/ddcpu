ddcpu
=====================
* Dynamic data-driven
* Associative matching


Memory usage
-------------------------
### function table
```
|function[0][_   ]| (FNADDR)
|function[0][ _  ]|
|function[0][   _]|
|function[1][_   ]|
...
```

### packet table
```
|packet[0][_      ]| (PCADDR)
|packet[0][ _     ]|
|packet[0][   _   ]|
|packet[0][    _  ]|
|packet[0][     _ ]|
|packet[1][_      ]|
...
```

Data format
-------------------------
### packet

#### opmode (2bits)
* 00: embedded instruction
* 01: function
* 10: memory access
* 11: don't care

#### opcode (10bits)

#### data1, data2, data3, data4 (32bits)
data1 ~ data2 is modifiable by packet flow.
data1 ~ data4 can be used as options of this packet (the value will be embedded by the compiler).

#### dest-option (3bits)
##### 000 (Just execute the dest)
No data of dest-packet will be modified.
And this packet will be sent to packet-loader directly.

##### 001 (One operand operation)
data1 of dest-packet will be modified.
And this packet will be sent to packet-loader directly.

##### 010: Two operands operation (left)
data1 of dest-packet will be modified.
And this packet will be sent to matching-memory.

##### 011: Two operands operation (right)
data2 of dest-packet will be modified.
And this packet will be sent to matching-memory.

##### 100: nop (nowhere)

##### 101: end of all execution
This cpu stops.

#### dest-addr (16bits)
This indicates the address of the dest-packet.

#### color (16its)


### function
A structure for expanding functions.
All elements contain dest-option and dest-addr (the size is 3 + 16 = 19bits).
The packets of the destination will be loaded.

#### coloring (19bits)
For setting the color of the return packet.

#### returning (19bits)
For setting the destination of the return packet.

#### arg1, arg2 (19bits)
#### exec (19bits)
#### padding (1bits)

### worker-result
* dest-option (3bits)
* dest-addr (16bits)
* color (16bits)
* data (32bits)

### packet-request
* dest-option (3bits)
* dest-addr (16bits)
* color (16bits)
* arg1, arg2 (32bits)
