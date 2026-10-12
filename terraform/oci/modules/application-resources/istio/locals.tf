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

  # ---------------------------------------------------------------------------
  # THE CCM ANNOTATION MAP - the direct replacement for AWS's
  # `local.ingress_annotations`.
  #
  # AWS's `alb.ingress.kubernetes.io/*` prefix becomes `oci.oraclecloud.com/*`
  # and `service.beta.kubernetes.io/oci-load-balancer-*`. These annotations are
  # read by the OCI Cloud Controller Manager, which every OKE cluster already
  # runs - there is no controller to install and no `Ingress` object involved.
  # ---------------------------------------------------------------------------
  ccm_annotations = merge(
    {
      # L7 (`lb`) mirrors AWS's ALB. L4 (`nlb`) mirrors GCP. Unresolved fork -
      # see the variable's own note and check sheet section 8 item 5.
      "oci.oraclecloud.com/load-balancer-type" = var.load_balancer_type

      # -----------------------------------------------------------------------
      # THE ANNOTATION THAT MUST NOT BE FORGOTTEN, and the reason it is set
      # unconditionally rather than exposed as a knob.
      #
      # This defaults to "All" in the CCM, which means: left alone, the CCM
      # AUTO-MANAGES VCN SECURITY LIST RULES to wire the load balancer to the
      # worker NodePort range for free. That is convenient and it is exactly
      # what network-security-model.md section 5 forbids - that document mandates
      # NSGs only and a neutered default security list, and OCI security-list and
      # NSG rules combine with UNION semantics, so CCM-created list rules would
      # silently widen a posture nothing in Terraform describes.
      #
      # Setting it to "None" makes the backend wiring (LB subnet -> worker
      # NodePorts 30000-32767, LB subnet -> kube-proxy health port 10256) a
      # hand-authored NSG rule instead of a free one. That rule belongs in
      # `composition/security-rules`, not here - see network-security.tf.
      #
      # THE RISK IS FORGETTING ONE OF THE TWO. Omit this annotation and the CCM
      # creates security-list rules that should not exist (silent widening).
      # Omit the `security-rules` addition and the load balancer cannot reach
      # any node (fails closed - a connectivity bug, not an exposure). Ship them
      # together.
      # -----------------------------------------------------------------------
      "service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode" = "None"
    },

    length(local.gateway_nsg_ids) > 0 ? {
      "oci.oraclecloud.com/oci-network-security-groups" = join(",", local.gateway_nsg_ids)
    } : {},

    var.create_gateway_reserved_ip ? {
      "oci.oraclecloud.com/reserved-ips" = one(oci_core_public_ip.gateway[*].id)
    } : {},

    # AWS attaches a certificate to the ALB by ACM ARN. The CCM attaches one by
    # KUBERNETES SECRET reference - a different mechanism, not a renamed field,
    # and the point at which acm.md's certificate-trust gap becomes concrete for
    # this module.
    var.tls_secret_ref != null && var.load_balancer_type == "lb" ? {
      "service.beta.kubernetes.io/oci-load-balancer-tls-secret" = var.tls_secret_ref
    } : {},

    var.gateway_service_annotations,
  )

  gateway_service_values = yamlencode(merge(
    {
      service = merge(
        {
          # AWS deploys this as ClusterIP behind an Ingress. On OCI the Service
          # IS the load balancer: the built-in CCM provisions a real OCI Load
          # Balancer from this line plus the annotations above, with no Helm
          # chart, no IAM role and no ServiceAccount to create.
          type        = "LoadBalancer"
          annotations = local.ccm_annotations
        },
        var.external_traffic_policy == null ? {} : { externalTrafficPolicy = var.external_traffic_policy },
      )
    }
  ))
}
