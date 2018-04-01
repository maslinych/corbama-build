#!/bin/sh
environment="testing"
cp -v bin/setup-bonito.sh "$environment"/chroot/.in/
cat built/*.setup.txt | \
    awk '{for (i=2;i<=NF;i++) {corp[$1]=corp[$1]" "$i}}END{for (c in corp) {print c, corp[c]}}' | \
    xargs -t -L 1 hsh-run --root "$environment" -- sh setup-bonito.sh 
