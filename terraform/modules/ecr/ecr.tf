resource "aws_ecr_repository" "ecr" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository_policy" "full_access" {
  repository = aws_ecr_repository.ecr.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAccountFullAccess"
        Effect   = "Allow"
        Action   = "ecr:*"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}
