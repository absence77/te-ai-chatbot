locals {
  prefix = "/${var.project_name}/${var.environment}"
}

resource "aws_ssm_parameter" "params" {
  for_each = var.secrets

  name  = "${local.prefix}/${each.key}"
  type  = "SecureString"
  value = each.value

  overwrite = true
}

output "parameters" {
  value = {
    for name, resource in aws_ssm_parameter.params :
    name => resource.name
  }
  sensitive = true
}

