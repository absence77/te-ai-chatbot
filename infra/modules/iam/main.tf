data "aws_caller_identity" "current" {}

# =========================================================
# Inputs (из root-модуля через module "iam" {...})
# =========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "codestar_connection_arn" {
  type        = string
  description = "CodeStar connection ARN for GitHub"
}

# =========================================================
# Locals
# =========================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${local.name_prefix}-${local.account_id}-artifacts"
}

# =========================================================
# CodeBuild IAM Role
# =========================================================

resource "aws_iam_role" "codebuild_role" {
  name = "${local.name_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codebuild_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_ssm" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_apprunner" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppRunnerFullAccess"
}

# --- CodeBuild S3 artifacts access -------------------

data "aws_iam_policy_document" "codebuild_s3_artifacts" {
  # Чтение и запись объектов в бакете артефактов
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }

  # List самого бакета
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

resource "aws_iam_policy" "codebuild_s3_artifacts" {
  name        = "${local.name_prefix}-codebuild-s3-artifacts"
  description = "Allow CodeBuild to read/write artifacts bucket"
  policy      = data.aws_iam_policy_document.codebuild_s3_artifacts.json
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_artifacts_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_s3_artifacts.arn
}


# =========================================================
# CodePipeline IAM Role
# =========================================================

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_full" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# =========================================================
# Policy: CodeStar Connection
# =========================================================

data "aws_iam_policy_document" "codepipeline_codestar" {
  statement {
    effect = "Allow"

    actions = [
      "codestar-connections:UseConnection",
    ]

    resources = [
      var.codestar_connection_arn,
    ]
  }
}

resource "aws_iam_policy" "codepipeline_codestar" {
  name        = "${local.name_prefix}-codepipeline-codestar"
  description = "Allow CodePipeline to use CodeStar connection"
  policy      = data.aws_iam_policy_document.codepipeline_codestar.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codestar.arn
}

# =========================================================
# Policy: S3 artifacts bucket (для CodePipeline)
# =========================================================

data "aws_iam_policy_document" "codepipeline_s3_artifacts" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

resource "aws_iam_policy" "codepipeline_s3_artifacts" {
  name        = "${local.name_prefix}-codepipeline-s3-artifacts"
  description = "Allow CodePipeline to read/write artifacts bucket"
  policy      = data.aws_iam_policy_document.codepipeline_s3_artifacts.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_artifacts_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_s3_artifacts.arn
}

# =========================================================
# Policy: CodePipeline → CodeBuild
# =========================================================

data "aws_iam_policy_document" "codepipeline_codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_codebuild" {
  name        = "${local.name_prefix}-codepipeline-codebuild"
  description = "Allow CodePipeline to trigger CodeBuild"
  policy      = data.aws_iam_policy_document.codepipeline_codebuild.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_codebuild.arn
}

# =========================================================
# Outputs
# =========================================================

output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_role.arn
}

output "codepipeline_role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}

