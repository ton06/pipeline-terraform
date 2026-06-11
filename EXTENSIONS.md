# Extensões Futuras Possíveis para o Projeto Windrose

Este arquivo documenta possíveis melhorias e extensões para o deployment do Windrose usando Terraform.

## 1. Load Balancer + Auto Scaling

```hcl
# Application Load Balancer
resource "aws_lb" "windrose_alb" {
  name_prefix = "wr"
  internal    = false
  load_balancer_type = "application"
  
  tags = {
    Name = "windrose-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "windrose_tg" {
  name_prefix = "wr"
  port        = var.windrose_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "windrose_asg" {
  vpc_zone_identifier  = [data.aws_subnet.default.id]
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  
  launch_template {
    id      = aws_launch_template.windrose_lt.id
    version = "$Latest"
  }
  
  target_group_arns    = [aws_lb_target_group.windrose_tg.arn]
}
```

## 2. Database (RDS)

```hcl
# RDS PostgreSQL
resource "aws_db_instance" "windrose_db" {
  allocated_storage    = 20
  db_name              = "windrose"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  username             = "windrose_admin"
  password             = var.db_password  # Use Secrets Manager em produção
  skip_final_snapshot  = true  # Mude para false em produção
  
  db_subnet_group_name      = aws_db_subnet_group.windrose.id
  vpc_security_group_ids    = [aws_security_group.windrose_db.id]
  publicly_accessible       = false
  
  tags = {
    Name = "windrose-database"
  }
}
```

## 3. Secrets Manager

```hcl
# Armazenar credenciais de forma segura
resource "aws_secretsmanager_secret" "windrose_secrets" {
  name_prefix = "windrose/"
}

resource "aws_secretsmanager_secret_version" "windrose_secrets" {
  secret_id = aws_secretsmanager_secret.windrose_secrets.id
  secret_string = jsonencode({
    db_password = random_password.db_password.result
    api_key     = random_password.api_key.result
  })
}

# EC2 pode ler do Secrets Manager
resource "aws_iam_role_policy" "windrose_secrets_access" {
  name_prefix = "windrose-secrets-access-"
  role        = aws_iam_role.windrose_ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.windrose_secrets.arn
    }]
  })
}
```

## 4. Container Registry (ECR)

```hcl
# Usar imagem customizada do ECR
resource "aws_ecr_repository" "windrose" {
  name                 = "windrose-server"
  image_tag_mutability = "IMMUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Environment = var.environment
  }
}

# Output para push de imagens
output "ecr_repository_url" {
  value = aws_ecr_repository.windrose.repository_url
}
```

## 5. VPC e Subnets Customizados

```hcl
# VPC dedicada
resource "aws_vpc" "windrose_vpc" {
  cidr_block = "10.0.0.0/16"
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "windrose-vpc"
  }
}

# Subnet Pública
resource "aws_subnet" "windrose_public" {
  vpc_id              = aws_vpc.windrose_vpc.id
  cidr_block          = "10.0.1.0/24"
  availability_zone   = data.aws_availability_zones.available.names[0]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "windrose-public-subnet"
  }
}

# Subnet Privada para DB
resource "aws_subnet" "windrose_private" {
  vpc_id            = aws_vpc.windrose_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "windrose-private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "windrose_igw" {
  vpc_id = aws_vpc.windrose_vpc.id
  
  tags = {
    Name = "windrose-igw"
  }
}

# NAT Gateway para saída privada
resource "aws_eip" "windrose_nat" {
  domain = "vpc"
  tags = {
    Name = "windrose-nat-ip"
  }
}

resource "aws_nat_gateway" "windrose_nat" {
  allocation_id = aws_eip.windrose_nat.id
  subnet_id     = aws_subnet.windrose_public.id
  
  depends_on = [aws_internet_gateway.windrose_igw]
  
  tags = {
    Name = "windrose-nat"
  }
}
```

## 6. CDN (CloudFront)

```hcl
# CloudFront para asset delivery
resource "aws_cloudfront_distribution" "windrose" {
  origin {
    domain_name = aws_eip.windrose_eip.public_ip
    origin_id   = "windrose"
    
    custom_origin_config {
      http_port              = var.windrose_port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled = true
  
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "windrose"
    
    forwarded_values {
      query_string = true
      
      cookies {
        forward = "all"
      }
      
      headers = [
        "*"
      ]
    }
    
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "windrose-cdn"
  }
}
```

## 7. Route 53 (DNS)

```hcl
# Domínio customizado
resource "aws_route53_zone" "windrose" {
  name = "windrose.example.com"
  
  tags = {
    Environment = var.environment
  }
}

# Record A apontando para Elastic IP
resource "aws_route53_record" "windrose_server" {
  zone_id = aws_route53_zone.windrose.zone_id
  name    = "api.windrose.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_eip.windrose_eip.public_ip]
}
```

## 8. Backup Automático (Snapshots)

```hcl
# AWS Backup
resource "aws_backup_vault" "windrose" {
  name = "windrose-backup-vault"
  
  tags = {
    Environment = var.environment
  }
}

# Criar snapshots diários
resource "aws_backup_plan" "windrose" {
  name = "windrose-daily-backup"
  
  rule {
    rule_name         = "windrose_daily_backup"
    target_backup_vault_name = aws_backup_vault.windrose.name
    schedule          = "cron(0 5 ? * * *)"  # 5 AM UTC
    
    lifecycle {
      delete_after = 30  # Manter por 30 dias
    }
  }
}

# Backup das instâncias
resource "aws_backup_resource_assignment" "windrose_instance" {
  name             = "windrose-instance-backup"
  backup_plan_id   = aws_backup_plan.windrose.id
  iam_role_arn     = aws_iam_role.windrose_backup.arn
  
  resources = [
    aws_instance.windrose_server.arn
  ]
}
```

## 9. Terraform Modules

Refatorar em módulos reutilizáveis:

```
modules/
├── ec2/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── database/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── monitoring/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## 10. CI/CD Pipeline para Deploy

```yaml
# GitHub Actions / GitLab CI
name: Terraform Deploy

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Plan
        run: terraform plan -var-file="environments/dev/terraform.tfvars"
        
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve -var-file="environments/dev/terraform.tfvars"
```

## Implementação Priorizada

1. **Alta Prioridade**: VPC customizada, RDS, Secrets Manager
2. **Média Prioridade**: CloudWatch Logs, Auto Scaling, Load Balancer
3. **Baixa Prioridade**: CDN, Route 53, CI/CD pipeline

## Próximos Passos

1. Testar o setup básico
2. Adicionar CloudWatch Logs (arquivo cloudwatch_monitoring.tf.disabled)
3. Implementar VPC customizada
4. Adicionar banco de dados RDS
5. Configurar load balancing e auto scaling

