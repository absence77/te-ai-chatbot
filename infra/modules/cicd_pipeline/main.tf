variable "github_connection_arn" {
  type = string
}

variable "project_name" {
  type        = string
  description = "Base project name (prefix for resources)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod)"
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
  description = "Branch that triggers deployment"
}

variable "github_oauth_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT token for pipeline access"
}

variable "ecr_repo_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "app_runner_service_arn" {
  type        = string
  description = "ARN of the App Runner service"
}

variable "codebuild_role_arn" {
  type        = string
  description = "IAM role ARN for CodeBuild"
}

variable "codepipeline_role_arn" {
  type        = string
  description = "IAM role ARN for CodePipeline"
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${local.name_prefix}-${local.account_id}-artifacts"
}

# ======================================================
# S3 bucket for CodePipeline artifacts
# ======================================================

resource "aws_s3_bucket" "artifacts" {
  bucket = local.bucket_name

  tags = {
    Name = "${local.bucket_name}"
  }
}

# ======================================================
# CodeBuild Project
# ======================================================

resource "aws_codebuild_project" "build" {
  name         = "${local.name_prefix}-build"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = var.ecr_repo_name
    }

    environment_variable {
      name  = "APP_RUNNER_SERVICE_ARN"
      value = var.app_runner_service_arn
    }

    # These are used by tag_commit.sh
    environment_variable {
      name  = "GITHUB_OWNER"
      value = var.github_owner
    }

    environment_variable {
      name  = "GITHUB_REPO"
      value = var.github_repo
    }

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = var.github_oauth_token
      type  = "PLAINTEXT"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.name_prefix}"
      stream_name = "build"
    }
  }
}

# ======================================================
# CodePipeline
# ======================================================

resource "aws_codepipeline" "pipeline" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # ---------- SOURCE STAGE (GitHub via CodeStar Connection) ----------
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}" # absence77/te-ai-chatbot
        BranchName       = var.github_branch                         # deploy_dev
      }
    }
  }

  # ---------- BUILD STAGE ----------
  stage {
    name = "Build"

    action {
      name             = "Build_and_Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}

# ======================================================
# Outputs
# ======================================================

output "pipeline_name" {
  value = aws_codepipeline.pipeline.name
}

output "codebuild_project_name" {
  value = aws_codebuild_project.build.name
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

