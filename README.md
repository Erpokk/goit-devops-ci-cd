# DevOps CI/CD Infrastructure with RDS

This project contains Terraform infrastructure for deploying a Django application on AWS EKS with Jenkins CI/CD, ArgoCD for GitOps, and RDS PostgreSQL database.

## Overview

The infrastructure includes:
- AWS EKS cluster for container orchestration
- RDS PostgreSQL database (with Aurora support)
- Jenkins for CI/CD pipelines
- ArgoCD for GitOps deployments
- ECR for Docker image registry
- Helm charts for application deployment

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. kubectl installed
4. Helm installed
5. GitHub Personal Access Token (PAT) with repo permissions

## Configuration

### 1. Setup Variables

Copy the example variables file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:
- `project_name` - Your project name (used for resource naming)
- `environment` - Environment name (dev, staging, prod)
- `aws_account_id` - Your AWS account ID
- `github_username` - Your GitHub username
- `github_repo` - Your repository name
- `github_branch` - Branch name (e.g., main, lesson-8-9)
- `ecr_repository_name` - ECR repository name
- `rds_password` - Secure database password
- `jenkins_admin_password` - Secure Jenkins admin password

### 2. Update Backend Configuration

Edit `backend.tf` and replace the bucket name with your S3 bucket name for Terraform state:

```hcl
bucket = "your-project-name-your-environment-terraform-state"
```

### 3. Update YAML Configuration Files

The following files contain placeholder variables that need to be replaced with actual values:

#### `modules/jenkins/values.yaml`
Replace:
- `${JENKINS_ADMIN_USERNAME}` - Jenkins admin username
- `${JENKINS_ADMIN_PASSWORD}` - Jenkins admin password
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

#### `modules/argo-cd/charts/values.yaml`
Replace:
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

#### `charts/django-app/values.yaml`
Replace:
- `${AWS_ACCOUNT_ID}` - AWS account ID
- `${AWS_REGION}` - AWS region (e.g., eu-central-1)
- `${ECR_REPOSITORY_NAME}` - ECR repository name
- `${POSTGRES_HOST}` - RDS endpoint (get from Terraform output after RDS creation)
- `${POSTGRES_PORT}` - Database port (default: 5432)
- `${POSTGRES_USER}` - Database username
- `${POSTGRES_DB}` - Database name
- `${POSTGRES_PASSWORD}` - Database password

#### `django/Jenkinsfile`
Replace:
- `${AWS_ACCOUNT_ID}` - AWS account ID
- `${AWS_REGION}` - AWS region
- `${ECR_REPOSITORY_NAME}` - ECR repository name
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

## How to Apply Terraform

1. Initialize Terraform:
```bash
terraform init
```

2. Review the execution plan:
```bash
terraform plan
```

3. Apply the infrastructure:
```bash
terraform apply
```

4. Confirm by typing `yes` when prompted.

5. Wait for all resources to be created (15-20 minutes):
   - VPC and subnets
   - EKS cluster and node groups
   - RDS database instance
   - ECR repository
   - Jenkins deployment
   - ArgoCD deployment

6. Get RDS endpoint from Terraform output:
```bash
terraform output rds_endpoint
```

7. Update `charts/django-app/values.yaml` with the RDS endpoint.

8. Get kubeconfig for the EKS cluster:
```bash
aws eks --region ${AWS_REGION} update-kubeconfig --name eks-${PROJECT_NAME}-${ENVIRONMENT}-cluster
```

9. Verify cluster access:
```bash
kubectl get nodes
```

## Terraform Module Structure

### RDS Module

Універсальний модуль RDS підтримує як стандартну RDS, так і Aurora PostgreSQL через параметр `use_aurora`.

#### Приклад використання модуля

```hcl
module "rds" {
  source = "./modules/rds"

  name                  = var.rds_name
  use_aurora            = false  # false = стандартна RDS, true = Aurora
  aurora_instance_count = 2      # кількість інстансів для Aurora (1 writer + replicas)
  
  # RDS Configuration (використовується коли use_aurora = false)
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"
  
  # Aurora Configuration (використовується коли use_aurora = true)
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  
  subnet_private_ids      = module.vpc.private_subnets
  subnet_public_ids       = module.vpc.public_subnets
  publicly_accessible     = true
  vpc_id                  = module.vpc.vpc_id
  multi_az                = true
  backup_retention_period  = 0
  
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
```

#### Опис усіх змінних модуля RDS

