# =============================================================================
# environments/prods/terraform.tfvars
# Variaveis do ambiente prods.
# NUNCA commite segredos aqui — use GitHub Secrets para valores sensiveis.
# =============================================================================

aws_region   = "sa-east-1"
instance_type = "t3.large"

server_name           = "PlayerShip"
invite_code           = "amigos2026"
server_password       = "butuca"
max_players           = 6
server_port           = 7777
use_direct_connection = true
update_on_start       = true
