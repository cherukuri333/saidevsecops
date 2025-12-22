# ECR Repository
# -------------------------
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.ecr_repo_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.ecr_repo_name}-${var.environment}"
    Environment = var.environment
    Project     = "saidevsecops"
  }
}

# -------------------------
# IAM Role
# -------------------------
resource "aws_iam_role" "ecr_role" {
  name = "${var.iam_role_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# -------------------------
# IAM Policy (FULL ECR ACCESS)
# -------------------------
resource "aws_iam_policy" "ecr_policy" {
  name        = "ecr-full-access-${var.environment}"
  description = "Full access to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      }
    ]
  })
}

# -------------------------
# Attach Policy to Role
# -------------------------
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
