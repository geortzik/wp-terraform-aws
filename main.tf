provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

resource "aws_instance" "elli" {
  ami           = "ami-0c960b947cbb2dd16"
  instance_type = "t2.micro"
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
