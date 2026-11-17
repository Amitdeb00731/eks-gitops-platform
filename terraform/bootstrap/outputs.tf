output "state_bucket_name" {
  value       = aws_s3_bucket.state.id
  description = "Pass this to each environment with terraform init -backend-config."
}

output "state_kms_key_arn" {
  value       = aws_kms_key.state.arn
  description = "The key that encrypts state."
}
