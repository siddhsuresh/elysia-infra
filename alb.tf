resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Test listener for blue/green — lets you preview the standby on port 8080
  # before promoting. Conditional ingress block keeps rolling-mode SG identical
  # to before.
  dynamic "ingress" {
    for_each = local.is_bluegreen ? [1] : []
    content {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-alb" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = local.prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = local.prefix }
}

resource "aws_lb_target_group" "app" {
  name_prefix = "ely-"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = { Name = "${var.name}-app" }

  lifecycle {
    create_before_destroy = true
  }
}

# Green (standby) target group — only created in bluegreen mode. The blue TG
# above is index 0 / "live"; this one is index 1 / "standby". Ravion's
# promote workflow flips listener.default_action between the two.
resource "aws_lb_target_group" "app_green" {
  count = local.is_bluegreen ? 1 : 0

  name_prefix = "ely-g-"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = { Name = "${var.name}-app-green" }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP listener — either redirect to HTTPS or forward to target group.
# In bluegreen mode this listener IS the production listener whenever no cert
# is set, so Ravion mutates default_action during promote — ignore_changes
# preserves the flip across `terraform apply`. In rolling mode the lifecycle
# block is harmless (default_action only ever points at the single TG).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Only set target_group_arn when NOT redirecting
    target_group_arn = var.certificate_arn == "" ? aws_lb_target_group.app.arn : null
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# HTTPS listener — only created when certificate is provided. Production
# listener for bluegreen when HTTPS is enabled.
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Test listener — bluegreen only. Pinned to the green (standby) TG so you can
# curl/preview the new revision on :8080 before promoting. Not flipped by
# Ravion — stays bound to green for its lifetime.
resource "aws_lb_listener" "test" {
  count = local.is_bluegreen ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_green[0].arn
  }
}
