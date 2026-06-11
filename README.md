# Terraform Pipeline - Windrose Game Server

## Descrição

Este projeto Terraform provisiona uma infraestrutura AWS com:
- **S3 Bucket**: Para armazenamento em nuvem
- **EC2 Instance**: Servidor para hospedar o jogo Windrose
- **Security Groups**: Configurações de firewall
- **Elastic IP**: IP público estático para o servidor

## Estrutura de Diretórios

```
infra/
├── main.tf              # Recurso S3
├── ec2_windrose.tf      # Recursos da instância EC2 (Security Group, EC2, Elastic IP)
├── variables.tf         # Definição de variáveis
├── providers.tf         # Configuração de providers (AWS)
├── backend.tf           # Configuração de backend (S3)
├── userdata.sh          # Script de inicialização da EC2
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars      # Variáveis para dev
│   └── main/
│       └── terraform.tfvars      # Variáveis para main
```

## Pré-requisitos

1. **Terraform** instalado (versão 1.0+)
2. **AWS CLI** configurado com suas credenciais
3. **Uma key pair EC2** criada na AWS (você precisa do nome da chave)
4. **Um bucket S3** já existente para armazenar o state do Terraform

## Configuração Inicial

### 1. Editar as variáveis de ambiente

Edite o arquivo `infra/environments/dev/terraform.tfvars` (ou o ambiente desejado):

```hcl
bucket_name = "seu-bucket-terraform-state"
ec2_key_name = "sua-chave-ec2"  # IMPORTANTE: Mude para o nome da sua key pair
environment = "dev"
instance_name = "windrose-dev-server"
ec2_instance_type = "t3.micro"  # Ajuste conforme necessário
windrose_port = 8000
```

### 2. Inicializar Terraform

```bash
cd infra
terraform init
```

### 3. Planejar a implantação

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

### 4. Aplicar a configuração

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Saídas (Outputs)

Após aplicar com sucesso, você receberá:

- `windrose_server_public_ip`: IP público para acessar o servidor
- `windrose_server_instance_id`: ID da instância EC2
- `windrose_server_private_ip`: IP privado da instância
- `windrose_server_url`: URL completa para acessar o servidor

## Variáveis Disponíveis

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `bucket_name` | Nome do S3 bucket | - |
| `environment` | Ambiente (dev, main, etc) | dev |
| `ec2_instance_type` | Tipo de instância EC2 | t3.micro |
| `ec2_key_name` | Nome da key pair SSH | **Obrigatório** |
| `windrose_port` | Porta do servidor Windrose | 8000 |
| `instance_name` | Nome da tag da instância | windrose-game-server |

## Segurança

### Portas Abertas

- **SSH (22)**: Permite acesso SSH de qualquer lugar (0.0.0.0/0)
- **Windrose (8000)**: Porta do servidor de jogo, aberta para TCP e UDP

**Nota**: Em produção, restrinja o acesso SSH apenas aos IPs necessários.

## Acessar o Servidor

Após criar a instância:

```bash
# Via SSH
ssh -i /caminho/para/chave.pem ubuntu@<PUBLIC_IP>

# Verificar logs de inicialização
tail -f /var/log/windrose-setup.log

# Acessar o servidor Windrose
http://<PUBLIC_IP>:8000
```

## Imagem Docker

O projeto usa a imagem Docker oficial:

```
indifferentbroccoli/windrose-server:latest
```

Repositório: https://github.com/indifferentbroccoli/windrose-server-docker

## Destruir Recursos

Para remover todos os recursos criados:

```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## Troubleshooting

### Script de inicialização não executando

Verifique o arquivo de log da cloud-init:

```bash
ssh -i caminho/chave.pem ubuntu@<IP>
tail -f /var/log/cloud-init-output.log
```

### Container não iniciando

```bash
ssh -i caminho/chave.pem ubuntu@<IP>
docker ps -a
docker logs windrose-server
```

### Reconectar ao container

```bash
docker start windrose-server  # Se parado
docker restart windrose-server  # Reiniciar
```

## Custos Estimados (AWS)

- EC2 t3.micro: ~$0.0104/hora (free tier qualifica 750h/mês por 12 meses)
- Elastic IP: Gratuito enquanto em uso, $0.005/hora se não associado
- S3 Standard: ~$0.023/GB/mês

## Observações

1. O script userdata.sh é templated e recebe a variável `windrose_port` dinamicamente
2. A instância usa a AMI Ubuntu 22.04 LTS mais recente
3. CloudWatch Logs está configurado para os logs da aplicação
4. O container é configurado para reiniciar automaticamente

## Próximas Melhorias

- [ ] Adicionar CloudFormation templates
- [ ] Implementar Auto Scaling Group
- [ ] Adicionar RDS para banco de dados
- [ ] Configurar Load Balancer
- [ ] Adicionar monitoramento com CloudWatch alarms

