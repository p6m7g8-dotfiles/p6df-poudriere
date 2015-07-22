usage() {
    cat <<EOF
Usage: poud index -f | -l | -h

Options:
    -f    -- fetch the INDEX in $PORTSDIR
    -h    -- this help message
    -l    -- make a local INDEX in $PORTSDIR
EOF
    exit 1
}

_poud_fetch_index () {
  (cd $PORTSDIR ; make fetchindex)
}

_poud_make_index () {

  local now=$(date +%Y%m%d_%H%M%S)

  (
    cd $PORTSDIR
    time ARCH= __MAKE_CONF=/dev/null INDEX_PRISTINE=1 INDEX_QUIET=1 make index > $tmp/make_index-${now}
    cat $tmp/make_index-${now}
  )
}

. ${POUD_LIBDIR}/globals.sh

if [ -z "${PORTSDIR}" ]; then
  echo "must call poud ptree <tree> 1st"
  exit 0
fi

while getopts h FLAG; do
    case ${FLAG} in
        f) _poud_fetch_index ;;
        h) usage             ;;
        l) _poud_make_index  ;;
    esac
done
shift $(($OPTIND-1))
