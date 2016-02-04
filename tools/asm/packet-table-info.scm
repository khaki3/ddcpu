(use srfi-13)
(use binary.io)

(define (dest-option-binary->char b)
  (case b
    ((#b000) 'e)
    ((#b001) 'o)
    ((#b010) 'l)
    ((#b011) 'r)
    ((#b100) 'n)))

(define (dest-binary->string db)
  #"[~(dest-option-binary->char (bit-field db 16 19))  ~(bit-field db 0 16)]")

(define (data-binary->string d)
  #" 0x~(number->string d 16) ")

(define (op-binary->string ob)
  (string-append
   " "
   (string-take-right 
    (string-append
     (make-string 12 #\0)
     (number->string ob 2))
    12)))

(define (packet-binary->string pb)
  (string-append
   "("
   (dest-binary->string (bit-field pb 1 20))
   (op-binary->string   (bit-field pb (+ 20 (* 32 4)) (+ 20 (* 32 4) 12)))
   (data-binary->string (bit-field pb (+ 20 (* 32 3)) (+ 20 (* 32 4))))
   (data-binary->string (bit-field pb (+ 20 (* 32 2)) (+ 20 (* 32 3))))
   (data-binary->string (bit-field pb (+ 20 (* 32 1)) (+ 20 (* 32 2))))
   (data-binary->string (bit-field pb (+ 20 (* 32 0)) (+ 20 (* 32 1))))
   ")"
   ))

(define (read-packet)
  (define (r)
    (read-u32 (current-input-port) 'big-endian))

  (let* ([a (r)] [b (r)] [c (r)] [d (r)] [e (r)])
    (if (eof-object? d) d
        (logior
         (ash a 128)
         (ash b 96)
         (ash c 64)
         (ash d 32)
         e))))

(define (main args)
  (until (read-packet) eof-object? => p
    (print (packet-binary->string p))))
