variable "project_name" {
  type        = string
  description = "Base project name used for SSM parameter prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod)"
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret name -> value"
}

