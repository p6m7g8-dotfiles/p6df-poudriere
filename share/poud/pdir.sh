usage() {
    cat <<EOF
Usage: poud pdir <tree> | -h

Will output commands similiar to ssh-agent or gpg-agent to be eval `` in
your current shell.  This will default this shell to this ports tree by setting PORTSDIR.
Thus saving typing.
EOF
    exit 1
}

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done

tree=$1

. ${POUD_SCRIPTDIR}/_globals.sh

if [ -n "$tree" ]; then
    echo PORTSDIR=$poudriere_ports_tree_dir/$tree
    echo POUD_PTREE=$tree
    echo export PORTSDIR
    echo export POUD_PTREE
fi
