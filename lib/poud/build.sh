# See lib/poud/aws.sh for aws implimentations
usage() {
    cat <<EOF
Usage: poud build [options]

typically:
   poud build -c

Options:
    -P    -- with ports tree to use (testport|bulk -p foo), defaults to \$PORTSDIR[$PORTSDIR]
    -a    -- build all ports (bulk -a)
    -b    -- which build to use (testport|bulk -j foo), defaults to \$POUD_BUILD[$POUD_BUILD]
    -c    -- build any port with changes in \$PORTSDIR[$PORTSDIR]
    -d    -- build any port which depends on <shell glob> according to INDEX
    -h    -- this message
    -p    -- build this port (if not used, will build the port who's directroy you are in for \$POUD_BUILD[$POUD_BUILD] in \$PORTSDIR[$PORTSDIR])
    -r    -- build any port who's port_directory matches <shell glob> according to INDEX
    -t    -- use testport instead of bulk  (sanity checks are always run regardless of options)
    -z    -- which option set to use (equivalent to -z in testport|bulk), default is default

AWS Options:
    -A    -- launch an AWS AMI with this id (generic freebsd ones will not work)
    -B    -- bid this amount for a spot instance (default $aws_spot_bid), do not include sigil.
    -G    -- what AWS security group to assign to the Instance
    -K    -- keep spot and/or ondemand running when done or after error
    -W    -- where to build (local|spot|ondemand), default: local, -a=spot, -c|-d|-p|-r|-t=local by default
EOF
    exit 1
}

_poud_build_spin_down () {
  local f_k=$1
  local f_t=$2
  local where=$3
  local sir=$4
  local iid=$5
  local build=$6

  if [ $f_k -eq 0 -a $f_t -eq 0 ]; then
    _poud_msg "$build: Spinning down....."
    case $where in
      spot) poud_aws_cancel_spot_instance_requests $sir ;;
    esac
    case $where in
      spot|ondemand) poud_aws_terminate_instances $iid ;;
    esac
  fi
}

_poud_build_exec_mount () {
  local ip=$1
  local build=$2
  local ports_tree=$3

  ssh $ip "sudo mkdir -p $poudriere_ports_tree_dir/$ports_tree"
  ssh $ip "sudo mkdir -p $poudriere_jails_dir/$build"
  ssh $ip "sudo mkdir -p $repos_dir"
  ssh $ip "sudo mkdir -p $poudriere_data_dir/.m"
  ssh $ip "sudo mkdir -p $poudriere_data_dir/cache"
  ssh $ip "sudo mkdir -p $poudriere_data_dir/logs"
  ssh $ip "sudo mkdir -p $poudriere_data_dir/packages"
  ssh $ip "sudo mkdir -p $poudriere_data_dir/wrkdirs"
  ssh $ip "sudo mkdir -p $poudriere_distfiles_dir"

  local mount_opts="-t nfs -o rw,intr,noatime,async"

  ssh $ip "sudo mount $mount_opts fs:$poudriere_ports_tree_dir/$ports_tree $poudriere_ports_tree_dir/$ports_tree"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_jails_dir/$build $poudriere_jails_dir/$build"

  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir          $poudriere_data_dir"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir/.m       $poudriere_data_dir/.m"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir/cache    $poudriere_data_dir/cache"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir/logs     $poudriere_data_dir/logs"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir/packages $poudriere_data_dir/packages"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_data_dir/wrkdirs  $poudriere_data_dir/wrkdirs"
  ssh $ip "sudo mount $mount_opts fs:$poudriere_distfiles_dir     $poudriere_distfiles_dir"

  ssh $ip "sudo mount $mount_opts fs:$repos_dir $repos_dir"
}

_poud_build_exec () {
  local f_t=$1
  local f_a=$2
  local build=$3
  local port=$4
  local where=$5
  local ports_file=$6
  local ip=$7
  local ports_tree=$8
  local optset=$9

  local dt=$(date "+%Y%m%d_%H%M")
  local B=$dt

  if [ $f_t -eq 1 ]; then
    sudo $poudriere -e $poudriere_conf_dir_local testport -j $build -o $port -p $ports_tree -i -s -z $optset
  else
    local what
    if [ $f_a -eq 1 ]; then
      what="-a"
    else
      what="-f $ports_file"
    fi

    local cmd="sudo $poudriere -e $poudriere_conf_dir_remote bulk -t -j $build -B $B -C $what -p $ports_tree -z $optset"
    case $where in
      local) eval "$cmd" ;;
      spot|ondemand)
        _poud_build_exec_mount $ip $build $ports_tree
        if [ $f_a -eq 0 ]; then
          scp -q $ports_file $ip:$ports_file
        fi
        ssh $ip "$cmd"
    esac
  fi
}

