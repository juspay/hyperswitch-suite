include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/application-resources/infraswitch-gcp-federation"
}

inputs = {
  project_id = include.root.locals.project_id

  aws_account_id = "123456789012"
  aws_role_name  = "atlantis-role"

  project_roles = [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/alloydb.admin",
    "roles/redis.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudkms.admin",
    "roles/storage.admin",
    "roles/secretmanager.admin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/dns.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/artifactregistry.admin",
    "roles/networkconnectivity.consumerNetworkAdmin",
    "roles/memorystore.admin",
  ]
}
