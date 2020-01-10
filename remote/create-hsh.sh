hasher_chroot="testing"
port="8098"
other_chroot="production"

mkdir -p "$hasher_chroot"

chroot_user="$(stat -c %U $other_chroot/chroot/var/)"

if [ "$chroot_user" == "corpora_a1" ] 
then number_opt="--number=0"
else number_opt="--number=1"
fi

hsh "$number_opt" --initroot --pkg-build-list="basesystem" --no-cache "$hasher_chroot" ; \
hsh-install "$number_opt" "$hasher_chroot" manatee-open bonito2-open apache2-base iproute2

cp bin/setup-corpus-environment.sh "$hasher_chroot/chroot/.in/"
cp bin/setup-bonito.sh "$hasher_chroot/chroot/.in/"

if test -z "$number_opt"
then share_network=yes hsh-run --mount=/proc --rooter "$hasher_chroot" -- sh setup-corpus-environment.sh "$port"
else share_network=yes hsh-run "$number_opt" --mount=/proc --rooter "$hasher_chroot" -- sh setup-corpus-environment.sh "$port"
fi
