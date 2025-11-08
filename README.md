# Lesson 5 Terraform AWS

## Структура проєкту

```
lesson-5/
├── main.tf           # Підключення модулів
├── backend.tf        # Налаштування бекенду (S3 + DynamoDB)
├── outputs.tf        # Глобальні outputs
├── modules/
│   ├── s3-backend/   # S3 bucket + DynamoDB для Terraform state
│   ├── vpc/          # VPC, підмережі, IGW, NAT, маршрути
│   └── ecr/          # ECR репозиторій і політика доступу
└── README.md
```

## Модулі

- `s3-backend`: створює S3 бакет з версіюванням, DynamoDB таблицю для блокувань, віддає імена/ARN.
- `vpc`: піднімає VPC 10.0.0.0/16, 3 public + 3 private підмережі, Internet Gateway, NAT Gateways, таблиці маршрутів.
- `ecr`: створює ECR репозиторій зі scan on push і політикою на повний доступ власному акаунту.

## Команди

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### Перший запуск (коли бекенд ще не створений)

```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply
mv backend.tf.disabled backend.tf
terraform init -migrate-state
```

## Вимоги

- Terraform >= 1.6.0
- AWS провайдер ~> 5.0
- Налаштований `aws configure` з потрібним профілем/ключами
