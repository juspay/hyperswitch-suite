# =============================================================================
# Runtime seed discovery (SUBSTITUTE - check sheet feature 11, section 4.4)
# =============================================================================
# DEFAULT FLIPPED, and that is the headline of this file. The AWS module's
# create_seed_discovery defaults ON; enable_seed_discovery here defaults OFF.
# This is a deliberate behaviour change, not a mechanical port, and it removes
# functionality the AWS design intentionally provides. Check sheet section 8
# item 4: ORACLE GATE ITEM, NOT YET CONSULTED.
#
# WHY AWS BUILT IT. A node coming up after the initial apply - a replacement, or
# a scale-out - needs its peers' current addresses. On AWS those addresses were
# not knowable at boot without asking the cloud, so the module ships a Lambda
# that queries EC2 by tag and returns the IPs, fronted by a PRIVATE API Gateway
# at /CassandraSeedNode.
#
# WHY IT IS OFF HERE. OCI's reserved private IPs (network.tf) make each node's
# address a value Terraform holds, so the seed list can be injected at apply time
# instead of fetched at boot - see locals.tf's seed_ip_addresses note for the one
# condition that carries (the caller must PIN the addresses, otherwise the
# reserved IPs are only known after the instances exist and cannot feed their own
# user_data). Turning discovery off removes a Function, a gateway, a container
# image pipeline and an IAM grant from the blast radius.
#
# WHAT IS GIVEN UP. Scale-out of NEW nodes without re-applying and touching
# already-running nodes' user data. If that turns out to be a real operational
# requirement rather than a theoretical one, this path must be built AND tested
# before it is needed under pressure - not left as an unexercised escape hatch.
#
# THREE-WAY DIVERGENCE WORTH RECORDING: AWS needs two resources (Lambda + API
# Gateway) because a private Lambda has no HTTPS endpoint of its own. OCI needs
# two for the same reason - Functions are invoked "using the CLI or by making
# signed HTTP requests", with no bare trigger URL. GCP needs ONE, because a Cloud
# Run function has a native HTTPS endpoint. OCI does not get GCP's simplification.
#
# UNBUILT DEPENDENCY: seed_discovery_image. OCI Functions deploy from an OCIR
# CONTAINER IMAGE, not a zip. That artifact pipeline does not exist and is not
# owned by vm-tier-and-images.md (which owns VM images, not function containers).
# Check sheet open question 9.3.

resource "oci_functions_application" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-seed-discovery"

  # Same subnet as the nodes. The function needs to be inside the VCN for the
  # PRIVATE gateway to reach it and for it to reach the compute API through the
  # service gateway.
  subnet_ids = [var.subnet_id]

  network_security_group_ids = local.nsg_ids

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_functions_function" "seed_discovery" {
  count = local.seed_discovery_enabled ? 1 : 0

  application_id = oci_functions_application.seed_discovery[0].id
  display_name   = "${local.name_prefix}-seed-discovery"

  # Fails at plan time when enable_seed_discovery is on and no image was
  # supplied, which is the correct place to fail - better than an apply that
  # creates a Function pointing at nothing.
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

  # PRIVATE matches the AWS module's endpoint_type = "PRIVATE". Note what is NOT
  # needed: AWS's private API Gateway required a PrivateLink VPC endpoint
  # (api_gateway_vpce_id). An OCI private gateway is simply attached to a subnet,
  # so that variable is dropped rather than renamed.
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

      # VERIFIED in provider 9.0.0's own schema in-session: the route backend
      # accepts type + function_id, which resolves check sheet open question 9.1
      # ("does oci_apigateway_deployment actually support an oci_functions_function
      # backend") in the affirmative.
      backend {
        type        = "ORACLE_FUNCTIONS_BACKEND"
        function_id = oci_functions_function.seed_discovery[0].id
      }
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
