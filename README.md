# 🚀 CI/CD for Django on EKS with Jenkins and ArgoCD

This project demonstrates how to deploy a Django application on AWS EKS using Terraform, Docker, ECR, Jenkins, and ArgoCD.

## Overview

The infrastructure includes:
- AWS EKS cluster for container orchestration
- RDS PostgreSQL database (with Aurora support)
- Jenkins for CI/CD pipelines
- ArgoCD for GitOps deployments
- ECR for Docker image registry
- Helm charts for application deployment
- Prometheus and Grafana for monitoring

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. kubectl installed
4. Helm installed
5. Docker installed
6. GitHub Personal Access Token (PAT) with repo permissions

## Configuration

### 1. Setup Variables

Copy the example variables file and fill in your values:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform/terraform.tfvars` with your configuration:

**Required variables:**
- `name` - Project name (used for resource naming)
- `aws_account_id` - Your AWS account ID
- `s3_backend_bucket` - S3 bucket name for Terraform state
- `ecr_repository_name` - ECR repository name
- `github_username` - Your GitHub username
- `github_repo` - Your GitHub repository name
- `jenkins_admin_password` - Secure Jenkins admin password
- `grafana_admin_password` - Secure Grafana admin password
- `rds_password` - Secure database password

**Optional variables (have defaults):**
- `aws_region` - AWS region (default: `us-east-1`)
- `github_branch` - GitHub branch name (default: `main`)
- `rds_username` - RDS username (default: `postgres`)
- `rds_database_name` - Database name (default: `myapp`)
- `rds_use_aurora` - Use Aurora (default: `false`)
- `rds_instance_class` - RDS instance class (default: `db.t3.micro`)

### 2. Update Backend Configuration

Edit `terraform/backend.tf` and replace the bucket name with your S3 bucket name:

```hcl
bucket = "your-project-name-terraform-state"
```

**Note:** Backend configuration cannot use variables directly. You must set the bucket name manually or use partial configuration via `-backend-config` flags.

### 3. Update YAML Configuration Files

The following YAML files contain placeholder variables that need to be replaced with actual values:

#### `terraform/modules/jenkins/values.yaml`
Replace:
- `${JENKINS_ADMIN_PASSWORD}` - Jenkins admin password
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

#### `terraform/modules/argo-cd/charts/values.yaml`
Replace:
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

#### `terraform/modules/monitoring/values.yaml`
Replace:
- `${GRAFANA_ADMIN_PASSWORD}` - Grafana admin password

#### `django/Jenkinsfile`
Replace:
- `${AWS_ACCOUNT_ID}` - AWS account ID
- `${AWS_REGION}` - AWS region
- `${ECR_REPOSITORY_NAME}` - ECR repository name
- `${GITHUB_USERNAME}` - GitHub username
- `${GITHUB_REPO}` - GitHub repository name
- `${GITHUB_BRANCH}` - GitHub branch name

## How to Use Variables

### Terraform Variables

All Terraform variables are defined in `terraform/variables.tf`. You can set them in three ways:

1. **terraform.tfvars file** (recommended):
```hcl
name = "my-project"
aws_account_id = "123456789012"
```

2. **Command line**:
```bash
terraform apply -var="name=my-project" -var="aws_account_id=123456789012"
```

3. **Environment variables**:
```bash
export TF_VAR_name="my-project"
export TF_VAR_aws_account_id="123456789012"
terraform apply
```

### YAML Variables

YAML files use placeholder syntax `${VARIABLE_NAME}`. These need to be replaced manually with actual values before deployment, or you can use a templating tool like `envsubst`:

```bash
export JENKINS_ADMIN_PASSWORD="your-password"
export GITHUB_USERNAME="your-username"
envsubst < modules/jenkins/values.yaml > modules/jenkins/values-resolved.yaml
```

### Jenkinsfile Variables

Jenkinsfile uses environment variables. Set them in Jenkins job configuration or in the Jenkinsfile itself:

```groovy
environment {
  AWS_ACCOUNT_ID = "123456789012"
  AWS_REGION = "us-east-1"
  ECR_REPOSITORY_NAME = "my-ecr-repo"
}
```

## Terraform Setup

1. Go to the Terraform directory:

```bash
cd terraform
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the execution plan:

```bash
terraform plan
```

4. Apply the infrastructure:

```bash
terraform apply
```

5. Destroy infrastructure (when needed):

```bash
terraform destroy
```

## Configure Kubernetes Access

After Terraform creates the EKS cluster, configure your kubeconfig:

```bash
aws eks --region ${AWS_REGION} update-kubeconfig --name eks-cluster-${PROJECT_NAME}
```

