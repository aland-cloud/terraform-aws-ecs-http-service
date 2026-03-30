# -----------------------------------------------------------------------------
# Task definition (EC2 + bridge networking)
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-task-definition"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  execution_role_arn = aws_iam_role.execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = var.custom_container_definitions != null ? var.custom_container_definitions : jsonencode([
    merge(
      {
        name      = var.container_name
        image     = var.container_image
        essential = true

        portMappings = [{
          containerPort = var.container_port
          hostPort      = 0
          protocol      = "tcp"
        }]
      },

        var.log_driver == "awslogs" ? {
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region        = var.aws_region != null ? var.aws_region : data.aws_region.current.name
            awslogs-group         = var.log_group_name != "" ? var.log_group_name : (var.create_log_group ? aws_cloudwatch_log_group.this[0].name : "/ecs/${var.name}")
            awslogs-stream-prefix = var.log_stream_prefix
          }
        }
      } : var.log_driver == "fluentd" ? {
        logConfiguration = {
          logDriver = "fluentd"
          options = {
            "fluentd-address" = var.fluentd_address
            tag               = coalesce(var.fluentd_tag, var.name)
          }
        }
      } : {},

        length(var.environment_variables) > 0 ? {
        environment = [
          for k, v in var.environment_variables : {
            name  = k
            value = v
          }
        ]
      } : {},

        length(var.execution_role_secrets) > 0 ? {
        secrets = [
          for s in var.execution_role_secrets : {
            name      = s.name
            valueFrom = s.valueFrom
          }
        ]
      } : {}
    )
  ])

  tags = merge(var.tags, {
    Service   = var.name
    ManagedBy = "terraform"
  })
}