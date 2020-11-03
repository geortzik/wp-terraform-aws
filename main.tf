
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
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "190.160.1.0/24"

  tags = {
    Name = "Subnet1"
  }
}

#resource "aws_instance" "vm1" {
#  ami           = "ami-0c960b947cbb2dd16"
#  instance_type = "t2.micro"
#}
