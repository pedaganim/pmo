terraform {
  backend "s3" {
    bucket         = "pmo-terraform-state-967438331002" # CHANGE THIS to your bucket name
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "pmo-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
}


# --- VPC & Networking ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "pmo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "pmo_cluster" {
  name = "pmo-cluster"
}

# --- ECR Repositories ---
resource "aws_ecr_repository" "backend" {
  name                 = "pmo-backend"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "frontend" {
  name                 = "pmo-frontend"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

# --- ALB (Shared across tenants) ---
resource "aws_lb" "pmo_alb" {
  name               = "pmo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.pmo_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }
}

# --- Security Groups ---
resource "aws_security_group" "alb_sg" {
  name   = "pmo-alb-sg"
  vpc_id = module.vpc.vpc_id

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
}
