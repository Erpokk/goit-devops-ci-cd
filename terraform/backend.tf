# Note: Backend configuration cannot use variables directly.
# Replace S3_BUCKET_NAME and AWS_REGION with your values, or use partial configuration via -backend-config flags
terraform {
  backend "s3" {
    # bucket = "${S3_BUCKET_NAME}"
    bucket         = "your-project-name-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
