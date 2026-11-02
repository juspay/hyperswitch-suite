terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # random_password.admin is a core resource here (OCI has no
    # manage_master_user_password equivalent), so the provider is pinned.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
