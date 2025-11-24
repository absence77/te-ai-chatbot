provider "aws" {
  region = var.aws_region
}

locals {
  full_project_name = "${var.project_name}-${var.environment}"
}

# 1. SSM secrets
module "secrets" {
  source       = "../../modules/secrets_ssm"
  project_name = var.project_name
  environment  = var.environment

  secrets = {
    SUPABASE_URL      = var.supabase_url
    SUPABASE_ANON_KEY = var.supabase_anon_key
    GITHUB_TOKEN      = var.github_oauth_token
    OPENAI_API_KEY    = var.openai_api_key
  }
}

# 2. IAM roles (CodeBuild / CodePipeline / policies)
module "iam" {
  source                  = "../../modules/iam"
  project_name            = var.project_name
  environment             = var.environment
  codestar_connection_arn = "arn:aws:codeconnections:us-east-1:921868492248:connection/26d9aafa-404c-4c9b-b08b-a4045aa9182b"
}

# 3. App Runner / ECS service module
module "app_runner" {
  source = "../../modules/app_runner_service"

  environment    = var.environment
  app_name       = "te-ai-chatbot"
  container_port = 3000
  cpu            = "1024"
  memory         = "2048"
}

# 4. CI/CD pipeline module
module "cicd" {
  source       = "../../modules/cicd_pipeline"
  project_name = var.project_name
  environment  = var.environment

  github_owner       = var.github_owner
  github_repo        = var.github_repo
  github_branch      = var.github_branch
  github_oauth_token = var.github_oauth_token

  ecr_repo_name          = module.app_runner.ecr_repository_name
  app_runner_service_arn = module.app_runner.service_arn

  github_connection_arn = "arn:aws:codeconnections:us-east-1:921868492248:connection/26d9aafa-404c-4c9b-b08b-a4045aa9182b"

  codebuild_role_arn    = module.iam.codebuild_role_arn
  codepipeline_role_arn = module.iam.codepipeline_role_arn
}