Verify cluster access:

```bash
kubectl get nodes
```

If nodes show `Ready`, your cluster is ready.

## Build and Push Docker Image

### Mac/Linux version

1. Authenticate Docker with AWS ECR:

```bash
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

2. Build and push the image:

```bash
docker buildx build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:${VERSION} --push .
```

Replace:
- `${AWS_ACCOUNT_ID}` - Your AWS account ID
- `${AWS_REGION}` - Your AWS region
- `${ECR_REPOSITORY_NAME}` - Your ECR repository name
- `${VERSION}` - Image version tag

## Jenkins and ArgoCD

### Access Jenkins

1. Get Jenkins LoadBalancer URL:
```bash
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Or use port-forward:
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:80
```

3. Login with:
   - Username: `admin`
   - Password: From `terraform/modules/jenkins/values.yaml` (or your configured password)

### Access ArgoCD

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

### Access Grafana

1. Port-forward Grafana service:
```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

2. Access Grafana:
   - Open `http://localhost:3000` in browser
   - Login with:
     - Username: `admin`
     - Password: From `terraform/modules/monitoring/values.yaml` (or your configured password)

## RDS Configuration

The RDS module supports both standard RDS and Aurora PostgreSQL. To change the database type, set the `rds_use_aurora` variable in `terraform.tfvars`:

```hcl
rds_use_aurora = true  # true for Aurora, false for standard RDS
```

### Changing RDS Parameters

Edit `terraform/terraform.tfvars`:

```hcl
# For Aurora
rds_use_aurora = true
rds_aurora_engine = "aurora-postgresql"
rds_aurora_engine_version = "15.3"

# For Standard RDS
rds_use_aurora = false
rds_instance_engine = "postgres"
rds_instance_engine_version = "17.2"
rds_instance_class = "db.t3.micro"
```

## General Maintenance

If you need to make changes to Jenkins or ArgoCD:

1. Uninstall Helm releases:
```bash
helm uninstall jenkins -n jenkins
helm uninstall argo-cd -n argocd
helm uninstall argo-cd-apps -n argocd
```

2. Reapply Terraform:
```bash
cd terraform
terraform apply
```

## Variables Reference

### Main Variables (terraform/variables.tf)

| Variable | Type | Description | Required | Default |
|----------|------|-------------|-----------|---------|
| `name` | `string` | Project name for resource naming | ✅ | - |
| `aws_region` | `string` | AWS region | ❌ | `us-east-1` |
| `aws_account_id` | `string` | AWS account ID | ✅ | - |
| `s3_backend_bucket` | `string` | S3 bucket for Terraform state | ✅ | - |
| `ecr_repository_name` | `string` | ECR repository name | ✅ | - |
| `github_username` | `string` | GitHub username | ✅ | - |
| `github_repo` | `string` | GitHub repository name | ✅ | - |
| `github_branch` | `string` | GitHub branch name | ❌ | `main` |
| `jenkins_admin_password` | `string` | Jenkins admin password (sensitive) | ✅ | - |
| `grafana_admin_password` | `string` | Grafana admin password (sensitive) | ✅ | - |
| `rds_password` | `string` | RDS database password (sensitive) | ✅ | - |
| `rds_username` | `string` | RDS username | ❌ | `postgres` |
| `rds_database_name` | `string` | Database name | ❌ | `myapp` |
| `rds_use_aurora` | `bool` | Use Aurora cluster | ❌ | `false` |
| `rds_instance_class` | `string` | RDS instance class | ❌ | `db.t3.micro` |
| `rds_publicly_accessible` | `bool` | Publicly accessible RDS | ❌ | `false` |
| `rds_multi_az` | `bool` | Multi-AZ deployment | ❌ | `true` |

## Important Notes

- **Security**: Never commit `terraform.tfvars` or files with real passwords to Git
- **Backend**: Update `terraform/backend.tf` with your S3 bucket name before first `terraform init`
- **YAML Variables**: Replace all `${VARIABLE}` placeholders in YAML files with actual values
- **Production**: This configuration is for development/testing. Adjust security settings for production use
- **Sensitive Data**: All passwords and secrets should be stored securely (AWS Secrets Manager, environment variables, etc.)

## Troubleshooting

- **Terraform errors**: Check AWS credentials and permissions
- **Jenkins pipeline fails**: Verify GitHub token and ECR permissions
- **ArgoCD sync issues**: Check repository access and branch name
- **Database connection**: Verify RDS endpoint and security group rules
- **Application not accessible**: Check service and pod status with `kubectl get pods -n default`
