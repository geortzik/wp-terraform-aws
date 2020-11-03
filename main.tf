
#Require TF version to be same or greater than 0.12.13
terraform {
  required_version = ">=0.12.13"
  backend "s3" {
    bucket         = "myuniquetfk3ydumbucket"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "myuniqueddbdumtable"
    encrypt        = "true"
  }
}

#Download AWS provider
provider "aws" {
  region = "eu-central-1"
}

#Build an s3 bucket to store TF state
resource "aws_s3_bucket" "state_bucket" {
  bucket = "myuniquetfk3ydumbucket"

  #Encrypt the s3 bucket
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  #Keep a version history of the state file
  versioning {
    enabled = true
  }

}

#Build a DynamoDB to use for terraform state locking
resource "aws_dynamodb_table" "tf_lock_State" {
  name = "myuniqueddbdumtable"

  #Change the default billing mode
  billing_mode = "PAY_PER_REQUEST"

  #Hash key is required
  hash_key = "LockID"

  #Hash key must be an attribute
  attribute {
    name = "LockID"
    type = "S"
  }

}

resource "aws_vpc" "main" {
  cidr_block       = "190.160.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "190.160.1.0/24"

  tags = {
    Name = "Subnet1"
  }
}

resource "aws_instance" "vm1" {
  ami             = "ami-0c960b947cbb2dd16"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.vm1_sg.id]
}

resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "Allow all inbound traffic to ELB"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP"
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

resource "aws_security_group" "vm1_sg" {
  name        = "vm1_sg"
  description = "Allow HTTP inbound traffic from elb"

  ingress {
    description = "HTTP from elb"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "SSH from my local machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["94.66.145.102/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "elb1" {
  name               = "elb1"
  availability_zones = ["eu-central-1b", "eu-central-1a"]
  security_groups    = [aws_security_group.elb_sg.id]
  instances          = [aws_instance.vm1.id]

#  listener {
#    instance_port     = 80
#    instance_protocol = "http"
#    lb_port           = 80
#    lb_protocol       = "http"
#  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
  }
}

resource "aws_db_instance" "db_1" {
  allocated_storage    = 20
# storage_type         = "gp2"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "db1"
# username             = "foo"
# password             = "foobarbaz"
  port                 = 3306
  availability_zone    = "eu-central-1b"
}
