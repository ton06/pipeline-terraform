# =============================================================================
# main.tf — Recursos principais da infraestrutura Windrose na AWS
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

# AMI mais recente do Windows Server 2022 Base (64-bit x86)
# O Windrose Dedicated Server e Windows-only (confirmado no guia oficial).
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
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
  description = "Security Group do servidor Windrose. RDP restrito ao admin, porta do jogo aberta para conexoes dos jogadores."
  vpc_id      = data.aws_vpc.default.id

  # RDP — acesso remoto ao Windows Server (restrito ao IP do admin)
  ingress {
    description = "RDP - Remote Desktop do administrador"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr_ssh]
  }

  # Porta do jogo — TCP (conexao direta dos jogadores)
  ingress {
    description = "Windrose - Direct Connection TCP"
    from_port   = var.direct_connection_port
    to_port     = var.direct_connection_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Porta do jogo — UDP (obrigatorio para conexao direta conforme guia oficial)
  ingress {
    description = "Windrose - Direct Connection UDP"
    from_port   = var.direct_connection_port
    to_port     = var.direct_connection_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saida irrestrita — necessario para SteamCMD baixar o servidor
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
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.windrose.id]

  # EBS root volume — minimo de 35 GB SSD conforme requisitos do guia oficial
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50  # 50 GB: 35 GB do jogo + margem para SO e saves
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "windrose-server-disk"
    }
  }

  # User Data: PowerShell executado automaticamente na primeira inicializacao.
  # Instala SteamCMD e baixa o Windrose Dedicated Server (App ID 4129620).
  user_data = templatefile("${path.module}/scripts/setup_windrose.ps1", {
    server_name            = var.server_name
    invite_code            = var.invite_code
    server_password        = var.server_password
    max_players            = var.max_players
    direct_connection_port = var.direct_connection_port
    world_preset           = var.world_preset
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
