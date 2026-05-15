terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "siddhsuresh_dev"

    workspaces {
      name = "deployment_manager"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    domains = {
      source  = "ravion.com/ravion/domains"
      version = "~> 0.1"
    }
  }
}

provider "aws" {
  region = var.region
}
