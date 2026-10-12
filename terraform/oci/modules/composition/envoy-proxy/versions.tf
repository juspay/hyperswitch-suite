terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Every argument in this module was read out of oracle/oci 9.0.0's own JSON
    # schema (`terraform providers schema -json`), not from memory. The
    # resources used and the doc IDs the check sheet verified them against:
    #   oci_core_instance_configuration            13481497
    #   oci_core_instance_pool                     13481500
    #   oci_autoscaling_auto_scaling_configuration 13481372
    #   oci_load_balancer_listener                 13482036
    #   oci_load_balancer_backend_set              13482033
    #   oci_load_balancer_load_balancer_routing_policy 13482038
    #   oci_waf_web_app_firewall                   13482313
    #   oci_objectstorage_object                   13482129
    #   oci_vault_secret                           13482294
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }

    # tls_private_key is a core resource of this module: OCI has no
    # aws_key_pair equivalent that generates material for you, so the
    # break-glass key is generated here exactly as the AWS module's
    # terraform-aws-modules/key-pair does. Pinned rather than implicitly
    # installed, same reasoning as database/versions.tf's random provider.
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
