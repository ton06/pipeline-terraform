# 🏴‍☠️ Windrose Dedicated Server — AWS Infrastructure

Infraestrutura Terraform para subir um servidor dedicado do jogo **Windrose** na AWS (região `sa-east-1` — São Paulo).

> **Windrose** é um jogo de sobrevivência na Era da Pirataria — mundo aberto procedural, construção de bases, batalhas navais e combate soulslike. [Site oficial](https://playwindrose.com)

---

## 📋 Pré-requisitos

Antes de rodar o Terraform, você precisa ter:

- [ ] [Terraform >= 1.6.0](https://developer.hashicorp.com/terraform/install) instalado
- [ ] [AWS CLI](https://aws.amazon.com/cli/) instalado e configurado (`aws configure`)
- [ ] Um **Key Pair** criado na AWS Console na região `sa-east-1`
  - Acesse: **EC2 → Key Pairs → Create key pair**
  - Salve o arquivo `.pem` com segurança — você vai precisar para acessar o servidor via RDP
- [ ] Seu IP público anotado para liberar acesso RDP
  - Descubra em: https://checkip.amazonaws.com

---

## ⚙️ Configuração inicial

### 1. Clone o repositório

```bash
git clone https://github.com/ton06/pipeline-terraform.git
cd pipeline-terraform
```

### 2. Configure as variáveis

Copie o arquivo de exemplo e preencha com seus valores:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Preencha **obrigatoriamente** no `terraform.tfvars`:

| Variável | Descrição | Exemplo |
|---|---|---|
| `key_pair_name` | Nome do seu Key Pair na AWS | `"meu-key-pair"` |
| `admin_cidr_ssh` | Seu IP para acesso RDP (formato CIDR) | `"203.0.113.10/32"` |

As demais variáveis já têm valores padrão funcionais.

### 3. Inicialize e aplique

```bash
terraform init
terraform plan   # revise o que sera criado
terraform apply  # cria a infraestrutura
```

Após o apply, você verá os outputs:

```
server_public_ip        = "54.x.x.x"
rdp_connection          = "54.x.x.x:3389"
game_connection_address = "54.x.x.x:7777"
invite_code             = "amigos2026"
instance_id             = "i-0abc123..."
```

---

## 🎮 Iniciando o servidor

1. Conecte-se via **Remote Desktop (RDP)**
   - Endereço: `<rdp_connection output>`
   - Usuário: `Administrator`
   - Senha: recupere em **EC2 → Instances → Get Windows Password** usando seu arquivo `.pem`

2. Aguarde o setup terminar (~10 min na primeira inicialização)
   - Acompanhe o progresso em `C:\windrose-setup.log`

3. Use o atalho **"Iniciar Windrose Server"** na área de trabalho
   - Ou execute `C:\windrose-server\StartServerForeground.bat` diretamente

4. Compartilhe com os amigos:
   - **Invite Code**: configurado no `terraform.tfvars`
   - **Conexão direta**: `<server_public_ip>:7777`

---

## 💸 Gerenciamento de custos

### Ligar/desligar o servidor

Use o script auxiliar para economizar quando não estiver jogando:

```bash
# Ligar o servidor
./scripts/manage_instance.sh start

# Desligar (para de cobrar EC2, mantém EBS e EIP)
./scripts/manage_instance.sh stop

# Ver status
./scripts/manage_instance.sh status
```

> ⚠️ O **Elastic IP** gera ~$0.005/hora quando alocado sem instância rodando. Se não for usar por um período longo, rode `terraform destroy` para eliminar este custo.

### Estimativa de custos (on-demand, sa-east-1)

| Recurso | t3.large (padrão) | m5.xlarge (upgrade) |
|---|---|---|
| EC2 Windows/hora | ~$0.208 | ~$0.353 |
| **Mensal 24/7** | **~$150/mês** | **~$254/mês** |
| **Mensal 8h/dia** | **~$50/mês** | **~$85/mês** |
| EBS gp3 50 GB | ~$5/mês | ~$5/mês |
| Elastic IP | ~$3.6/mês | ~$3.6/mês |

---

## ⚠️ Aviso importante sobre RAM

A instância `t3.large` tem **8 GB de RAM**. O guia oficial do Windrose recomenda:

| Jogadores | RAM recomendada |
|---|---|
| 2 jogadores | 8 GB |
| 4 jogadores | **12 GB** |
| 6–10 jogadores | **16 GB** |

Para 6 jogadores simultâneos, considere fazer upgrade para **`m5.xlarge`** alterando `instance_type` no `terraform.tfvars`.

---

## 🔄 Atualizando o servidor do jogo

Sempre que o Windrose receber uma atualização, atualize o servidor:

```powershell
# Execute via RDP no servidor Windows
C:\scripts\update_server.ps1
```

> ⚠️ Versões diferentes entre cliente e servidor causam bugs de conexão. Atualize sempre após um patch do jogo.

---

## 🗑️ Destruir a infraestrutura

```bash
terraform destroy
```

> ⚠️ Isso deleta tudo, incluindo os saves do servidor. Faça backup de `C:\windrose-server\R5\Saved\` antes.

---

## 📁 Estrutura do projeto

```
pipeline-terraform/
├── main.tf                    # Recursos AWS (EC2, Security Group, Elastic IP)
├── variables.tf               # Declaração de variáveis
├── outputs.tf                 # Outputs após o apply
├── terraform.tfvars.example   # Template de configuração (COPIE para terraform.tfvars)
├── .gitignore                 # Protege .tfstate e .tfvars com segredos
├── scripts/
│   ├── setup_windrose.ps1     # Setup automático via EC2 User Data (roda 1x)
│   ├── start_server.ps1       # Inicia o servidor manualmente
│   ├── update_server.ps1      # Atualiza o servidor via SteamCMD
│   └── manage_instance.sh     # Liga/desliga EC2 via AWS CLI
└── README.md
```

---

## 🔗 Referências

- [Guia oficial do Windrose Dedicated Server](https://playwindrose.com/dedicated-server-guide/)
- [Windrose no Steam](https://store.steampowered.com/app/windrose)
- [AWS EC2 Instance Types e preços](https://instances.vantage.sh)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
