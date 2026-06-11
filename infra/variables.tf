# =============================================================================
# variables.tf — Declaracao de todas as variaveis do projeto
# =============================================================================

variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados."
  type        = string
  default     = "sa-east-1"
}

variable "instance_type" {
  description = "Tipo da instancia EC2 Linux. Padrao: t3.large (2 vCPU / 8 GB RAM)."
  type        = string
  default     = "t3.large"
}

variable "server_name" {
  description = "Nome do servidor Windrose exibido para os jogadores in game."
  type        = string
  default     = "PlayerShip"
}

variable "invite_code" {
  description = "Codigo de convite do servidor (min. 6 chars, case-sensitive, apenas 0-9 a-z A-Z)."
  type        = string
  default     = "amigos2026"
}

variable "server_password" {
  description = "Senha para entrar no servidor in game. Deixe vazio para servidor sem senha."
  type        = string
  default     = "butuca"
  sensitive   = true
}

variable "max_players" {
  description = "Numero maximo de jogadores simultaneos permitidos."
  type        = number
  default     = 6
}

variable "server_port" {
  description = "Porta do servidor para conexao direta TCP+UDP. Padrao oficial do Windrose: 7777."
  type        = number
  default     = 7777
}

variable "use_direct_connection" {
  description = "Habilita conexao direta por IP:porta (USE_DIRECT_CONNECTION=true)."
  type        = bool
  default     = true
}

variable "update_on_start" {
  description = "Atualiza automaticamente o servidor ao iniciar o container."
  type        = bool
  default     = true
}
