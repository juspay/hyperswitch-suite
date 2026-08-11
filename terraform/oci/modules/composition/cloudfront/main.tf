# ============================================================================
# GAP MODULE - see README.md.
#
# OCI has no general-purpose CDN PaaS with a Terraform resource (unlike AWS
# CloudFront, Azure CDN, or GCP Cloud CDN). This module does NOT provide edge
# caching, edge functions, or PoP-based content delivery - it only attaches
# OCI Web Application Firewall to the load balancer, which is the closest
# managed edge-security layer OCI offers. No verified registry module exists
# for OCI WAF - raw oci provider resource.
# ============================================================================
resource "oci_waf_web_app_firewall" "this" {
  compartment_id             = var.compartment_id
  display_name               = coalesce(var.display_name, "${var.environment}-${var.project_name}-waf")
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = var.load_balancer_id
  web_app_firewall_policy_id = var.web_app_firewall_policy_id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
