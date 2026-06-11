# =============================================================================
# outputs.tf — Valores exibidos apos o terraform apply
# =============================================================================

output "server_public_ip" {
  description = "IP publico fixo do servidor Windrose (Elastic IP)."
  value       = aws_eip.windrose.public_ip
}

output "server_public_dns" {
  description = "DNS publico do servidor."
  value       = aws_eip.windrose.public_dns
}

output "ssm_connection" {
  description = "Comando para abrir terminal na EC2 via SSM Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.windrose.id} --region ${var.aws_region}"
}

output "game_connection_address" {
  description = "Endereco de conexao direta para os jogadores (IP:porta)."
  value       = "${aws_eip.windrose.public_ip}:${var.server_port}"
}

output "invite_code" {
  description = "Codigo de convite configurado para o servidor."
  value       = var.invite_code
}

output "instance_id" {
  description = "ID da instancia EC2."
  value       = aws_instance.windrose.id
}

output "instance_type" {
  description = "Tipo de instancia EC2 em uso."
  value       = aws_instance.windrose.instance_type
}
