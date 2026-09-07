include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../..//modules/application-resources/gateway-controller"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  create_ssl_policy = true

  ssl_policy_profile         = "MODERN"
  ssl_policy_min_tls_version = "TLS_1_2"

  create_service_account = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "gateway-controller"
    managed_by  = "terraform"
  }
}
