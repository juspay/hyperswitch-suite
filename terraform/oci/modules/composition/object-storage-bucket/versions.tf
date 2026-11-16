terraform {
  # Matches every other OCI module in this tree. The 1.12.0 floor is inherited
  # from composition/object-storage-backend rather than re-derived: that module
  # needs it because the `oci` state backend only exists from 1.12.0, and this
  # tree keeps one floor so a single `terraform` binary can run all of it.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
