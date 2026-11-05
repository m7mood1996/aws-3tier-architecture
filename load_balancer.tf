


# 1. The Application Load Balancer (Deploys into PUBLIC subnets)
resource "aws_lb" "external_alb" {
  name               = "saa-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "saa-alb"
  }
}

# 2. The Target Group (tells the ALB where to route traffic)
resource "aws_lb_target_group" "app_tg" {
  name     = "saa-app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# 3. The Listener (Listens on public Port 80 and forwards to the Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Attach the Auto Scaling Group to the Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.id
  lb_target_group_arn   = aws_lb_target_group.app_tg.arn
}