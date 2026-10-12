locals {
  name_prefix = "${var.environment}-${var.project_name}-istio"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "istio"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  nsg_display_name = coalesce(var.nsg_display_name, "${local.name_prefix}-gateway-nsg")

  gateway_nsg_ids = compact(concat(
    var.create_gateway_nsg ? [one(oci_core_network_security_group.gateway[*].id)] : [],
    var.gateway_nsg_ids,
  ))

  # The CCM annotation map, read by the OCI Cloud Controller Manager that every
  # OKE cluster already runs.
  ccm_annotations = merge(
    {
      # L7 (`lb`) mirrors AWS's ALB; L4 (`nlb`) mirrors GCP. Unresolved fork.
      "oci.oraclecloud.com/load-balancer-type" = var.load_balancer_type

      # Must be "None": left unset it defaults to "All", and the CCM
      # auto-manages VCN security-list rules to wire the LB to the worker
      # NodePort range. Security-list and NSG rules combine with UNION
      # semantics, so CCM-created list rules would silently widen a posture
      # nothing in Terraform describes. This annotation makes the backend wiring
      # a hand-authored NSG rule instead. Ship it together with that rule.
      "service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode" = "None"
    },

    length(local.gateway_nsg_ids) > 0 ? {
      "oci.oraclecloud.com/oci-network-security-groups" = join(",", local.gateway_nsg_ids)
    } : {},

    var.create_gateway_reserved_ip ? {
      "oci.oraclecloud.com/reserved-ips" = one(oci_core_public_ip.gateway[*].id)
    } : {},

    # The CCM attaches a certificate by Kubernetes SECRET reference, not by ARN.
    var.tls_secret_ref != null && var.load_balancer_type == "lb" ? {
      "service.beta.kubernetes.io/oci-load-balancer-tls-secret" = var.tls_secret_ref
    } : {},

    var.gateway_service_annotations,
  )

  gateway_service_values = yamlencode(merge(
    {
      service = merge(
        {
          # On OCI the Service IS the load balancer: the CCM provisions a real
          # OCI Load Balancer from this plus the annotations above - no Helm
          # chart, no IAM role, no ServiceAccount.
          type        = "LoadBalancer"
          annotations = local.ccm_annotations
        },
        var.external_traffic_policy == null ? {} : { externalTrafficPolicy = var.external_traffic_policy },
      )
    }
  ))
}
