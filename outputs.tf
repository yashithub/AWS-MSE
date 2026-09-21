output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.web[*].id
}

output "public_ips" {
  description = "Public IPs of the created EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "public_dns" {
  description = "Public DNS names of the created EC2 instances"
  value       = aws_instance.web[*].public_dns
}

output "environment_info" {
  description = "Current active environment details"
  value = {
    workspace       = terraform.workspace
    environment     = var.environment
    instance_count  = var.instance_count
    deployment_tier = var.deployment_tier
  }
}

output "vpc_subnets" {
  description = "List of subnets available in the default VPC"
  value       = data.aws_subnets.default.ids
}
