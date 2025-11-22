variable "name" {
  description = "Name of the RDS instance or cluster"
  type        = string
}

variable "engine" {
  description = "Database engine type for standard RDS (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
}

variable "engine_cluster" {
  description = "Database engine type for Aurora cluster (aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "aurora_replica_count" {
  description = "Number of Aurora reader replica instances"
  type        = number
  default     = 1
}

variable "aurora_instance_count" {
  description = "Total number of Aurora instances (1 writer + replicas)"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Engine version for standard RDS instance"
  type        = string
  default     = "14.7"
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro, db.t3.small, db.r5.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (only for standard RDS)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "subnet_private_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "List of public subnet IDs for DB subnet group"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment (only for standard RDS)"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "Map of database parameters to apply"
  type        = map(string)
  default     = {}
}

variable "use_aurora" {
  description = "Use Aurora cluster (true) or standard RDS instance (false)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to RDS resources"
  type        = map(string)
  default     = {}
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family for Aurora cluster"
  type        = string
  default     = "aurora-postgresql15"
}

variable "engine_version_cluster" {
  description = "Engine version for Aurora cluster"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family for standard RDS"
  type        = string
  default     = "postgres15"
}
