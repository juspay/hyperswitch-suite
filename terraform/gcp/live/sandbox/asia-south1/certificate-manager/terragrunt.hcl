# Managed TLS certificates for whatever domains front the deployment
# (envoy-proxy / istio gateway / load-balancer). No official registry module
# exists for this service - see the module's own header comment in
# hyperswitch-suite for why.
#
# Publish the resulting DNS authorization record (see the
# dns_authorization_records output) via ../cloud-dns.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/certificate-manager?ref=gcp-certificate-manager-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  certificates = {
    api = {
      domain_name               = values.domains.api
      subject_alternative_names = []
      validation_method         = "DNS"
    }
  }

  create_certificate_map = true

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
