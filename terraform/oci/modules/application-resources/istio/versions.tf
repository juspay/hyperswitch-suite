terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # Declared but DELIBERATELY NOT CONFIGURED in this module - there is no
    # inline `provider "kubernetes"` / `provider "helm"` block here (a known
    # defect on the GCP modules, which could not plan as committed). The default
    # providers are inherited from the calling root's `generate "provider"`
    # block. PREREQUISITE: the OCI live root must emit `provider "helm"` and
    # `provider "kubernetes"` against the OKE cluster before this unit can plan.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}
