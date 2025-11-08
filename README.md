# Lesson 7 – Terraform + EKS + Helm

## Структура

```
lesson-7/
├── terraform/
│   ├── backend.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── s3-backend/
│       ├── vpc/
│       ├── ecr/
│       └── eks/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            ├── hpa.yaml
            └── ingress.yaml
```

## Терраформ

1. **Перший запуск без бекенда**
   ```bash
   cd terraform
   mv backend.tf backend.tf.disabled
   terraform init
   terraform apply
   ```

2. **Увімкнути бекенд**
   ```bash
   mv backend.tf.disabled backend.tf
   terraform init -migrate-state
   ```

3. **Базові команди**
   ```bash
   terraform plan
   terraform apply
   terraform destroy
   ```

4. **Оновити kubeconfig**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster
   kubectl get nodes
   ```

## ECR та Docker

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

docker buildx build --platform linux/amd64 -t lesson-7-ecr:latest .
docker tag lesson-7-ecr:latest <account>.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr:latest
```

## Helm

```bash
helm upgrade --install django-app ./charts/django-app \
  --set image.repository=<account>.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr \
  --set image.tag=latest

kubectl get svc django-app-django
kubectl get hpa django-app-hpa
```

### Ingress (опційно)

У `values.yaml` виставити:
```yaml
ingress:
  enabled: true
  className: nginx
  host: app.example.com
  tls: true
```
Потім встановити cert-manager та nginx ingress controller.

## Outputs

- `s3_bucket_name`, `s3_bucket_arn`
- `eks_cluster_endpoint`, `eks_cluster_certificate_authority`
- `ecr_repository_url`
- `nat_gateway_ids`, `public_subnet_ids`, `private_subnet_ids`

Ці значення потрібні для kubeconfig та деплою застосунку.
