. ${POUD_LIBDIR}/build.sh

for tag in $build_tags; do
  build=$(echo $tag | sed -e 's,-.*,,' -e 's,\.,,g')
  for arch in $arches; do
    poud_build -W spot -b $build$arch $* &
  done
done
