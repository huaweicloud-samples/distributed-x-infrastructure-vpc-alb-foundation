#!/bin/bash
# Destroys REGIONAL resources only: VPC + ELB + security group (+ EIP/IGW/subnets).
# Two-step teardown to avoid the ELB listener 409 conflict:
#   step 1 breaks the listener->pool binding first,
#   step 2 destroys the rest (LB delete cascades to remaining pool).
# Usage:
#   ./run-tf-regional-destroy.sh -e <env> -r <region>
#   e.g. ./run-tf-regional-destroy.sh -e dev -r cn-north-4
set -euo pipefail

ENV="dev"
REGION="cn-north-4"

while getopts ":e:r:" o; do
  case "${o}" in
    e) ENV=${OPTARG} ;;
    r) REGION=${OPTARG} ;;
    *) echo "Usage: $0 -e <env> -r <region>"; exit 1 ;;
  esac
done

export HW_REGION_NAME="$REGION"
terraform init -reconfigure

# Step 1: break the listener->pool binding (avoids ELB.8907 / conflict)
terraform destroy -auto-approve -var="env=${ENV}" \
  -target=huaweicloud_elb_pool.ext_lb \
  -target=huaweicloud_elb_listener.ext_lb || true

# Step 2: destroy everything else in the regional module
terraform destroy -auto-approve -var="env=${ENV}" -target=module.regional
