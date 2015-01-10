# sequences

## Summary

Seq.el provides Sequence manipulation functions that complement basic
functions provided by `subr.el`.  The library is included in Emacs 25.

All functions are prefixed with `seq-`.

All provided functions work on lists, strings and vectors.

Functions taking a predicate or a function iterating over the sequence
as argument take the function as their first argument and the sequence
as their second argument.  All other functions take the sequence as
their first argument.

All functions are tested in `test/seq-tests.el`

# Contributing

Fetch dependencies:

    $ cd /path/to/seq.el
    $ cask

Run the tests:

    $ ./run-tests.sh

[COPYING]: ./COPYING
