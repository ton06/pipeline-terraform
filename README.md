# 🏴‍☠️ Windrose Dedicated Server — AWS Infrastructure

Infraestrutura Terraform para subir um servidor dedicado do jogo **Windrose** na AWS (`sa-east-1` — São Paulo), usando a imagem Docker oficial da comunidade.

> **Windrose** é um jogo de sobrevivência na Era da Pirataria — mundo aberto procedural, construção de bases, batalhas navais e combate soulslike. [Site oficial](https://playwindrose.com)

---

## 🐳 Stack

- **EC2**: Ubuntu 24.04 LTS (`t3.large` por padrão) — sem custo de licença Windows
- **Container**: [`indifferentbroccoli/windrose-server-docker`](https://github.com/indifferentbroccoli/windrose-server-docker)
- **Orquestração**: Docker Compose
- **Região**: `sa-east-1` (São Paulo)

---

## 📋 Pré-requisitos

Antes de rodar o Terraform, você precisa ter:

- [ ] [Terraform >= 1.6.0](https://developer.hashicorp.com/terraform/install) instalado
- [ ] [AWS CLI](https://aws.amazon.com/cli/) instalado e configurado (`aws configure`)
- [ ] Um **Key Pair** criado na AWS Console na região `sa-east-1`
  - Acesse: **EC2 → Key Pairs → Create key pair**
  - Salve o arquivo `.pem` com segurança
- [ ] Seu IP público anotado para liberar acesso SSH
  - Descubra em: https://checkip.amazonaws.com

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

Preencha **obrigatoriamente** no `terraform.tfvars`:

| Variável | Descrição | Exemplo |
|---|---|---|
| `key_pair_name` | Nome do seu Key Pair na AWS | `"meu-key-pair"` |
| `admin_cidr_ssh` | Seu IP para acesso SSH (formato CIDR) | `"203.0.113.10/32"` |

### 3. Inicialize e aplique

```bash
terraform init
terraform plan   # revise o que sera criado
terraform apply  # cria a infraestrutura
```

Após o apply, você verá os outputs:

```
server_public_ip        = "54.x.x.x"
ssh_connection          = "ssh -i seu-arquivo.pem ubuntu@54.x.x.x"
game_connection_address = "54.x.x.x:7777"
invite_code             = "amigos2026"
instance_id             = "i-0abc123..."
```

---

## 🎮 Iniciando o servidor

O container sobe **automaticamente** na primeira inicialização via User Data. Para acompanhar:

```bash
# Conectar ao servidor
ssh -i seu-arquivo.pem ubuntu@<server_public_ip>

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

> ⚠️ O **Elastic IP** gera ~$0.005/hora quando alocado sem instância rodando. Use `terraform destroy` para eliminar todos os custos quando não for usar por um período longo.

### Estimativa de custos (on-demand, sa-east-1)

| Recurso | t3.large Linux | t3.large Windows (ref.) |
|---|---|---|
| EC2/hora | ~$0.104 | ~$0.208 |
| **Mensal 24/7** | **~$75/mês** | ~~$150/mês~~ |
| **Mensal 8h/dia** | **~$25/mês** | ~~$50/mês~~ |
| EBS gp3 50 GB | ~$5/mês | ~$5/mês |
| Elastic IP | ~$3.6/mês | ~$3.6/mês |

---

## 🔄 Atualizando o servidor do jogo

```bash
# SSH no servidor e execute:
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
├── main.tf                    # Recursos AWS (EC2 Ubuntu, Security Group, Elastic IP)
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
- [AWS EC2 Instance Types e precos](https://instances.vantage.sh)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
