# Available AZs in the target region
data "huaweicloud_availability_zones" "all" {}

locals {
  # Take the first `number_of_azs` AZs.
  availability_zones = slice(sort(data.huaweicloud_availability_zones.all.names), 0, var.number_of_azs)
}

# Global resources (account-level): IAM agency
# NOTE: The IAM agency (ECS-trusted) is intentionally NOT managed by Terraform
# here. The huaweicloud provider v1.96.1 maps `delegated_service_name` to a
# domain lookup, so an ECS-trusted agency cannot be created via this provider.
# Create it manually in the console (IAM > 委托 > 创建委托, trusted service
# "ECS", permissions "readonly"). The core infra below is unaffected.
#
# module "global" {
#   source = "./modules/global"
#   env    = var.env
# }

# Regional resources: VPC + internet-facing application load balancer
module "regional" {
  source = "./modules/regional"

  env                  = var.env
  number_of_azs        = var.number_of_azs
  name_prefix          = var.name_prefix
  account              = var.account
  availability_zones   = local.availability_zones
  elb_l7_flavor_name   = var.elb_l7_flavor_name
  nat_spec             = var.nat_spec
}
