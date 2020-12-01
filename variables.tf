#AWS variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_ig_id" {
  description = "AWS internet gateway id"
  type        = string
  default     = "igw-00882b6b"
}

variable "aws_av_zone_1" {
  description = "AWS availability zone 1"
  type        = string
  default     = "eu-central-1a"
}

variable "aws_av_zone_2" {
  description = "AWS availability zone 2"
  type        = string
  default     = "eu-central-1b"
}


#Remote state variables

variable "bucket_name" {
  description = "Unique name of the s3 state bucket"
  type        = string
  default     = "myuniquetfk3ydumbucket"
}

variable "dynamodb_table_name" {
  description = "Unique name of the dynamodb table"
  type        = string
  default     = "myuniqueddbdumtable"
}


#Subnet variables

variable "subnet_cidr_block_1" {
  description = "CIDR block for subnet1"
  type        = string
  default     = "172.31.254.0/24"
}

variable "subnet_cidr_block_2" {
  description = "CIDR block for subnet2"
  type        = string
  default     = "172.31.255.0/24"
}


#VM instance variables - free tier eligible

variable "ami_id" {
  description = "AMI for the provisioned VM instance"
  type        = string
  default     = "ami-0c960b947cbb2dd16"
}

variable "instance_type" {
  description = "Instance type for the provisioned VM instance"
  type        = string
  default     = "t2.micro"
}


#Domain variables

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "www.aws-gt.nkorb.gr"
}

variable "zone_id" {
  description = "Zone id"
  type        = string
  default     = "Z020595615Z5MST8DWA0V"
}


#RDS db instance variables - free tier eligible

variable "db_engine" {
  description = "Engine for the RDS db instance"
  type        = string
  default     = "mysql"
}

variable "instance_class" {
  description = "Instance class for the RDS db instance"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "RDS db instance name"
  type        = string
  default     = "db1"
}

variable "db_username" {
  description = "Username for the RDS db instance"
  type        = string
  default     = "foo"
}

