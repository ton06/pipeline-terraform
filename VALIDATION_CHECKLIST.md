# Checklist de Validação Pós-Deployment

Use este checklist após executar `terraform apply` para validar se tudo está funcionando corretamente.

## ✅ Fase 1: Verificação do Terraform

- [ ] Terraform apply concluído sem erros
- [ ] Outputs aparecem corretamente:
  ```bash
  terraform output
  ```
  Deve mostrar:
  - windrose_server_public_ip
  - windrose_server_instance_id
  - windrose_server_private_ip
  - windrose_server_url

- [ ] Salvar o IP para referência:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  echo "Windrose Server IP: $IP"
  ```

## ✅ Fase 2: Verificação da Instância EC2

- [ ] Instância EC2 existe e está running:
  ```bash
  aws ec2 describe-instances \
    --instance-ids $(terraform output -raw windrose_server_instance_id) \
    --query 'Reservations[0].Instances[0].State.Name'
  ```
  Esperado: "running"

- [ ] Elastic IP está associado:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  aws ec2 describe-addresses \
    --addresses $IP
  ```
  Esperado: AssociationId deve estar definido

- [ ] Security Group está aplicado:
  ```bash
  INSTANCE_ID=$(terraform output -raw windrose_server_instance_id)
  aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups'
  ```

## ✅ Fase 3: Conexão SSH

**Nota**: Aguarde 2-3 minutos após criar a instância antes de tentar SSH

- [ ] SSH conecta sem erros:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  ssh -i sua-chave.pem ubuntu@$IP "echo 'SSH OK'"
  ```

- [ ] Sistema Ubuntu está respondendo:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "uname -a"
  ```

## ✅ Fase 4: Docker Installation

- [ ] Docker está instalado:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker --version"
  ```
  Esperado: Docker version X.XX.X

- [ ] Docker daemon está rodando:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "sudo systemctl status docker"
  ```
  Esperado: "active (running)"

- [ ] Usuário ubuntu pode usar docker:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker ps"
  ```
  Esperado: Lista de containers (vazia no início)

## ✅ Fase 5: Container Windrose

**Nota**: Pode levar 3-5 minutos para o container iniciar

- [ ] Container windrose-server existe:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker ps -a"
  ```
  Esperado: Container "windrose-server" listado

- [ ] Container está running:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker ps"
  ```
  Esperado: windrose-server em status "Up"

- [ ] Verificar logs de inicialização:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "tail -50 /var/log/cloud-init-output.log"
  ```

- [ ] Ver logs do container:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker logs windrose-server"
  ```

## ✅ Fase 6: Conectividade de Porta

- [ ] Porta 22 (SSH) está aberta:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  nmap -p 22 $IP
  # ou
  nc -zv $IP 22
  ```
  Esperado: "open"

- [ ] Porta 8000 (Windrose) está aberta:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  curl -I http://$IP:8000/
  # ou
  nc -zv $IP 8000
  ```

## ✅ Fase 7: Servidor Windrose

- [ ] Servidor responde na porta 8000:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  curl -v http://$IP:8000/
  ```
  Esperado: Response do servidor Windrose

- [ ] Testar endpoint básico:
  ```bash
  IP=$(terraform output -raw windrose_server_public_ip)
  curl http://$IP:8000/health  # ou outro endpoint existente
  ```

- [ ] Verificar se o container tem acesso à internet:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker exec windrose-server ping -c 1 8.8.8.8"
  ```

## ✅ Fase 8: Performance e Recursos

- [ ] CPU e Memória estão OK:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "free -h"
  ssh -i sua-chave.pem ubuntu@$IP "top -bn1 | head -10"
  ```

- [ ] Espaço em disco:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "df -h"
  ```
  Esperado: Espaço suficiente disponível

- [ ] Container não consome muita memória:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker stats --no-stream windrose-server"
  ```

## ✅ Fase 9: Logs e Monitoramento

- [ ] Ver arquivo de setup:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "cat /var/log/windrose-setup.log"
  ```

- [ ] Monitorar logs em tempo real:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "docker logs -f windrose-server"
  # Pressione Ctrl+C para parar
  ```

- [ ] Verificar dmesg para erros:
  ```bash
  ssh -i sua-chave.pem ubuntu@$IP "sudo dmesg | tail -20"
  ```

