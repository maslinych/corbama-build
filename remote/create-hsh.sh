hasher_chroot="$1"
shift
port="$1"
shift

hsh --initroot "$hasher_chroot"
hsh-install "$hasher_chroot" manatee-open bonito2-open apache2-base
cp setup-corpus-environment.sh "$hasher_chroot/chroot/.in/"
share_ipc=yes share_network=yes hsh-run --mount=/proc --rooter "$hasher_chroot" -- sh setup-corpus-environment.sh "$port"

