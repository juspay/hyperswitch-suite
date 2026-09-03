terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # GoogleCloudPlatform/alloy-db/google ~> 8.0 requires this floor -
      # stricter than composition/cloud-sql's >= 6.0.
      version = ">= 7.23, < 8.0"
    }
    # random_password.master is a core resource of this module, so the provider
    # gets pinned rather than implicitly installed.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
