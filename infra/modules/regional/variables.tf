variable "env" {
  type = string
}

variable "number_of_azs" {
  type = number
}

variable "name_prefix" {
  type = string
}

variable "account" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "elb_l7_flavor_name" {
  type = string
}

variable "nat_spec" {
  type = string
}
