variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "te-ai-chatbot"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organization"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "github_branch" {
  type        = string
  description = "Branch to trigger deployments"
  default     = "deploy_dev"
}

variable "github_oauth_token" {
  type        = string
  description = "GitHub PAT for CodePipeline"
  sensitive   = true
}

variable "supabase_url" {
  type        = string
  description = "Supabase project URL"
  sensitive   = true
}

variable "supabase_anon_key" {
  type        = string
  description = "Supabase anon key"
  sensitive   = true
}

