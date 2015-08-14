_poud_msg () {
  local msg=$1

  local ts=$(date "+%Y/%m/%d_%H:%M:%S")

  echo -e >&2 "[$ts]: $msg"
}

_poud_append_file () {
  local dir=$1
  local modifier=$2

  local out
  case $modifier in
    M) out=$(echo $dir | sed -e 's,/usr/ports/,,' -e 's,$,/Makefile,') ;;
    P) out=$(echo $dir | sed -e 's,/usr/ports/,,' -e 's,$,/pkg-plist,') ;;
    D) out=$(echo $dir | sed -e 's,/usr/ports/,,' -e 's,$,/pkg-descr,') ;;
    *) out=$(echo $dir | sed -e 's,/usr/ports/,,') ;;
  esac

  echo $out
}

_poud_from_dir_or_arg () {
  local port=$1

  if [ -z $port ]; then
    port=$(echo `pwd` | sed -e "s,$PORTSDIR/,,")
  fi

  echo $port
}

_poud_pkg_to_port () {
  local pkg=$1
  local modifier=$2

  local out=$(awk -F\| "\$1 ~ /$pkg/ { print \$2 }" $PORTSDIR/INDEX-11 | sed -e "s,/usr/ports/,,")

  if [ -n $out ]; then
    _poud_append_file $out $modifier
  fi
}

_poud_new_or_modified_ports () {

  local mports="$(cd $PORTSDIR ; git status | grep : | awk -F: '/\// { print $2 }' | cut -d / -f 1,2 | sed -e 's, ,,g' | sort -u | grep -v Mk/)"
  local nports="$(cd $PORTSDIR ; git status | grep "/$" | sed -e 's, ,,g' -e 's,/$,,' -e 's,^ *,,' -e 's, *$,,' | grep -v Mk/)"

  echo "$mports $nports"
}

_poud_ip () {
  local field=$1
  local regex=$2
  local modifier=$3

  local index_file=$PORTSDIR/INDEX-11
  if [ ! -r $index_file ]; then
      exit 1
  fi

  case $field in
    name)        pos=1;;
    dir)         pos=2;;
    prefix)      pos=3;;
    comment)     pos=4;;
    desc)        pos=5;;
    maintainer)  pos=6;;
    categories)  pos=7;;
    build)       pos=8;;
    run)         pos=9;;
    www)         pos=10;;
    extract)     pos=11;;
    patch)       pos=12;;
    fetch)       pos=13;;
    deps)        pos=0;;
    *)           pos=-1;;
  esac

  if [ $pos -lt 0 ]; then
      exit 1
  fi

  local regex=$(echo $regex | sed -e 's,/,\\/,g')

  local out
  local col=2
  case $modifier in
    m) col=6 ;;
  esac

  if [ $field = "deps" ]; then
      out=$(awk -F'|' "\$8 ~ /$regex/ || \$9 ~ /$regex/ || \$11 ~ /$regex/ || \$12 ~ /$regex/ || \$13 ~ /$regex/ { print \$$col }" $index_file)
  else
      out=$(awk -F'|' "\$$pos ~ /$regex/ { print \$$col }" $index_file)
  fi

  if [ -n "$out" ]; then
      for dir in $out; do
        _poud_append_file $dir $modifier
      done
  fi
}
