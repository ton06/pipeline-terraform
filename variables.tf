# =============================================================================
# variables.tf — Declaracao de todas as variaveis do projeto
# =============================================================================

variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados."
  type        = string
  default     = "sa-east-1"
}

variable "key_pair_name" {
  description = "Nome do Key Pair existente na conta AWS (regiao sa-east-1). Crie em: EC2 -> Key Pairs -> Create key pair. Sem este valor o terraform apply falha."
  type        = string
  # Sem default — obrigatorio preencher no terraform.tfvars
}

variable "admin_cidr_ssh" {
  description = "CIDR IP autorizado para acesso RDP (porta 3389). Ex: '203.0.113.10/32'. Descubra seu IP em: https://checkip.amazonaws.com"
  type        = string
  # Sem default — obrigatorio preencher no terraform.tfvars
}

variable "instance_type" {
  description = "Tipo da instancia EC2. Padrao: t3.large (2 vCPU / 8 GB RAM). ATENCAO: o guia oficial recomenda 12 GB para 4 jogadores e 16 GB para 6-10 jogadores. Considere m5.xlarge se notar lentidao."
  type        = string
  default     = "t3.large"
}

variable "server_name" {
  description = "Nome do servidor Windrose exibido para os jogadores."
  type        = string
  default     = "Windrose Server"
}

variable "invite_code" {
  description = "Codigo de convite do servidor (min. 6 chars, case-sensitive, apenas 0-9 a-z A-Z)."
  type        = string
  default     = "amigos2026"
}

variable "server_password" {
  description = "Senha do servidor. Deixe vazio para acesso livre entre os convidados."
  type        = string
  default     = ""
  sensitive   = true
}

variable "max_players" {
  description = "Numero maximo de jogadores simultaneos permitidos."
  type        = number
  default     = 6
}

variable "direct_connection_port" {
  description = "Porta usada para conexao direta TCP+UDP. Padrao oficial do Windrose: 7777."
  type        = number
  default     = 7777
}

variable "world_preset" {
  description = "Dificuldade do mundo: Easy, Medium ou Hard."
  type        = string
  default     = "Medium"

  validation {
    condition     = contains(["Easy", "Medium", "Hard"], var.world_preset)
    error_message = "world_preset deve ser 'Easy', 'Medium' ou 'Hard'."
  }
}
