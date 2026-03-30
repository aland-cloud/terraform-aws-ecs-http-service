# -----------------------------------------------------------------------------
# Module outputs
# -----------------------------------------------------------------------------
output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN."
  value       = aws_ecs_task_definition.this.arn
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = aws_lb_target_group.this.arn
}

output "listener_rule_arn" {
  description = "Listener rule ARN."
  value       = aws_lb_listener_rule.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name."
  value       = local.log_group_name
}

output "autoscaling_target_arn" {
  description = "Autoscaling target ARN (if enabled)."
  value       = try(aws_appautoscaling_target.this[0].arn, null)
}
