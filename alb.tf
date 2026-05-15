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

# HTTP listener — always redirects to HTTPS (HTTPS always exists now that
# the Ravion-issued cert is wired in directly via domains_module_certificate).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# HTTPS listener — production listener. Initially serves the bootstrap
# self-signed cert (see bootstrap_cert.tf for why); once
# domains_module_certificate.demo issues the real cert, api-go's reconciler
# attaches it as an additional SNI cert on this listener via the listener_arn
# wired on that resource.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.bootstrap.arn

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
