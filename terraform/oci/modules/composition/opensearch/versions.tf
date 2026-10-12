terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0 - every argument used by this module was
    # read out of that provider's own JSON schema in-session, not from memory.
    # See README.md, which records what that reading resolved and disproved.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
