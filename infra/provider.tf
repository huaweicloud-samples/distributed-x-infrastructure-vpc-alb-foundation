terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
  }

  required_version = ">= 1.3.0"

  # State backend: OBS.
  # The OBS backend needs a bucket that already exists. If you do not have one
  # yet, comment out this block to fall back to local state.
  # backend "obs" {
  #   bucket   = "my-tf-state-bucket"
  #   key      = "distributed-x-infrastructure-vpc-alb-foundation/terraform.tfstate"
  #   endpoint = "obs.cn-north-4.myhuaweicloud.com"
  # }
}

# Credentials are injected from the environment (never hardcode secrets):
#   export HW_ACCESS_KEY=<HW_ACCESS_KEY>
#   export HW_SECRET_KEY=<HW_SECRET_KEY>
#   export HW_REGION_NAME=cn-north-4   # optional; provider.region below also sets it
provider "huaweicloud" {
  region = var.region
}
