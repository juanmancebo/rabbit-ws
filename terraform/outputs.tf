# Outputs file
output "URL" {
  value = "http://${aws_eip.rabbitws.public_dns}:8080"
}
