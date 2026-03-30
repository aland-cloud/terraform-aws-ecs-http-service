# -----------------------------------------------------------------------------
# Common assume role policy for ECS tasks (used by BOTH roles)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# -----------------------------------------------------------------------------
# Execution role secrets/SSM policy (only if secrets exist)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "execution_secrets" {
  count = (length(local.exec_secret_arns) > 0 || length(local.exec_ssm_param_arns) > 0) ? 1 : 0

  dynamic "statement" {
    for_each = length(local.exec_secret_arns) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.exec_secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.exec_ssm_param_arns) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["ssm:GetParameter", "ssm:GetParameters"]
      resources = local.exec_ssm_param_arns
    }
  }
}

# -----------------------------------------------------------------------------
# Task Execution Role (always created)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  name               = "${var.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = merge(var.tags, {
    Service   = var.name
    ManagedBy = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "execution_secrets" {
  count  = (length(local.exec_secret_arns) > 0 || length(local.exec_ssm_param_arns) > 0) ? 1 : 0
  name   = "${var.name}-execution-secrets-policy"
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "execution_secrets" {
  count      = (length(local.exec_secret_arns) > 0 || length(local.exec_ssm_param_arns) > 0) ? 1 : 0
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_secrets[0].arn
}

# -----------------------------------------------------------------------------
# Task Role (always created)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = merge(var.tags, {
    Service   = var.name
    ManagedBy = "terraform"
  })
}

resource "aws_iam_role_policy" "task_role_inline" {
  count  = var.task_role_inline_policy_json != null ? 1 : 0
  name   = "${var.name}-task-inline"
  role   = aws_iam_role.task_role.id
  policy = var.task_role_inline_policy_json
}