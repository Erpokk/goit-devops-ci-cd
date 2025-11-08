output "s3_bucket_name" {
  description = "S3 bucket for Terraform state storage"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}