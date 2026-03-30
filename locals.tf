data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  service_name   = var.service_name != "" ? var.service_name : var.name
  container_name = var.container_name != "" ? var.container_name : var.name
  log_group_name = var.log_group_name != "" ? var.log_group_name : "/ecs/${var.name}"
  tg_name        = substr("${var.name}-tg", 0, 32)

  cluster_name = element(split("/", var.cluster_arn), length(split("/", var.cluster_arn)) - 1)
  aws_region   = coalesce(var.aws_region, data.aws_region.current.name)

  # Secrets Manager ARNs only
  exec_secret_arns = distinct([
    for s in var.execution_role_secrets : (
      can(regex("^arn:aws:secretsmanager:", s.valueFrom))
      ? "${replace(s.valueFrom, "/:[^:]*::?$/", "")}*" # allow all versions/stages
      : "arn:${data.aws_partition.current.partition}:secretsmanager:${local.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${s.valueFrom}*"
    )
    if !startswith(s.valueFrom, "/") && !can(regex("^arn:aws:ssm:", s.valueFrom))
  ])

  # SSM Parameter ARNs only
  exec_ssm_param_arns = distinct([
    for s in var.execution_role_secrets : (
      can(regex("^arn:aws:ssm:", s.valueFrom))
      ? s.valueFrom
      : "arn:${data.aws_partition.current.partition}:ssm:${local.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${startswith(s.valueFrom, "/") ? "" : "/"}${s.valueFrom}"
    )
    if startswith(s.valueFrom, "/") || can(regex("^arn:aws:ssm:", s.valueFrom))
  ])
}