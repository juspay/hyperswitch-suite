include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/firewall-rules"
}

inputs = {
  project_id   = include.root.locals.project_id
  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short
  network_name = "hyperswitch-dev-vpc"

  rules = {
    envoy-proxy = {
      rules = [
        {
          name        = "allow-iap-ssh"
          description = "IAP-tunneled SSH to envoy-proxy fleet instances"
          direction   = "INGRESS"
          priority    = 1000
          ranges      = ["35.235.240.0/20"]
          target_tags = ["envoy-proxy"]
          allow = [{
            protocol = "tcp"
            ports    = ["22"]
          }]
        },
      ]
    }
  }
}
