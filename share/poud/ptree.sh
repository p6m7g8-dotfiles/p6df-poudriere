usage() {
    cat <<EOF
Usage: poud ptree -h | -i | -m

Options:
    -h    -- this help message
    -i    -- initialize ptree with git-svn
    -m    -- clone ptrees for use
EOF
    exit 1
}

# Stolen from: https://wiki.freebsd.org/GitWorkflow/GitSvn
# XXX: change svn to repo, but its broken
# XXX: e-mailed developpers@ on 2015/07/17
# XXX: Message-ID: <CACM2dAZ+b+ahgEcDma-8Va8HukTy6dZ+R7Te=TZg_7dfZSTp_w@mail.gmail.com>
poud_ptrees_init() {

  local git_repo=git@github.com:$USER/freebsd-ports.git
  local git_svn_uri=svn.freebsd.org/ports
  local svn_proto=svn+ssh

  local zdir=$ZPOOL$poudriere_ports_tree_dir
  local fsdir=${zdir##$ZPOOL}

  sudo zfs destroy -fr $zdir
  sudo zfs create -p $zdir
  sudo zfs set mountpoint=$fsdir $zdir

  sudo chown $USER:$USER $fsdir
  git clone $git_repo $fsdir

  (
    cd $fsdir
    git svn init -T head $svn_proto://$git_svn_uri .

    git config oh-my-zsh hide-dirty 1
    git config --add remote.origin.fetch '+refs/pull/*:refs/remotes/origin/pull/*'

    git update-ref refs/remotes/origin/trunk `git show-ref origin/svn_head | cut -d" " -f1`
    git svn fetch

    git checkout trunk
    git branch -D master
    git checkout -b master trunk

    git svn rebase
    git remote add upstream git@github.com:freebsd/freebsd-ports.git
    git branch --set-upstream-to=origin/master master
  )

  exit 0
}

_poud_ptree_make () {
  local tree=$1
  local from=${2:-clean}

  sha=$(git log -1 | awk '/commit/ { print $2 }')
  rev=$(git svn find-rev $sha)
  snapshot="poud_${rev}_${sha}"

  sudo zfs snapshot $ZPOOL$poudriere_ports_tree_dir/$from@$snapshot
  sudo $poudriere -e $poudriere_conf_dir_local ports -c -F -p $tree
  sudo zfs clone  $ZPOOL$poudriere_ports_tree_dir/$from@$snapshot $ZPOOL$poudriere_ports_tree_dir/$tree
}

poud_ptrees () {

  local tree
  for tree in $ports_trees; do
    _poud_ptree_make $tree
  done

  exit 0
}

. ${POUD_SCRIPTDIR}/_globals.sh

while getopts "him" FLAG; do
  case "${FLAG}" in
    i) poud_ptrees_init ;;
    m) poud_ptrees_make ;;
    *|h) usage ;;
  esac
done

usage
