terraform {
  required_version = "0.14.0-beta2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.16.0"
    }
  }
}
