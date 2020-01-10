#!/bin/sh
environment="testing"
site="$1"
shift
corplist="$@"
cp bin/setup-bonito.sh "$environment"/chroot/.in/
hsh-run --rooter "$environment" -- sh -x setup-bonito.sh $site $corplist
