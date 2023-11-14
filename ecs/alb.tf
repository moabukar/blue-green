## Application Load balancer for directing traffic to the different ports.

resource "aws_security_group" "application_elb_sg" {
  vpc_id = var.vpc_id
  name   = "application_elb_sg"
}

resource "aws_security_group_rule" "application_elb_sg_ingress" {
  count             = length(var.elb_sg_ingress_ports)
  type              = "ingress"
  from_port         = var.elb_sg_ingress_ports[count.index]
  to_port           = var.elb_sg_ingress_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application_elb_sg.id
}

resource "aws_lb" "app_lb" {
  name               = "application_load_balancer"
  load_balancer_type = "application"
  subnets            = var.public_subnets[*].id
  idle_timeout       = 60
  security_groups    = [aws_security_group.application_elb_sg.id]
}

## Target groups (blue and green)

locals {
  target_groups = [
    "green",
    "blue",
  ]
}

resource "aws_lb_target_group" "tg" {
  count = length(local.target_groups)

  name        = "${var.lb_target_group_443_name}-${element(local.target_groups, count.index)}"
  port        = 443
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  health_check {
    matcher = "200,301,302,404"
    path    = "/"
  }

}

## ALB listeners ( 3 listeners — 443 which will be the one users communicate with, 80 as the main port and 8080 as the alternative port.)

resource "aws_alb_listener" "l_80" {
  load_balancer_arn = aws_lb.app_lb.arn
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

resource "aws_alb_listener" "l_8080" {
  load_balancer_arn = aws_lb.app_lb.id
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[1].arn
  }
}

resource "aws_alb_listener" "l_443" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = XXXX
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
  depends_on = [aws_lb_target_group.tg]

  lifecycle {
    ignore_changes = [default_action]
  }
}
