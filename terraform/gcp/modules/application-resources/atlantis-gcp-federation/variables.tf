variable "project_id" {
  description = "GCP project ID that owns the workload identity pool and its role grants"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID that hosts the atlantis-role (the sandbox management account infra-switch/atlantis runs in)"
  type        = string
}

variable "aws_role_name" {
  description = "Name (not ARN) of the AWS IAM role that infra-switch's worker/repo-server pods assume via IRSA - the only AWS identity trusted by the pool provider"
  type        = string
  default     = "atlantis-role"
}

variable "project_roles" {
  description = "Predefined GCP project roles granted directly to the federated AWS identity - covers both infra provisioning (VPC, GKE, Envoy, Squid, AlloyDB, Memorystore-Valkey) and application-stack units (apps/hyperswitch, apps/superposition, etc.). Broad by design, mirroring the AWS atlantis-role's per-service wildcard policy - narrow later only if a real need shows up."
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
  ]
}
