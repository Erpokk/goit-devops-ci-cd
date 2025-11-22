variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "django-app"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "github_username" {
  description = "GitHub username for repository access"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch name"
  type        = string
  default     = "main"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "jenkins_admin_username" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

