if [ -n "$1" ]; then
  ${ME} $1 -h
else
  cat <<EOF
all      - build for all jails
bname    - set build
build    - build /test stuff
go.sh    - move to a port
help     - display this message
index    - perform INDEX operations
ip       - look through INDEX
jails    - peform jail operations
nuke     - violently remove packages, logs, cache
pdir     - set portstree dir
pkgs     - install recommend pkgs
ptree    - perform portstree operations
repos    - initialize/clone portstrees
uses     - look for use patterns
version  - display software version
zfs      - setup zfs
EOF
fi
