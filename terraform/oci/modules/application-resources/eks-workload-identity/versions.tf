terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source = "oracle/oci"
      # >= 8.18.0 for the IdentityPropagationTrust JWT/RPST resource attributes
      # (claim_validations/claim_propagations/impersonating_resource/
      # subject_type="Resource"). Bump to >= 8.22.0 for the provider's NATIVE
      # auth="WorkloadIdentityFederation" mode (deploy workload, not this unit).
      version = ">= 8.18.0"
    }
  }
}