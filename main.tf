terraform {
  backend "s3" {
    bucket         = "terraform-state-ertdsaw" # choose your own bucket name
    key            = "state/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "my-terraform-locks" # choose your own DynamoDB table
    encrypt        = true
  }
}


provider "aws" {
  region = "eu-west-1" # Adjust this to your preferred AWS region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  # Assuming the default security group is named "default", adjust if your setup differs
  filter {
    name   = "group-name"
    values = ["default"]
  }
}


variable "db_username" {}
variable "db_password" {}

module "db" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "6.4.0"
  family                    = "mysql8.0"
  identifier                = "mydemo-mysql-db"
  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "mysql"
  engine_version       = "8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20

  manage_master_user_password = false
  db_name                     = "argocddemo"
  username                    = var.db_username
  password                    = var.db_password
  port                        = "3306"

  # Using the default VPC and subnets
  vpc_security_group_ids = [data.aws_security_group.default.id]
  publicly_accessible    = true

  # Backup, maintenance, and other settings
  backup_retention_period = 0 # Minimize costs; consider implications for real environments
  skip_final_snapshot     = true
  deletion_protection     = false
}

output "db_instance_endpoint" {
  value = module.db.db_instance_endpoint
}