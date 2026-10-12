terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0 (995 resources / 2395 data sources).
    # Every argument used by this module was read out of that provider's own
    # JSON schema, not from memory - see README.md "Provider verification".
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # random_password.admin is a core resource of this module (OCI Database
    # with PostgreSQL has no manage_master_user_password equivalent), so the
    # provider is pinned rather than implicitly installed. Same reasoning as
    # gcp/modules/composition/alloydb/versions.tf.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
