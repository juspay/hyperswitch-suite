terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"

      # Glue across two regions: default provider = source region, aws.replica =
      # destination region. The caller passes both:
      #   providers = { aws = aws, aws.replica = aws.<replica-region> }
      configuration_aliases = [aws, aws.replica]
    }
  }
}
