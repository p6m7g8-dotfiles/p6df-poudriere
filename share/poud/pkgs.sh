usage () {

    cat << EOF
Usage: poud pkg [-h]

YOU MUST RUN THIS FROM A ROOT SHELL not through sudo.

Options:
    -h    -- this message
EOF
    exit 1
}

. ${POUD_LIBDIR}/util.sh

while getopts h FLAG; do
    case ${FLAG} in
        h) usage ;;
    esac
done
shift $(($OPTIND-1))

if [ `id -u` != 0 ]; then
    _poud_msg "need to be root"
    exit 1
fi
if [ -n "${SUDO_USER}" ]; then
    _poud_msg "do not run this through sudo"
    exit 1
fi

pkg delete -af -y
env ASSUME_ALWAYS_YES=YES pkg bootstrap
pkg install -y \
    automake awscli bash-static dialog4ports emacs-nox11 git-subversion \
    hub libtool nginx php5-arcanist portlint python34 ruby21-gems rsync \
    sudo swaks tmux vim-lite zsh
