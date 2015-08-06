usage() {
    cat <<EOF
Usage: poud uses <depends glob> [<pattern:USES>] | -h

Using INDEX look for any ports Makefile that depends on
<depends glob> and then filter to lines with by default USES.
Useful to find examples of how to do things. Assuming you trust
the found ports.
EOF
    exit 1
}

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

str=$1
pattern=${2:-USE}

. ${POUD_SCRIPTDIR}/_util.sh

(cd $PORTSDIR ; _poud_ip deps $str M | xargs grep $pattern)
