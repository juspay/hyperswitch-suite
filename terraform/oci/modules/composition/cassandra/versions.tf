terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0 - every argument used by this module was
    # read out of that provider's own JSON schema in-session, not from memory.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # Unchanged from the AWS module. Only the escrow destination changes.
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
