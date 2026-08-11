terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 8.14.0"
      configuration_aliases = [oci.home]
    }
  }
}
