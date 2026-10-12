terraform {
  # >= 1.12.0, NOT the >= 1.5.0 floor every AWS and GCP module in this repo
  # uses. Terraform 1.12.0 is the release that added the first-party `oci`
  # backend (hashicorp/terraform CHANGELOG, "Added Terraform backend
  # implementation for OCI Object Storage (#34465)"). Below that version the
  # bucket this module creates has no backend type that can talk to it, so the
  # floor is a hard functional requirement, not housekeeping.
  # See docs/multi-cloud-parity/oci/state-backend-decision.md sections 1 and 4.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
