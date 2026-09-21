variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment (dev or prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to provision"
  type        = number
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "deployment_tier" {
  description = "The deployment tier (e.g., testing or production)"
  type        = string
}
