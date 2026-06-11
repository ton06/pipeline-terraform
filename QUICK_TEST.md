✅ TESTE RÁPIDO - Validar Mudanças
═══════════════════════════════════════════════════════════════════

Execute este checklist para validar que tudo foi alterado corretamente:

## 1️⃣ Verificar Variáveis

```bash
cd infra
grep -n "ec2_key_name" variables.tf
```

Resultado esperado:
```
(nenhuma linha deve conter ec2_key_name)
```

✓ Se não encontrou nada = Sucesso!

---

## 2️⃣ Verificar Instance Type Padrão

```bash
grep "default.*=" variables.tf | grep instance_type
```

Resultado esperado:
```
default     = "t3.large"
```

✓ Se mostrar "t3.large" = Sucesso!

---

## 3️⃣ Verificar tfvars Dev

```bash
cat environments/dev/terraform.tfvars
```

Resultado esperado:
```
bucket_name = "testes-pipeline-terraform"
environment       = "dev"
instance_name     = "windrose-dev-server"
ec2_instance_type = "t3.large"
windrose_port     = 8000
```

✓ Se mostrar "t3.large" e sem "ec2_key_name" = Sucesso!

---

## 4️⃣ Verificar tfvars Main

```bash
cat environments/main/terraform.tfvars
```

Resultado esperado:
```
bucket_name = "testes-pipeline-terraform-main"
environment       = "main"
instance_name     = "windrose-main-server"
ec2_instance_type = "t3.xlarge"
windrose_port     = 8000
```

✓ Se mostrar "t3.xlarge" e sem "ec2_key_name" = Sucesso!

---

## 5️⃣ Verificar EC2 Resource - Key Name Removido

```bash
grep -n "key_name" ec2_windrose.tf
```

Resultado esperado:
```
(nenhuma linha deve conter key_name =)
```

✓ Se não encontrou nada = Sucesso!

---

## 6️⃣ Verificar IAM Profile Adicionado

```bash
grep -n "iam_instance_profile" ec2_windrose.tf
```

Resultado esperado:
```
106 |   iam_instance_profile   = aws_iam_instance_profile.windrose_profile.name
```

✓ Se encontrou a linha = Sucesso!

---

## 7️⃣ Verificar IAM Resources Criados

```bash
grep -n "resource.*iam" ec2_windrose.tf | head -5
```

Resultado esperado:
```
3:resource "aws_iam_role" "windrose_ssm_role" {
21:resource "aws_iam_role_policy_attachment" "ssm_policy" {
26:resource "aws_iam_instance_profile" "windrose_profile" {
```

✓ Se encontrou os 3 recursos = Sucesso!

---

## 8️⃣ Testar Formatação Terraform

```bash
terraform fmt -check -recursive
```

Resultado esperado:
```
(sem output significa que está formatado)
```

✓ Se sem erros = Sucesso!

---

## 9️⃣ Testar Sintaxe Terraform

```bash
terraform init -upgrade
terraform validate
```

Resultado esperado:
```
Success! The configuration is valid.
```

✓ Se retornar "Success!" = Sucesso!

---

## 🔟 Visualizar Plano de Mudanças

```bash
terraform plan -var-file="environments/dev/terraform.tfvars" -no-color | grep -E "^\+" | head -20
```

Verifique se mostra:
- `+ aws_iam_role` (nova IAM role)
- `+ aws_iam_role_policy_attachment` (nova attachment)
- `+ aws_iam_instance_profile` (novo profile)
- `+ aws_instance` (instância com t3.large)
- `+ aws_eip` (IP elástico)
- `+ aws_security_group` (security group)

✓ Se tudo acima aparecer = Sucesso!

---

## ✅ TODOS OS TESTES PASSARAM?

Se você marcou ✓ em todos os 10 itens acima, então:

### ✨ MUDANÇAS VALIDADAS COM SUCESSO! ✨

Você está pronto para fazer deploy:

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

---

## 🎯 Próximos Passos

1. **Deploy:**
   ```bash
   terraform apply -var-file="environments/dev/terraform.tfvars"
   ```

2. **Aguarde provisioning** (~5-10 minutos)

3. **Conectar via Systems Manager:**
   ```bash
   INSTANCE_ID=$(terraform output -raw windrose_server_instance_id)
   aws ssm start-session --target $INSTANCE_ID
   ```

4. **Dentro da sessão, verificar:**
   ```bash
   docker ps
   docker logs windrose-server
   ```

---

## 📊 O Que Mudou

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Key Pair SSH | Obrigatório | ❌ Removido |
| Acesso | SSH + Chave | AWS Systems Manager |
| Instance Type | t3.micro | t3.large |
| vCPUs | 1 | 2 |
| RAM | 1 GB | 8 GB |
| Porta SSH | 22 (aberta) | Fechada |
| Segurança | Mediana | Melhorada |

---

## 🔐 Benefícios da Mudança

✅ **Sem Chave SSH** - Menos pontos de falha
✅ **SSH Fechado** - Reduz superfície de ataque
✅ **Auditado** - Todas as conexões registradas
✅ **IAM-Based** - Controle granular
✅ **Mais Poder** - 2 CPUs + 8GB RAM (vs 1 CPU + 1GB)
✅ **Escalável** - Fácil aumentar/diminuir

---

## 🆘 Se Algo Defer Errado

```bash
# Ver logs detalhados
TF_LOG=DEBUG terraform apply -var-file="environments/dev/terraform.tfvars"

# Resetar tudo
terraform destroy -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"

# Validar sintaxe novamente
terraform fmt -recursive
terraform validate
```

---

Você está tudo pronto! Execute o terraform apply agora. 🚀

