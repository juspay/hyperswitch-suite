# Istio control plane and gateway
# The three releases and their dependency order are cloud-agnostic. The one OCI
# difference is `istio_gateway`'s values: `service.type = "LoadBalancer"` plus
# the OCI CCM annotation map. THERE IS NO `kubernetes_ingress_v1` HERE AND
# SHOULD NEVER BE - a plan that creates an Ingress means someone reintroduced
# the AWS shape, which needs a controller that does not exist here.

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
  # override `service.type` and silently break the exposure path.
  values = concat(
    [local.gateway_service_values],
    var.istio_gateway.values_file != "" ? [file(var.istio_gateway.values_file)] : [],
    var.istio_gateway.values,
  )

  depends_on = [helm_release.istiod]
}

# Stable public address

resource "oci_core_public_ip" "gateway" {
  count = var.create_gateway_reserved_ip ? 1 : 0

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "${local.name_prefix}-gateway-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
