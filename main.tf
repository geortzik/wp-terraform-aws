
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

#Adopt default VPC into management
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#resource "aws_internet_gateway" "gw" {
#  vpc_id = aws_default_vpc.default.id
#
#  tags = {
#    Name = "main"
#  }
#}


data "aws_internet_gateway" "default" {
  internet_gateway_id = "igw-00882b6b"
}

#Create subnet1
resource "aws_subnet" "subnet1" {
  availability_zone = "eu-central-1a"
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = "172.31.254.0/24"

  tags = {
    Name = "Subnet for eu-central-1a"
  }
}

#Create subnet2
resource "aws_subnet" "subnet2" {
  availability_zone = "eu-central-1b"
  vpc_id            = aws_default_vpc.default.id
  cidr_block        = "172.31.255.0/24"

  tags = {
    Name = "Subnet for eu-central-1b"
  }
}

resource "aws_route_table" "r1" {
  vpc_id = aws_default_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

#  route {
#    cidr_block             = "172.31.0.0/16"
#    local_gateway_id = 
#  }

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

#  route {
#    cidr_block             = "172.31.0.0/16"
#    local_gateway_id =      
#  }

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
  ami                     = "ami-0c960b947cbb2dd16"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.vm1_sg.id]
  subnet_id               = aws_subnet.subnet1.id
 # depends_on              = [aws_internet_gateway.default]

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
    cidr_blocks = ["188.4.230.124/32"]
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
#  availability_zones  = ["eu-central-1b", "eu-central-1a"]
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.lb_sg.id]
  subnets             = ["aws_subnet.subnet1.id", "aws_subnet.subnet2.id"]

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
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.lb1_listener.arn

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    http_header {
      http_header_name = "X-Forwarded-For"
      values           = ["192.168.1.*"]
    }
  }
}

#Create a cert for our domain name
resource "aws_acm_certificate" "default" {
  domain_name               = "www.aws-gt.nkorb.gr"
#  subject_alternative_name  = "aws-gt.nkorb.gr"
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
  zone_id = "Z020595615Z5MST8DWA0V"
}

#Successful validation
resource "aws_acm_certificate_validation" "default" {
  certificate_arn          = aws_acm_certificate.default.arn

  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

#Create a random password for RDS db instance
resource "random_password" "password" {
  length = 16
  special = true
  override_special = "%@/_"
}

#Create an RDS db instance
resource "aws_db_instance" "db_1" {
  allocated_storage    = 20
# storage_type         = "gp2"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "db1"
  username             = "foo"
  password             = random_password.password.result
  port                 = 3306
  availability_zone    = "eu-central-1b"
  db_subnet_group_name = "aws_db_subnet_group.default"
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["aws_subnet.subnet1.id", "aws_subnet.subnet2.id"]

  tags = {
    Name = "My DB subnet group"
  }
}


