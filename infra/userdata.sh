#!/bin/bash
set -e

echo "Starting Windrose Game Server setup..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io

# Start Docker daemon
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group (allow running docker without sudo)
usermod -aG docker ubuntu

echo "Docker installed successfully"

# Pull and run Windrose Server Docker image
echo "Starting Windrose Server container..."
docker run -d \
  --name windrose-server \
  --restart unless-stopped \
  -p ${windrose_port}:8000 \
  --log-driver awslogs \
  --log-opt awslogs-group=/aws/ec2/windrose-server \
  --log-opt awslogs-region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region) \
  --log-opt awslogs-stream=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
  indifferentbroccoli/windrose-server:latest

echo "Windrose Server container started"
echo "Server running on port ${windrose_port}"

# Log completion
echo "Setup completed successfully at $(date)" >> /var/log/windrose-setup.log

