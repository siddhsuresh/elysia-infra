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

# "rolling": one ECS service, one target group, listener forwards to it (current behavior).
# "bluegreen": adds a second (green) service + target group + a port-8080 test listener
# pinned to green. Ravion's promote workflow flips the production listener's
# default_action between the two TGs. Switching to "bluegreen" is additive — the
# existing rolling resources keep their state addresses, so flipping back is clean.
variable "ravion_base_url" {
  description = "URL of the Ravion api-go server the TF provider talks to."
  type        = string
  default     = "http://localhost:8080"
}

variable "ravion_api_key" {
  description = "DomainProviderClaims JWT minted via the authtest helper in the dns-provider repo. See INFRA_PROMPT.md for the mint snippet."
  type        = string
  sensitive   = true
}

variable "demo_domain" {
  description = "FQDN to issue the demo cert for. The user must control DNS for this so they can add the ACM validation CNAMEs that show up in the Ravion Domains tab."
  type        = string
}

variable "deployment_strategy" {
  type        = string
  default     = "rolling"
  description = "Deployment strategy: 'rolling' or 'bluegreen'."

  validation {
    condition     = contains(["rolling", "bluegreen"], var.deployment_strategy)
    error_message = "deployment_strategy must be 'rolling' or 'bluegreen'."
  }
}
