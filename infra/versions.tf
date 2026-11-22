terraform {
  required_version = ">= 1.6"

  # Local state on purpose: one person, one environment, no extra AWS resources to pay for.
  # The state file contains the DB password, so it is gitignored. Upgrade path: S3 backend
  # with encryption and locking once more than one person (or CI) runs Terraform.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "skiscope"
      ManagedBy = "terraform"
    }
  }
}
