terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
