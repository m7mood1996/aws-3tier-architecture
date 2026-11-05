


# 1. ALB Security Group (Allows traffic from the entire public internet)
resource "aws_security_group" "alb_sg" {
  name        = "saa-alb-sg"
  description = "Allow public web traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the public internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. EC2 App Security Group (ONLY allows traffic coming from the ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "saa-ec2-sg"
  description = "Allow traffic ONLY from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Strict link to the ALB!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 3. Database Security Group (ONLY allows traffic from the EC2 Application instances)
resource "aws_security_group" "db_sg" {
  name        = "saa-db-sg"
  description = "Allow traffic ONLY from the EC2 tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432 # Default PostgreSQL port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Strict link to the EC2 App servers!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}