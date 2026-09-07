# GKE's Gateway/Ingress controller is built in - this unit only creates the
# supporting SSL policy. Gateway/HTTPRoute objects are Kubernetes-native and
# applied via GitOps/kubectl, not Terraform.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  # NOTE: `gcp-apps-gcp` is the published tag for the gateway-controller
  # module — it looks like a mis-typed tag name. Re-tag as
  # gcp-apps-gateway-controller-vX.Y.Z and repoint this when convenient.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/gateway-controller?ref=gcp-apps-gcp-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  create_ssl_policy          = true
  ssl_policy_profile         = "MODERN"
  ssl_policy_min_tls_version = "TLS_1_2"

  create_service_account = false

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
