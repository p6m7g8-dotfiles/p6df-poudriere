usage () {

    cat << EOF
Usage: poud repos [-h]

Clone relevant repos into the right places

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

sudo mkdir -p $repos_freebsd_dir $repos_pgollucci_dir
sudo chown -R $USER:$USER $repos_freebsd_dir $repos_pgollucci_dir

(
  cd $repos_freebsd_dir
  git clone git@github.com:freebsd/poudriere.git
  git clone git@github.com:freebsd/pkg.git
)
(
  cd $repos_pgollucci_dir
  git clone git@github.com:pgollucci/poudriere-plugins.git
)
(
  cd $poudriere_repo_dir
  ./autogen
  ./configure
  make
)

cp $poud_etc_dir/poudriere.conf $poudriere_conf

