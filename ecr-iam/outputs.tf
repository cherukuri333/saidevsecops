output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.ecr.name
}

output "ecr_repository_url" {
  description = "URI of the ECR repository"
  value       = aws_ecr_repository.ecr.repository_url
}

output "iam_role_name" {
  description = "IAM role name created for ECR access"
  value       = aws_iam_role.ecr_role.name
}

output "iam_role_arn" {
  description = "IAM role ARN created for ECR access"
  value       = aws_iam_role.ecr_role.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN attached to the role"
  value       = aws_iam_policy.ecr_policy.arn
}
