resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.name}-ecs-"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from ALB
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-ecs-tasks" }

  lifecycle {
    create_before_destroy = true
  }
}

# Placeholder task definition — the deploy manager registers new revisions
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  # Placeholder container — deploy manager will register new task def revisions
  # with the actual image from the build step
  container_definitions = jsonencode([
    {
      name      = "${var.name}-app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "PORT", value = tostring(var.container_port) },
        { name = "NODE_ENV", value = "production" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -sf http://localhost:${var.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = { Name = "${var.name}-app" }

  lifecycle {
    # Don't revert task definition when deploy manager updates it
    ignore_changes = [container_definitions]
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.prefix}-app"
  retention_in_days = 30
  tags              = { Name = "${local.prefix}-app" }
}

resource "aws_ecs_service" "app" {
  name            = "${var.name}-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.name}-app"
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = false # Deploy manager handles rollback
  }

  propagate_tags          = "TASK_DEFINITION"
  enable_ecs_managed_tags = true

  # Deploy manager controls task definition and desired count
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http]

  tags = { Name = "${var.name}-app" }
}
