output "app_runner_service_url" {
  value       = module.app_runner.service_url
  description = "Public URL for the deployed App Runner application"
}

output "ecr_repository_url" {
  value       = module.app_runner.ecr_repository_url
  description = "URL of the created ECR repository"
}

