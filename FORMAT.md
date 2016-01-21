## memory usage
```scm
;;;
;;;  ============================================
;;;  | operations | function_table | free space | (memory)
;;;  ============================================
;;;
;;;  fetch as a packet  / \
;;;       | |           | |
;;;       \ /         look up
;;;
;;;     =====================
;;;     |        CPU        |
;;;     =====================
;;;
```

## data format
quote from emulator code...

```scm
(define-record-type packet #t #t
  ;;; opcode 2bits
  ;; 00: embedded instruction
  ;; 01: function
  ;; 10: memory access
  ;; 11: don't care
  opmode

  ;;; opcode 10bits
  opcode

  ;;; dataN 32bits
  ;; data1 ~ data2 can be modified by packet flow
  ;; data1 ~ data4 can be used as options of the operation
  ;;                (the value will be embedded by the compiler)
  data1 data2 data3 data4

  ;;; dest-option 3bits
  ;; 000:  just exec dest          valid args: | | |
  ;; 001:  one operand operation               |x| |
  ;; 010:  left                                |x| |
  ;; 011:  right                               | |x|
  ;; 100:  nop (nowhere)
  ;; 101:  end of all executions
  ;; else: don't care
  dest-option
  ;;; dest-addr 16bits to operations-region of memory
  dest-addr

  ;;; color 16bits
  color
  )

;; all elements contain dest-option and dest-addr
;; (the size is 16 + 3 = 19bits)
(define-record-type function #t #t
  coloring ; for setting color
  returing ; for setting dest
  arg1
  arg2
  exec)

(define-record-type worker-result %make-worker-result #t
  dest-option
  dest-addr
  color
  result ; 32bits
  )
```
