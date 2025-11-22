########################
# Variables
########################

variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "cpu" {
  type    = string
  default = "1024"
}

variable "memory" {
  type    = string
  default = "2048"
}

########################
# Locals
########################

locals {
  name_prefix    = "${var.app_name}-${var.environment}"
  container_name = "${local.name_prefix}-app"
}

########################
# ECR repository
########################

resource "aws_ecr_repository" "repo" {
  name = local.name_prefix

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

########################
# Networking (VPC & Subnets)
########################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################
# Security groups
########################

# Только один SG – для ECS сервиса, сразу открыт наружу на порт приложения
resource "aws_security_group" "service" {
  name        = "${local.name_prefix}-svc-sg"
  description = "ECS service security group"
  vpc_id      = data.aws_vpc.default.id

  # Открываем порт приложения в интернет
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public access to app"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# ECS Cluster
########################

resource "aws_ecs_cluster" "this" {
  name = local.name_prefix
}

########################
# IAM Role for ECS task execution
########################

resource "aws_iam_role" "task_execution" {
  name = "${local.name_prefix}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

########################
# ECS Task Definition
########################

resource "aws_ecs_task_definition" "this" {
  family                   = local.name_prefix
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name  = local.container_name
      image = "${aws_ecr_repository.repo.repository_url}:latest"

      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      # SSM параметры (имена – как ты уже создал через module.secrets)
      secrets = [
        {
          name      = "GITHUB_TOKEN"
          valueFrom = "/te-ai-chatbot/dev/GITHUB_TOKEN"
        },
        {
          name      = "SUPABASE_ANON_KEY"
          valueFrom = "/te-ai-chatbot/dev/SUPABASE_ANON_KEY"
        },
        {
          name      = "SUPABASE_URL"
          valueFrom = "/te-ai-chatbot/dev/SUPABASE_URL"
        }
      ]
    }
  ])
}

########################
# ECS Service (Fargate, без ALB)
########################

resource "aws_ecs_service" "this" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.service.id]
    assign_public_ip = true
  }

  # Никакого load_balancer и depends_on – работаем напрямую по public IP таски
}

########################
# Outputs
########################

# ECR repo URL – используется в CI/CD
output "ecr_repository_url" {
  value = aws_ecr_repository.repo.repository_url
}

# Cluster and service names – для обновления сервиса из CodeBuild
output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.this.name
}

# В этом аккаунте ALB нельзя, поэтому честный output
output "service_url" {
  value = "No ALB available in this AWS account – use ECS task Public IP (port ${var.container_port}) from AWS console."
}

# Backward-compatible outputs для cicd модуля
output "ecr_repository_name" {
  value = aws_ecr_repository.repo.name
}

output "service_arn" {
  # В AWS provider ARN сервиса возвращается в id
  value = aws_ecs_service.this.id
}

