variable "region" {
  type        = string
  description = "Target Huawei Cloud region, e.g. cn-north-4"
  default     = "cn-north-4"
}

variable "account" {
  type        = string
  description = "Target Huawei Cloud domain/project id (placeholder, used for tagging only)"
  default     = "555555555555"
}

variable "env" {
  type        = string
  description = "Environment name (dev/qa/staging/prod)"
}

variable "number_of_azs" {
  type        = number
  description = "Number of AZs to spread resources across"
  default     = 2
}

variable "name_prefix" {
  type        = string
  description = "Name prefix applied to created resources"
  default     = "demo"
}

# --- Specs are explicit: no data.xxx.ids[N] lookups ---
variable "elb_l7_flavor_name" {
  type        = string
  description = "L7 (application) ELB flavor name. Confirm per region via 'data.huaweicloud_elb_flavors' (type=L7)."
  default     = "L7_flavor.elb.s1.small"
}

variable "nat_spec" {
  type        = string
  description = "NAT gateway spec: 1=small .. 4=xlarge. Fixed for predictable sizing."
  default     = "1"
}
