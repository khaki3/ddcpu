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

(define (function-binary->string fb)
  (define (ref i)
    (bit-field fb (+ (* 19 i) 1) (+ (* 19 (+ i 1)) 1)))
  
  (string-append
   "("
   (dest-binary->string (ref 4))
   (dest-binary->string (ref 3))
   (dest-binary->string (ref 2))
   (dest-binary->string (ref 1))
   (dest-binary->string (ref 0))
   ")"))

(define (read-function)
  (define (r)
    (read-u32 (current-input-port) 'big-endian))

  (let* ([a (r)] [b (r)] [c (r)])
    (if (eof-object? c) c
        (logior
         (ash a 64)
         (ash b 32)
         c))))

(define (main args)
  (until (read-function) eof-object? => f
    (print (function-binary->string f))))
