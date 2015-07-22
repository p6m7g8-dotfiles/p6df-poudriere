usage() {
    cat <<EOF
Usage: poud zfs -f | -h

Options:
    -f    -- force run if its already been run
    -h    -- this message
    -z    -- pre-existing zpool to work with

Initialize ZPOOL with ZFS containers for use with poudriere-plugins.
Also sets up zfs sharenfs.
EOF
    exit 1
}

. ${POUD_LIBDIR}/globals.sh
. ${POUD_LIBDIR}/util.sh

flag_f=0
ZPOOL=
while getopts "fhz:" FLAG; do
  case "${FLAG}" in
    f) flag_f=1      ;;
    h) usage         ;;
    z) ZPOOL=$OPTARG ;;
  esac
done

if [ -z $ZPOOL ]; then
    _poud_msg "must set specificy -z ZPOOL"
    exit 1
fi

atime=$(zfs get -H atime $ZPOOL | awk '{print $3}')
if [ "$atime" = "off" -a $flag_f -eq 0 ]; then
    _poud_msg "Already run, -f to force."
    exit 1
fi

sudo zfs set mountpoint=none $ZPOOL
sudo zfs set atime=off $ZPOOL
sudo zfs set checksum=fletcher4 $ZPOOL

sudo zfs create -p -o mountpoint=$prefix/etc/nginx $ZPOOL$prefix/etc/nginx
sudo zfs create -p -o mountpoint=$repos_dir $ZPOOL$repos_dir
sudo zfs create -p -o mountpoint=$poudriere_dir $ZPOOL$poudriere_dir
sudo zfs create -p -o mountpoint=$poudriere_distfiles_dir $ZPOOL$poudriere_distfiles_dir

sudo touch /etc/exports
sudo zfs sharenfs="-maproot=root -network $nfs_cidr" $ZPOOL
