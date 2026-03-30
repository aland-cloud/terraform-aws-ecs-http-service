# -----------------------------------------------------------------------------
# ALB target group + listener rule
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "this" {
  # Instance target type is required for EC2 + bridge + dynamic port mapping.
  name                 = local.tg_name
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.deregistration_delay
  slow_start           = var.slow_start

  # Health checks for the ECS targets.
  health_check {
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "this" {
  # Listener rule forwards traffic to the service target group.
  listener_arn = var.alb_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  # Optional host header routing.
  dynamic "condition" {
    for_each = length(var.host_header_values) > 0 ? [var.host_header_values] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }

  # Optional path-based routing.
  dynamic "condition" {
    for_each = length(var.path_pattern_values) > 0 ? [var.path_pattern_values] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  tags = var.tags
}
