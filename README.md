# 🏴‍☠️ Windrose Dedicated Server — AWS Infrastructure

Infraestrutura Terraform para subir um servidor dedicado do jogo **Windrose** na AWS (`sa-east-1` — São Paulo), usando a imagem Docker oficial da comunidade.

> **Windrose** é um jogo de sobrevivência na Era da Pirataria — mundo aberto procedural, construção de bases, batalhas navais e combate soulslike. [Site oficial](https://playwindrose.com)

---

## 🐳 Stack

- **EC2**: Ubuntu 24.04 LTS (`t3.large` por padrão)
- **Container**: [`indifferentbroccoli/windrose-server-docker`](https://github.com/indifferentbroccoli/windrose-server-docker)
- **Orquestração**: Docker Compose
- **Acesso ao servidor**: AWS SSM Session Manager (sem key pair, sem SSH exposto)
- **Região**: `sa-east-1` (São Paulo)

---

## 📋 Pré-requisitos

Antes de rodar o Terraform, você precisa ter:

- [ ] [Terraform >= 1.6.0](https://developer.hashicorp.com/terraform/install) instalado
- [ ] [AWS CLI](https://aws.amazon.com/cli/) instalado e configurado (`aws configure`)
- [ ] [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) instalado (para abrir terminal via SSM)
- [ ] IAM com permissões para criar EC2, IAM Role e Security Group

---

## ⚙️ Configuração inicial

### 1. Clone o repositório

```bash
git clone https://github.com/ton06/pipeline-terraform.git
cd pipeline-terraform
```

### 2. Configure as variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
```

Todos os valores já têm defaults funcionais. Edite o `terraform.tfvars` apenas se quiser personalizar nome do servidor, senha, número de jogadores etc.

### 3. Inicialize e aplique

```bash
terraform init
terraform plan   # revise o que sera criado
terraform apply  # cria a infraestrutura
```

Após o apply, você verá os outputs:

```
server_public_ip        = "54.x.x.x"
ssm_connection          = "aws ssm start-session --target i-0abc123... --region sa-east-1"
game_connection_address = "54.x.x.x:7777"
invite_code             = "amigos2026"
instance_id             = "i-0abc123..."
```

---

## 🎮 Iniciando o servidor

O container sobe **automaticamente** na primeira inicialização via User Data. Para acompanhar via SSM:

```bash
# Abrir terminal na EC2 (sem SSH, sem key pair)
aws ssm start-session --target <instance_id> --region sa-east-1

# Ver log do setup inicial
cat /var/log/windrose-setup.log

# Ver logs do container em tempo real
docker compose -f /opt/windrose/docker-compose.yml logs -f

# Ver status do container
docker compose -f /opt/windrose/docker-compose.yml ps
```

Compartilhe com os amigos:
- **Invite Code**: configurado no `terraform.tfvars` (ex: `amigos2026`)
- **Conexão direta**: `<server_public_ip>:7777`

---

## 💸 Gerenciamento de custos

### Ligar/desligar o servidor

```bash
# Ligar o servidor
./scripts/manage_instance.sh start

# Desligar (para de cobrar EC2, mantém EBS e EIP)
./scripts/manage_instance.sh stop

# Ver status
./scripts/manage_instance.sh status
```

### Estimativa de custos (on-demand, sa-east-1)

| Recurso | t3.large |
|---|---|
| EC2/hora | ~$0.104 |
| **Mensal 24/7** | **~$75/mês** |
| **Mensal 8h/dia** | **~$25/mês** |
| EBS gp3 50 GB | ~$5/mês |
| Elastic IP | ~$3.6/mês |

---

## 🔄 Atualizando o servidor do jogo

```bash
# Via SSM na EC2:
sudo /opt/windrose/update_server.sh
```

> ⚠️ Sempre atualize o servidor após um patch do jogo. Versões diferentes causam bugs de conexão.

---

## 🗑️ Destruir a infraestrutura

```bash
terraform destroy
```

> ⚠️ Isso deleta tudo, incluindo os saves do servidor. Faça backup de `/opt/windrose/server-files/` antes.

---

## 📁 Estrutura do projeto

```
pipeline-terraform/
├── main.tf                    # EC2 Ubuntu, IAM Role SSM, Security Group, Elastic IP
├── variables.tf               # Declaracao de variaveis
├── outputs.tf                 # Outputs apos o apply
├── terraform.tfvars.example   # Template de configuracao (COPIE para terraform.tfvars)
├── .gitignore                 # Protege .tfstate, .tfvars e .env
├── scripts/
│   ├── setup_docker.sh        # Setup automatico via EC2 User Data (roda 1x)
│   ├── update_server.sh       # Atualiza o servidor via Docker pull
│   └── manage_instance.sh     # Liga/desliga EC2 via AWS CLI
└── README.md
```

---

## 🔗 Referências

- [Guia oficial do Windrose Dedicated Server](https://playwindrose.com/dedicated-server-guide/)
- [indifferentbroccoli/windrose-server-docker](https://github.com/indifferentbroccoli/windrose-server-docker)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [AWS EC2 Instance Types e precos](https://instances.vantage.sh)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
