output "ec2_public_ip" {
  description = "Elastic Public IP address of the EC2 instance"
  value       = aws_eip.server.public_ip
}

output "api_url_http" {
  description = "FastAPI endpoint via HTTP reverse proxy"
  value       = "http://${aws_eip.server.public_ip}"
}

output "api_url_direct_port" {
  description = "FastAPI endpoint via direct port 8000"
  value       = "http://${aws_eip.server.public_ip}:8000"
}

output "api_docs_url" {
  description = "FastAPI Swagger documentation"
  value       = "http://${aws_eip.server.public_ip}/docs"
}

output "ssh_command" {
  description = "SSH connection string"
  value       = "ssh ubuntu@${aws_eip.server.public_ip}"
}
