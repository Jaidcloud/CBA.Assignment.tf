provider "aws" {
  region = var.region
}

# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# 2. Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# 3. Create Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# 4. Create Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zones[1]
  tags = {
    Name = "private-subnet-2"
  }
}

# 5. Create Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt"
  }
}

# 6. Associate Route Tables with Subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 7. Create NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
}

# 8. Add route to private route table for NAT gateway
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# 9. Create Elastic Load Balancers
resource "aws_lb" "internet_facing_lb" {
  name               = "internet-facing-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "InternetFacingLB"
  }
}

resource "aws_lb" "internal_lb" {
  name               = "app-internal-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "app-internal-lb"
  }
}

# 10. Create Security Groups
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id
  name   = "lb_sg"

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

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id
  name   = "app_sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 11. Create Target Groups
resource "aws_lb_target_group" "internet_tg" {
  name     = "internet-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path              = "/"
    unhealthy_threshold = 2
  }

  tags = {
    Name = "InternetTG"
  }
}

resource "aws_lb_target_group" "internal_tg" {
  name     = "app-internal-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path             = "/"
    unhealthy_threshold = 2
  }

  tags = {
    Name = "InternalTG"
  }
}

# 12. Create Auto Scaling Group
resource "aws_launch_template" "app_lt" {
  name          = "app-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-instance"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

# 13. Create a Bastion Host in a Public Subnet
resource "aws_instance" "bastion" {
  ami             = var.bastion_ami_id
  instance_type   = var.bastion_instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.public_1.id
  security_groups = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  name   = "bastion_sg"

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
}

