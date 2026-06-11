# ⚡ QUICK START - Windrose Game Server on AWS

Comece em menos de 5 minutos! (Mais o tempo de provisioning do AWS ~5 min)

## 1️⃣ Pré-requisitos (2 min)

```bash
# Instale Terraform
# Windows Chocolatey:
choco install terraform

# ou baixe de: https://www.terraform.io/downloads

# Instale AWS CLI
# Windows: https://aws.amazon.com/cli/

# Configure suas credenciais AWS
aws configure
# Insira: AWS Access Key ID
#        AWS Secret Access Key
#        Default region: sa-east-1
#        Default output: json
```

## 2️⃣ Criar EC2 Key Pair (1 min)

```bash
# AWS Console: EC2 → Key Pairs → Create Key Pair
# Nome: minha-chave (use este nome depois)
# Tipo: RSA
# Download: minha-chave.pem
# Salve em: ~/.ssh/minha-chave.pem
# Permissões: chmod 400 ~/.ssh/minha-chave.pem (Linux/Mac)

# Teste a chave
aws ec2 describe-key-pairs --key-names minha-chave
```

## 3️⃣ Editar Configuração (1 min)

```bash
# Abra: infra/environments/dev/terraform.tfvars
# Mude:
ec2_key_name = "minha-chave"  # Use o nome da sua chave
```

## 4️⃣ Deploy (1 min comando + 5-10 min AWS)

```bash
cd infra

# Inicializar Terraform
terraform init

# Visualizar o que será criado
terraform plan -var-file="environments/dev/terraform.tfvars"

# Criar a infraestrutura
terraform apply -var-file="environments/dev/terraform.tfvars"
# Digite: yes quando pedido

# ⏳ Aguarde 5-10 minutos...
```

## 5️⃣ Obter IP do Servidor (30 seg)

```bash
# Após terraform apply terminar:
terraform output windrose_server_public_ip

# Ou ver todos os outputs:
terraform output
```

## 6️⃣ Acessar o Jogo 🎮

```bash
# Abra no navegador:
http://<IP_QUE_VOCÊ_RECEBEU>:8000

# Ou via line:
IP=$(terraform output -raw windrose_server_public_ip)
curl http://$IP:8000
```

## 7️⃣ SSH para Debugging (opcional)

```bash
IP=$(terraform output -raw windrose_server_public_ip)
ssh -i ~/.ssh/minha-chave.pem ubuntu@$IP

# Ver logs do Docker:
docker logs windrose-server

# Ver logs de inicialização:
tail -f /var/log/cloud-init-output.log
```

## 8️⃣ Destruir (Para Parar de Pagar)

```bash
cd infra
terraform destroy -var-file="environments/dev/terraform.tfvars"
# Digite: yes quando pedido
```

---

## 🆘 Problemas Rápidos?

### SSH não conecta
```bash
# Aguarde 2-3 minutos após criar a instância
# Verifique a chave:
chmod 400 ~/.ssh/minha-chave.pem

# Verbose debug:
ssh -v -i ~/.ssh/minha-chave.pem ubuntu@<IP>
```

### Porta 8000 não responde
```bash
# Aguarde Docker iniciar (3-5 min total)
# Verifique security group:
aws ec2 describe-security-groups --group-ids <SG-ID>

# Via SSH, teste:
ssh -i ~/.ssh/minha-chave.pem ubuntu@$IP docker ps
```

### Terraform não reconhece meu código
```bash
terraform fmt -recursive
terraform validate
```

### Erro: "ec2_key_name is null"
```bash
# Edite: infra/environments/dev/terraform.tfvars
# Adicione: ec2_key_name = "sua-chave-aqui"
```

---

## 📊 Custos

- EC2 t3.micro: ~**$0.0104/hora** 
- Não está no free tier? Use t3.micro mesmo assim, é muito barato
- **~$7.50/mês** de operação contínua

---

## 📚 Próximo Passo

Leia `README.md` para mais informações sobre:
- Variáveis avançadas
- Troubleshooting detalhado
- Atualizações e melhorias
- Deploy em produção

---

## 🎮 Pronto!

Seus jogadores já podem acessar em: `http://<seu-ip>:8000`

Divirta-se! 🚀

