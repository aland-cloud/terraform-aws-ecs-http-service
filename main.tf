# -----------------------------------------------------------------------------
# ECS service wiring
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  # The service ties the task definition to the ECS cluster.
  name                               = local.service_name
  cluster                            = var.cluster_arn
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  enable_execute_command             = var.enable_execute_command
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  propagate_tags                     = var.propagate_tags
  launch_type                        = length(var.capacity_provider_strategy) == 0 ? var.launch_type : null

  # Safeguard deployments with automatic rollback.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Optional capacity provider strategy for EC2 clusters.
  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  # Attach service to the ALB target group.
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.this]

  tags = var.tags
}
