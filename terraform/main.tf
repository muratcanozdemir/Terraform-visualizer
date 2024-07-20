# TODO Fix Checkov shit
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_kms_key" "ecr" {
  enable_key_rotation     = true
  rotation_period_in_days = 7
  policy                  = <<POLICY
  {
    
  }
  POLICY
}

resource "aws_ecr_repository" "main" {
  # checkov:skip=CKV_AWS_51: We're not fancy version pushers
  name = "terraform-state-visualizer"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = KmsKeyARN
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "terraform-state-visualizer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  container_definitions = jsonencode([
    {
      name                   = "terraform-state-visualizer"
      image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/terraform-state-visualizer:latest"
      essential              = true
      readonlyRootFilesystem = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role
  task_role_arn      = aws_iam_role.ecs_task_role
}

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
}
