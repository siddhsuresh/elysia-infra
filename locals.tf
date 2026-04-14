locals {
  # prefix is used for globally-unique resource names (ECR, IAM roles, ALB,
  # CloudWatch log group, ECS cluster). Scoped resources like the ECS service
  # name and container name stay as "${var.name}-app" since they don't need
  # to be globally unique within the account/region.
  prefix = "${var.name}-${var.suffix}"
}
