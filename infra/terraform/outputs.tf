output "server_url" {
  description = "Put this in the Android app (Settings > Server URL)"
  value       = "https://${local.hostname}"
}

output "public_ip" {
  value = aws_eip.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}

output "ssm_prefix" {
  description = "Parameter Store path holding all secrets (<prefix>/secret/*) and config (<prefix>/env/*)"
  value       = local.ssm_prefix
}

output "get_api_token" {
  description = "Read the app's API token from Parameter Store (needs AWS credentials with ssm:GetParameter on the prefix)"
  value       = "aws ssm get-parameter --region ${var.region} --name ${local.ssm_prefix}/secret/JOBHUB_API_TOKEN --with-decryption --query Parameter.Value --output text"
}

output "shell_access" {
  description = "Shell on the instance without SSH"
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.this.id}"
}

output "reacher_public_ip" {
  description = "Elastic IP of the Reacher EC2 instance (submit this IP to AWS for Port 25 unblocking)"
  value       = var.enable_reacher && length(aws_eip.reacher) > 0 ? aws_eip.reacher[0].public_ip : null
}

output "reacher_internal_url" {
  description = "Private VPC URL used by JobHub to query Reacher"
  value       = var.enable_reacher && length(aws_instance.reacher) > 0 ? "http://${aws_instance.reacher[0].private_ip}:3000" : null
}
