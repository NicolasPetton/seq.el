# seq.el [![Build Status](https://secure.travis-ci.org/NicolasPetton/seq.el.png)](http://travis-ci.org/NicolasPetton/seq.el)

## Summary

seq.el provides Sequence manipulation functions that complement basic
functions provided by `subr.el`.  The library is included in Emacs 25.

All functions are prefixed with `seq-`.

All provided functions work on lists, strings and vectors.

Functions taking a predicate or iterating over a sequence using a
function as argument take the function as their first argument and the
sequence as their second argument.  All other functions take the
sequence as their first argument.

All functions are tested in `test/seq-tests.el`

*Note*: The version 2 of seq.el is maintained in the Emacs git
repository, please consider sending patches there.

## Functions

seq.el provides the following functions:

- `seq-drop` seq n

  This function returns a sequence of all but the first `n`
  elements of the sequence `seq`.

  `seq` may be a list, vector or string and `n` must be an
  integer.  The result is the same type of sequence as `seq`.

  If `n` is a negative integer or zero, `seq` is returned.

- `seq-take` seq n

  This function returns a sequence of the first `n` elements of
  `seq`.

  `seq` may be a list, vector or string and `n` must be an
  integer.  The result is the same type of sequence as `seq`.

  If `n` is a negative integer or zero, an empty sequence is
  returned.

- `seq-take-while` pred seq

  This function returns a sub-sequence of the successive elements of
  `seq` for which calling `pred` with that element returns
  non-nil.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.  The result is the same type of sequence as
  `seq`.

  If evaluating `pred` with the first element of `seq` as argument
  returns `nil`, an empty sequence is returned.

- `seq-drop-while` pred seq

  This function returns a sub-sequence of `seq` from the first
  element for which calling `pred` with that element returns
  `nil`.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.  The result is the same type of sequence as
  `seq`.

  If evaluating `pred` with every element of `seq` returns
  `nil`, `seq` is returned.

- `seq-filter` pred seq

  This function returns a list of all the elements in `seq` for
  which calling `pred` with that element returns non-nil.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-map` function seq

  This function returns the result of applying `function` to each
  element of `seq`.  The returned value is a list.

  `function` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-remove` pred seq
  This function returns a list of all the elements in `seq` for
  which calling `pred` with that element returns `nil`.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-reduce` function seq initial-value
  This function returns the result of calling `function` with
  `initial-value` and the first element of `seq`, then calling
  `function` with that result and the second element of `seq`,
  then with that result and the third element of `seq`, etc.

  `function` must be a two-arguments function and `seq` may be a
  list, vector or string.

  If `seq` is empty, `initial-value` is returned and
  `function` is not called.

- `seq-some` pred seq
  This function returns non-nil if calling `pred` with any element of
  `seq` returns non-nil. If so, the returned value is the value
  returned by `seq`.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-find` pred seq &optional default
  This function returns the first element for which `pred` returns
  non-nil in `seq`.  If no element matches `pref`, `default` is
  returned.

  Note that this function has an ambiguity if the found element is
  identical to `default`, as it cannot be known if an element was
  found or not.

- `seq-every-p` pred seq
  This function returns non-nil if successively calling `pred` with
  each element of `seq` always returns non-nil, `nil` otherwise.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-empty-p` seq
  This function returns non-nil if the sequence `seq` is empty,
  `nil` otherwise.

  `seq` may be a list, vector or string.

- `seq-count` pred seq
  This function returns the number of elements in `seq` for which
  calling `pred` with that element returns non-nil.

  `pred` must be a one-argument function and `seq` may be a
  list, vector or string.

- `seq-sort` pred seq
  This function returns a sorted sequence of the elements of
  `seq`, comparing its elements with `pred`.  Called with two
  elements of `seq`, `pred` should return non-nil if the first
  element should sort before the second.

  `pred` must be a two-arguments function, `seq` may be a list,
  vector or string.

  The result is a sequence of the same type as SEQ.

- `seq-contains` seq elt testfn
  This function returns the first element in `seq` that equals to
  `elt`.

  Equality is defined by `testfn` if non-nil or by `equal` if
  `nil`.

  `seq` may be a list, vector or string.

- `seq-position` seq elt testfn
  This function returns the index of the first element in `seq` that is equal to
  `elt`.  Equality is defined by `testfn` if non-nil or by `equal` if nil."

  `seq` may be a list, vector or string.

- `seq-uniq` seq testfn
  This function returns a list of the elements of `seq` with
  duplicates removed.  `testfn` is used to compare elements, or
  `equal` if `testfn` is `nil`.

  `testfn` must be a two-argument function or `nil` and
  `seq` may be a list, vector or string.

- `seq-subseq` seq start &optional end
  This function returns a sub-sequence of `seq` from `start`
  to `end`.  If `end` is omitted, it default to the length of
  `seq`. If `start` or `end` is negative, it counts from
  the end of `seq`.

  `seq` may be a list, vector or string.
  The result is the same type of sequence as `seq`.

- `seq-concatenate` type &rest seqs
  This function returns a sequence made of the concatenation of
  `seqs`.  The result is a sequence of type `type`.  `type`
  may be one of the following symbols: `vector`, `list` or
  `string`.

- `seq-mapcat` function sequence &optional type
   This function returns the result of applying `seq-concatenate` to
   the result of applying `function` to each element of `sequence`.  The
   result is a sequence of type `type`, or a list if `type` is nil.

-  `seq-partition` sequence n
   This function returns a list of the elements of `sequence` grouped
   into sub-sequences of length `n`.  The last sequence may contain less
   elements than `n`.  `n` must be an integer.  If `n` is a negative integer
   or 0, nil is returned.

- `seq-group-by` function sequence
   This function separates the elements of `sequence` into an alist
   whose keys are the result of applying `function` to each element of
   `sequence`.  Keys are compared using `equal`.

- `seq-intersection` seq1 seq2 &optional testfn
   Return a list of the elements that appear in both `seq1` and `seq2`.
   Equality is defined by TESTFN if non-nil or by `equal` if nil.

- `seq-difference` seq1 seq2 &optional testfn
   Return a list of the elements that appear in both `seq1` but not in `seq2`.
   Equality is defined by TESTFN if non-nil or by `equal` if nil.

- `seq-doseq` (var seq [result]) body...
  This macro is like `dolist`, except that `seq` can be a list,
  vector or string.

  `seq-doseq` is primarily useful for side-effects.

- `seq-let` args &rest body
  Bind the variables in ARGS to the elements of SEQ then evaluate BODY.
  ARGS can also include the `&rest' marker followed by a variable
  name to be bound to the rest of SEQ.

## Contributing

Since this library is in Emacs 25, contributors must have signed the
Emacs Copyright assignment.

Fetch dependencies:

    $ cd /path/to/seq.el
    $ cask

Run the tests:

    $ ./run-tests.sh

[COPYING]: ./COPYING
