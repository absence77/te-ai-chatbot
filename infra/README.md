Terraform: how infrastructure is built
 Environment root module: infra/envs/dev

This directory describes one environment (dev):

main.tf — wires all Terraform modules together:

module "iam" – IAM roles and policies for CodeBuild / CodePipeline.

module "secrets_ssm" – creates SSM parameters:

/te-ai-chatbot/dev/OPENAI_API_KEY

/te-ai-chatbot/dev/SUPABASE_URL

/te-ai-chatbot/dev/SUPABASE_ANON_KEY

module "app_runner_service" – despite the name, this module actually creates:

ECR repository for the app image

ECS Cluster (Fargate)

Fargate Task Definition with:

PORT=3000, NODE_ENV=production

OPENAI_API_KEY, NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY from SSM

Security Group that exposes port 3000 to the Internet

ECS Service with desired_count = 1, launch_type = "FARGATE", assign_public_ip = true

module "cicd_pipeline" – CI/CD layer:

CodeBuild project that:

builds Docker image from this repo

pushes it to the ECR repo created above

runs aws ecs update-service --force-new-deployment to trigger a new deployment

CodePipeline that:

listens to changes in the GitHub branch deploy_dev

triggers the CodeBuild project

variables.tf — parameters for the environment (AWS region, GitHub repo, branch name…).

terraform.tfvars — actual values for the dev environment.

outputs.tf — exports ECR repo URL, ECS cluster/service names and other useful info.

 Module dependency flow
infra/envs/dev/main.tf

  ├─ module.iam
  │     └─ IAM roles for CodeBuild / CodePipeline / ECS tasks
  │
  ├─ module.secrets_ssm
  │     └─ SSM parameters for OPENAI + Supabase
  │
  ├─ module.app_runner_service
  │     ├─ ECR repo   (for Docker images)
  │     ├─ ECS cluster + Fargate service
  │     └─ Security group + networking
  │
  └─ module.cicd_pipeline
        ├─ CodeBuild project
        └─ CodePipeline (GitHub → Build → Deploy)
          (depends on ECR repo and ECS service)

 How to create / update infrastructure

From your laptop:

cd infra/envs/dev

# 1. Initialize Terraform
terraform init

# 2. See the plan
terraform plan

# 3. Apply changes (creates/updates AWS resources)
terraform apply


Everything (roles, secrets, ECS, CI/CD) is reproducible from Terraform.
No manual clicking in the console is required once the TF files are correct.
