# DevOps CI/CD Infrastructure

This project contains Terraform infrastructure for deploying a Django application on AWS EKS with Jenkins CI/CD and ArgoCD for GitOps.

## Overview

The infrastructure includes:
- AWS EKS cluster for container orchestration
- Jenkins for CI/CD pipelines
- ArgoCD for GitOps deployments
- ECR for Docker image registry
- Helm charts for application deployment

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed
3. kubectl installed
4. Helm installed
5. GitHub Personal Access Token (PAT)

## Configuration

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Fill in all required variables in `terraform.tfvars`:
- `project_name` - Your project name
- `environment` - Environment name (dev, staging, prod)
- `github_username` - Your GitHub username
- `github_repo` - Your repository name
- `github_branch` - Branch name (e.g., lesson-8-9)
- `aws_account_id` - Your AWS account ID
- `ecr_repository_name` - ECR repository name
- `postgres_password` - Database password
- `jenkins_admin_password` - Jenkins admin password

3. Update YAML files with your values:
- `modules/jenkins/values.yaml` - Replace `${GITHUB_USERNAME}`, `${GITHUB_REPO}`, `${GITHUB_BRANCH}`, `${JENKINS_ADMIN_USERNAME}`, `${JENKINS_ADMIN_PASSWORD}`
- `modules/argo-cd/charts/values.yaml` - Replace `${GITHUB_USERNAME}`, `${GITHUB_REPO}`, `${GITHUB_BRANCH}`
- `charts/django-app/values.yaml` - Replace `${AWS_ACCOUNT_ID}`, `${AWS_REGION}`, `${ECR_REPOSITORY_NAME}`, `${POSTGRES_PASSWORD}`
- `django/Jenkinsfile` - Replace `${AWS_ACCOUNT_ID}`, `${AWS_REGION}`, `${ECR_REPOSITORY_NAME}`, `${GITHUB_USERNAME}`, `${GITHUB_REPO}`, `${GITHUB_BRANCH}`

4. Update `backend.tf` with your S3 bucket name for Terraform state.

## Terraform

In terraform we add new module for EKS:

```hcl


data "aws_eks_cluster" "eks" {
  name = module.eks.eks_cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.eks_cluster_name

  depends_on = [module.eks]
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}


module "jenkins" {
  source       = "./modules/jenkins"
  cluster_name = module.eks.eks_cluster_name
  providers = {
    helm = helm
  }
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  depends_on = [
    module.eks
  ]
}


module "argo_cd" {
  source        = "./modules/argo-cd"
  namespace     = "argocd"
  chart_version = "5.46.4"
}



```

## Як застосувати Terraform (How to apply Terraform)

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

4. Confirm the apply by typing `yes` when prompted.

5. Wait for all resources to be created (this may take 15-20 minutes):
- VPC and subnets
- EKS cluster and node groups
- ECR repository
- Jenkins deployment
- ArgoCD deployment

6. After completion, save the ECR repository URL from the output - it will be used to push images.

7. Get kubeconfig for the EKS cluster:
```bash
aws eks --region ${AWS_REGION} update-kubeconfig --name eks-${PROJECT_NAME}-${ENVIRONMENT}-cluster
```

8. Verify cluster access:
```bash
kubectl get nodes
```

After all infrastructure is created, save ECR repository URL - it will be used to push image to ECR.

Provide it to Jenkinsfile:

```Jenkinsfile
ECR_REGISTRY = "your-account-id.dkr.ecr.eu-central-1.amazonaws.com"
IMAGE_NAME   = "${ECR_REPOSITORY_NAME}"
```

## EKS

For EKS cluster we need to get kubeconfig file

`aws eks --region ${AWS_REGION} update-kubeconfig --name eks-${PROJECT_NAME}-${ENVIRONMENT}-cluster`

Check if it is working:

`kubectl get nodes`

After this we can comment our providers in main.tf file
and use the local config:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
```

## Jenkins

Jenkins is autoconfigured using JCasC.

Add credentials to jenkins:

```yaml
credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - usernamePassword:
                      scope: GLOBAL
                      id: github-token
                      username: ${GITHUB_USERNAME}
                      password: # provide your github token here
                      description: GitHub PAT
```

Add new job to jenkins:

```yaml
jobs:
- script: |
    folder('jcasc') # create folder jcasc

- script: |
    pipelineJob("jcasc/goit-django-docker")  # create pipeline job
    ....
```

After configuration, you can run pipeline jobs to build and deploy the application.

## Як перевірити Jenkins job (How to check Jenkins job)

1. Get Jenkins LoadBalancer URL:
```bash
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Access Jenkins UI in browser using the LoadBalancer URL (or use port-forward):
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:80
```
Then open `http://localhost:8080` in browser.

3. Login with credentials from `modules/jenkins/values.yaml`:
- Username: `${JENKINS_ADMIN_USERNAME}` (default: admin)
- Password: `${JENKINS_ADMIN_PASSWORD}`

4. Navigate to the pipeline job:
- Go to `jcasc` folder
- Open `goit-django-docker` pipeline job

5. Check job status:
- Click on the job name
- View "Build History" to see all builds
- Click on a build number to see details
- Check "Console Output" to see build logs

6. Trigger a new build:
- Click "Build Now" button
- Monitor the build progress in real-time
- Verify that the pipeline:
  - Builds Docker image
  - Pushes to ECR
  - Updates Git repository with new image tag

7. Verify Git commit:
- Check your GitHub repository
- Confirm that `charts/django-app/values.yaml` was updated with new image tag

## ArgoCD

ArgoCD is autoconfigured using helm chart.
In the argocd module we provide values.yaml file with the values for the chart to add application automatically:

```yaml
repositories:
  - name: goit-devops-django-app
    username: ${GITHUB_USERNAME}
    password: # provide your github token here
```

After argocd module is deployed by terraform and helm chart is deployed, the application will be available in ArgoCD UI.

## Як побачити результат в Argo CD (How to see the result in Argo CD)

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
- Login with credentials:
  - Username: `admin`
  - Password: (from step 1)

4. View applications:
- Click on "Applications" in the left menu
- You should see your application (e.g., `example-app`)
- Check application status:
  - **Synced** - Application is synchronized with Git
  - **Healthy** - All resources are healthy
  - **OutOfSync** - Changes detected in Git that need to be synced

5. View application details:
- Click on the application name
- See the application topology (resources tree)
- Check sync status and health of each resource
- View application logs and events

6. Manual sync (if needed):
- Click "Sync" button
- Select resources to sync
- Click "Synchronize"

7. View deployed application:
- Port-forward to Django service:
```bash
kubectl port-forward svc/django-app-service -n default 8000:8000
```
- Open `http://localhost:8000` in browser to see the Django application

8. Monitor synchronization:
- ArgoCD automatically syncs when changes are detected in Git
- After Jenkins updates the image tag in Git, ArgoCD will detect the change
- The application will be automatically updated with the new image
