;;;
;;; Scheme template engine
;;;

(use file.util)

(define (sten-eval string)
  (with-output-to-string
    (^[] (eval (read-from-string
                (string-append "(begin " string ")"))
               (current-module)))))

(define (sten string)
  (regexp-replace-all
   #/<SCM>(.*?)<\/SCM>/
   string
   (^[x] (sten-eval (x 1)))))

(define (save file string)
  (with-output-to-file file
    (^[] (display string))))

(define (usage)
  (display
   "Usage: sten [input] [output]\n"
   (current-error-port)))

(define (main args)
  (unless (= (length args) 3)
    (usage)
    (sys-exit -1))

  (let ([in  (~ args 1)]
        [out (~ args 2)])
    (save out (sten (file->string in))))

  (sys-exit 0))
