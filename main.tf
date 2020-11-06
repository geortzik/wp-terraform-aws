# wp-terraform-aws
# Copyright (C) 2020 Georgios Tzikas
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#Require TF version to be same or greater than 0.12.13
terraform {
  required_version = ">=0.12.13"
  backend "s3" {
    bucket         = "myuniquebucketname"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "myuniquetablename"
    encrypt        = "true"
  }
}

#Download AWS provider
provider "aws" {
  region = var.aws_region
}

#Build an s3 bucket to store TF state
resource "aws_s3_bucket" "state_bucket" {
  bucket = var.bucket_name

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
  name = var.dynamodb_table_name

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

#Adopt default VPC into management
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


data "aws_internet_gateway" "default" {
  internet_gateway_id = var.aws_ig_id
}

#Create subnet1
resource "aws_subnet" "subnet1" {
  availability_zone = var.aws_av_zone_1
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = var.subnet_cidr_block_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet for eu-west-3a"
  }
}

#Create subnet2
resource "aws_subnet" "subnet2" {
  availability_zone = var.aws_av_zone_2
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = var.subnet_cidr_block_2
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet for eu-west-3b"
  }
}

resource "aws_route_table" "r1" {
  vpc_id = aws_default_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }


  tags = {
    Name = "Subnet1 route table"
  }
}

resource "aws_route_table" "r2" {
  vpc_id = aws_default_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }


  tags = {
    Name = "Subnet2 route table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r1.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r2.id
}

#Create vm instance vm1
resource "aws_instance" "vm1" {
  ami                     = var.vm_ami_id
  instance_type           = var.vm_instance_type
  vpc_security_group_ids  = [aws_security_group.vm1_sg.id]
  subnet_id               = aws_subnet.subnet1.id
  key_name                = aws_key_pair.deployer.id
}

#Deploy key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

#Create security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow all inbound traffic to LB"
  vpc_id      = aws_default_vpc.default.id

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

#Create security group for the vm instance
resource "aws_security_group" "vm1_sg" {
  name        = "vm1_sg"
  description = "Allow HTTP inbound traffic from lb"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "HTTP from lb"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

ingress {
    description = "SSH from my local machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create load balancer target group
resource "aws_lb_target_group" "lbtg" {
  name     = "lbtg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

#Create load balancer target group attachment
resource "aws_lb_target_group_attachment" "lbatt" {
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

#Create load balancer
resource "aws_lb" "lb1" {
  name                = "lb1"
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.lb_sg.id]
  subnets             = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

}

#Create load balancer listener
resource "aws_lb_listener" "lb1_listener" {
  certificate_arn   = aws_acm_certificate_validation.default.certificate_arn
  load_balancer_arn = aws_lb.lb1.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }
}

#Redirect action
resource "aws_lb_listener" "lb1_listener2" {
  load_balancer_arn = aws_lb.lb1.arn
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


#Create a cert for our domain name
resource "aws_acm_certificate" "default" {
  domain_name               = var.domain_name
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy   = true
  }
}

#Create route53 CNAME record for validation
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

#Successful validation
resource "aws_acm_certificate_validation" "default" {
  certificate_arn          = aws_acm_certificate.default.arn

  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

#Create alias record for the lb
resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias{
    name                   = aws_lb.lb1.dns_name
    zone_id                = aws_lb.lb1.zone_id
    evaluate_target_health = true
  }
}

#Create a random password for RDS db instance
resource "random_password" "password" {
  length = 16
  special = true
  override_special = "!$%"
}

#Create an RDS db instance
resource "aws_db_instance" "db_1" {
  allocated_storage    = 20
  engine               = var.db_engine
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = random_password.password.result
  port                 = 3306
  availability_zone    = var.aws_av_zone_2
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true

}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

output "db_password" {
  value       = aws_db_instance.db_1.password
  description = "The password for logging in to the database."
  sensitive   = true
}

