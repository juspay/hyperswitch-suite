include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/application-resources/eks-iam"
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  bucket_name = "hs-dev-vector-logging-storage"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = "hs"

  app_name  = "vector-logging"
  role_name = null

  oidc_providers = {
    eks_cluster = {
      provider_arn = dependency.eks.outputs.oidc_provider_arn
      conditions = [
        {
          type   = "StringEquals"
          claim  = "aud"
          values = ["sts.amazonaws.com"]
        },
        {
          type   = "StringEquals"
          claim  = "sub"
          values = ["system:serviceaccount:vector:vector-logging"]
        },
      ]
    }
  }

  create_s3_bucket     = true
  s3_bucket_name       = null
  s3_force_destroy     = false
  s3_enable_versioning = false
  s3_sse_algorithm     = "AES256"
  s3_kms_master_key_id = null

  s3_server_access_logging = {
    enabled       = false
    target_bucket = ""
    target_prefix = ""
  }

  s3_lifecycle_rules = []

  s3_permissions_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*",
        ]
      },
    ]
  })

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
