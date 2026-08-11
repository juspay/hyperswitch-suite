variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cluster_id" {
  description = "OCID of the OKE cluster (equivalent to AWS cluster_id/cluster_name)"
  type        = string
}

variable "cluster_endpoint" {
  description = "OKE Kubernetes API endpoint (equivalent to AWS cluster_endpoint)"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA cert (equivalent to AWS cluster_certificate_authority_data)"
  type        = string
}

variable "create_default_rbac_roles" {
  type    = bool
  default = true
}

variable "custom_rbac_roles" {
  type = map(object({
    rules = list(object({
      api_groups     = list(string)
      resources      = list(string)
      verbs          = list(string)
      resource_names = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "create_default_storage_class" {
  type    = bool
  default = true
}

variable "default_storage_class_name" {
  type    = string
  default = "oci-bv"
}

variable "custom_storage_classes" {
  type = map(object({
    storage_provisioner    = string
    volume_binding_mode    = optional(string, "WaitForFirstConsumer")
    reclaim_policy         = optional(string, "Delete")
    allow_volume_expansion = optional(bool, true)
    parameters             = optional(map(string), {})
    annotations            = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Cluster Autoscaler (equivalent of AWS enable_cluster_autoscaler and its
# IRSA/ECR-sync machinery). OKE's cluster autoscaler runs with
# --cloud-provider=oci and discovers node pools via OCI-specific
# node-pool-autoscaling annotations rather than ASG tags.
# ---------------------------------------------------------------------------
variable "enable_cluster_autoscaler" {
  type    = bool
  default = true
}

variable "cluster_autoscaler_image" {
  description = "Equivalent of AWS cluster_autoscaler_final_image resolution; OKE-specific autoscaler images are published at iad.ocir.io/oracle/oci-cluster-autoscaler"
  type        = string
  default     = "iad.ocir.io/oracle/oci-cluster-autoscaler:v1.30.0"
}

variable "cluster_autoscaler_node_pools" {
  description = "List of OKE node pool OCIDs with min/max sizes (equivalent of AWS node-group-auto-discovery tags)"
  type = list(object({
    node_pool_id = string
    min_size     = number
    max_size     = number
  }))
  default = []
}

variable "cluster_autoscaler_service_account_name" {
  type    = string
  default = null
}

variable "cluster_autoscaler_resources" {
  type = object({
    requests_cpu    = optional(string, "100m")
    requests_memory = optional(string, "600Mi")
    limits_cpu      = optional(string, "100m")
    limits_memory   = optional(string, "600Mi")
  })
  default = {}
}

# ---------------------------------------------------------------------------
# Hyperswitch Helm deployment (unchanged from AWS - cloud-agnostic)
# ---------------------------------------------------------------------------
variable "enable_helm_deployments" {
  type    = bool
  default = true
}

variable "hyperswitch_namespace" {
  type    = string
  default = "hyperswitch"
}

variable "create_ocir_registry_secret" {
  description = "Equivalent of AWS create_ecr_registry_secret"
  type        = bool
  default     = true
}

variable "ocir_server" {
  description = "e.g. iad.ocir.io"
  type        = string
}

variable "ocir_auth_token" {
  description = "OCI Auth Token for the service user pulling images (equivalent of AWS ECR auth token, but OCIR tokens are long-lived, not auto-rotated per apply)"
  type        = string
  sensitive   = true
}

variable "ocir_username" {
  description = "Format: <tenancy-namespace>/<username> (or /<oci-identity-domain>/<username> for identity-domain tenancies)"
  type        = string
}

variable "hyperswitch_release_name" {
  type    = string
  default = "hyperswitch"
}

variable "hyperswitch_helm_repository" {
  type = string
}

variable "hyperswitch_helm_chart" {
  type = string
}

variable "hyperswitch_chart_version" {
  type    = string
  default = null
}

variable "hyperswitch_values_file" {
  type    = string
  default = null
}

variable "hyperswitch_helm_timeout" {
  type    = number
  default = 900
}

variable "tags" {
  type    = map(string)
  default = {}
}
