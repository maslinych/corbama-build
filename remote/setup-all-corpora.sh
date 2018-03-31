#!/bin/sh
cat built/*.setup.txt | \
    awk '{for (i=2;i<=NF;i++) {corp[$1]=corp[$1]" "$i}}END{for (c in corp) {print c, corp[c]}}' | \
    xargs setup-bonito.sh
