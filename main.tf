terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "recipe_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "recipe_igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "recipe_public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "recipe_public-subnet-2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "recipe_private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "recipe_private-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "recipe_public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

#Security groups
resource "aws_security_group" "alb" {
  name        = "recipe_alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "recipe_alb-sg"
  }
}

resource "aws_security_group" "ec2" {
  name        = "recipe_ec2-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "recipe_ec2-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "recipe_rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "recipe_rds-sg"
  }
}


# S3 BUCKET - privremeno zakomentirano
# Kreira se rucno u AWS konzoli

/*
resource "aws_s3_bucket" "static_assets" {
  bucket = var.s3_bucket_name
  tags = {
    Name = "recipe_static-assets"
  }
}
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket                  = aws_s3_bucket.static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_object" "logo" {
  bucket       = aws_s3_bucket.static_assets.id
  key          = "assets/logo1.png"
  source       = var.logo_file_path
  content_type = "image/png"
}
*/

 #RDS
resource "aws_db_subnet_group" "main" {
  name       = "recipe_db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "recipe_db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "recipe-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  tags = {
    Name = "recipe_postgres"
  }
}

#pronalazk ispravnost AMI ID-a

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user

    docker pull maidakam/projekat1_iso-backend:latest
    docker run -d -p 5000:5000 --name backend \
      -e DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.address}:5432/${var.db_name} \
      maidakam/projekat1_iso-backend:latest

    docker pull maidakam/projekat1_iso-frontend:latest
    docker run -d -p 3000:80 --name frontend \
      maidakam/projekat1_iso-frontend:latest

  EOF
}

# EC2 -1
resource "aws_instance" "app_1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = local.user_data
  tags = {
    Name = "recipe_instance-1"
  }
}

# EC2 -2
resource "aws_instance" "app_2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = local.user_data

  tags = {
    Name = "recipe_instance-2"
  }
}

# Aplication load balancer
resource "aws_lb" "main" {
  name               = "recipe-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "recipe_alb"
  }
}

# Target Group - Frontend (nginx port 3000)
resource "aws_lb_target_group" "frontend" {
  name     = "recipe-frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
  }
  tags = {
    Name = "recipe_frontend-tg"
  }
}
# Target Group - Backend (Flask port 5000)
resource "aws_lb_target_group" "backend" {
  name     = "recipe-backend-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/recipes"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "recipe_backend-tg"
  }
}

# Registracija instanci u Frontend TG
resource "aws_lb_target_group_attachment" "frontend_1" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.app_1.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "frontend_2" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.app_2.id
  port             = 3000
}

# Registracija instanci u Backend TG
resource "aws_lb_target_group_attachment" "backend_1" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.app_1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "backend_2" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.app_2.id
  port             = 5000
}

# ALB Listener - port 80, default ide na frontend
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ALB Rule - /recipes/* ide na backend
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/recipes", "/recipes/*"]
    }
  }
}
