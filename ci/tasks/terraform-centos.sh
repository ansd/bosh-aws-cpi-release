#!/usr/bin/env bash

set -e -x

source bosh-cpi-release/ci/tasks/utils.sh

check_param aws_access_key_id
check_param aws_secret_access_key
check_param concourse_ip

semver=`cat terraform-state-version/number`

# generates a plan
/terraform/terraform plan -out=centos-bats.tfplan \
  -var "access_key=${aws_access_key_id}" \
  -var "secret_key=${aws_secret_access_key}" \
  -var "build_id=bats-centos-${semver}" \
  -var "concourse_ip=${concourse_ip}" \
  bosh-concourse-ci/pipelines/bosh-aws-cpi

state-file=centos-bats-${semver}.tfstate
exports-file=terraform-centos-exports-${semver}.sh

# applies the plan, generates a state file
/terraform/terraform apply -state=$state-file centos-bats.tfplan

# exports values into an exports file
echo -e "#!/usr/bin/env bash" >> $exports-file
echo -e "export CENTOS_DIRECTOR=$(/terraform/terraform output -state=${state-file} director_vip)" >> $exports-file
echo -e "export CENTOS_VIP=$(/terraform/terraform output -state=${state-file} bats_vip)" >> $exports-file
echo -e "export CENTOS_SUBNET_ID=$(/terraform/terraform output -state=${state-file} subnet_id)" >> $exports-file
echo -e "export CENTOS_SECURITY_GROUP_NAME=$(/terraform/terraform output -state=${state-file} security_group_name)" >> $exports-file
echo -e "export CENTOS_AVAILABILITY_ZONE=$(/terraform/terraform output -state=${state-file} availability_zone)" >> $exports-file
