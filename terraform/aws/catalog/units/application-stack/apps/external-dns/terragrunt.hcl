include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/external-dns?ref=module/aws/external-dns-v0.1.1"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "route53" {
  config_path = "../../../route53"

  mock_outputs = {
    zone_arns = {
      hyperswitch_public   = "arn:aws:route53:::hostedzone/mock"
      hyperswitch_internal = "arn:aws:route53:::hostedzone/mock"
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  eks_cluster_name = dependency.eks.outputs.cluster_name

  # IAM access to every zone the route53 unit creates; `domain_filters` below
  # is what actually scopes which zones external-dns manages.
  external_dns_hosted_zone_arns = values(dependency.route53.outputs.zone_arns)

  external_dns_namespace = try(values.external_dns_namespace, "kube-system")

  external_dns_service_account_name = try(values.external_dns_service_account_name, "external-dns-sa")

  create_external_dns_service_account = try(values.create_external_dns_service_account, false)

  service_account_labels = {}

  additional_service_account_annotations = {}

  create_helm_release = try(values.create_helm_release, false)

  # "" (both zone types) since domain_filters below includes both the public
  # zone and the private zone (hyperswitch_internal).
  aws_zone_type = ""

  # Zones external-dns is allowed to manage. Supplied by the stack, and must
  # match the zone names its route53 unit creates.
  domain_filters = values.domain_filters

  txt_owner_id = "${include.root.locals.environment.short}-${include.root.locals.region_code}"

  policy = try(values.external_dns_policy, "upsert-only")

  dry_run = false

  common_tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "external-dns"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
