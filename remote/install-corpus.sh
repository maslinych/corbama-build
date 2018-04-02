#!/bin/bash
environment="testing"
corpus="$1"
shift
corptar="built/$corpus.tar.xz"
rm -f "$environment/chroot/.in/${corptar##built/}"
ln "$corptar" "$environment"/chroot/.in/
corpnames="$(cat ${corptar%%.tar.xz}.setup.txt | cut -d' ' -f2-)"
for corpus in $corpnames
do
    hsh-run --rooter "$environment" -- rm -rf "/var/lib/manatee/{data,registry,vert}/$corpus"
done
hsh-run --rooter "$environment" -- tar --no-same-permissions --no-same-owner -xJvf "${corptar##built/}" --directory /var/lib/manatee
for corpus in $corpnames
do
    hsh-run --rooter "$environment" -- /bin/sh -c "export MANATEE_REGISTRY=/var/lib/manatee/registry && mksizes $(corpus)"
done
