# 🏴‍☠️ Windrose Server — AWS

EC2 Ubuntu 24.04 + Docker ([indifferentbroccoli/windrose-server-docker](https://github.com/indifferentbroccoli/windrose-server-docker)) + SSM Session Manager.

## Setup

```bash
cp terraform.tfvars.example terraform.tfvars
# edite o terraform.tfvars se quiser mudar nome, senha, jogadores etc.
terraform init && terraform apply
```

## Acesso ao servidor

```bash
# Terminal na EC2
aws ssm start-session --target <instance_id> --region sa-east-1

# Log do setup
cat /var/log/windrose-setup.log

# Logs do container
docker compose -f /opt/windrose/docker-compose.yml logs -f
```

## Ligar / desligar

```bash
./scripts/manage_instance.sh start
./scripts/manage_instance.sh stop
./scripts/manage_instance.sh status
```

## Atualizar o servidor

```bash
sudo /opt/windrose/update_server.sh
```

## Destruir

```bash
terraform destroy
# faca backup de /opt/windrose/server-files/ antes
```
