output "s3_logs_user_key" {
  value = aws_iam_access_key.s3_logs.id
}

output "s3_logs_user_secret" {
  value = aws_iam_access_key.s3_logs.secret
  sensitive = true
}