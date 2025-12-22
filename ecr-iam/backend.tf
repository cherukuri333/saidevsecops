terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "saidevsecops-tf-state"
    key            = "ecr-iam/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "saidevsecops-tf-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
