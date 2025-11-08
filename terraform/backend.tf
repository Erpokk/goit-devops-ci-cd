terraform {
  backend "s3" {
    bucket         = "terraform-lesson5-bucket-max-ad"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
