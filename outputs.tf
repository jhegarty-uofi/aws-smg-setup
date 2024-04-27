
output "secret" {
  value     = aws_iam_access_key.smgu.secret
  sensitive = true
}
