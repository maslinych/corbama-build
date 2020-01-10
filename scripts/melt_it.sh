#!/bin/sh
dos2unix | \
    sed \
    -e '1s/^\uFEFF//' \
    -e 's/^<s[^>]\+>/<s>/' \
    -e 's/\(.\)</\1\n</g' \
    -e 's/^\(<[^> ]\+>\)\(.\+\)/\1\n\2/g' \
    -e '/^\s*\r\?$/d' | \
    MElt -t | \
    sed -e 's/>\/NC/>/g' -e 's, /[A-Z+-],,g'| \
    MElt_lemmatiser.pl -l fr -nfu | \
    MElt_finalise.pl | \
    sed 's, \?\([^/ ]\+\)/\([^/ ]\+\)/\([^/ ]\+\),\1\t\2\t\3\n,g' | \
    grep .
