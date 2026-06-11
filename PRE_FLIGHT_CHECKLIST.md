# ✅ PRÉ-VOO CHECKLIST - Antes de fazer deploy

Use este checklist para garantir que tudo está pronto antes de executar `terraform apply`.

## 🔐 Segurança & Credenciais

- [ ] AWS CLI configurado com credenciais corretas
  ```bash
  aws sts get-caller-identity  # Deve mostrar suas informações
  ```

- [ ] Você tem permissões para criar EC2, Security Groups, Elastic IPs
  ```bash
  # Mínimas permissões necessárias em IAM Policy:
  # - ec2:RunInstances
  # - ec2:DescribeInstances
  # - ec2:CreateSecurityGroup
  # - ec2:AuthorizeSecurityGroupIngress
  # - ec2:AllocateAddress
  # - ec2:AssociateAddress
  # - ec2:DescribeImages
  ```

- [ ] EC2 Key Pair criada e armazenada com segurança
  ```bash
  # Verificar que a chave existe
  aws ec2 describe-key-pairs --key-names sua-chave
  
  # Permissões corretas
  ls -la ~/.ssh/sua-chave.pem  # Deve ser -r--r--r--
  chmod 400 ~/.ssh/sua-chave.pem  # Se necessário
  ```

## 🏗️ Infraestrutura Pré-requisita

- [ ] S3 Bucket para Terraform state existe
  ```bash
  # Verificar
  aws s3 ls | grep "testes-pipeline-terraform"
  
  # O bucket deve estar acessível
  # (Se não existir, crie um)
  ```

- [ ] Região AWS correta: sa-east-1
  ```bash
  # Verificar em infra/providers.tf
  grep "sa-east-1" infra/providers.tf
  ```

## 📝 Configuração Terraform

- [ ] Arquivo terraform.tfvars revisado
  ```bash
  cat infra/environments/dev/terraform.tfvars
  
  # Dados que devem estar presentes:
  # - bucket_name (S3 bucket existente)
  # - ec2_key_name (nome da sua chave)
  # - environment (dev ou main)
  # - windrose_port (porta do servidor)
  ```

- [ ] Variável `ec2_key_name` configurada e não vazia
  ```bash
  # Verificar
  grep "ec2_key_name" infra/environments/dev/terraform.tfvars
  
  # Não deve ser vazio ou "your-ec2-key-name"
  ```

- [ ] Arquivo `userdata.sh` está presente
  ```bash
  test -f infra/userdata.sh && echo "✓ userdata.sh existe"
  ```

- [ ] Arquivo `ec2_windrose.tf` está presente
  ```bash
  test -f infra/ec2_windrose.tf && echo "✓ ec2_windrose.tf existe"
  ```

## 💾 Terraform State

- [ ] Diretor `.terraform` não existe (para fresh init)
  ```bash
  test ! -d infra/.terraform && echo "✓ Pronto para init"
  ```

- [ ] Nenhum lock files bloqueando aplicações
  ```bash
  ls -la infra/.terraform* 2>/dev/null || echo "✓ Nenhum lock"
  ```

- [ ] Backend está corretamente configurado
  ```bash
  cat infra/backend.tf
  # Deve mostrar configuração S3 vazia (será completada pelo init)
  ```

## 🔍 Validações Sintáticas

- [ ] Terraform syntax é válida
  ```bash
  cd infra
  terraform validate  # Nota: precisa de terraform init antes
  # Deve mostrar "Success! The configuration is valid."
  ```

- [ ] HCL formatting está correto
  ```bash
  # Verificar (sem aplicar)
  terraform fmt -check -recursive
  
  # Se houver erros, executar:
  terraform fmt -recursive
  ```

- [ ] Sem conflitos de nomes de recursos
  ```bash
  grep -r "resource \"" infra/ | grep -v ".disabled" | wc -l
  # Deve mostrar um número sem duplicatas óbvias
  ```

## 📋 Variáveis e Valores

- [ ] Todos os valores obrigatórios estão preenchidos
  ```bash
  # Verificar as variáveis obrigatórias
  grep -A1 "variable" infra/variables.tf | grep -B1 'type ='
  ```

