variable "project_name" {
  type        = string
  description = "Base project name used for SSM parameter prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod)"
}

locals {
  prefix = "/${var.project_name}/${var.environment}"
}

# Create one SSM parameter per secret
resource "aws_ssm_parameter" "params" {
  for_each = var.secrets

  name  = "${local.prefix}/${each.key}"
  type  = "SecureString"
  value = each.value

  overwrite = true
}

# Export map: secret_name -> SSM parameter full path
output "parameters" {
  value = {
    for name, resource in aws_ssm_parameter.params :
    name => resource.name
  }
  sensitive = true
}

