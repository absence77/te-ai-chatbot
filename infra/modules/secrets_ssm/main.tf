locals {
  base_path = "/${var.project_name}/${var.environment}"
}

resource "aws_ssm_parameter" "params" {
  for_each = var.secrets

  name        = "${local.base_path}/${each.key}"
  description = "Secret ${each.key} for ${var.project_name} (${var.environment})"
  type        = "SecureString"
  value       = each.value
  overwrite   = true
}
output "param_arns" {
  description = "ARNs of created SSM parameters, keyed by logical name"
  value       = { for name, p in aws_ssm_parameter.params : name => p.arn }
}

