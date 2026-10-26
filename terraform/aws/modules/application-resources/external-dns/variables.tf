# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "external_dns_hosted_zone_arns" {
  description = "List of Route53 hosted zone ARNs external-dns is allowed to manage records in"
  type        = list(string)
}

variable "external_dns_namespace" {
  description = "Namespace external-dns is installed on"
  type        = string
  default     = "kube-system"
}

variable "external_dns_service_account_name" {
  description = "Service Account Name of external-dns"
  type        = string
  default     = "external-dns-sa"
}

variable "create_external_dns_service_account" {
  description = "Whether to create the external-dns Service Account"
  type        = bool
  default     = false
}

variable "create_helm_release" {
  description = "Whether to create the Helm release for external-dns"
  type        = bool
  default     = true
}

variable "external_dns_chart_version" {
  description = "Version of the external-dns Helm chart"
  type        = string
  default     = "1.15.0"
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "external-dns"
}

variable "helm_chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://kubernetes-sigs.github.io/external-dns"
}

variable "helm_chart_values" {
  description = "Additional values to pass to the Helm chart"
  type        = list(string)
  default     = []
}

variable "helm_values_file" {
  description = "Path to a values.yaml file to use with the Helm chart. If provided, this will be used alongside helm_chart_values"
  type        = string
  default     = ""
}

variable "service_account_labels" {
  description = "Labels to apply to the external-dns Service Account"
  type        = map(string)
  default     = {}
}

variable "additional_service_account_annotations" {
  description = "Additional annotations to apply to the external-dns Service Account"
  type        = map(string)
  default     = {}
}

variable "domain_filters" {
  description = "List of domains external-dns is allowed to manage records for (--domain-filter)"
  type        = list(string)
  default     = []
}

variable "txt_owner_id" {
  description = "TXT registry owner ID used by external-dns to disambiguate records it owns (--txt-owner-id). Must be unique per cluster/region sharing a zone."
  type        = string
}

variable "aws_zone_type" {
  description = "Which zone type external-dns should manage records in (public, private, or empty for both)"
  type        = string
  default     = "public"
}

variable "policy" {
  description = "external-dns record ownership policy: sync (create/update/delete) or upsert-only (never delete)"
  type        = string
  default     = "upsert-only"
}

variable "dry_run" {
  description = "Run external-dns in --dry-run mode (log intended changes, write nothing to Route53)"
  type        = bool
  default     = true
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
