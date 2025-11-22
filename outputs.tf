output "s3_bucket_name" {
  description = "S3 bucket name for state storage"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = module.s3_backend.dynamodb_table_name
}


output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.ecr_name
}


output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}


output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

output "eks_endpoint" {
  value = data.aws_eks_cluster.eks.endpoint
}

output "eks_ca" {
  value = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
}