## ✅ Fase 10: Durabilidade

- [ ] Restart automático está funcionando:
  ```bash
  # Parar o container
  ssh -i sua-chave.pem ubuntu@$IP "docker stop windrose-server"
  
  # Aguardar 30 segundos
  sleep 30
  
  # Verificar se reiniciou
  ssh -i sua-chave.pem ubuntu@$IP "docker ps | grep windrose-server"
  ```
  Esperado: Container rodando novamente

## ⚠️ Problemas Comuns e Soluções

### "permission denied" para docker
```bash
# Reaplicar permissões
ssh -i sua-chave.pem ubuntu@$IP "sudo usermod -aG docker ubuntu"

# Fazer logout e login novamente
```

### Container não inicia
```bash
# Ver logs detalhados
ssh -i sua-chave.pem ubuntu@$IP "docker logs windrose-server"

# Verificar se a imagem foi puxada
ssh -i sua-chave.pem ubuntu@$IP "docker images"

# Tentar pull manual
ssh -i sua-chave.pem ubuntu@$IP "docker pull indifferentbroccoli/windrose-server:latest"
```

### Porta não acessível
```bash
# Verificar security group rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw windrose_sg_id) 2>/dev/null || \
  echo "Adicione output para SG ID"

# Testar conectividade local na instância
ssh -i sua-chave.pem ubuntu@$IP "telnet localhost 8000"
```

### Instância muito lenta
```bash
# Verificar uso de CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$(terraform output -raw windrose_server_instance_id) \
  --statistics Average \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300
```

## 🔧 Script de Validação Completa

Salva isso como `validate.sh`:

```bash
#!/bin/bash

echo "=========================================="
echo "Windrose Server Validation"
echo "=========================================="

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$(dirname "$0")/infra" || exit

# Get outputs
IP=$(terraform output -raw windrose_server_public_ip 2>/dev/null)
INSTANCE_ID=$(terraform output -raw windrose_server_instance_id 2>/dev/null)

if [ -z "$IP" ]; then
    echo -e "${RED}✗ Cannot get Terraform outputs${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Terraform outputs obtained${NC}"
echo "  IP: $IP"
echo "  Instance ID: $INSTANCE_ID"
echo ""

# Test SSH
echo "Testing SSH..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/your-key.pem ubuntu@$IP "echo 'SSH OK'" &>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${YELLOW}⚠ SSH not ready yet (may take 2-3 min)${NC}"
fi
echo ""

# Test Docker
echo "Testing Docker..."
if ssh -o ConnectTimeout=5 -i ~/.ssh/your-key.pem ubuntu@$IP "docker ps" &>/dev/null; then
    echo -e "${GREEN}✓ Docker is accessible${NC}"
else
    echo -e "${RED}✗ Docker not accessible${NC}"
fi
echo ""

# Test Windrose Container
echo "Testing Windrose Container..."
if ssh -i ~/.ssh/your-key.pem ubuntu@$IP "docker ps | grep windrose-server" &>/dev/null; then
    echo -e "${GREEN}✓ Windrose container is running${NC}"
else
    echo -e "${YELLOW}⚠ Windrose container not running${NC}"
fi
echo ""

# Test HTTP Access
echo "Testing HTTP Access..."
if curl -s -o /dev/null -w "%{http_code}" http://$IP:8000/ | grep -q "200"; then
    echo -e "${GREEN}✓ Windrose server responding (200 OK)${NC}"
else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP:8000/)
    echo -e "${YELLOW}⚠ Windrose server HTTP code: $HTTP_CODE${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Validation Complete!${NC}"
echo "=========================================="
```

Use assim:
```bash
chmod +x validate.sh
./validate.sh
```

## ✅ Definitivo: Tudo OK!

Se todos os itens acima passarem:

- 🎮 O servidor Windrose está rodando
- 🌐 É acessível via HTTP na porta 8000
- 🔐 SSH funciona para administração
- 🔄 Container reinicia automaticamente
- 📊 Logs estão sendo salvos
- ✨ Deployment foi bem-sucedido!

Você pode agora acessar o servidor em:
```
http://<IP_PUBLIC>:8000
```

Divirta-se com o Windrose! 🎮

