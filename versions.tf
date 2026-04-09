terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "siddhsuresh_dev"

    workspaces {
      name = "dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
