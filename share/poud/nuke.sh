usage () {

    cat <<EOF
Usage: poud nuke [-h]

Will wipe out all content but not ZFS containetrs in \$poudriere_data_dir[$poudriere_data_dir]

Options:
    -h    -- this help message
EOF
    exit 1
}

. ${POUD_LIBDIR}/globals.sh

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

# XXX: relies on ZFS to be lazy
sudo rm -rf $poudriere_data_dir
