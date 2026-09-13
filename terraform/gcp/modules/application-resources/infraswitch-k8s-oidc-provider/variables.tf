variable "project_id" {
  description = "GCP project ID that owns the workload identity pool"
  type        = string
}

variable "workload_identity_pool_id" {
  description = "ID of the existing workload identity pool to attach this provider to"
  type        = string
  default     = "infraswitch-aws-pool"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster, for the provider's display name and description"
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster this provider trusts"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace of the ServiceAccount allowed to use this provider"
  type        = string
  default     = "infra-switch"
}

variable "k8s_service_account" {
  description = "Name of the Kubernetes ServiceAccount allowed to use this provider"
  type        = string
  default     = "infra-switch-sa"
}

variable "project_roles" {
  description = "Predefined GCP project roles granted directly to the federated identity"
  type        = list(string)
  default = [
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
    "roles/logging.configWriter",
    "roles/iam.roleAdmin",
    "roles/iap.admin",
  ]
}
