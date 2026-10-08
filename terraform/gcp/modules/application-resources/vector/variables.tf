variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
  default     = "hyperswitch"
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting Vector"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider"
  type        = string
  sensitive   = true
}

variable "k8s_namespace" {
  description = "Kubernetes namespace Vector runs in"
  type        = string
  default     = "observability"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by Vector"
  type        = string
  default     = "vector"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant Vector's service account"
  type        = list(string)
  default     = []
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (typically created by this app's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use_existing_k8s_sa = true; harmless otherwise"
  type        = bool
  default     = true
}

variable "create_bucket" {
  description = "Whether to create a dedicated GCS bucket for Vector's log storage"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Custom bucket name. If null, auto-generated as '<env>-<project>-vector-logs'"
  type        = string
  default     = null
}

variable "bucket_location" {
  description = "Location for the logs bucket"
  type        = string
  default     = "US"
}

variable "bucket_force_destroy" {
  description = "Whether to allow bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "bucket_lifecycle_rules" {
  description = "Lifecycle rules for the logs bucket, in the shape expected by simple_bucket"
  type        = any
  default     = []
}

variable "create_queue" {
  description = "Whether to create the Pub/Sub topic/subscription pair for log-event notifications"
  type        = bool
  default     = true
}

variable "subscription_ack_deadline_seconds" {
  description = "Acknowledgement deadline for the pull subscription"
  type        = number
  default     = 60
}

variable "subscription_message_retention_duration" {
  description = "How long unacknowledged messages are retained on the subscription"
  type        = string
  default     = "604800s" # 7 days
}

variable "cross_region_reader_members" {
  description = "List of IAM members (e.g. 'serviceAccount:...') in other regions or projects granted subscriber access to the subscription"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_name_suffix" {
  description = "Suffix appended to this module's DEFAULT bucket names (<env>-<project>-<component>-<role>-<suffix>). GCS bucket names are global, so the same name in two projects collides; the suffix is what lets several environments coexist. null = the first 6 hex characters of sha256(project_id): stable across applies and unique per project. \"\" = no suffix (the names this module produced before the suffix existed - set it on existing deployments to avoid replacing their buckets). Any other value is used as given (1-16 lowercase letters, digits and hyphens). The readable prefix is trimmed so the full name stays within the 63-character GCS limit; the role and the suffix are never trimmed."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name_suffix == null || can(regex("^([a-z0-9]([a-z0-9-]{0,14}[a-z0-9])?)?$", var.bucket_name_suffix))
    error_message = "bucket_name_suffix must be null, an empty string, or 1-16 characters of lowercase letters, digits and hyphens that starts and ends with a letter or digit."
  }
}
