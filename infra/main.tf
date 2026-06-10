# =============================================================================
# main.tf — Recursos principais da infraestrutura Windrose na AWS
# Imagem Docker: indifferentbroccoli/windrose-server-docker
# SO: Ubuntu 26.04 LTS
# Acesso: IAM Instance Profile + SSM Session Manager (sem key pair / sem SSH)
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto no S3 — configurado via -backend-config pelo workflow ton06/workflows
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "windrose-server"
      ManagedBy   = "terraform"
      Environment = "game"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# AMI mais recente do Ubuntu 26.04 LTS (64-bit x86)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-plucky-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# VPC padrao da conta AWS na regiao configurada
data "aws_vpc" "default" {
  default = true
}

# -----------------------------------------------------------------------------
# IAM Role + Instance Profile (SSM Session Manager)
# Permite acesso ao terminal da EC2 direto pelo console AWS,
# sem necessidade de key pair ou regra SSH no Security Group.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "windrose_ssm" {
  name = "windrose-server-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "windrose_ssm" {
  role       = aws_iam_role.windrose_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "windrose_ssm" {
  name = "windrose-server-ssm-profile"
  role = aws_iam_role.windrose_ssm.name
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "windrose" {
  name        = "windrose-server-sg"
  description = "Security Group do servidor Windrose. Porta do jogo aberta para jogadores, sem SSH exposto."
  vpc_id      = data.aws_vpc.default.id

  # Porta do jogo — TCP (conexao direta dos jogadores)
  ingress {
    description = "Windrose - Direct Connection TCP"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Porta do jogo — UDP (obrigatorio para conexao direta)
  ingress {
    description = "Windrose - Direct Connection UDP"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saida irrestrita — necessario para Docker puxar a imagem e SSM Agent comunicar
  egress {
    description = "Saida irrestrita"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "windrose-server-sg"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------

resource "aws_instance" "windrose" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.windrose_ssm.name
  vpc_security_group_ids = [aws_security_group.windrose.id]

  # EBS root volume — 50 GB gp3 SSD para SO + imagem Docker + saves do servidor
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "windrose-server-disk"
    }
  }

  # User Data: instala Docker e sobe o container do Windrose automaticamente
  user_data = templatefile("${path.module}/scripts/setup_docker.sh", {
    server_name           = var.server_name
    invite_code           = var.invite_code
    server_password       = var.server_password
    max_players           = var.max_players
    server_port           = var.server_port
    use_direct_connection = var.use_direct_connection
    update_on_start       = var.update_on_start
  })

  user_data_replace_on_change = false

  tags = {
    Name = "windrose-server"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP — IP fixo para o servidor nao mudar entre reinicializacoes
# -----------------------------------------------------------------------------

resource "aws_eip" "windrose" {
  instance = aws_instance.windrose.id
  domain   = "vpc"

  tags = {
    Name = "windrose-server-eip"
  }
}
