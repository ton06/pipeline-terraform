# Comandos Úteis para Terraform + Windrose Server

## Inicialização

```bash
# Inicializar Terraform na pasta infra
cd infra
terraform init

# Com backend remoto específico
terraform init -backend-config="bucket=seu-bucket" -backend-config="key=terraform/dev/prod.tfstate"
```

## Planejamento e Aplicação

```bash
# Planejar mudar para ambiente dev
terraform plan -var-file="environments/dev/terraform.tfvars" -out=plan.tfplan

# Aplicar o plano
terraform apply plan.tfplan

# Aplicar diretamente (sem plano)
terraform apply -var-file="environments/dev/terraform.tfvars"

# Aplicar com aprovação automática (útil em CI/CD)
terraform apply -auto-approve -var-file="environments/dev/terraform.tfvars"
```

## Leitura de Estado

```bash
# Ver todos os outputs
terraform output

# Ver um output específico
terraform output windrose_server_public_ip

# Para usar em scripts
IP=$(terraform output -raw windrose_server_public_ip)
echo $IP

# Ver estado completo
terraform state list
terraform state show aws_instance.windrose_server
```

## Destruição

```bash
# Destruir com confirmação
terraform destroy -var-file="environments/dev/terraform.tfvars"

# Destruir sem confirmação (cuidado!)
terraform destroy -auto-approve -var-file="environments/dev/terraform.tfvars"

# Remover recurso específico do estado
terraform state rm aws_instance.windrose_server
```

## Debugging e Logs

```bash
# Modo verbose (mostra requisições HTTP)
TF_LOG=TRACE terraform plan -var-file="environments/dev/terraform.tfvars"

# Modo debug
TF_LOG=DEBUG terraform apply -var-file="environments/dev/terraform.tfvars"

# Salvar log em arquivo
TF_LOG=INFO TF_LOG_PATH=terraform.log terraform plan -var-file="environments/dev/terraform.tfvars"

# Debug do provedor AWS
TF_LOG_AWS_SDK=TRACE terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Validação

```bash
# Validar sintaxe HCL
terraform validate

# Formatar código Terraform
terraform fmt -recursive

# Verificar formatação sem aplicar
terraform fmt -check -recursive
```

## Importar Recursos Existentes

```bash
# Se você tem uma EC2 instance existente que quer gerenciar
terraform import aws_instance.windrose_server i-0123456789abcdef0

# Se você tem um security group existente
terraform import aws_security_group.windrose_sg sg-0123456789abcdef0
```

## Acessar o Servidor

```bash
# Obter IP e conectar via SSH
IP=$(terraform output -raw windrose_server_public_ip)
ssh -i sua-chave.pem ubuntu@$IP

# Ver logs de inicialização da instância
aws ec2 get-console-output --instance-id $(terraform output -raw windrose_server_instance_id)

# Ver logs do cloud-init na instância
ssh -i sua-chave.pem ubuntu@$IP tail -f /var/log/cloud-init-output.log

# Ver logs do Windrose
ssh -i sua-chave.pem ubuntu@$IP docker logs windrose-server

# Monitorar logs em tempo real
ssh -i sua-chave.pem ubuntu@$IP docker logs -f windrose-server
```

## Gerenciador de Múltiplos Ambientes

```bash
# Criar workspaces para diferentes ambientes
terraform workspace new dev
terraform workspace new main
terraform workspace new staging

# Listar workspaces
terraform workspace list

# Mudar de workspace
terraform workspace select dev

# Usar workspace em comandos
terraform plan -var-file="environments/dev/terraform.tfvars"

# Com workspace, você pode ter different states
terraform workspace select main
terraform apply -var-file="environments/main/terraform.tfvars"
```

## Monitoramento com AWS CLI

```bash
# Verificar status da instância
aws ec2 describe-instances --instance-ids $(terraform output -raw windrose_server_instance_id)

# Ver grupos de segurança
aws ec2 describe-security-groups --group-ids $(terraform output -raw windrose_sg_id) 2>/dev/null || echo "Adicione output para SG ID"

# Ver Elastic IP
aws ec2 describe-addresses --allocation-ids $(terraform output -raw windrose_eip_allocation_id) 2>/dev/null

# Iniciar/parar instância
aws ec2 stop-instances --instance-ids $(terraform output -raw windrose_server_instance_id)
aws ec2 start-instances --instance-ids $(terraform output -raw windrose_server_instance_id)
```

## Limpeza e Manutenção

```bash
# Limpar cache do Terraform
rm -rf .terraform

# Refazer plan
terraform refresh

# Migrar o estado de um local para outro
terraform state push-remote

# Fazer backup do estado
cp terraform.tfstate terraform.tfstate.backup
```

## Dicas de Performance

```bash
# Parallelizar operações (padrão é 10)
terraform apply -parallelism=20 -var-file="environments/dev/terraform.tfvars"

# Ver tempos de operação
time terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Troubleshooting

```bash
# Se a instância não inicia corretamente:
# 1. Verificar logs de user data
ssh -i sua-chave.pem ubuntu@IP
sudo cat /var/log/cloud-init-output.log

# 2. Verificar status da instância no console AWS
aws ec2 describe-instance-status --instance-ids $(terraform output -raw windrose_server_instance_id)

# 3. Verificar grupo de segurança
aws ec2 describe-security-groups --group-ids <sg-id>

# 4. Verificar Docker
docker ps -a
docker logs windrose-server

# Se precisa fazer rollback:
terraform state list
terraform destroy -var-file="environments/dev/terraform.tfvars"
# Editar terraform.tfvars se necessário
terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Variáveis Globais

```bash
# Passar variáveis nas flags
terraform apply \
  -var="environment=dev" \
  -var="ec2_key_name=my-key" \
  -var="windrose_port=8000"

# Usando arquivo de variáveis
terraform apply -var-file="custom.tfvars"

# Múltiplos arquivos de variáveis (últimas vencem)
terraform apply \
  -var-file="base.tfvars" \
  -var-file="environments/dev/terraform.tfvars" \
  -var="ec2_key_name=override-key"
```

