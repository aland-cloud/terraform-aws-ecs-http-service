# terraform-aws-ecs-http-service (EC2)

A best-practice Terraform module that provisions an **ECS EC2 HTTP service** behind an existing **ALB listener**. It creates an ECS task definition/service, target group, listener rule, CloudWatch log group, optional autoscaling/alarms, and can optionally manage an ECR repository.

## Architecture

**Deterministic, production-safe, SOC2/audit-friendly** by design:

- **ECS EC2 service** (bridge networking, dynamic port mapping)
- **Task definition** (single container by default, override supported)
- **ALB target group** (instance mode) + **listener rule** (host/path routing)
- **CloudWatch log group** for container logs
- Optional **autoscaling** (CPU/memory target tracking)
- Optional **CloudWatch alarms** (ALB + ECS)
- Optional **ECR repository** with lifecycle policy

## Requirements

Existing infrastructure required:

- VPC + subnets
- ALB and listener (provide `alb_listener_arn`)
- ECS cluster and EC2 capacity providers/ASG

Terraform requirements:

- Terraform >= 1.3
- AWS provider >= 5.0

## Listener Rule Priority

`listener_rule_priority` must be **unique per listener**. Choose a number outside the range used by other services.
A safe pattern is to reserve priority ranges per service (e.g., 100–199).

## Important Notes

- Uses **bridge networking** with **dynamic port mapping** (`hostPort = 0`).
- ALB target group **must use `target_type = "instance"`** for EC2 + bridge mode.
- This approach is deterministic, safe for production, and audit/SOC2 friendly.

## Usage

```hcl
module "ecs_http_service" {
  source = "github.com/aland-cloud/terraform-aws-ecs-http-service"

  name                   = "orders"
  cluster_arn            = aws_ecs_cluster.this.arn
  vpc_id                 = aws_vpc.main.id
  alb_listener_arn       = aws_lb_listener.http.arn
  listener_rule_priority = 100

  container_image = "nginx:latest"
  container_port  = 80
  cpu             = 256
  memory          = 512

  # Optional: override region used for awslogs
  aws_region = "us-east-1"

  environment_variables = {
    ENV = "prod"
  }

  execution_role_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.database_url.arn
    }
  ]

  host_header_values = ["orders.example.com"]
  path_pattern_values = ["/*"]

  desired_count = 2

  enable_autoscaling        = true
  autoscaling_min_capacity  = 2
  autoscaling_max_capacity  = 6
  enable_cpu_autoscaling    = true
  cpu_target_utilization    = 60

  enable_alarms            = true
  enable_ecs_cpu_alarm     = true
  alarm_actions            = [aws_sns_topic.alerts.arn]
  ok_actions               = [aws_sns_topic.alerts.arn]

  # Optional: create an ECR repository for the service
  create_ecr_repository = true
  ecr_repository_name   = "orders"

  tags = {
    Environment = "prod"
    Service     = "orders"
  }
}
```

## Autoscaling

Enable service autoscaling with target tracking:

```hcl
enable_autoscaling       = true
autoscaling_min_capacity = 2
autoscaling_max_capacity = 10

# CPU target tracking
enable_cpu_autoscaling = true
cpu_target_utilization = 60

# Memory target tracking
enable_memory_autoscaling = true
memory_target_utilization = 75
```

## CloudWatch Alarms

Enable alarms for ALB target health and ECS service utilization:

```hcl
enable_alarms           = true
enable_ecs_cpu_alarm    = true
enable_ecs_memory_alarm = true
alarm_actions           = [aws_sns_topic.alerts.arn]
ok_actions              = [aws_sns_topic.alerts.arn]
```

## Secrets (SSM Parameter Store / Secrets Manager)

`execution_role_secrets` supports both Secrets Manager and SSM Parameter Store.
The module derives least-privilege ARNs and attaches the required permissions.

**Secrets Manager example:**

```hcl
execution_role_secrets = [
  {
    name      = "DATABASE_URL"
    valueFrom = aws_secretsmanager_secret.database_url.arn
  }
]
```

**SSM Parameter example:**

```hcl
execution_role_secrets = [
  {
    name      = "DATABASE_URL"
    valueFrom = "/prod/orders/database_url"
  }
]
```

## SOC2 Checklist

Use this checklist to align with common SOC2 expectations:

- ✅ **Centralized logging** via CloudWatch (`create_log_group`, `log_retention_days`).
- ✅ **Log encryption** via KMS (`log_kms_key_id`).
- ✅ **Least-privilege IAM** for Secrets Manager/SSM (scoped to `execution_role_secrets`).
- ✅ **Resource tagging** (`tags`) for ownership and audit trails.

> **Note:** ALB access logging and VPC flow logs are configured outside this module.

## Inputs

Key inputs (see `variables.tf` for full list):

- `name` - base name for ECS resources
- `cluster_arn` - ECS cluster ARN
- `vpc_id` - VPC for the target group
- `alb_listener_arn` - existing ALB listener
- `listener_rule_priority` - rule priority
- `container_image` - container image URI
- `container_port` - container port
- `cpu` / `memory` - CPU and memory for container/task
- `environment_variables` - environment variables map
- `execution_role_secrets` - secrets list (name/valueFrom)
- `custom_container_definitions` - override container definitions JSON
- `aws_region` - override region for awslogs configuration
- `task_role_inline_policy_json` - optional inline policy JSON for the task role
- `enable_autoscaling` / `enable_alarms` - feature toggles

### Logging inputs
- `log_retention_days` - CloudWatch retention days
- `log_kms_key_id` - KMS key for log encryption

## Outputs

- `service_arn`
- `task_definition_arn`
- `target_group_arn`
- `listener_rule_arn`
- `log_group_name`
- `autoscaling_target_arn`

## Notes

- ECS cluster, capacity providers, VPC, subnets, and ALB are expected to exist.
- Uses EC2 + bridge networking with dynamic port mapping (hostPort = 0) and target group type `instance`.
- Execution role secrets/SSM permissions are scoped to the ARNs derived from `execution_role_secrets`.
