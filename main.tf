terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project = local.name_prefix
      Managed = "terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "Perfil de credenciales AWS (archivo ~/.aws/credentials)"
  default     = "web-app"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR para la VPC"
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR para la subred pública"
  default     = "10.20.1.0/24"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Desde dónde permitir SSH (recomendado: tu IP /32)"
  default     = "0.0.0.0/0"
}

locals {
  name_prefix = "web-app"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name_prefix}-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "subnet_assoc" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Permitir SSH, HTTP y HTTPS"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key_pem" {
  filename        = "${path.module}/${local.name_prefix}.pem"
  file_permission = "0600"
  content         = tls_private_key.ssh.private_key_pem
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*",
      "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-arm64-server-*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.this.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.this.key_name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get install -y nginx openssl curl

    cat > /var/www/html/index.html <<'EOT'
    <!doctype html>
    <html lang="es">
      <head><meta charset="utf-8"><title>Prueba técnica</title></head>
      <body style="font-family:Arial,Helvetica,sans-serif;text-align:center;margin-top:10vh;">
        <h1>¡Bienvenido a la prueba técnica de AWS!</h1>
      </body>
    </html>
    EOT

    mkdir -p /etc/nginx/ssl

    CN=$(curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/public-hostname || echo localhost)

    openssl req -x509 -nodes -days 365 \
      -subj "/C=CO/ST=Bogota/L=Bogota/O=Demo/OU=IT/CN=$${CN}" \
      -newkey rsa:2048 \
      -keyout /etc/nginx/ssl/selfsigned.key \
      -out /etc/nginx/ssl/selfsigned.crt

    chmod 600 /etc/nginx/ssl/selfsigned.key

    cat > /etc/nginx/sites-available/web-app <<'NGINXCONF'
    server {
      listen 80 default_server;
      listen [::]:80 default_server;
      server_name _;
      return 301 https://$host$request_uri;
    }

    server {
      listen 443 ssl http2 default_server;
      listen [::]:443 ssl http2 default_server;
      server_name _;

      ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
      ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
      ssl_protocols       TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;

      root /var/www/html;
      index index.html;

      location / {
        try_files $uri $uri/ =404;
      }
    }
    NGINXCONF

    ln -sf /etc/nginx/sites-available/web-app /etc/nginx/sites-enabled/web-app
    rm -f /etc/nginx/sites-enabled/default || true

    nginx -t
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = {
    Name = "${local.name_prefix}-server-1"
  }
}

output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "IP pública del servidor"
}

output "public_dns" {
  value       = aws_instance.web.public_dns
  description = "DNS público del servidor"
}

output "http_url" {
  value       = "http://${aws_instance.web.public_dns}"
  description = "URL HTTP"
}

output "https_url" {
  value       = "https://${aws_instance.web.public_dns}"
  description = "URL HTTPS (certificado autofirmado)"
}

output "ssh_private_key_pem_path" {
  value       = local_file.private_key_pem.filename
  description = "Ruta del .pem para conectar por SSH"
  sensitive   = true
}
