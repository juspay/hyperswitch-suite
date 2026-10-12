# =============================================================================
# Istio control plane and gateway (check sheet features 1, 2, 3, 8, 9)
# =============================================================================
# The three releases and their dependency order are cloud-agnostic and
# near-verbatim from both the AWS and GCP modules - same chart repo, same
# structure, same `depends_on` chain. Exactly one thing changes, and it is in
# `istio_gateway`'s values: `service.type = "LoadBalancer"` plus the OCI CCM
# annotation map, where AWS renders `type = "ClusterIP"` and puts a separate
# `kubernetes_ingress_v1` in front of it.
#
# THERE IS NO `kubernetes_ingress_v1` IN THIS MODULE, AND THERE SHOULD NEVER BE
# ONE. A plan for this module that creates an Ingress means someone has
# reintroduced the AWS shape, which on OCI needs a controller that does not
# exist here - see the header of variables.tf.

resource "helm_release" "istio_base" {
  count = var.create_helm_releases && var.istio_base.enabled ? 1 : 0

  name             = var.istio_base.release_name
  repository       = var.istio_base.chart_repo
  chart            = "base"
  namespace        = var.istio_namespace
  version          = var.istio_base.chart_version
  create_namespace = true
  wait             = true
  force_update     = true

  values = concat(
    [yamlencode({ defaultRevision = "default", base = { enableCRDTemplates = true } })],
    var.istio_base.values_file != "" ? [file(var.istio_base.values_file)] : [],
    var.istio_base.values,
  )
}

resource "helm_release" "istiod" {
  count = var.create_helm_releases && var.istiod.enabled ? 1 : 0

  name       = var.istiod.release_name
  repository = var.istiod.chart_repo
  chart      = "istiod"
  namespace  = var.istio_namespace
  version    = var.istiod.chart_version
  wait       = true

  values = concat(
    var.istiod.values_file != "" ? [file(var.istiod.values_file)] : [],
    var.istiod.values,
  )

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_gateway" {
  count = var.create_helm_releases && var.istio_gateway.enabled ? 1 : 0

  name       = var.istio_gateway.release_name
  repository = var.istio_gateway.chart_repo
  chart      = "gateway"
  namespace  = var.istio_namespace
  version    = var.istio_gateway.chart_version
  wait       = true

  # Generated block first, caller-supplied values last - so a caller CAN
  # override `service.type` and silently break the exposure path. Documented on
  # the variable rather than defended against, matching how the AWS and GCP
  # modules already behave.
  values = concat(
    [local.gateway_service_values],
    var.istio_gateway.values_file != "" ? [file(var.istio_gateway.values_file)] : [],
    var.istio_gateway.values,
  )

  depends_on = [helm_release.istiod]
}

# =============================================================================
# Stable public address (check sheet feature 7, FULL)
# =============================================================================
# AWS feature 7 is "a stable network address", satisfied IMPLICITLY by the ALB's
# own persistent DNS hostname - nothing to create, nothing to name, and Route 53
# aliases to it. OCI's equivalent is a stable IP, which is a real resource, and
# DNS points an A record at it. Mirrors GCP's `google_compute_address` +
# `loadBalancerIP` almost exactly, and is the same Reserved-Public-IP mechanism
# `load-balancer.md` established for the standalone-LB case (different resource
# path, same underlying concept).
#
# `scope` is not set: it is computed, and `lifetime = "RESERVED"` already
# implies a regional scope.
resource "oci_core_public_ip" "gateway" {
  count = var.create_gateway_reserved_ip ? 1 : 0

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "${local.name_prefix}-gateway-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
