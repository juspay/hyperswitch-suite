terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5"
}
