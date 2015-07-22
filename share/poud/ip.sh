usage() {
    cat <<EOF
Usage: poud ip field regex [modifier] | -h

Match field against regex according to INDEX and optionally append information according to
modifier.

Field:
    name      
    dir       
    prefix    
    comment   
    desc      
    maintainer
    categories
    build     
    run       
    www       
    extract  
    patch     
    fetch

Special Field:
    deps 
    will match against build,run,extract,patch,fetch depends 

Modifier:
  None - port_directory
  M    - port_directory/Makefile
  P    - port_directory/pkg-plist
  D    - port_directory/pkg-descr
    
EOF
    exit 1
}

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

field=$1
regex=$2
modifier=$3

. ${POUD_LIBDIR}/util.sh

_poud_ip $field $regex $modifier
