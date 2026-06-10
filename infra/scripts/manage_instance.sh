#!/bin/bash
# =============================================================================
# manage_instance.sh
# Liga/desliga a instancia EC2 via AWS CLI para economizar custos.
# Uso: ./infra/scripts/manage_instance.sh {start|stop|status}
# =============================================================================

set -e

INSTANCE_ID=$(terraform -chdir=infra output -raw instance_id 2>/dev/null)

if [ -z "$INSTANCE_ID" ]; then
  echo "Erro: nao foi possivel obter o Instance ID. Execute o pipeline primeiro."
  exit 1
fi

REGION="sa-east-1"

case "$1" in
  start)
    echo "Iniciando instancia $INSTANCE_ID..."
    aws ec2 start-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
    echo "Instancia iniciada! IP publico:"
    terraform -chdir=infra output server_public_ip
    ;;
  stop)
    echo "Parando instancia $INSTANCE_ID..."
    aws ec2 stop-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    echo "Instancia parada."
    ;;
  status)
    aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --region "$REGION" \
      --query 'Reservations[0].Instances[0].State.Name' \
      --output text
    ;;
  *)
    echo "Uso: $0 {start|stop|status}"
    exit 1
    ;;
esac
