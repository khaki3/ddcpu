;;;
;;; ddcpu assembler
;;;
   
#| syntax

<asm> ::= <fun> ...

;; (def name coloring returning arg1 arg2 exec (body ...))
<fun> ::= (def name <dest> <dest> <dest> <dest> <dest> (<packet> ...))

;; exec, one, left, right, nop
<dest> ::= ([eolrn] <packet-number>)

<packet> ::= (<dest> <op> <arg> <arg> <arg> <arg>)

<op> ::= op-symbol | fun-name

;; '_' will be undefined value
<arg> ::= 32bits binary | fun-name | '_' | <dest>

;; packet-number will be began from 0
<packet-number> ::= <number>

|#

#| sample

(def main [r 1] [r 2] [n _] [n _] [e 0]
  (([l 1] f _ _ _ _) ; 0

   ([l 2] SET_COLOR _ _ _ _) ; 1

   ([n 0] DISTRIBUTE _ _ (n _) _) ;2
   ))

(def f [r 3] [r 4] [n _] [n _] [e 0]
  (([r 1] REF #x2000_0000 _ _ _) ; 0

   ([r 2] + 10 _ _ _) ; 1

   ([l 3] SET #x2000_0004 _ _ _) ; 2

   ([l 4] SET_COLOR _ _ _ _) ; 3

   ([n _] DISTRIBUTE _ _ (n _) _) ; 4
   ))

  ||
  \/

(define (main)
  (f))

(define (f)
  (set-to #x2000_0004 (+ 10 (read-from #x2000_0000))))

|#

(use srfi-11)
(use file.util)
(use util.match)
(use binary.io)
(use gauche.uvector)
(use gauche.record)
(use gauche.sequence)

; TODO
;
; CALL
; SWITCH
; SYNC
; REF
; SET
; SET_COLOR
; DISTRIBUTE
; +
;

(define-record-type def %make-def #t
  name
  coloring
  returning
  arg1
  arg2
  exec
  packets)

(define-record-type dest %make-dest #t
  option
  packet-number)

(define-record-type packet %make-packet #t
  dest
  args)

(define-constant PCADDR_STEP 16) ; (/ (* 32 4) 8)
(define-constant FNADDR_STEP 12) ; (/ (* 32 3) 8)

(define (find&delete pred lst)
  (define (return val lst fst)
    (values val (append (reverse! fst) lst)))

  (let loop ([lst lst] [fst '()])
    (if (null? lst) (return #f lst fst)
        (let* ([head (car lst)]
               [tail (cdr lst)])
          (if (pred head)
              (return head tail fst)
              (loop tail (cons head fst)))))))

(define (sort-defs defs)
  (let-values ([(main remains)
                (find&delete (^[d] (eq? (def-name d) 'main)) defs)])
    (cons main remains)))

(define (make-def-order defs)
  (map-with-index
   (^[i d]
     (cons (def-name d) i))
   defs))

;; exec, one, left, right, nop
(define (dest-option->binary dest-option)
  (match dest-option
    ['e #b000]
    ['o #b001]
    ['l #b010]
    ['r #b011]
    ['n #b100]))

(define (dest->binary dest base)
  (logior
   (ash (dest-option->binary (dest-option dest)) 16)
   (+ (dest-packet-number dest) base)))

(define (def->function-binary def base)
  (let loop ([ret 0]
             [lst (list
                   (def-coloring def)
                   (def-returning def)
                   (def-arg1 def)
                   (def-arg2 def)
                   (def-exec def))])
    (if (null? lst) ret
        (loop
         (logior (ash ret 19)
                 (dest->binary (car lst) base))
         (cdr lst)))))

(define (byte-ref val i)
  (let* ([start (* i 8)]
         [end   (+ start 8)])
    (bit-field val start end)))

(define (number->u8vector val size)
  (let1 ret (make-u8vector size)
    (let loop ([i 0])
      (if (= i size) ret
          (begin
            (put-u8! ret (- size i 1) (byte-ref val i))
            (loop (+ i 1))
            )))))

(define (def->function-u8vector def base)
  (let1 fb (def->function-binary def base)
    (number->u8vector fb (* 32 3))))

(define (make-function-table defs def-order)
  (apply
   u8vector-append
   (map
    (^[d]
      (let1 base (* FNADDR_STEP (assq-ref def-order (def-name d)))
        (def->function-u8vector d base)))
    defs)))

(define (make-packet-table defs def-order)
  #u8()
  ;; TODO
  )

;; defs -> (values function-table packet-table)
(define (assemble defs)
  (let* ([defs (sort-defs defs)]
         [def-order (make-def-order defs)])
    (values
     (make-function-table defs def-order)
     (make-packet-table   defs def-order))))

(define (usage)
  (display
   "Usage: asm [input] [function-output] [packet-output]\n"
   (current-error-port)))

(define (number-validate n)
  (if (eq? n '_) 0 n))

(define (make-dest lst)
  (%make-dest (~ lst 0) (number-validate (~ lst 1))))

(define (make-packet lst)
  (%make-packet
   (make-dest (~ lst 0))
   (map (^[a] (if (list? a)
                  (make-dest a)
                  (number-validate a)))
        (cdr lst))))

(define (make-def lst)
  (%make-def
   (~ lst 1)
   (make-dest (~ lst 2))
   (make-dest (~ lst 3))
   (make-dest (~ lst 4))
   (make-dest (~ lst 5))
   (make-dest (~ lst 6))
   (map make-packet (~ lst 7))))

(define (table-output tbl oport)
  (write-uvector tbl oport 0 -1 'big-endian))

(define (main args)
  (unless (= (length args) 4)
    (usage)
    (sys-exit -1))

  (let* ([in   (~ args 1)]
         [fout (~ args 2)]
         [pout (~ args 3)]
         [defs (map make-def (file->sexp-list in))])
    (let-values ([; function table, packet table
                  (ft  pt) (assemble defs)])
      (call-with-output-file fout (pa$ table-output ft))
      (call-with-output-file pout (pa$ table-output pt))
      ))

  (sys-exit 0))