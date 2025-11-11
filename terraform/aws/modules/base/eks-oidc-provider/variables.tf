variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL from the EKS cluster"
  type        = string
}

variable "client_id_list" {
  description = "List of client IDs (audiences) for the OIDC provider"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
