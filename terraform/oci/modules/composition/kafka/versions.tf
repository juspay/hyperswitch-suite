terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0 - every argument used by this module was
    # read out of that provider's own JSON schema in-session
    # (`terraform providers schema -json`), not from memory. See README.md
    # "Provider verification".
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # Unchanged from the AWS module: the SSH key pair is generated with `tls`
    # on every cloud. Only the escrow destination changes (SSM -> OCI Vault).
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }

    # time_sleep.wait_for_controller is a straight carry-over from the AWS
    # module. The `time` provider is not cloud-scoped, so this is one of the
    # very few resources that ports byte-for-byte.
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
