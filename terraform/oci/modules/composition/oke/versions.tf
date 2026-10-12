# oke - provider requirements.
#
# This module needs five extra providers (helm/cloudinit/random/time/null) only
# because the registry module it wraps declares them; they are pulled in by
# features we deliberately leave switched off, but Terraform still requires the
# provider blocks to resolve.
#
# `oci.home` is deliberately NOT declared as a `configuration_aliases` entry:
# we pass the default provider into that slot in main.tf
# (`providers = { oci.home = oci }`), which is safe only because
# create_iam_resources = false. Declaring the alias here would force every
# consuming root.hcl to add a second `provider "oci" { alias = "home" }`.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.1"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
