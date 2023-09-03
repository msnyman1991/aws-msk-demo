terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "${data.aws_caller_identity.current.account_id}-terraform-state"
    region         = "eu-west-1"
    key            = "aws-msk-demo.tfstate"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  # default_tags {
  #   tags = {

  #   }
  # }
  region = "eu-west-1"
}