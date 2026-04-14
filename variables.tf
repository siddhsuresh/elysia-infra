variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "elysia"
}

variable "suffix" {
  type        = string
  description = "Short suffix appended to globally-unique resource names (ECR, IAM, ALB, log group, ECS cluster) to avoid collisions across deploys. Use something like 'dev', 'prod', or your initials."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for HTTPS. Leave empty for HTTP only."
}
