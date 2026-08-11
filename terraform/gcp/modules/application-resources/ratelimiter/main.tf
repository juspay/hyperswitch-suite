# ============================================================================
# Ratelimiter (GCP equivalent of application-resources/ratelimiter)
# ============================================================================
# GSA + Workload Identity binding, an optional dedicated Memorystore
# instance (composition/memorystore), and a firewall rule allowing the GKE
# node pool to reach it - mirroring the AWS module's IRSA role +
# composition/elasticache + LB security group rules.
#
# Usage:
#   module "ratelimiter" {
#     source = "../../modules/application-resources/ratelimiter"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#     region       = "europe-west1"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#
#     network             = module.vpc_network.network_self_link
#     network_name         = module.vpc_network.network_name
#     authorized_network   = module.vpc_network.network_id
#   }
# ============================================================================

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "ratelimiter"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.additional_project_roles

  labels = local.common_labels
}

module "memorystore" {
  source = "../../composition/memorystore"

  count = var.create_redis ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-ratelimiter"
  region       = var.region

  authorized_network = var.authorized_network
  tier               = var.redis_tier
  memory_size_gb     = var.redis_memory_size_gb

  labels = local.common_labels
}

module "firewall_rules" {
  source = "../../composition/firewall-rules"

  count = var.create_redis && var.create_firewall_rule ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  network_name = var.network_name

  rules = {
    ratelimiter-to-redis = {
      rules = [
        {
          name                    = "allow-ratelimiter-to-redis"
          description             = "Allow ratelimiter workloads to reach Memorystore"
          direction               = "INGRESS"
          target_service_accounts = [module.workload_identity.service_account_email]
          ranges                  = [var.gke_pods_cidr]
          allow                   = [{ protocol = "tcp", ports = ["6379"] }]
        },
      ]
    }
  }
}
