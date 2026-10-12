# =============================================================================
# oke - provider requirements
# =============================================================================
#
# Port note (AWS `composition/eks` -> OCI `composition/oke`):
# The AWS module needs only the `aws` provider. This module needs five, because
# the registry module it wraps (`oracle-terraform-modules/oke/oci`) declares
# them: `helm`/`cloudinit`/`random`/`time`/`null` are pulled in by features we
# deliberately leave switched off (Helm installers, operator cloud-init), but
# Terraform still requires the provider blocks to resolve.
#
# `oci.home` is NOT declared as a `configuration_aliases` entry here on purpose.
# The registry module declares it because its IAM sub-module must write
# dynamic groups and policies in the tenancy's home region. We pass the default
# provider into that slot in `main.tf` (`providers = { oci.home = oci }`), which
# is safe only because `create_iam_resources = false` - see the comment there.
# Declaring the alias here would force every consuming live root's generated
# provider block to grow a second `provider "oci" { alias = "home" }`, and
# root.hcl is hand-written per environment. See gap 4.1 in
# docs/multi-cloud-parity/oci/modules/eks.md.

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
