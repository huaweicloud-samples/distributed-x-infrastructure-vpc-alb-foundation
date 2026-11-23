output "vpc_id" {
  description = "ID of the VPC"
  value       = huaweicloud_vpc.this.id
}

output "public_subnet_ids" {
  description = "VPC-layer IDs of the public subnets"
  value       = huaweicloud_vpc_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "VPC-layer IDs of the private subnets"
  value       = huaweicloud_vpc_subnet.private[*].id
}

# Neutron-level subnet IDs (required by ELB member / LB ipv4_subnet_id)
output "public_subnet_ipv4_ids" {
  description = "Neutron (ipv4_subnet_id) IDs of the public subnets"
  value       = huaweicloud_vpc_subnet.public[*].ipv4_subnet_id
}

output "private_subnet_ipv4_ids" {
  description = "Neutron (ipv4_subnet_id) IDs of the private subnets"
  value       = huaweicloud_vpc_subnet.private[*].ipv4_subnet_id
}
