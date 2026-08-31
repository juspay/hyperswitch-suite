variable "project_id" {
  description = "GCP project ID that owns the workload identity pool and its role grants"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID that hosts the IAM role your CI/CD apply worker assumes"
  type        = string
}

variable "aws_role_name" {
  description = "Name (not ARN) of the AWS IAM role your CI/CD apply worker assumes via IRSA (or an EC2 instance profile) - the only AWS identity trusted by the pool provider"
  type        = string
}

variable "pool_display_name" {
  description = "Display name for the workload identity pool, shown in the GCP console - customize to identify which CI/CD worker/environment this federation belongs to"
  type        = string
  default     = "AWS CI/CD apply worker federation"
}

variable "pool_description" {
  description = "Description for the workload identity pool"
  type        = string
  default     = "Federates one AWS IAM role for a CI/CD apply worker's terraform/terragrunt runs"
}

variable "project_roles" {
  description = "Predefined GCP project roles granted directly to the federated AWS identity. The defaults are a reasonable starting point for a general infra + application-stack CI/CD worker - narrow or extend as your setup needs."
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
