include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "sdk_assets" {
  config_path = "../hyperswitch-sdk-assets"

  mock_outputs = {
    bucket_name = "mock-bucket"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../../modules/composition/cloud-cdn"
}

inputs = {
  project_id   = include.root.locals.project_id
  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short

  name_override = "sdk"

  backend_buckets = {
    sdk = {
      bucket_name = dependency.sdk_assets.outputs.bucket_name
    }
  }

  ssl                             = true
  managed_ssl_certificate_domains = ["34-117-162-90.sslip.io"]
  http_redirect_to_https          = true

  enable_logging = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cloud-cdn-sdk"
    managed_by  = "terraform"
  }
}
