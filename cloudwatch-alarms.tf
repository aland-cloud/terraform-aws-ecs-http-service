# -----------------------------------------------------------------------------
# CloudWatch alarms for ALB + ECS service
# -----------------------------------------------------------------------------
data "aws_lb_listener" "this" {
  # Resolve ALB ARN from the listener for alarm dimensions.
  arn = var.alb_listener_arn
}

data "aws_lb" "this" {
  arn = data.aws_lb_listener.this.load_balancer_arn
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  # Alarm on unhealthy target count in the target group.
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.name}-tg-unhealthy"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.unhealthy_host_count_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    TargetGroup  = aws_lb_target_group.this.arn_suffix
    LoadBalancer = data.aws_lb.this.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  # Alarm on 5XX errors from targets.
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.name}-tg-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.target_5xx_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    TargetGroup  = aws_lb_target_group.this.arn_suffix
    LoadBalancer = data.aws_lb.this.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  # Alarm on ECS service CPU utilization.
  count               = var.enable_alarms && var.enable_ecs_cpu_alarm ? 1 : 0
  alarm_name          = "${var.name}-ecs-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.ecs_cpu_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  # Alarm on ECS service memory utilization.
  count               = var.enable_alarms && var.enable_ecs_memory_alarm ? 1 : 0
  alarm_name          = "${var.name}-ecs-memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.ecs_memory_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = local.service_name
  }
}
