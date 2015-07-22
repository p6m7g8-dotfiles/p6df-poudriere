usage() {
    cat <<EOF
Usage: poud go <port glob> | -h

Will look through INDEX to find the 1st matching 
port_directory entry and cd to that ports dir.
EOF
    exit 1
}

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

port=$1

. ${POUD_LIBDIR}/util.sh

dir=$(_poud_ip dir $port | head -1)
cd $PORTSDIR/$dir
