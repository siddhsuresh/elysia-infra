# ── Cluster ──
output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

# ── Services ──
# In rolling mode `service_arn` is the only service. In bluegreen mode it's the
# blue (live) service at apply time; promote physically swaps blue↔green ARNs
# in Ravion's EcsDeploymentSlot row, but the terraform-managed resource keeps
# its name and ARN.
output "service_arn" {
  value = aws_ecs_service.app.id
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "blue_service_arn" {
  value = aws_ecs_service.app.id
}

output "green_service_arn" {
  value = local.is_bluegreen ? aws_ecs_service.app_green[0].id : null
}

# ── ALB ──
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "green_target_group_arn" {
  value = local.is_bluegreen ? aws_lb_target_group.app_green[0].arn : null
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

# Production listener — the one Ravion's promote workflow flips between blue
# and green target groups. HTTPS when a cert is provided, otherwise HTTP.
output "production_listener_arn" {
  value = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

# Test listener (bluegreen only) — :8080 pinned to the green TG for previewing
# the standby before promoting.
output "test_listener_arn" {
  value = local.is_bluegreen ? aws_lb_listener.test[0].arn : null
}

# Strategy-conditional service-ARNs array — `[]` in rolling, `[green_arn]` in
# bluegreen. Spread as `- ...<<stack.output.bluegreen_extra_service_arns>>`
# under `ecs_service_arns` in module YAML, so a single deployment block works
# for both strategies (Ravion infers strategy from the count: 1 = rolling, 2
# = bluegreen). Target groups and listeners are auto-discovered by the deploy
# manager — they're NOT part of the module deployment schema.
output "bluegreen_extra_service_arns" {
  value = local.is_bluegreen ? [aws_ecs_service.app_green[0].id] : []
}

# ── IAM ──
output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

# ── ECR ──
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

# ── CloudWatch ──
output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

# ── Task Definition ──
output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

# ── VPC ──
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# ── Security Groups ──
output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "region" {
  value = var.region
}
