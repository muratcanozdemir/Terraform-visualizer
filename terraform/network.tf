
resource "aws_lb" "main" {
  # checkov:skip=CKV2_AWS_28: WAF stuff is complicated yall
  name                       = "ecs-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ecs_service_sg.id]
  subnets                    = var.private_subnet_ids
  enable_deletion_protection = true
  drop_invalid_header_fields = true
  access_logs {
    bucket  = "nlb-log-data-bucket"
    prefix  = "access-logs"
    enabled = true
  }
}

resource "aws_lb_target_group" "main" {
  name        = "ecs-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    protocol            = "HTTPS"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_ecs_service.main.id
  port             = 8000
}

resource "aws_route53_record" "main" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description = "Ingress"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