| Змінна | Тип | Опис | Дефолт | Обов'язкова |
|--------|-----|------|--------|-------------|
| `name` | `string` | Назва RDS інстансу або кластера | - | ✅ |
| `use_aurora` | `bool` | Використовувати Aurora (`true`) або стандартну RDS (`false`) | `false` | ❌ |
| `aurora_instance_count` | `number` | Кількість інстансів для Aurora (1 writer + replicas) | `2` | ❌ |
| `aurora_replica_count` | `number` | Кількість reader реплік для Aurora | `1` | ❌ |
| `engine` | `string` | Тип движка для стандартної RDS (postgres, mysql, mariadb) | `"postgres"` | ❌ |
| `engine_version` | `string` | Версія движка для стандартної RDS | `"14.7"` | ❌ |
| `engine_cluster` | `string` | Тип движка для Aurora (aurora-postgresql, aurora-mysql) | `"aurora-postgresql"` | ❌ |
| `engine_version_cluster` | `string` | Версія движка для Aurora | `"15.3"` | ❌ |
| `instance_class` | `string` | Клас інстансу (db.t3.micro, db.t3.small, db.r5.large тощо) | `"db.t3.micro"` | ❌ |
| `allocated_storage` | `number` | Розмір диску в GB (тільки для стандартної RDS) | `20` | ❌ |
| `db_name` | `string` | Назва бази даних | - | ✅ |
| `username` | `string` | Мастер username для БД | - | ✅ |
| `password` | `string` | Мастер password для БД (sensitive) | - | ✅ |
| `vpc_id` | `string` | ID VPC для створення Security Group | - | ✅ |
| `subnet_private_ids` | `list(string)` | Список ID приватних підмереж | - | ✅ |
| `subnet_public_ids` | `list(string)` | Список ID публічних підмереж | - | ✅ |
| `publicly_accessible` | `bool` | Чи доступна БД з інтернету | `false` | ❌ |
| `multi_az` | `bool` | Multi-AZ розгортання (тільки для стандартної RDS) | `false` | ❌ |
| `backup_retention_period` | `string` | Період збереження бекупів (дні) | `""` | ❌ |
| `parameter_group_family_rds` | `string` | Сімейство параметрів для стандартної RDS | `"postgres15"` | ❌ |
| `parameter_group_family_aurora` | `string` | Сімейство параметрів для Aurora | `"aurora-postgresql15"` | ❌ |
| `parameters` | `map(string)` | Додаткові параметри БД (наприклад, max_connections) | `{}` | ❌ |
| `tags` | `map(string)` | Теги для ресурсів | `{}` | ❌ |

#### Як змінити тип БД, engine, клас інстансу тощо

**1. Зміна типу БД (RDS ↔ Aurora):**

```hcl
module "rds" {
  # ...
  use_aurora = true  # true для Aurora, false для стандартної RDS
  # ...
}
```

**2. Зміна типу движка (PostgreSQL ↔ MySQL):**

Для стандартної RDS:
```hcl
module "rds" {
  # ...
  engine = "mysql"  # або "postgres", "mariadb"
  engine_version = "8.0"  # версія движка
  parameter_group_family_rds = "mysql8.0"  # сімейство параметрів
  # ...
}
```

Для Aurora:
```hcl
module "rds" {
  # ...
  engine_cluster = "aurora-mysql"  # або "aurora-postgresql"
  engine_version_cluster = "8.0.mysql_aurora.3.02.0"
  parameter_group_family_aurora = "aurora-mysql8.0"
  # ...
}
```

**3. Зміна класу інстансу:**

```hcl
module "rds" {
  # ...
  instance_class = "db.t3.small"  # або db.t3.medium, db.r5.large тощо
  # ...
}
```

Доступні класи:
- **Burstable**: `db.t3.micro`, `db.t3.small`, `db.t3.medium`, `db.t3.large`
- **General Purpose**: `db.m5.large`, `db.m5.xlarge`
- **Memory Optimized**: `db.r5.large`, `db.r5.xlarge`

**4. Зміна розміру диску (тільки для стандартної RDS):**

```hcl
module "rds" {
  # ...
  allocated_storage = 100  # розмір в GB
  # ...
}
```

**5. Зміна кількості реплік для Aurora:**

```hcl
module "rds" {
  # ...
  use_aurora = true
  aurora_instance_count = 3  # 1 writer + 2 reader replicas
  aurora_replica_count = 2   # кількість reader реплік
  # ...
}
```

**6. Налаштування параметрів БД:**

```hcl
module "rds" {
  # ...
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
    shared_buffers             = "256MB"
  }
  # ...
}
```

**7. Зміна доступності (public/private):**

```hcl
module "rds" {
  # ...
  publicly_accessible = false  # false = тільки в VPC, true = доступна з інтернету
  # ...
}
```

