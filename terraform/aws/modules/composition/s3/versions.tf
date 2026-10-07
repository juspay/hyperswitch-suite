terraform {
  # terraform-aws-modules/s3-bucket/aws 5.0.0 required >= 1.10, but 5.1.0+
  # relaxed it back to >= 1.5.7; ~> 5.0 resolves to the latest 5.x, so match that.
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.2"
    }
  }
}
