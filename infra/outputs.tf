output "region" {
  description = "Region Terraform is operating in"
  value       = var.region
}

output "env" {
  description = "Environment name"
  value       = var.env
}

output "account" {
  description = "Target domain/project id"
  value       = var.account
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.regional.vpc_id
}

output "elb_public_ip" {
  description = "Public IP of the internet-facing application load balancer"
  value       = module.regional.elb_public_ip
}
