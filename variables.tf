# -----------------------------------------------------------------------------
# Core identifiers
# -----------------------------------------------------------------------------
variable "name" {
  type        = string
  description = "Base name used for ECS resources."
}

variable "service_name" {
  type        = string
  description = "ECS service name override."
  default     = ""
}

variable "container_name" {
  type        = string
  description = "Container name override."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all supported resources."
  default     = {}
}

# -----------------------------------------------------------------------------
# Cluster + ALB wiring
# -----------------------------------------------------------------------------
variable "cluster_arn" {
  type        = string
  description = "ECS cluster ARN to place the service in."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the target group."
}

variable "alb_listener_arn" {
  type        = string
  description = "Existing ALB listener ARN for routing."
}

variable "listener_rule_priority" {
  type        = number
  description = "Priority for the listener rule."
}

variable "host_header_values" {
  type        = list(string)
  description = "Optional host header values for routing."
  default     = []
}

variable "path_pattern_values" {
  type        = list(string)
  description = "Path patterns for routing."
  default     = ["/*"]
}

# -----------------------------------------------------------------------------
# Container/task definition inputs
# -----------------------------------------------------------------------------
variable "container_image" {
  type        = string
  description = "Container image URI."
}

variable "container_port" {
  type        = number
  description = "Container port to expose."
  default     = 80
}

variable "cpu" {
  type        = number
  description = "CPU units for the container/task."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Memory (MiB) for the container/task."
  default     = 512
}

variable "custom_container_definitions" {
  type        = string
  description = "Override container definitions JSON."
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the container."
  default     = {}
}

variable "execution_role_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Container secrets (name/valueFrom)."
  default     = []
}

variable "aws_region" {
  type        = string
  description = "AWS region used for log configuration (defaults to current region)."
  default     = null
}

# -----------------------------------------------------------------------------
# Service settings
# -----------------------------------------------------------------------------
variable "desired_count" {
  type        = number
  description = "Desired number of tasks."
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum healthy percent during deployments."
  default     = 50
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percent during deployments."
  default     = 200
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before LB health checks start."
  default     = 60
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS exec."
  default     = false
}

variable "capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "Capacity provider strategy for the service."
  default     = []
}

variable "launch_type" {
  type        = string
  description = "Launch type used when no capacity provider strategy is set."
  default     = "EC2"
}

variable "enable_ecs_managed_tags" {
  type        = bool
  description = "Enable ECS managed tags."
  default     = true
}

variable "propagate_tags" {
  type        = string
  description = "Propagate tags from the service or task definition."
  default     = "SERVICE"
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
variable "create_log_group" {
  type        = bool
  description = "Create the CloudWatch log group."
  default     = true
}

variable "log_group_name" {
  type        = string
  description = "Override log group name."
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "Log retention in days."
  default     = 30
}

variable "log_stream_prefix" {
  type        = string
  description = "Stream prefix for awslogs."
  default     = "ecs"
}

variable "log_kms_key_id" {
  type        = string
  description = "KMS key ID/ARN for encrypting CloudWatch logs (optional)."
  default     = null
}

variable "log_driver" {
  type        = string
  description = "Container log driver: awslogs | json-file | fluentd"
  default     = "awslogs"

  validation {
    condition     = contains(["awslogs", "json-file", "fluentd"], var.log_driver)
    error_message = "log_driver must be one of: awslogs, json-file, fluentd"
  }
}

variable "fluentd_address" {
  type        = string
  description = "Fluentd/Fluent Bit forward input address (only for fluentd driver)"
  default     = "127.0.0.1:24224"

  validation {
    condition     = var.log_driver != "fluentd" || length(var.fluentd_address) > 0
    error_message = "fluentd_address must be provided when log_driver = fluentd"
  }
}

variable "fluentd_tag" {
  type        = string
  description = "Fluentd tag (only for fluentd driver)"
  default     = null
}

variable "log_group_tags" {
  type        = map(string)
  description = "Additional tags for CloudWatch log group"
  default     = {}
}

# -----------------------------------------------------------------------------
# Target group + health checks
# -----------------------------------------------------------------------------
variable "deregistration_delay" {
  type        = number
  description = "Target group deregistration delay."
  default     = 30
}

variable "slow_start" {
  type        = number
  description = "Target group slow start duration."
  default     = 0
}

variable "health_check_path" {
  type        = string
  description = "Health check path."
  default     = "/"
}

variable "health_check_matcher" {
  type        = string
  description = "HTTP code matcher."
  default     = "200-399"
}

variable "health_check_interval" {
  type        = number
  description = "Health check interval."
  default     = 30
}

variable "health_check_timeout" {
  type        = number
  description = "Health check timeout."
  default     = 5
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Healthy threshold."
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Unhealthy threshold."
  default     = 2
}

# -----------------------------------------------------------------------------
# Autoscaling
# -----------------------------------------------------------------------------
variable "enable_autoscaling" {
  type        = bool
  description = "Enable ECS service autoscaling."
  default     = false
}

variable "autoscaling_min_capacity" {
  type        = number
  description = "Autoscaling minimum capacity."
  default     = 1
}

variable "autoscaling_max_capacity" {
  type        = number
  description = "Autoscaling maximum capacity."
  default     = 4
}

variable "enable_cpu_autoscaling" {
  type        = bool
  description = "Enable CPU target tracking."
  default     = true
}

variable "cpu_target_utilization" {
  type        = number
  description = "CPU target utilization percentage."
  default     = 60
}

variable "enable_memory_autoscaling" {
  type        = bool
  description = "Enable memory target tracking."
  default     = false
}

variable "memory_target_utilization" {
  type        = number
  description = "Memory target utilization percentage."
  default     = 75
}

variable "scale_in_cooldown" {
  type        = number
  description = "Scale-in cooldown seconds."
  default     = 300
}

variable "scale_out_cooldown" {
  type        = number
  description = "Scale-out cooldown seconds."
  default     = 60
}

# -----------------------------------------------------------------------------
# Alarms
# -----------------------------------------------------------------------------
variable "enable_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms."
  default     = false
}

variable "alarm_actions" {
  type        = list(string)
  description = "Alarm action ARNs."
  default     = []
}

variable "ok_actions" {
  type        = list(string)
  description = "OK action ARNs."
  default     = []
}

variable "alarm_evaluation_periods" {
  type        = number
  description = "Number of evaluation periods."
  default     = 2
}

variable "alarm_period" {
  type        = number
  description = "Alarm period in seconds."
  default     = 60
}

variable "unhealthy_host_count_threshold" {
  type        = number
  description = "Threshold for unhealthy hosts."
  default     = 1
}

variable "target_5xx_threshold" {
  type        = number
  description = "Threshold for target 5xx errors."
  default     = 1
}

variable "enable_ecs_cpu_alarm" {
  type        = bool
  description = "Enable ECS CPU alarm."
  default     = false
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "ECS CPU alarm threshold."
  default     = 80
}

variable "enable_ecs_memory_alarm" {
  type        = bool
  description = "Enable ECS memory alarm."
  default     = false
}

variable "ecs_memory_threshold" {
  type        = number
  description = "ECS memory alarm threshold."
  default     = 80
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
variable "task_role_inline_policy_json" {
  description = "Optional inline policy JSON to attach to the task role"
  type        = string
  default     = null
}