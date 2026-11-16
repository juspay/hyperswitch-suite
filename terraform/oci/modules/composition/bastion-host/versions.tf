terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Every argument in this module was read out of oracle/oci 9.0.0's own JSON
    # schema (`terraform providers schema -json`), not from memory. The
    # resources used and the doc IDs the check sheet verified them against:
    #   oci_bastion_bastion       13481373
    #   oci_bastion_session       13481374  (NOT created here - see main.tf)
    #   oci_logging_log_group     13482063
    #   oci_core_instance         (core compute)
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}
