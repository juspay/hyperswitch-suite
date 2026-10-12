# Runtime seed discovery.
# DEFAULT FLIPPED: AWS's create_seed_discovery defaults ON; enable_seed_discovery here
# defaults OFF. Turning it off removes a Function, a gateway, a container image
# pipeline and an IAM grant from the blast radius. What is given up: scaling out
# NEW nodes without re-applying and touching running nodes' user data.
# UNBUILT DEPENDENCY: seed_discovery_image is an OCIR CONTAINER IMAGE, whose artifact
# pipeline does not yet exist - required before enable_seed_discovery can be honest.

resource "oci_functions_application" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-seed-discovery"

  # Same subnet as the nodes, so the PRIVATE gateway and the compute API are reachable.
  subnet_ids = [var.subnet_id]

  network_security_group_ids = local.nsg_ids

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_functions_function" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  application_id = oci_functions_application.seed_discovery[0].id
  display_name   = "${local.name_prefix}-seed-discovery"

  # Fails at plan time when discovery is on and no image was supplied.
  image = var.seed_discovery_image

  memory_in_mbs = var.seed_discovery_memory_in_mbs

  config = {
    CLUSTER_TAG_NAME  = var.cluster_tag_name
    CLUSTER_TAG_VALUE = var.cluster_tag_value
    COMPARTMENT_ID    = var.compartment_id
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_apigateway_gateway" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-seed-discovery-gw"

  # PRIVATE matches AWS's endpoint_type = "PRIVATE"; OCI's private gateway is
  # simply attached to a subnet - no PrivateLink VPC endpoint needed.
  endpoint_type = var.seed_discovery_gateway_endpoint_type
  subnet_id     = var.subnet_id

  network_security_group_ids = local.nsg_ids

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_apigateway_deployment" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  compartment_id = var.compartment_id
  gateway_id     = oci_apigateway_gateway.seed_discovery[0].id
  display_name   = "${local.name_prefix}-seed-discovery"
  path_prefix    = "/"

  specification {
    routes {
      path    = var.seed_discovery_path
      methods = ["GET"]

      # Verified in provider 9.0.0's schema: the route backend accepts type + function_id.
      backend {
        type        = "ORACLE_FUNCTIONS_BACKEND"
        function_id = oci_functions_function.seed_discovery[0].id
      }
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
