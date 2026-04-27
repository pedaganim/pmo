variable "tenant_id" {}
variable "domain_name" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "cluster_id" {}
variable "alb_listener_arn" {}
variable "backend_image" {}
variable "frontend_image" {}

# --- Database ---
resource "aws_db_instance" "tenant_db" {
  identifier           = "pmo-db-${var.tenant_id}"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  db_name              = "pmo_${var.tenant_id}"
  username             = "pmo_admin"
  password             = "secure_password_here" # Use Secrets Manager in production
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.tenant_db_subnet.name
}

resource "aws_db_subnet_group" "tenant_db_subnet" {
  name       = "pmo-db-subnet-${var.tenant_id}"
  subnet_ids = var.private_subnets
}

# --- ECS Service ---
resource "aws_ecs_task_definition" "tenant_task" {
  family                   = "pmo-task-${var.tenant_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      portMappings = [{ containerPort = 8080 }]
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.tenant_db.endpoint}/${aws_db_instance.tenant_db.db_name}" },
        { name = "SPRING_DATASOURCE_USERNAME", value = aws_db_instance.tenant_db.username },
        { name = "SPRING_DATASOURCE_PASSWORD", value = aws_db_instance.tenant_db.password }
      ]
    },
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      portMappings = [{ containerPort = 80 }]
    }
  ])
}

resource "aws_ecs_service" "tenant_service" {
  name            = "pmo-service-${var.tenant_id}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.tenant_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tenant_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }
}

# --- ALB Routing ---
resource "aws_lb_target_group" "tenant_tg" {
  name        = "pmo-tg-${var.tenant_id}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener_rule" "tenant_rule" {
  listener_arn = var.alb_listener_arn
  priority     = 100 # In production, manage priorities dynamically

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant_tg.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

# --- Security Groups ---
resource "aws_security_group" "db_sg" {
  name   = "pmo-db-sg-${var.tenant_id}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.service_sg.id]
  }
}

resource "aws_security_group" "service_sg" {
  name   = "pmo-service-sg-${var.tenant_id}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Should be restricted to ALB SG in production
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
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
