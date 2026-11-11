data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

resource "random_password" "db_root_password" {
  length  = 24
  special = false
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "random_password" "secret_key" {
  length  = 48
  special = false
}

resource "aws_security_group" "server" {
  name        = "${var.project_name}-sg"
  description = "Security group for Smart City backend and reverse proxy"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP (Caddy / Nginx reverse proxy)
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Caddy auto SSL)
  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FastAPI direct port (optional direct access)
  ingress {
    description = "FastAPI direct port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.server.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive

              # 1. Setup 2GB Swap for build/runtime headroom
              if [ ! -f /swapfile ]; then
                  fallocate -l 2G /swapfile
                  chmod 600 /swapfile
                  mkswap /swapfile
                  swapon /swapfile
                  echo '/swapfile none swap sw 0 0' >> /etc/fstab
              fi

              # 2. Install Docker & Compose plugin
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release git

              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc

              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              systemctl enable --now docker
              usermod -aG docker ubuntu

              # 3. Clone repository
              mkdir -p /opt/smartcity
              cd /opt/smartcity

              if [ ! -d "/opt/smartcity/.git" ]; then
                  git clone https://github.com/kavishi-dev-team/smartcity-ai-platform.git .
              fi

              git fetch origin
              git checkout main
              git pull origin main

              # 4. Generate production environment file
              cat << 'ENVEOF' > .env.prod
              APP_NAME=SmartCityAI
              APP_ENV=production
              DEBUG=false
              API_V1_PREFIX=/api/v1

              MYSQL_ROOT_PASSWORD=${random_password.db_root_password.result}
              MYSQL_DATABASE=smartcity_db
              MYSQL_USER=smartcity_user
              MYSQL_PASSWORD=${random_password.db_password.result}

              DATABASE_URL=mysql+pymysql://smartcity_user:${random_password.db_password.result}@mysql:3306/smartcity_db
              SECRET_KEY=${random_password.secret_key.result}
              ACCESS_TOKEN_EXPIRE_MINUTES=60
              REFRESH_TOKEN_EXPIRE_DAYS=7

              AI_API_KEY=${var.ai_api_key}
              AI_MODEL=${var.ai_model}
              ENVEOF

              chown -R ubuntu:ubuntu /opt/smartcity

              # 5. Build and launch Docker Compose stack
              docker compose -f docker-compose.prod.yml down || true
              docker compose -f docker-compose.prod.yml up -d --build
              EOF

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  }
}

resource "aws_eip" "server" {
  instance = aws_instance.server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
  }
}
