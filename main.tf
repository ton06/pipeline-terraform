# =============================================================================
# main.tf — Recursos principais da infraestrutura Windrose na AWS
# Imagem Docker: indifferentbroccoli/windrose-server-docker
# SO: Ubuntu 24.04 LTS
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State armazenado localmente.
  # Para uso em equipe, considere migrar para S3 backend com DynamoDB lock:
  # https://developer.hashicorp.com/terraform/language/backend/s3
  backend "local" {}
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

# AMI mais recente do Ubuntu 24.04 LTS (64-bit x86)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "windrose" {
  name        = "windrose-server-sg"
  description = "Security Group do servidor Windrose. SSH restrito ao admin, porta do jogo aberta para jogadores."
  vpc_id      = data.aws_vpc.default.id

  # SSH — acesso ao servidor Linux (restrito ao IP do admin)
  ingress {
    description = "SSH - Acesso do administrador"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_ssh]
  }

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

  # Saida irrestrita — necessario para Docker puxar a imagem
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
  key_name               = var.key_pair_name
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
