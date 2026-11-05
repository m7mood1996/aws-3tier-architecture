



# 1. Find the latest free-tier eligible Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# 2. Launch Template (Defines what the EC2 instances look like)
resource "aws_launch_template" "app" {
  name_prefix   = "saa-app-template-"
  
  # Official Amazon Linux 2023 AMI for eu-north-1
  image_id      = "ami-0705384c0b33c194c" 
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Forces the startup sequence to execute simple echoes without calling public repo mirrors
  user_data = base64encode(<<-EOF
              #!/bin/bash
              cd /
              mkdir web
              cd web
              echo "<h1>Hello from the Private Tier in Tech! (Offline Python Server)</h1>" > index.html
              
              # Starts a built-in background web server on Port 80 with zero internet downloads needed
              sudo python3 -m http.server 80 &
              EOF
  )
}

# 3. Auto Scaling Group (Deploys instances across BOTH private subnets)
resource "aws_autoscaling_group" "app_asg" {
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "saa-app-worker"
    propagate_at_launch = true
  }
}