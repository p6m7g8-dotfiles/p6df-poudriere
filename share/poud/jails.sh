usage() {
  cat <<EOF
Usage: poud jails -c|-d|-h|-u

Otions:
    -c    -- create jails
    -d    -- delete jails
    -h    -- this help message
    -u    -- update jails
EOF
  exit 1
}

poud_jails_create() {

  for tag in $build_tags; do
    local build=$(echo $tag | sed -e 's,-.*,,' -e 's,\.,,g')
    for arch in $arches; do
      sudo $poudriere -e $poudriere_conf_dir_local jail -c -j $build$arch -v $tag -a $arch
    done
  done

  exit 0
}

poud_jails_delete () {

  for tag in $build_tags; do
    local build=$(echo $tag | sed -e 's,-.*,,' -e 's,\.,,g')
    for arch in $arches; do
      sudo $poudriere -e $poudriere_conf_dir_local jail -d -j $build$arch
    done
  done

  exit 0
}

poud_jails_update () {

  for tag in $build_tags; do
    local build=$(echo $tag | sed -e 's,-.*,,' -e 's,\.,,g')
    if echo $tag | grep -q CURRENT; then
      for arch in $arches; do
        sudo $poudriere -e $poudriere_conf_dir_local jail -d -j $build$arch
        sudo $poudriere -e $poudriere_conf_dir_local jail -c -j $build$arch
      done
    else
      for arch in $arches; do
        sudo $poudriere -e $poudriere_conf_dir_local jail -u -j $build$arch
      done
    fi
  done

  exit 0
}

. ${POUD_SCRIPTDIR}/_globals.sh
. ${POUD_SCRIPTDIR}/_util.sh

while getopts "cdhu" FLAG; do
  case "${FLAG}" in
    c) poud_jails_create ;;
    d) poud_jails_delete ;;
    u) poud_jails_update ;;
    *|h) usage ;;
  esac
done
