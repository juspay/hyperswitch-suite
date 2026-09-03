include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {

  source = "tfr:///terraform-google-modules/cloud-storage/google//modules/simple_bucket?version=12.3.0"
}

inputs = {
  project_id = include.root.locals.project_id

  name          = "${include.root.locals.project_id}-${include.root.locals.region}-sdk-assets"
  location      = include.root.locals.region
  force_destroy = true
  versioning    = false

  bucket_policy_only = true

  iam_members = [{
    role   = "roles/storage.objectViewer"
    member = "serviceAccount:service-${include.root.locals.project_number}@https-lb.iam.gserviceaccount.com"
  }]

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "hyperswitch-web-sdk"
    managed_by  = "terraform"
  }
}
