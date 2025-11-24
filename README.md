# AI Chatbot Platform – Infrastructure + Application

This project is a complete, production-grade AI chatbot platform built on top of:
- **Next.js 14**
- **Supabase**
- **AWS ECS Fargate**
- **AWS CodeBuild + ECR**
- **Terraform (modular IaC)**
- **Docker multi-stage builds**

It is designed to be reliable, reproducible, fully automated and vendor-independent.

The deployment is 100% Infrastructure-as-Code.

---

## 🎯 Business Goal

The goal of this project:

- Deploy an AI chatbot system in a scalable, professional infrastructure
- Eliminate manual deployments
- Ensure reliable CI/CD
- Guarantee reproducible environment builds
- Run securely and predictably in the cloud

This is intended to evolve into a commercial product.

---

## 🧭 High-Level Architecture

User
│
▼
AWS Load Balancer
│
▼
AWS ECS Fargate Cluster
│
▼
Docker Image from ECR
│
▼
Next.js application
│
├─ connects to Supabase Auth
└─ connects to OpenAI API

markdown
Copy code

Infrastructure layers:

- **Terraform provisions:**  
  - ECR repository
  - ECS cluster
  - ECS service
  - IAM roles
  - SSM parameters (secrets)
  - CI/CD pipeline

- **CodeBuild performs:**  
  - builds image
  - pushes to ECR
  - triggers ECS redeployment

- **ECS runs the application using latest image**

---

## 🗂 Repository Structure

/
├── app/ # Next.js app router pages
├── components/ # React UI components
├── lib/ # Helpers & utils
├── supabase/ # DB migrations + seed
├── infra/ # Terraform IaC for AWS
│ ├── envs/
│ └── modules/
├── Dockerfile
├── buildspec.yml
└── package.json

yaml
Copy code

---

## 🏗 Why This Architecture Was Chosen

### ✔ Modular Terraform
Because we want:
- repeatable deployments
- isolated environments
- reusable modules
- infrastructure evolution

### ✔ AWS ECS Fargate instead of Vercel
Because:
- full control
- predictable costs
- no hidden limitations
- no traffic-based pricing surprises
- works in private VPC if needed

### ✔ CodeBuild instead of manual deploys
Because:
- fully automated builds
- secure runtime environment
- no developer workstation dependency

### ✔ Public AWS ECR Node image instead of DockerHub
Because:
- DockerHub rate limits break pipelines
- AWS Public ECR never rate-limits

### ✔ Multi-stage Dockerfile
Because:
- smaller final image
- faster deploys
- faster cold starts
- less attack surface

---

## 🐳 Dockerfile – Key Design Choices

We changed the Dockerfile for 3 reasons:

### 1) avoid DockerHub pull limit failures  
→ moved to `public.ecr.aws/node:20-alpine`

### 2) simpler dependency install  
→ switched from `npm ci` (requires lock) to `npm install`

### 3) optimized final image
→ via 3 stage build:
- deps
- build
- runner

---

## 🚀 CI/CD Flow

### On push to `deploy_dev`:

1) CodeBuild downloads source  
2) Logs in to ECR  
3) Builds Docker image  
4) Pushes to ECR  
5) Forces ECS rolling redeploy  
6) New containers replace old ones automatically  

No SSH.  
No manual build.  
No docker build locally.  
No human steps.

---

## 🔐 Secret Management

Secrets are stored only in:

=> AWS SSM Parameter Store

They are injected into ECS at runtime.

NOT inside image.  
NOT inside code.  
NOT inside Git repo.

---

## 🧪 Local Dev Run

```sh
npm install
npm run dev
App runs on:
http://localhost:3000

📦 Production Deploy – single command
From infra/envs/dev:

sh
Copy code
terraform apply
Everything is created.

📚 Future Improvements
SSL + custom domain

staging + production environment separation

monitoring dashboards

auto-scaling

CloudFront CDN

WAF

global redundancy

automated DB migrations

🏁 Summary
This project demonstrates:

real production architecture

using real cloud tools

using Terraform to provision everything

automated CI/CD pipeline

secure secret management

predictable and stable deploys

modern scalable app stack



[ User Browser ]
     |
     | 1. Open http://<public-ip>:3000/sign-in
     v
[ ECS Fargate Task ]
(Next.js app running on PORT=3000)
     |
     | 2. Auth / API calls
     |   - /sign-in
     |   - /api/chat
     v
[ Supabase ]
(Auth + Database: users, sessions, chats)
     |
     | 3. When user sends a message:
     v
[ Next.js API route /api/chat ]
     |
     | 4. Calls OpenAI with user's prompt + history
     v
[ OpenAI API ]
     |
     | 5. Returns model response
     v
[ Next.js ]
     |
     | 6. Streams response back to browser
     v
[ User Browser ]
(Sees assistant answer in UI)



(1) Developer workflow
----------------------
[ You on MacBook ]
     |
     |  git commit + git push origin deploy_dev
     v
[ GitHub repo te-ai-chatbot ]


(2) CI/CD in AWS
----------------
[ CodeBuild Project ]
  - reads buildspec.yml
  - pulls source from GitHub
  - logs in to ECR
  - builds Docker image using Dockerfile
  - tags image as :latest

     |
     |  docker build
     v

[ Docker build ]
  STAGE 1: deps
   - FROM public.ecr.aws/docker/library/node:20-alpine
   - COPY package.json
   - RUN npm install

  STAGE 2: builder
   - COPY source code
   - RUN npm run build

  STAGE 3: runner
   - COPY .next, public, node_modules
   - CMD ["npm", "run", "start"]

     |
     |  docker push
     v

[ ECR Repository te-ai-chatbot-dev ]


(3) Deployment to ECS
---------------------
[ CodeBuild ]
     |
     | aws ecs update-service --force-new-deployment
     v
[ ECS Service te-ai-chatbot-dev ]
     |
     | launches new Fargate tasks
     v
[ Fargate Task ]
  - pulls new image from ECR
  - injects secrets from SSM
  - starts Next.js server on PORT=3000
  - gets public IP from AWS

     |
     | traffic from internet
     v
[ Users hit http://<task-public-ip>:3000 ]



