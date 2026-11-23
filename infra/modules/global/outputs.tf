output "agency_name" {
  description = "Name of the IAM agency"
  value       = huaweicloud_iam_agency.this.name
}

output "agency_id" {
  description = "ID of the IAM agency"
  value       = huaweicloud_iam_agency.this.id
}
