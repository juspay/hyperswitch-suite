terraform {
  # terraform_data (used by the plan-time guards in guards.tf) needs >= 1.4;
  # optional object attributes with defaults need >= 1.3. Pinned to the same
  # floor the AWS and GCP composition modules use.
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