##/ _poud_build_spin_up()
##/ side effects:
##/   sir
##/   iid
##/   ip
_poud_build_spin_up () {
  local aws_ami_id=$1
  local aws_instance_type=$2
  local aws_security_group_id=$3
  local where=$4
  local buiild=$5

  case $where in
    spot)
      sir=$(poud_aws_request_spot_instances $aws_ami_id $aws_spot_bid $aws_security_group_id $build)
      iid=$(poud_aws_spot_fulfilled $sir $build)
      ip=$(poud_aws_get_priv_ip $iid $build)
      poud_aws_wait_for_ssh $ip $build
      ;;
    ondemand)
      iid=$(poud_aws_run_on_demand $aws_ami_id $aws_security_group_id $build)
      ip=$(poud_aws_get_priv_ip $iid $build)
      poud_aws_wait_for_ssh $ip $build
      ;;
  esac
}

_poud_build_what () {
  local f_a=$1
  local f_c=$2
  local depends_on=$3
  local dir=$4
  local port=$5
  local ports_file=$6
  local build=$7

  _poud_msg "$build: What to build....."

  local ports
  if [ $f_a -eq 1 ]; then
    ports=""
  elif [ $f_c -eq 1 ]; then
    ports="$(_poud_new_or_modified_ports)"
  elif [ x"$depends_on" != x"" ]; then
    ports="$(_poud_ip deps $depends_on)"
  elif [ x"$dir" != x"" ]; then
    ports="$(_poud_ip dir $dir)"
  elif [ x"$port" != x"" ]; then
    ports=$port
  else
    exit 1
  fi

  if [ x"$ports" != x"" ]; then
    echo "$ports" > $ports_file
  fi
}

. ${POUD_LIBDIR}/aws.sh

poud_build () {
  local f_a=0
  local build=$POUD_BUILD
  local f_c=0
  local depends_on=""
  local f_k=0
  local port=""
  local dir=""
  local f_t=0
  local where=local
  local ports_tree=$POUD_PTREE
  local optset=default

  ## parse options
  while getopts A:B:G:KP:W:ab:cd:hp:r:tz: FLAG; do
    case ${FLAG} in
      A) aws_ami_id=$OPTARG            ;;
      B) aws_spot_bid=$OPTARG          ;;
      K) f_k=1                         ;;
      G) aws_security_group_id=$OPTARG ;;
      W) where=$OPTARG                 ;;

      P) ports_tree=$OPTARG            ;;
      a) f_a=1                         ;;
      b) build=$OPTARG                 ;;
      c) f_c=1                         ;;
      d) depends_on=$OPTARG            ;;
      p) port=$OPTARG                  ;;
      r) dir=$OPTARG                   ;;
      t) f_t=1                         ;;
      z) optset=$OPTARG                ;;
      *|h) usage                       ;;
    esac
  done
  shift $(($OPTIND-1))

  ## validate args
  [ $f_t -eq 1 ] && where=local
  [ $f_a -eq 1 ] && where=spot

  if [ -z "$ports_tree" -o -z "$build" ]; then
      _poud_msg "must set ports_tree and build"
      usage
  fi

  ## what to build
  local ports_file="$tmp/fbsd-poudriere-$build-$(date "+%Y%m%d_%H%M")"
  _poud_build_what $f_a $f_c "$depends_on" "$dir" "$port" $ports_file "$build-$ports_tree"

  ## spin up
  _poud_build_spin_up $aws_ami_id $aws_spot_bid $aws_security_group_id $where "$build-$ports_tree"

  ## do it
  _poud_build_exec $f_t $f_a $build "$port" $where $ports_file "$ip" $ports_tree $optset

  ## spin down
  _poud_build_spin_down $f_k $f_t $where "$sir" $iid "$build-$ports_tree"
}
