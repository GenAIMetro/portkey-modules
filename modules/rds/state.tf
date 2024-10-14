locals {
  backend_name = "${var.name}-terraform"
}
terraform {
  backend "s3"{
    key = "dev/rds.tfstate"
    bucket = "${local.backend_name}-state"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = var.region
    bucket = "${local.backend_name}-state"
    key    = "dev/vpc.tfstate"
  }
}
