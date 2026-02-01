output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions (add to GitHub secrets as AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}
