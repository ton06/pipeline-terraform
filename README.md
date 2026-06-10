# 🏴‍☠️ Windrose Server — AWS

EC2 Ubuntu 26.04 + Docker ([indifferentbroccoli/windrose-server-docker](https://github.com/indifferentbroccoli/windrose-server-docker)) + SSM Session Manager.

Deploy via pipeline reutilizavel [ton06/workflows](https://github.com/ton06/workflows).

## Deploy

O pipeline roda automaticamente a cada push na `main`.

```
push -> main -> deploy.yml -> ton06/workflows/terraform.yml
                           -> terraform plan/apply (environment: prods)
```

## Estrutura

```
infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── destroy.json            # { "destroy": false } — mude para true para destruir
├── environments/
│   └── prods/
│       └── terraform.tfvars
└── scripts/
    ├── setup_docker.sh     # User Data: instala Docker e sobe o container (roda 1x)
    ├── update_server.sh    # Atualiza a imagem Docker do servidor
    └── manage_instance.sh  # Liga/desliga EC2 via AWS CLI
```

## Secrets necessarios no GitHub

| Secret | Descricao |
|---|---|
| `AWS_ASSUME_ROLE_ARN` | ARN da role IAM para o GitHub Actions assumir |
| `AWS_STATEFILE_S3_BUCKET` | Nome do bucket S3 para armazenar o state |

## Destruir a infraestrutura

Edite `infra/destroy.json`:
```json
{ "destroy": true }
```
Faca commit e push — o pipeline vai rodar `terraform destroy` automaticamente.

## Acesso ao servidor (pos-deploy)

```bash
# Terminal na EC2 via SSM
aws ssm start-session --target <instance_id> --region sa-east-1

# Logs do container
docker compose -f /opt/windrose/docker-compose.yml logs -f
```
