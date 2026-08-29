# Rendered by scripts/self-host/generate.sh — edit hyperswitch-bootstrap.conf
# and rerun the generator (with --force) rather than editing by hand.
#
# After changing this file run `terragrunt stack generate` in this directory
# and commit the generated tree.
stack "__AWS_REGION__" {
  source = "../../catalog/stacks/standalone"
  path   = "__AWS_REGION__"

  no_dot_terragrunt_stack = true

  values = {
    project_name = "__MERCHANT_NAME__"
    env          = "__ENVIRONMENT__"
    region       = "__AWS_REGION__"
    account_id   = "__AWS_ACCOUNT_ID__"
    state_bucket = "__STATE_BUCKET__"

    # Merchant-provided VPC
    vpc_id                       = "__VPC_ID__"
    vpc_cidr                     = "__VPC_CIDR__"
    database_subnet_ids          = __DB_SUBNET_IDS_HCL__
    elasticache_subnet_ids       = __CACHE_SUBNET_IDS_HCL__
    eks_workers_subnet_ids       = __EKS_WORKER_SUBNET_IDS_HCL__
    eks_control_plane_subnet_ids = __EKS_CP_SUBNET_IDS_HCL__

    # Access
    admin_role_arn     = "__ADMIN_ROLE_ARN__"
    admin_access_cidrs = __ADMIN_ACCESS_CIDRS_HCL__

    # Sizing
    db_instance_class  = "__DB_INSTANCE_CLASS__"
    db_engine_version  = "__DB_ENGINE_VERSION__"
    cache_node_type    = "__CACHE_NODE_TYPE__"
    eks_version        = "__EKS_VERSION__"
    eks_instance_types = __EKS_INSTANCE_TYPES_HCL__
    eks_ami_id         = __EKS_AMI_ID_HCL__
  }
}
