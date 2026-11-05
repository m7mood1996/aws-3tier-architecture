


# 1. Isolated Data Subnets
resource "aws_subnet" "data_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "eu-north-1a"
  tags              = { Name = "saa-data-1" }
}

resource "aws_subnet" "data_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "eu-north-1b"
  tags              = { Name = "saa-data-2" }
}

# 2. DB Subnet Group (Tells RDS which subnets it can use)
resource "aws_db_subnet_group" "db_segments" {
  name       = "saa-db-subnet-group"
  subnet_ids = [aws_subnet.data_1.id, aws_subnet.data_2.id]
  tags       = { Name = "Main DB Subnet Group" }
}

# 3. Database Instance (Free-Tier eligible engine & size)
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20 # 20GB is the Free-Tier baseline minimum
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # Free-Tier eligible instance
  db_name                = "israelihightechdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_segments.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  multi_az               = true # Essential for SAA-C03 production environments
}