**8. Увімкнення Multi-AZ (тільки для стандартної RDS):**

```hcl
module "rds" {
  # ...
  multi_az = true  # створює standby replica в іншій AZ
  # ...
}
```

#### Компоненти модуля

Модуль автоматично створює:

- **DB Subnet Group** (`aws_db_subnet_group`) - група підмереж для БД
- **Security Group** (`aws_security_group`) - правила доступу (порт 5432 для PostgreSQL)
- **Parameter Group**:
  - `aws_db_parameter_group` - для стандартної RDS
  - `aws_rds_cluster_parameter_group` - для Aurora кластера

Всі компоненти створюються автоматично залежно від значення `use_aurora`.

## Application Configuration

The Django application is configured to use PostgreSQL via environment variables. Update `django/myapp/settings.py`:

```python
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "localhost")
POSTGRES_PORT = os.environ.get("POSTGRES_PORT", "5432")
POSTGRES_DB = os.environ.get("POSTGRES_DB", "postgres")
POSTGRES_USER = os.environ.get("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "password")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "HOST": POSTGRES_HOST,
        "PORT": int(POSTGRES_PORT),
        "NAME": POSTGRES_DB,
        "USER": POSTGRES_USER,
        "PASSWORD": POSTGRES_PASSWORD,
    }
}
```

## How to Check Jenkins Job

1. Get Jenkins LoadBalancer URL:
```bash
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Access Jenkins UI (or use port-forward):
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:80
```
Open `http://localhost:8080` in browser.

3. Login with credentials from `modules/jenkins/values.yaml`.

4. Navigate to `jcasc` folder → `goit-django-docker` pipeline job.

5. Check job status:
   - View "Build History" to see all builds
   - Click on a build number to see details
   - Check "Console Output" to see build logs

6. Trigger a new build:
   - Click "Build Now"
   - Monitor the build progress
   - Verify that the pipeline builds Docker image, pushes to ECR, and updates Git

7. Verify Git commit:
   - Check your GitHub repository
   - Confirm that `charts/django-app/values.yaml` was updated with new image tag

## How to See Result in Argo CD

1. Get ArgoCD admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. Port-forward ArgoCD server:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. Access ArgoCD UI:
   - Open `https://localhost:8080` in browser
   - Accept the self-signed certificate warning
   - Login with username `admin` and password from step 1

4. View applications:
   - Click on "Applications" in the left menu
   - Check application status (Synced, Healthy, OutOfSync)

5. View application details:
   - Click on the application name
   - See the application topology
   - Check sync status and health of each resource

6. View deployed application:
```bash
kubectl port-forward svc/django-app-service -n default 8000:8000
```
Open `http://localhost:8000` in browser to see the Django application.

## ArgoCD Configuration

ArgoCD is configured via Helm chart. Database connection values are provided in `charts/django-app/values.yaml`:

```yaml
config:
  POSTGRES_PORT: ${POSTGRES_PORT}
  POSTGRES_HOST: ${POSTGRES_HOST}  # RDS endpoint from Terraform output
  POSTGRES_USER: ${POSTGRES_USER}
  POSTGRES_DB: ${POSTGRES_DB}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

After ArgoCD detects changes in Git (from Jenkins pipeline), it automatically syncs and updates the application.

## Variables Reference

All variables are defined in `variables.tf`. Key variables:

- **Project**: `project_name`, `environment`
- **AWS**: `aws_account_id`, `aws_region`
- **GitHub**: `github_username`, `github_repo`, `github_branch`
- **ECR**: `ecr_repository_name`
- **RDS**: `rds_name`, `rds_db_name`, `rds_username`, `rds_password`, `rds_instance_class`, `rds_allocated_storage`
- **Jenkins**: `jenkins_admin_username`, `jenkins_admin_password`

## Important Notes

- **Security**: Never commit `terraform.tfvars` or files with real passwords to Git
- **Backend**: Update `backend.tf` with your S3 bucket name before first `terraform init`
- **RDS Endpoint**: Get the RDS endpoint from Terraform output and update `charts/django-app/values.yaml`
- **YAML Variables**: Replace all `${VARIABLE}` placeholders in YAML files with actual values
- **Production**: This configuration is for development/testing. Adjust security settings for production use.

## Troubleshooting

- **Terraform errors**: Check AWS credentials and permissions
- **Jenkins pipeline fails**: Verify GitHub token and ECR permissions
- **ArgoCD sync issues**: Check repository access and branch name
- **Database connection**: Verify RDS endpoint and security group rules
- **Application not accessible**: Check service and pod status with `kubectl get pods -n default`
