resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true      
  enable_dns_hostnames = true     

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-subnet-b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "strapi_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-strapi-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-rds-sg"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.strapi_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# SSH key for EC2 access
resource "aws_key_pair" "strapi_key" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/strapi-key.pub")
}

resource "aws_instance" "strapi" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.strapi_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -e

              apt-get update -y
              apt-get install -y docker.io docker-compose-plugin netcat

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ubuntu

              mkdir -p /opt/strapi
              cat <<EOD > /opt/strapi/docker-compose.yml
              version: '3'
              services:
                strapi:
                  image: strapi/strapi
                  restart: always
                  environment:
                    DATABASE_CLIENT: postgres
                    DATABASE_HOST: ${aws_db_instance.strapi.address}
                    DATABASE_PORT: 5432
                    DATABASE_NAME: ${var.db_name}
                    DATABASE_USERNAME: ${var.db_username}
                    DATABASE_PASSWORD: ${var.db_password}
                  ports:
                    - "1337:1337"
              EOD

              # ✅ Wait for RDS availability
              echo "Waiting for Postgres to be ready..."
              until nc -z ${aws_db_instance.strapi.address} 5432; do
                echo "Still waiting for Postgres..."
                sleep 10
              done

              echo "Postgres is ready! Starting Strapi..."
              docker compose -f /opt/strapi/docker-compose.yml up -d
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-db-"
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}

resource "aws_db_instance" "strapi" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  multi_az               = false

  tags = {
    Name = "${var.project_name}-rds"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "media" {
  bucket = "${var.project_name}-media-${random_id.bucket_id.hex}"

  tags = {
    Name = "${var.project_name}-media"
  }
}