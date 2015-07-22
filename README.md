# Description:
Utilities and wrappers for FreeBSD's poudriere. 

Note, this is meant for developers and committers, though
its possible a non techie might be able to use it.

You do not need to have already installed poudriere.

# Installation:
```sh
cd ~
git clone git@github.com:pgollucci/poudriere-plugins.git
zpool create $name ...... 

cd poudriere-plugins
su -
 bin/poud pkgs
exit

bin/poud zfs -z $name

# optional (all tunable variables are in lib/poud/globals.sh)
vim lib/poud/globals.sh

bin/poud repos
cd $poud_repo_dir

# if you changed lib/poud/globals.sh
cp ~/poudriere-plugins/poud/lib/globals.sh $poud_repo_dir/lib/poud/globals.sh

rm -rf ~/poudriere-plugins
```

# Initialize
```sh
# fork freebsd/freebsd-ports on github into your GitHub
# it is assumed your github USER is your $USER

# optional but highly suggested add $poud_repo_dir/bin to your $PATH

## build jails for $build_tags & $arches
poud jails -c

## initialize a git-svn ports tree in $poudriere_ports_dir/clean
poud ptree -i

## make ports tree clones for $ports_trees based on the clean one
poud ptree -m 
```

# Configure
```sh
# optional: add to your shell init
pdir () {
  eval `poud pdir $1`
}

pbuild () {
  eval `poud bname $1`
}

alias ip="poud ip"
alias cdpdir='cd $PORTSDIR'
```

# Test
```sh
ptree prs
pbuild 110amd64
poud build -t -p devel/ccache
```

# Sub-commands
All sub-commands support -h.  Read it and them.

# Nginx Support
```sh
echo nginx_enable="YES" >> /etc/rc.conf
sudo service nginx start
curl http://hostname.com
```

# AWS Support
- Sign up for AWS
- Create a VPC (any option as long as you do it right)
  i.e. 10.0.0.0/16

- Create 4 subnets
   - 10.0.0.0/24
   - 10.0.1.0/24
   - 10.0.2.0/24
   - 10.0.3.0/24
 
- Create Security Groups
   - nfs
   - http
   - internal icmp
   - ssh

- Edit lib/poud/globals.sh
  overwrite the values for the aws variables with yours from above.
    
- Launch an fbsd -current instance into any one of these subnets.  I suggest a spot r3.4xlarge.
  Assign this ALL of the above security groups.  This is your NFS host.  Follow the Install, Initialize, Configure
  Steps above on this host.  I suggest making an AMI when you're done.  Note, you should use an EBS(s) for the zpool
  since any data on the spot is forfeit if it goes away.

- Add to /etc/rc.conf
```sh
rpcbind_enable="YES"
nfs_reserved_port_only="YES"
nfs_server_enable="YES"
mountd_enable="YES"
rpc_lockd_enable="YES"
rpc_statd_enable="YES"
```

- Reboot

- Non Local builds
  both Spot and OnDemand instances can now perform builds for you.  You must use a pre-configured AMI as the clients.
  I publish this one which is public: ami-XXXXXXXX, and is the default.

  It must be an NFS client and run sshd. It should allow $USER to login via ssh and run sudo without a password.

  You should re-order the AZs in the lib/poud/global.sh to have the AZ where your NFS server is 1st or you will pay
  AZ transfer costs for the NFS traffic.

  Note, should use EFS when its not in PREVIEW.

  You should change the instance_types in lib/poud/global.sh based on what you're willing to pay for.
  I have my reasons you have yours, but note, I did not pick these and this order lightly.

- Try it
```sh
poud build -w spot|ondemand -p devel/m4
```

It should kill the spot request and instance automatically when done.  But double check or you will pay for them.
You can view your builds using the NFS server on http://hostname.com via the previously setup nginx.

- Bulk (ALL)
```sh
poud build -a
```

This will take 30-70 hours depending on distfile fetching, instance type, az zone choice.
It  will default to spot.
