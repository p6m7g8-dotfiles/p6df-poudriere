usage() {
    cat <<EOF
Usage: poud bname <build_name> | -h

Will output commands similiar to ssh-agent or gpg-agent to be eval `` in 
your current shell.  This will default this shell to this build.
Thus saving typing.
EOF
    exit 1
}

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

build=$1

if [ -n "$build" ]; then
    echo POUD_BUILD=$build
    echo export POUD_BUILD
fi
