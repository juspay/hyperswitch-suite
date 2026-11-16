terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0 - every argument used by this module was
    # read out of that provider's own JSON schema in-session, not from memory.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }

    # Keeper-before-server ordering. `time` is not cloud-scoped, so this ports
    # unchanged.
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
