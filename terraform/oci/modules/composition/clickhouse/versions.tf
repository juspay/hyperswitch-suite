terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0's JSON schema.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
