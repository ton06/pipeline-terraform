# =============================================================================
# outputs.tf — Valores exibidos apos o terraform apply
# =============================================================================

output "server_public_ip" {
  description = "IP publico fixo do servidor Windrose (Elastic IP). Compartilhe com os amigos para conexao direta."
  value       = aws_eip.windrose.public_ip
}

output "server_public_dns" {
  description = "DNS publico do servidor."
  value       = aws_eip.windrose.public_dns
}

output "rdp_connection" {
  description = "Endereco para acesso RDP ao servidor Windows. Abra o Remote Desktop Connection e use este endereco."
  value       = "${aws_eip.windrose.public_ip}:3389"
}

output "game_connection_address" {
  description = "Endereco de conexao direta para os jogadores (IP:porta). Use no campo 'Connect to Server' do Windrose."
  value       = "${aws_eip.windrose.public_ip}:${var.direct_connection_port}"
}

output "invite_code" {
  description = "Codigo de convite configurado para o servidor."
  value       = var.invite_code
}

output "instance_id" {
  description = "ID da instancia EC2. Util para gerenciar via AWS CLI (start/stop)."
  value       = aws_instance.windrose.id
}

output "instance_type" {
  description = "Tipo de instancia EC2 em uso."
  value       = aws_instance.windrose.instance_type
}
