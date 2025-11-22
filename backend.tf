# Note: Backend configuration cannot use variables directly.
# Replace PROJECT_NAME and ENVIRONMENT with your values, or use partial configuration via -backend-config flags
terraform {
  backend "s3" {
    # bucket = "${PROJECT_NAME}-${ENVIRONMENT}-terraform-state"
    bucket         = "your-project-name-your-environment-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
