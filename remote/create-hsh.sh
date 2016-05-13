hasher_chroot="$1"
shift
port="$1"
shift
if [ "$hasher_chroot" == "testing" ]
then other_chroot="production"
else echo "Unexpected directory: $hasher_chroot"; exit 1
fi

chroot_user="$(stat -c %U $other_chroot/chroot/var/)"

if [ "$chroot_user" == "corpora_a1" ] 
then number_opt="--number=1"
else number_opt=""
fi

if test -z "$number_opt"
then hsh --initroot --pkg-build-list="basesystem" --no-cache "$hasher_chroot" ; \
    hsh-install "$hasher_chroot" manatee-open bonito2-open apache2-base iproute2
else hsh "$number_opt" --initroot --pkg-build-list="basesystem" --no-cache "$hasher_chroot" ; \
    hsh-install "$number_opt" "$hasher_chroot" manatee-open bonito2-open apache2-base iproute2
fi

cp setup-corpus-environment.sh "$hasher_chroot/chroot/.in/"
cp setup-bonito.sh "$hasher_chroot/chroot/.in/"

if test -z "$number_opt"
then share_ipc=yes share_network=yes hsh-run --mount=/proc --rooter "$hasher_chroot" -- sh setup-corpus-environment.sh "$port"
else share_ipc=yes share_network=yes hsh-run "$number_opt" --mount=/proc --rooter "$hasher_chroot" -- sh setup-corpus-environment.sh "$port"
fi
