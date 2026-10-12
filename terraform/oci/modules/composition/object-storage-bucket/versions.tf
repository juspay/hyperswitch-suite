terraform {
  # 1.12.0 floor because the `oci` state backend only exists from 1.12.0; the tree
  # keeps one floor so a single terraform binary can run all of it.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
