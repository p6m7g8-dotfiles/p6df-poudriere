#!/bin/sh

# XXX: depends on aws cli
# XXX: could use curl and json

. ${POUD_LIBDIR}/globals.sh
. ${POUD_LIBDIR}/util.sh

poud_aws_run_on_demand () {
  local aws_ami_id=$1
  local aws_security_group_id=$2
  local build=$3

  _poud_msg "$build: Making OnDemand Request....."
  local iid=$(aws ec2 run-instances \
                --image-id $aws_ami_id \
                --count 1 \
                --instance-type "c3.4xlarge" \
                --security-group-ids $aws_security_group_id \
                --subnet-id $aws_default_subnet_id \
                --associate-public-ip-address | \
                 awk -F: '/InstanceId/ { gsub(/[", ]/, "", $2); print $2}'
        )

  sleep 3

  _poud_msg "$build: Tagging Instance"
  aws ec2 create-tags --resource $iid --tags "Key=Name,Value=ond.pbuilder.$build"

  _poud_msg "$build: Setting root EBS to delete on terminate....."
  local json="[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
  aws ec2 modify-instance-attribute --instance-id $iid --block-device-mappings "$json" 2>/dev/null

  echo $iid
}

##/ _poud_aws_find_cheapest
##  side_effects:
##/   aws_cheapest_zone
##/   aws_cheapest_type
_poud_aws_find_cheapest () {
  local build=$1

  _poud_msg  "$build: Looking for cheapest option....."

  local rolling_cheapest_price=""
  local rolling_cheapest_zone=""
  local rolling_cheapest_type=""

  for type in $aws_instance_types; do
    local cheapest_zone=""
    local cheapest_price=""

    for az in $aws_azs; do
      local price=$(aws ec2 describe-spot-price-history \
                        --max-items 1 \
                        --availability-zone us-east-$az \
                        --instance-types $type | \
                         awk -F: '/SpotPrice"/ { print $2 }' | \
                         sed -e 's/[", ]//g'
            )
      # XXX: Floating point math
#      _poud_msg "$build: $type -> $az = $price"
      local rc=$(echo $price $cheapest_price | awk '{ printf "%d", ($1 <= $2) }')
      if [ $rc -eq 1 -o "$cheapest_price" = "" ]; then
         cheapest_zone=$az
         cheapest_price=$price
       fi
    done
#    _poud_msg "$build: Cheapest:($type) in $cheapest_zone @ \$$cheapest_price\n"

    local rc=$(echo $cheapest_price $rolling_cheapest_price | awk '{ printf "%d", ($1 <= $2) }')
    if [ $rc -eq 1 -o "$rolling_cheapest_price" = "" ]; then
      rolling_cheapest_zone=$cheapest_zone
      rolling_cheapest_price=$cheapest_price
      rolling_cheapest_type=$type
    fi
  done

  _poud_msg "$build: Found:($rolling_cheapest_type) in $rolling_cheapest_zone @ \$$rolling_cheapest_price\n"

  aws_cheapest_zone=$rolling_cheapest_zone
  aws_cheapest_type=$rolling_cheapest_type
}

_poud_aws_zone_to_subnet () {
  local zone=$1

  case $zone in
    1a) subnet_id=$aws_subnet_1a_id ;;
    1b) subnet_id=$aws_subnet_1b_id ;;
    1c) subnet_id=$aws_subnet_1c_id ;;
    1e) subnet_id=$aws_subnet_1e_id ;;
  esac

  echo $subnet_id
}

poud_aws_request_spot_instances () {
  local aws_ami_id=$1
  local aws_spot_bid=$2
  local aws_security_group_id=$3
  local build=$4

  local aws_cheapest_zone
  local aws_cheapest_type
  _poud_aws_find_cheapest $build

  local aws_subnet_id=$(_poud_aws_zone_to_subnet $aws_cheapest_zone)

  _poud_msg "$build: Requesting Spot Instance....."
  local json="{\"ImageId\":\"$aws_ami_id\",\"InstanceType\":\"$aws_cheapest_type\",\"NetworkInterfaces\":[{\"Groups\":[\"$aws_security_group_id\"],\"DeviceIndex\":0,\"SubnetId\":\"$aws_subnet_id\",\"AssociatePublicIpAddress\":true}]}"
  local sir=$(aws ec2 request-spot-instances \
                  --spot-price "$aws_spot_bid" \
                  --instance-count 1 \
                  --type "one-time" \
                  --launch-specification "$json" | \
                   awk -F: '/SpotInstanceRequestId/ { gsub(/[", ]/, "", $2); print $2}'
        )

  _poud_msg "$build: Tagging Spot Request"
  aws ec2 create-tags --resources $sir --tags "Key=Name,Value=sir.pbuilder.$build"

  echo $sir
}

poud_aws_spot_fulfilled () {
  local sir=$1
  local build=$2

  _poud_msg "$build: Waiting for fulfillment....."

  local prev_code=
  local code=
  while [ x"$code" != x"fulfilled" ]; do
    local code=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids $sir | awk -F: '/Code/ { gsub(/[", ]/, "", $2); print $2}')
    if [ x"$prev_code" != x"$code" ]; then
      prev_code=$code
      _poud_msg "$build: -> $code"
    fi
    sleep 5
  done

  local iid=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids $sir | awk -F: '/InstanceId/ { gsub(/[", ]/, "", $2); print $2}')
  local json="[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
  aws ec2 modify-instance-attribute --instance-id $iid --block-device-mappings "$json"

  _poud_msg "$build: Tagging Spot Instance"
  aws ec2 create-tags --resources $iid --tags "Key=Name,Value=sir.pbuilder.$build"

  echo $iid
}

poud_aws_get_priv_ip () {
  local iid=$1
  local build=$2

  local ip=$(aws ec2 describe-instances --instance-ids $iid | awk -F: '/PrivateIpAddress/ && /10/ { gsub(/[", ]/, "", $2); print $2}' | head -1)
  _poud_msg "$build: Instance has private ip: $ip"

  echo $ip
}

poud_aws_wait_for_ssh () {
  local ip=$1
  local build=$2

  _poud_msg "$build: Waiting for ssh....."
  local avail=n
  while [ "$avail" != "y" ]; do
    ssh -N -o ConnectTimeOut=2 -o BatchMode=yes $ip 'echo' >/dev/null 2>&1
    case $? in
      0) avail=y ;;
      *) avail=n ;;
    esac
    sleep 5
  done
}

poud_aws_terminate_instances () {
  local iid=$1

  aws ec2 terminate-instances --instance-ids $iid
}

poud_aws_cancel_spot_instance_requests () {
  local sir=$1

  aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $sir
}
