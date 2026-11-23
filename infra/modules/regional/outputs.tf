output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "elb_public_ip" {
  description = "Public IP (EIP) of the internet-facing application load balancer"
  value       = huaweicloud_vpc_eip.elb.address
}
