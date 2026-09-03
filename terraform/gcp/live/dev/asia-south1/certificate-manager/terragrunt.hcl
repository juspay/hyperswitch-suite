include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/certificate-manager"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  certificates = {}

  dns_authorization_type = "FIXED_RECORD"

  create_certificate_map = true

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "certificate-manager"
    managed_by  = "terraform"
  }
}
