;;; seq.el --- Sequence manipulation functions  -*- lexical-binding: t -*-

;; Copyright (C) 2014-2015 Free Software Foundation, Inc.

;; Author: Nicolas Petton <nicolas@petton.fr>
;; Keywords: sequences
;; Version: 1.7
;; Package: seq

;; Maintainer: emacs-devel@gnu.org

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Sequence-manipulation functions that complement basic functions
;; provided by subr.el.
;;
;; All functions are prefixed with "seq-".
;;
;; All provided functions work on lists, strings and vectors.
;;
;; Functions taking a predicate or iterating over a sequence using a
;; function as argument take the function as their first argument and
;; the sequence as their second argument.  All other functions take
;; the sequence as their first argument.
;;
;; All functions are tested in test/automated/seq-tests.el

;;; Code:

(eval-when-compile (require 'cl-lib))

(defmacro seq-doseq (spec &rest body)
  "Loop over a sequence.
Similar to `dolist' but can be applied to lists, strings, and vectors.

Evaluate BODY with VAR bound to each element of SEQ, in turn.

\(fn (VAR SEQ) BODY...)"
  (declare (indent 1) (debug ((symbolp form &optional form) body)))
  (let ((length (make-symbol "length"))
        (seq (make-symbol "seq"))
        (index (make-symbol "index")))
    `(let* ((,seq ,(cadr spec))
            (,length (if (listp ,seq) nil (seq-length ,seq)))
            (,index (if ,length 0 ,seq)))
       (while (if ,length
                  (< ,index ,length)
                (consp ,index))
         (let ((,(car spec) (if ,length
                                (prog1 (seq-elt ,seq ,index)
                                  (setq ,index (+ ,index 1)))
                              (pop ,index))))
           ,@body)))))

(if (fboundp 'pcase-defmacro)
    ;; Implementation of `seq-let' based on a `pcase'
    ;; pattern. Requires Emacs>=25.1.
    (progn
      (pcase-defmacro seq (&rest args)
        "pcase pattern matching sequence elements.
Matches if the object is a sequence (list, string or vector), and
binds each element of ARGS to the corresponding element of the
sequence."
        `(and (pred seq-p)
              ,@(seq--make-pcase-bindings args)))

      (defmacro seq-let (args seq &rest body)
        "Bind the variables in ARGS to the elements of SEQ then evaluate BODY.

ARGS can also include the `&rest' marker followed by a variable
name to be bound to the rest of SEQ."
        (declare (indent 2) (debug t))
        `(pcase-let ((,(seq--make-pcase-patterns args) ,seq))
           ,@body)))

  ;; Implementation of `seq-let' compatible with Emacs<25.1.
  (defmacro seq-let (args seq &rest body)
    "Bind the variables in ARGS to the elements of SEQ then evaluate BODY.

ARGS can also include the `&rest' marker followed by a variable
name to be bound to the rest of SEQ."
    (declare (indent 2) (debug t))
    (let ((seq-var (make-symbol "seq")))
      `(let* ((,seq-var ,seq)
              ,@(seq--make-bindings args seq-var))
         ,@body))))

(defun seq-drop (seq n)
  "Return a subsequence of SEQ without its first N elements.
The result is a sequence of the same type as SEQ.

If N is a negative integer or zero, SEQ is returned."
  (if (<= n 0)
      seq
    (if (listp seq)
        (seq--drop-list seq n)
      (let ((length (seq-length seq)))
        (seq-subseq seq (min n length) length)))))

(defun seq-take (seq n)
  "Return a subsequence of SEQ with its first N elements.
The result is a sequence of the same type as SEQ.

If N is a negative integer or zero, an empty sequence is
returned."
  (if (listp seq)
      (seq--take-list seq n)
    (seq-subseq seq 0 (min (max n 0) (seq-length seq)))))

(defun seq-drop-while (pred seq)
  "Return a sequence from the first element for which (PRED element) is nil in SEQ.
The result is a sequence of the same type as SEQ."
  (if (listp seq)
      (seq--drop-while-list pred seq)
    (seq-drop seq (seq--count-successive pred seq))))

(defun seq-take-while (pred seq)
  "Return the successive elements for which (PRED element) is non-nil in SEQ.
The result is a sequence of the same type as SEQ."
  (if (listp seq)
      (seq--take-while-list pred seq)
    (seq-take seq (seq--count-successive pred seq))))

(defun seq-filter (pred seq)
  "Return a list of all the elements for which (PRED element) is non-nil in SEQ."
  (let ((exclude (make-symbol "exclude")))
    (delq exclude (seq-map (lambda (elt)
                             (if (funcall pred elt)
                                 elt
                               exclude))
                           seq))))

(defun seq-remove (pred seq)
  "Return a list of all the elements for which (PRED element) is nil in SEQ."
  (seq-filter (lambda (elt) (not (funcall pred elt)))
              seq))

(defun seq-reduce (function seq initial-value)
  "Reduce the function FUNCTION across SEQ, starting with INITIAL-VALUE.

Return the result of calling FUNCTION with INITIAL-VALUE and the
first element of SEQ, then calling FUNCTION with that result and
the second element of SEQ, then with that result and the third
element of SEQ, etc.

If SEQ is empty, return INITIAL-VALUE and FUNCTION is not called."
  (if (seq-empty-p seq)
      initial-value
    (let ((acc initial-value))
      (seq-doseq (elt seq)
        (setq acc (funcall function acc elt)))
      acc)))

(defun seq-some-p (pred seq)
  "Return any element for which (PRED element) is non-nil in SEQ, nil otherwise."
  (catch 'seq--break
    (seq-doseq (elt seq)
      (when (funcall pred elt)
        (throw 'seq--break elt)))
    nil))

(defun seq-every-p (pred seq)
  "Return non-nil if (PRED element) is non-nil for all elements of the sequence SEQ."
  (catch 'seq--break
    (seq-doseq (elt seq)
      (or (funcall pred elt)
          (throw 'seq--break nil)))
    t))

(defun seq-count (pred seq)
  "Return the number of elements for which (PRED element) is non-nil in SEQ."
  (let ((count 0))
    (seq-doseq (elt seq)
      (when (funcall pred elt)
        (setq count (+ 1 count))))
    count))

(defun seq-empty-p (seq)
  "Return non-nil if the sequence SEQ is empty, nil otherwise."
  (if (listp seq)
      (null seq)
    (= 0 (seq-length seq))))

(defun seq-sort (pred seq)
  "Return a sorted sequence comparing using PRED the elements of SEQ.
The result is a sequence of the same type as SEQ."
  (if (listp seq)
      (sort (seq-copy seq) pred)
    (let ((result (seq-sort pred (append seq nil))))
      (seq-into result (type-of seq)))))

(defun seq-contains-p (seq elt &optional testfn)
  "Return the first element in SEQ that equals to ELT.
Equality is defined by TESTFN if non-nil or by `equal' if nil."
  (seq-some-p (lambda (e)
                (funcall (or testfn #'equal) elt e))
              seq))

(defun seq-uniq (seq &optional testfn)
  "Return a list of the elements of SEQ with duplicates removed.
TESTFN is used to compare elements, or `equal' if TESTFN is nil."
  (let ((result '()))
    (seq-doseq (elt seq)
      (unless (seq-contains-p result elt testfn)
        (setq result (cons elt result))))
    (nreverse result)))

(defun seq-subseq (seq start &optional end)
  "Return the subsequence of SEQ from START to END.
If END is omitted, it defaults to the length of the sequence.
If START or END is negative, it counts from the end."
  (cond ((or (stringp seq) (vectorp seq)) (substring seq start end))
        ((listp seq)
         (let (len (errtext (format "Bad bounding indices: %s, %s" start end)))
           (and end (< end 0) (setq end (+ end (setq len (seq-length seq)))))
           (if (< start 0) (setq start (+ start (or len (setq len (seq-length seq))))))
           (when (> start 0)
             (setq seq (nthcdr (1- start) seq))
             (or seq (error "%s" errtext))
             (setq seq (cdr seq)))
           (if end
               (let ((res nil))
                 (while (and (>= (setq end (1- end)) start) seq)
                   (push (pop seq) res))
                 (or (= (1+ end) start) (error "%s" errtext))
                 (nreverse res))
             (seq-copy seq))))
        (t (error "Unsupported sequence: %s" seq))))

(defun seq-concatenate (type &rest seqs)
  "Concatenate, into a sequence of type TYPE, the sequences SEQS.
TYPE must be one of following symbols: vector, string or list.

\n(fn TYPE SEQUENCE...)"
  (pcase type
    (`vector (apply #'vconcat seqs))
    (`string (apply #'concat seqs))
    (`list (apply #'append (append seqs '(nil))))
    (t (error "Not a sequence type name: %S" type))))

(defun seq-mapcat (function seq &optional type)
  "Concatenate the result of applying FUNCTION to each element of SEQ.
The result is a sequence of type TYPE, or a list if TYPE is nil."
  (apply #'seq-concatenate (or type 'list)
         (seq-map function seq)))

(defun seq-partition (seq n)
  "Return a list of the elements of SEQ grouped into sub-sequences of length N.
The last sequence may contain less than N elements.  If N is a
negative integer or 0, nil is returned."
  (unless (< n 1)
    (let ((result '()))
      (while (not (seq-empty-p seq))
        (push (seq-take seq n) result)
        (setq seq (seq-drop seq n)))
      (nreverse result))))

(defun seq-intersection (seq1 seq2 &optional testfn)
  "Return a list of the elements that appear in both SEQ1 and SEQ2.
Equality is defined by TESTFN if non-nil or by `equal' if nil."
  (seq-reduce (lambda (acc elt)
                (if (seq-contains-p seq2 elt testfn)
                    (cons elt acc)
                  acc))
              (seq-reverse seq1)
              '()))

(defun seq-difference (seq1 seq2 &optional testfn)
  "Return a list of th elements that appear in SEQ1 but not in SEQ2.
Equality is defined by TESTFN if non-nil or by `equal' if nil."
  (seq-reduce (lambda (acc elt)
                (if (not (seq-contains-p seq2 elt testfn))
                    (cons elt acc)
                  acc))
              (seq-reverse seq1)
              '()))

(defun seq-group-by (function seq)
  "Apply FUNCTION to each element of SEQ.
Separate the elements of SEQ into an alist using the results as
keys.  Keys are compared using `equal'."
  (seq-reduce
   (lambda (acc elt)
     (let* ((key (funcall function elt))
            (cell (assoc key acc)))
       (if cell
           (setcdr cell (push elt (cdr cell)))
         (push (list key elt) acc))
       acc))
   (seq-reverse seq)
   nil))

(defalias 'seq-reverse
  (if (ignore-errors (reverse [1 2]))
      #'reverse
    (lambda (seq)
      "Return the reversed copy of list, vector, or string SEQ.
See also the function `nreverse', which is used more often."
      (let ((result '()))
        (seq-map (lambda (elt) (push elt result))
                 seq)
        (if (listp seq)
            result
          (seq-into result (type-of seq)))))))

(defun seq-into (seq type)
  "Convert the sequence SEQ into a sequence of type TYPE.
TYPE can be one of the following symbols: vector, string or list."
  (pcase type
    (`vector (vconcat seq))
    (`string (concat seq))
    (`list (append seq nil))
    (t (error "Not a sequence type name: %S" type))))

(defmacro seq--with-matrix-macros (&rest body)
  (declare (indent 0) (debug t))
  `(cl-macrolet ((make-matrix (rows columns &optional init-value)
                   (list 'apply (list 'quote 'vector)
                         (list 'cl-loop 'for 'i 'from 1 'to rows
                               'collect (list 'make-vector columns init-value))))
                 (mset (matrix row column newelt)
                   (list 'aset (list 'aref matrix row) column newelt))
                 (mref (matrix row column)
                   (list 'aref (list 'aref matrix row) column)))
     ,@body))

(defun seq-alignment (seq1 seq2 &optional
                           similarity-fn
                           gap-penalty
                           alignment-type
                           score-only-p
                           gap-symbol)
  "Compute an alignment of sequences SEQ1 and SEQ2.

SIMILARITY-FN should be a function. It is called with two
arguments: One element from SEQ1 and one from SEQ2 and it should
return a number determining how similar the elements are, where
higher values mean `more similar'.  The default returns 1 if the
elements are equal, else -1.

GAP-PENALTY is the penalty for one single gap in the alignment,
the default is -1.

ALIGNMENT-TYPE may be one of the symbols `prefix', `suffix',
`infix' or nil.  If it is `prefix' \(resp. `suffix'\), trailing
\(resp. preceding\) elements in SEQ2 may be ignored; `infix' is
the combination of both.  The default is nil, which means to
match the whole sequence.

Return a cons \(SCORE . ALINGMENT\), unless SCORE-ONLY-P is
non-nil, in which case only SCORE is returned.  SCORE says how
similar the sequences are and ALINGMENT is a list of \(E1 . E2\),
where E1 is an element from SEQ1 or GAP-SYMBOL, likewise for E2.
If one of them is the GAP-SYMBOL, it means there is a gap at this
position in the respective sequence in the alignment."

  ;; See https://en.wikipedia.org/wiki/Needleman-Wunsch_algorithm
  (seq--with-matrix-macros
    (let* ((len1 (length seq1))
           (len2 (length seq2))
           (score (make-matrix (1+ len1) (1+ len2)))
           (prefix-p (memq alignment-type '(prefix infix)))
           (suffix-p (memq alignment-type '(suffix infix))))

      (unless similarity-fn (setq similarity-fn
                                  (lambda (a b)
                                    (if (equal a b) 1 -1))))
      (unless gap-penalty (setq gap-penalty -1))

      (cl-loop for i from 0 to len1 do
        (mset score i 0 (* i gap-penalty)))
      (cl-loop for j from 0 to len2 do
        (mset score 0 j (if suffix-p 0 (* j gap-penalty))))

      (cl-loop for i from 1 to len1 do
        (cl-loop for j from 1 to len2 do
          (let ((max (max
                      (+ (mref score (1- i) j) -1)
                      (+ (mref score i (1- j))
                         (if (and prefix-p (= i len1))
                             0 gap-penalty))
                      (+ (mref score (1- i) (1- j))
                         (funcall similarity-fn
                                  (elt seq1 (1- i))
                                  (elt seq2 (1- j)))))))
            (mset score i j max))))

      (if score-only-p
          (mref score len1 len2)
        (let ((i len1)
              (j len2)
              alignment)
          (while (or (> i 0)
                     (> j 0))
            (cond
             ((and (> i 0)
                   (= (mref score i j)
                      (+ (mref score (1- i) j) gap-penalty)))
              (cl-decf i)
              (push (cons (elt seq1 i) gap-symbol) alignment))
             ((and (> j 0)
                   (= (mref score i j)
                      (+ (mref score i (1- j))
                         (if (or (and (= i 0) suffix-p)
                                 (and (= i len1) prefix-p))
                             0
                           gap-penalty))))
              (cl-decf j)
              (push (cons gap-symbol (elt seq2 j)) alignment))
             (t
              (cl-assert (and (> i 0) (> j 0)) t)
              (cl-decf i)
              (cl-decf j)
              (push (cons (elt seq1 i)
                          (elt seq2 j)) alignment))))
          (cons (mref score len1 len2) alignment))))))

(defun seq-edit-distance (seq1 seq2 &optional
                               max-distance
                               allow-transposition
                               score-only-p
                               gap-symbol)
  "Compute the Levenshtein distance of sequence SEQ1 and SEQ2

MAX-DISTANCE should be the maximal expected distance, i.e. if the
real distance is greater than this value, this function returns
nil.  Lower values result in better performance. If MAX-DISTANCE
is nil, the proper distance is always returned.

Also recognize the transposition of elements as one atomic
operation, if ALLOW-TRANSPOSITION is non-nil.

See `seq-alignment' for the return value of this function and the
SCORE-ONLY-P and GAP-SYMBOL argument."

  ;; See `Algorithms for Approximate String Matching', E. Ukkonen

  (seq--with-matrix-macros
   (let* ((len1 (length seq1))
          (len2 (length seq2))
          (infinity (+ 1 len2 len1))
          (p1 1)
          (p2 (+ len1 len2))
          (k (or max-distance infinity)))

     (unless (> (abs (- len2 len1)) k)
       (let* ((dist (make-matrix (1+ len1) (1+ len2) infinity))
              (p (ceiling (/ (- k (abs (- len2 len1))) 2.0)))
              (j 0)
              i i-end (ok-p t))

         (while (and ok-p (<= p1 p2) (<= j len2))
           (setq ok-p nil)
           (if (>= len1 len2)
               (setq i (max 0 (1- p1) (- j p))
                     i-end (min len1 (+ j (- len1 len2) p)))
             (setq i (max 0 (1- p1) (- (+ j (- len1 len2)) p))
                   i-end (min len1 (+ j p))))
           (while (<=  i i-end)
             (cond
              ((= i 0)
               (mset dist i j j))
              ((= j 0)
               (mset dist i j i))
              (t
               (mset dist i j
                     (min
                      (1+ (mref dist (1- i) j))
                      (1+ (mref dist i (1- j)))
                      (+ (mref dist (1- i) (1- j))
                         (if (equal
                              (elt seq1 (1- i))
                              (elt seq2 (1- j)))
                             0 1))
                      (or (and allow-transposition
                               (> i 1)
                               (> j 1)
                               (= (elt seq1 (- i 2))
                                  (elt seq2 (- j 1)))
                               (= (elt seq1 (- i 1))
                                  (elt seq2 (- j 2)))
                               (1+ (mref dist (- i 2) (- j 2))))
                          infinity)))))
             (if (<= (mref dist i j) k)
                 (if (not ok-p)
                     (setq ok-p t
                           p1 i)
                   (if (= i i-end)
                       (setq p2 i)))
               (if (not ok-p)
                   (setq p1 (1+ i))
                 (setq p2 (1- i))))
             (setq i (1+ i)))
           (setq j (1+ j)))

         (when (<= (mref dist len1 len2) k)
           (if score-only-p
               (mref dist len1 len2)
             (let ((i len1)
                   (j len2)
                   mapping)
               (while (or (> i 0)
                          (> j 0))
                 (cond
                  ((and (> i 0)
                        (= (mref dist i j)
                           (1+ (mref dist (1- i) j))))
                   (cl-decf i)
                   (push (cons (elt seq1 i) gap-symbol) mapping))
                  ((and (> j 0)
                        (= (mref dist i j)
                           (1+ (mref dist i (1- j)))))
                   (cl-decf j)
                   (push (cons gap-symbol (elt seq2 j)) mapping))
                  (t
                   (cl-assert (and (> i 0) (> j 0)) t)
                   (cl-decf i)
                   (cl-decf j)
                   (push (cons (elt seq1 i)
                               (elt seq2 j)) mapping))))
               (cons (mref dist len1 len2) mapping)))))))))

(defun seq--drop-list (list n)
  "Return a list from LIST without its first N elements.
This is an optimization for lists in `seq-drop'."
  (while (and list (> n 0))
    (setq list (cdr list)
          n (1- n)))
  list)

(defun seq--take-list (list n)
  "Return a list from LIST made of its first N elements.
This is an optimization for lists in `seq-take'."
  (let ((result '()))
    (while (and list (> n 0))
      (setq n (1- n))
      (push (pop list) result))
    (nreverse result)))

(defun seq--drop-while-list (pred list)
  "Return a list from the first element for which (PRED element) is nil in LIST.
This is an optimization for lists in `seq-drop-while'."
  (while (and list (funcall pred (car list)))
    (setq list (cdr list)))
  list)

(defun seq--take-while-list (pred list)
  "Return the successive elements for which (PRED element) is non-nil in LIST.
This is an optimization for lists in `seq-take-while'."
  (let ((result '()))
    (while (and list (funcall pred (car list)))
      (push (pop list) result))
    (nreverse result)))

(defun seq--count-successive (pred seq)
  "Return the number of successive elements for which (PRED element) is non-nil in SEQ."
  (let ((n 0)
        (len (seq-length seq)))
    (while (and (< n len)
                (funcall pred (seq-elt seq n)))
      (setq n (+ 1 n)))
    n))

(defun seq--make-pcase-bindings (args)
  "Return a list of bindings of the variables in ARGS to the elements of a sequence."
  (let ((bindings '())
        (index 0)
        (rest-marker nil))
    (seq-doseq (name args)
      (unless rest-marker
        (pcase name
          (`&rest
           (progn (push `(app (pcase--flip seq-drop ,index)
                              ,(seq--elt-safe args (1+ index)))
                        bindings)
                  (setq rest-marker t)))
          (t
           (push `(app (pcase--flip seq--elt-safe ,index) ,name) bindings))))
      (setq index (1+ index)))
    bindings))

(defun seq--make-pcase-patterns (args)
  "Return a list of `(seq ...)' pcase patterns from the argument list ARGS."
  (cons 'seq
        (seq-map (lambda (elt)
                   (if (seq-p elt)
                       (seq--make-pcase-patterns elt)
                     elt))
                 args)))

;; Helper function for the Backward-compatible version of `seq-let'
;; for Emacs<25.1.
(defun seq--make-bindings (args seq &optional bindings)
  "Return a list of bindings of the variables in ARGS to the elements of a sequence.
if BINDINGS is non-nil, append new bindings to it, and return
BINDINGS."
  (let ((index 0)
        (rest-marker nil))
    (seq-doseq (name args)
      (unless rest-marker
        (pcase name
          ((pred seq-p)
           (setq bindings (seq--make-bindings (seq--elt-safe args index)
                                              `(seq--elt-safe ,seq ,index)
                                              bindings)))
          (`&rest
           (progn (push `(,(seq--elt-safe args (1+ index))
                          (seq-drop ,seq ,index))
                        bindings)
                  (setq rest-marker t)))
          (t
           (push `(,name (seq--elt-safe ,seq ,index)) bindings))))
      (setq index (1+ index)))
    bindings))

(defun seq--elt-safe (seq n)
  "Return element of SEQ at the index N.
If no element is found, return nil."
  (when (or (listp seq)
            (and (sequencep seq)
                 (> (seq-length seq) n)))
    (seq-elt seq n)))

(defun seq--activate-font-lock-keywords ()
  "Activate font-lock keywords for some symbols defined in seq."
  (font-lock-add-keywords 'emacs-lisp-mode
                          '("\\<seq-doseq\\>" "\\<seq-let\\>")))

(defalias 'seq-copy #'copy-sequence)
(defalias 'seq-elt #'elt)
(defalias 'seq-length #'length)
(defalias 'seq-do #'mapc)
(defalias 'seq-each #'seq-do)
(defalias 'seq-map #'mapcar)
(defalias 'seq-p #'sequencep)

(unless (fboundp 'elisp--font-lock-flush-elisp-buffers)
  ;; In Emacs≥25, (via elisp--font-lock-flush-elisp-buffers and a few others)
  ;; we automatically highlight macros.
  (add-to-list 'emacs-lisp-mode-hook #'seq--activate-font-lock-keywords))

(provide 'seq)
;;; seq.el ends here
