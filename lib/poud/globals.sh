# XXX: could read this section from poudriere.conf
ZPOOL=zfs
# XXX: end

prefix=/usr/local

repos_dir=/repos
repos_freebsd_dir=$repos_dir/freebsd
repos_pgollucci_dir=$repos_dir/pgollucci

poud_repo_dir=$repos_pgollucci_dir/poudriere-plugins
poud_etc_dir=$poud_repo_dir/etc

poudriere_repo_dir=$repos_freebsd_dir/poudriere

poudriere_conf_dir_local=$poud_etc_dir/conf-local
poudriere_conf_dir_remote=$poud_etc_dir/conf-remote

poudriere_dir=$prefix/poudriere
poudriere_distfiles_dir=$prefix/poudriere/distfiles
poudriere_data_dir=$poudriere_dir/data
poudriere_ports_tree_dir=$poudriere_dir/ports
poudriere_jails_dir=$poudriere_dir/jails

poudriere=$poudriere_repo_dir/src/bin/poudriere

arches="i386 amd64"
build_tags="9.3-RELEASE 10.1-RELEASE 11.0-CURRENT"
ports_trees="default apache lua mysql perl pgsql prs python ruby"

nfs_cidr="10.0.0.0/22"

tmp=/tmp

aws_ami_id=ami-df8c52b4
aws_spot_bid=2.00
aws_security_group_id=sg-76ff1811

aws_default_subnet_id="subnet-614f3b38"
aws_azs="1a 1b 1e 1c" # XXX: order matters based on where the nfs box is
aws_instance_types="r3.8xlarge c3.8xlarge c4.8xlarge m4.10xlarge i2.8xlarge d2.8xlarge" # XXX: order matters for code in case of ties

aws_subnet_1a_id=subnet-875032ac
aws_subnet_1b_id=subnet-5baf882c
aws_subnet_1c_id=subnet-614f3b38
aws_subnet_1e_id=subnet-02dedc38
