output "role_arn" {
  value       = aws_iam_role.this.arn
  description = "Annotate the service account with this: eks.amazonaws.com/role-arn."
}

output "role_name" {
  value = aws_iam_role.this.name
}
