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

#AWS variables

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "aws_ig_id" {
  description = "AWS internet gateway id"
  type        = string
  default     = "CHANGEME"
}

variable "aws_av_zone_1" {
  description = "AWS availability zone 1"
  type        = string
  default     = "eu-west-3a"
}

variable "aws_av_zone_2" {
  description = "AWS availability zone 2"
  type        = string
  default     = "eu-west-3b"
}


#Remote state variables

variable "bucket_name" {
  description = "Unique name of the s3 state bucket"
  type        = string
  default     = "myuniquebucketname"
}

variable "dynamodb_table_name" {
  description = "Unique name of the dynamodb table"
  type        = string
  default     = "myuniquetablename"
}


#Subnet variables

variable "subnet_cidr_block_1" {
  description = "CIDR block for subnet1"
  type        = string
  default     = "192.0.2.128/26"
}

variable "subnet_cidr_block_2" {
  description = "CIDR block for subnet2"
  type        = string
  default     = "192.0.2.192/26"
}

#Local machine variables for SSH

variable "my_ip" {
  description = "CIDR block for SSH"
  type        = string
  default     = "192.0.2.0/32"
}

#VM instance variables - free tier eligible

variable "vm_ami_id" {
  description = "AMI for the provisioned VM instance"
  type        = string
  default     = "CHANGEME"
}

variable "vm_instance_type" {
  description = "Instance type for the provisioned VM instance"
  type        = string
  default     = "t2.micro"
}


#Domain variables

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "example.com"
}

variable "zone_id" {
  description = "Zone id"
  type        = string
  default     = "CHANGEME"
}


#RDS db instance variables - free tier eligible

variable "db_engine" {
  description = "Engine for the RDS db instance"
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "Instance class for the RDS db instance"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "RDS db instance name"
  type        = string
  default     = "db"
}

variable "db_username" {
  description = "Username for the RDS db instance"
  type        = string
  default     = "rds_admin"
}

#Public key var

variable "public_key" {
  description = "Public key for the key pair"
  type        = string
  default     = "CHANGEME"
}
