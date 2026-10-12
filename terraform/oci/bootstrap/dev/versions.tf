terraform {
  # >= 1.12.0 is the release that added the first-party `oci` backend this
  # bootstrap exists to make usable. Below it, the bucket created here has no
  # backend type able to address it. Same floor as the module, restated here so
  # a human running this root hits the version error before the apply, not
  # after. See ../../modules/composition/object-storage-backend/README.md.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
