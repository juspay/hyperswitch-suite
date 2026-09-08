include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/vector?ref=vector-v0.1.1"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  app_name     = "vector-dr"

  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = try(values.kubernetes_namespace, "vector")
        name      = try(values.service_account_name, "vector-dr")
      }
    ]
  }

  s3 = {
    create             = true
    bucket_name        = "telemetry-backfill"
    force_destroy      = try(values.s3_force_destroy, true)
    versioning_enabled = try(values.s3_versioning_enabled, false)
    lifecycle_rules    = []
  }

  sqs = {
    create             = true
    message_retention  = try(values.sqs_message_retention, 1209600)
    receive_wait_time  = try(values.sqs_receive_wait_time, 20)
    visibility_timeout = try(values.sqs_visibility_timeout, 300)
  }

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Component   = "vector-dr"
  }
}
