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

output "ssh_connection" {
  description = "Comando SSH para acessar o servidor. Substitua 'seu-arquivo.pem' pelo caminho do seu Key Pair."
  value       = "ssh -i seu-arquivo.pem ubuntu@${aws_eip.windrose.public_ip}"
}

output "game_connection_address" {
  description = "Endereco de conexao direta para os jogadores (IP:porta). Use no campo 'Connect to Server' do Windrose."
  value       = "${aws_eip.windrose.public_ip}:${var.server_port}"
}

output "invite_code" {
  description = "Codigo de convite configurado para o servidor."
  value       = var.invite_code
}

output "instance_id" {
  description = "ID da instancia EC2. Util para gerenciar via AWS CLI ou script manage_instance.sh."
  value       = aws_instance.windrose.id
}

output "instance_type" {
  description = "Tipo de instancia EC2 em uso."
  value       = aws_instance.windrose.instance_type
}
