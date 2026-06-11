# Security Group for Windrose Game Server
# IAM Role para Systems Manager (acesso sem SSH)
resource "aws_iam_role" "windrose_ssm_role" {
  name_prefix = "windrose-ssm-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.windrose_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "windrose_profile" {
  name_prefix = "windrose-profile-"
  role        = aws_iam_role.windrose_ssm_role.name
}

resource "aws_security_group" "windrose_sg" {
  name_prefix = "windrose-sg-"
  description = "Security group for Windrose game server"

  tags = {
    Name = "windrose-security-group"
  }
}


# Allow Windrose game server port
resource "aws_security_group_rule" "allow_windrose" {
  type              = "ingress"
  from_port         = var.windrose_port
  to_port           = var.windrose_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windrose_sg.id
}

# Allow UDP for game server (if needed)
resource "aws_security_group_rule" "allow_windrose_udp" {
  type              = "ingress"
  from_port         = var.windrose_port
  to_port           = var.windrose_port
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windrose_sg.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windrose_sg.id
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for Windrose Game Server
resource "aws_instance" "windrose_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.windrose_profile.name
  vpc_security_group_ids = [aws_security_group.windrose_sg.id]
  subnet_id              = data.aws_subnet.default.id

  # Associate public IP address
  associate_public_ip_address = true

  # User data script to install Docker and run windrose-server
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    windrose_port = var.windrose_port
  }))

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Application = "windrose-game-server"
  }

  monitoring = true
}

# Elastic IP for static public IP
resource "aws_eip" "windrose_eip" {
  instance = aws_instance.windrose_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.instance_name}-eip"
    Environment = var.environment
  }

  depends_on = [aws_instance.windrose_server]
}

# Outputs
output "windrose_server_public_ip" {
  description = "Public IP address of the Windrose game server"
  value       = aws_eip.windrose_eip.public_ip
}

output "windrose_server_instance_id" {
  description = "Instance ID of the Windrose game server"
  value       = aws_instance.windrose_server.id
}

output "windrose_server_private_ip" {
  description = "Private IP address of the Windrose game server"
  value       = aws_instance.windrose_server.private_ip
}

output "windrose_server_url" {
  description = "URL to access the Windrose game server"
  value       = "http://${aws_eip.windrose_eip.public_ip}:${var.windrose_port}"
}

