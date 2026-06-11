# Acesso via Systems Manager (em vez de SSH)

## O Que Mudou?

- ❌ Removido: `ec2_key_name` (sem necessidade de chave SSH)
- ✅ Adicionado: AWS Systems Manager Session Manager (acesso seguro)
- ✅ Aumentado: EC2 Instance para `t3.large` (2 vCPUs, 8GB RAM)

## Vantagens

- ✅ Sem necessidade de gerenciar chaves SSH
- ✅ Acesso auditado (CloudTrail)
- ✅ Sem expor porta SSH na internet
- ✅ Permissões granulares via IAM
- ✅ Gerenciado automaticamente pelo AWS

## Como Acessar a Instância

### Opção 1: AWS Console (Mais Fácil)

1. Acesse: AWS Console → EC2 → Instances
2. Selecione a instância `windrose-dev-server`
3. Clique em "Connect"
4. Selecione a aba "Session Manager"
5. Clique em "Connect"

Você terá acesso a um terminal bash na instância!

### Opção 2: AWS CLI

```bash
# Instale Session Manager Plugin
# Windows: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Conectar
aws ssm start-session --target <instance-id>

# Executar um comando único
aws ssm start-session --target <instance-id> --document-name AWS-StartInteractiveCommand --parameters command="docker logs windrose-server"
```

### Opção 3: AWS Toolkit VSCode

1. Instale: AWS Toolkit extension no VSCode
2. Configure suas credenciais AWS
3. Vá para: AWS Explorer → EC2 → Sua instância
4. Clique em "Start Session"

## Exemplos de Uso

### Ver logs do Docker em tempo real

```bash
# Conectar via Session Manager
aws ssm start-session --target i-xxxxxxxxx

# Dentro da sessão:
docker logs -f windrose-server
```

### Executar comando remoto diretamente

```bash
# Ver status do container
aws ssm start-session --target i-xxxxxxxxx --document-name AWS-RunShellScript \
  --parameters 'command=["docker ps"]'

# Reiniciar container
aws ssm start-session --target i-xxxxxxxxx --document-name AWS-RunShellScript \
  --parameters 'command=["docker restart windrose-server"]'
```

## Pré-requisitos

- AWS CLI v2 instalado
- Session Manager Plugin instalado
- Permissões IAM para SSM (já vem por padrão no seu IAM user)

## Sessions Logs

Sessions são automaticamente registradas em CloudTrail para auditoria:

```bash
# Ver logs das sessions
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=windrose-server --max-results 10
```

## Troubleshooting

### "Unable to connect to the instance"

```bash
# Verificar status da instância
aws ec2 describe-instances --instance-ids i-xxxxxxxxx

# Verificar IAM role
aws iam get-role-policy --role-name windrose-ssm-role-xxxx --policy-name AmazonSSMManagedInstanceCore
```

### "Operation timed out"

A instância pode estar inicializando. Aguarde 2-3 minutos.

## Segurança

✅ Sessions são criptografadas
✅ Sem necessidade de gerenciar chaves SSH
✅ Acesso auditado e registrado
✅ Permissões granulares via IAM
✅ Sem exposição da porta SSH na internet

## Próximo Passo

Para acessar agora:

```bash
# 1. Obter o ID da instância
INSTANCE_ID=$(terraform output -raw windrose_server_instance_id)

# 2. Conectar
aws ssm start-session --target $INSTANCE_ID

# 3. Dentro da sessão
docker ps
docker logs windrose-server
```

Aproveite! 🚀

