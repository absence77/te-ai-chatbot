variable "project_name" {
  type        = string
  description = "Base project name for SSM parameter path"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod/etc)"
}

variable "secrets" {
  type        = map(string)
  description = "Map of secrets to store in SSM Parameter Store"
}

