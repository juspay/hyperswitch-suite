terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      # Floor inherited from the nested ../alloydb module, which pins
      # >= 7.23, < 8.0 for GoogleCloudPlatform/alloy-db ~> 8.0. A looser
      # constraint here would still resolve to the same version but would
      # make this module look independently compatible with google 6.x,
      # which it is not.
      source  = "hashicorp/google"
      version = ">= 7.23, < 8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}
