cmds=$(ls -1 ${POUD_SCRIPTDIR} | sed -e 's,.sh, ,g' -e 's,|$,,')

echo $cmds
