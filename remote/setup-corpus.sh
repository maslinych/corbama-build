#!/bin/sh
environment="testing"
site="$1"
shift
corplist="$@"
cp bin/setup-bonito.sh "$environment"/chroot/.in/
hsh-run --rooter "$environment" -- "setup-bonito.sh $corpname $corplist"