- [ ] Não há valores hard-coded sensíveis
  ```bash
  grep -r "password\|secret\|token" infra/
  # Não deve retornar valores real sensíveis
  ```

- [ ] Valores padrão fazem sentido
  ```bash
  # Revisar:
  # - instance_type: t3.micro (OK para dev)
  # - windrose_port: 8000 (padrão)
  # - environment: dev (correto)
  ```

## 🌐 Conectividade AWS

- [ ] Conectividade com AWS está funcionando
  ```bash
  # Testar latência
  ping -c 3 aws.amazon.com  # Linux/Mac
  # ou
  Test-Connection -ComputerName aws.amazon.com -Count 3  # Windows PowerShell
  ```

- [ ] STS (Security Token Service) está acessível
  ```bash
  aws sts get-caller-identity --region sa-east-1
  ```

- [ ] EC2 service está disponível na região
  ```bash
  aws ec2 describe-regions --region-names sa-east-1
  ```

## 💻 Ambiente Local

- [ ] Terraform versão compatível
  ```bash
  terraform version
  # Deve ser 1.0+ (provider requer)
  ```

- [ ] AWS CLI versão compatível
  ```bash
  aws --version
  # Deve ser 2.x+
  ```

- [ ] SSH client está disponível
  ```bash
  # Linux/Mac
  which ssh
  
  # Windows PowerShell
  Get-Command ssh
  ```

- [ ] Git configurado (se planeja versionar)
  ```bash
  git config --global user.email
  git config --global user.name
  ```

## 📁 Estrutura de Diretórios

- [ ] Todos os arquivos estão no lugar correto
  ```
  infra/
  ├── ec2_windrose.tf ✓
  ├── main.tf ✓
  ├── providers.tf ✓
  ├── variables.tf ✓
  ├── backend.tf ✓
  ├── userdata.sh ✓
  ├── environments/
  │   ├── dev/
  │   │   └── terraform.tfvars ✓
  │   └── main/
  │       └── terraform.tfvars ✓
  ```

- [ ] Sem arquivos indesejados
  ```bash
  ls -la infra/
  # Não deve conter terraform.tfstate, .terraform/, .terraform.lock.hcl
  ```

## 🎯 Planejamento

- [ ] Você tem ~5-10 minutos livres para o processo
  ```
  - terraform init: ~1 min
  - terraform plan: ~1 min
  - terraform apply: ~2 min
  - AWS provisioning: ~3-5 min
  - Docker startup: ~1-2 min
  ```

- [ ] Você sabe qual é seu IP público (para referência)
  ```bash
  curl -s https://api.ipify.org
  ```

- [ ] Você tem um navegador para testar o servidor
  ```
  Qualquer navegador moderno serve
  ```

## 📱 Comunicação & Alertas

- [ ] Monitorar logs enquanto o terraform apply roda
  ```bash
  # Em outro terminal:
  terraform refresh
  terraform output -raw windrose_server_public_ip
  ```

## ✨ Revisão Final

Antes de executar `terraform apply`:

```bash
# 1. Fazer uma última revisão do plano
cd infra
terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan

# 2. Revisar o arquivo tfplan (legível human)
terraform show tfplan

# 3. Se tudo parecer OK:
terraform apply tfplan
```

---

## 🚨 Se Algo Der Errado

**NÃO ENTRE em pânico!** Terraform é idempotente.

```bash
# 1. Ver o que aconteceu
terraform show

# 2. Ver logs detalhados
TF_LOG=INFO terraform apply -var-file="environments/dev/terraform.tfvars"

# 3. Destruir tudo (se necessário)
terraform destroy -var-file="environments/dev/terraform.tfvars"

# 4. Começar de novo
terraform apply -var-file="environments/dev/terraform.tfvars"
```

---

## ✅ Pronto?

Se todos os itens acima estão marcados ✓, você está pronto para:

```bash
cd infra
terraform init
terraform apply -var-file="environments/dev/terraform.tfvars"
```

**Boa sorte!** 🚀

