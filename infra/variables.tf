variable "bucket_name" {
  default = ""
  type    = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "ec2_instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.large"
}

variable "windrose_port" {
  description = "Port for Windrose game server"
  type        = number
  default     = 8000
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "windrose-game-server"
}
