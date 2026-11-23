variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  type        = list(string)
  description = "Availability zones for the VPC"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs"
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "single_nat_gateway" {
  type        = bool
  description = "Provision a single shared NAT gateway across all private networks"
  default     = false
}

variable "vpc_enable_nat_gateway" {
  type        = bool
  description = "Enable NAT gateway for the VPC (default OFF: this template needs no public NAT)"
  default     = false
}

variable "vpc_tags" {
  type        = map(string)
  description = "Tags applied to VPC resources"
}

variable "vpc_public_subnet_tags" {
  type        = map(string)
  description = "Extra tags for public subnets"
  default     = {}
}

variable "vpc_private_subnet_tags" {
  type        = map(string)
  description = "Extra tags for private subnets"
  default     = {}
}

variable "nat_spec" {
  type        = string
  description = "NAT gateway spec (1=small .. 4=xlarge)"
  default     = "1"
}
