terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Resources and their verified doc IDs are listed in the check sheet.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # tls_private_key generates the break-glass keypair here; OCI has no
    # key-pair resource that generates material for you.
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
