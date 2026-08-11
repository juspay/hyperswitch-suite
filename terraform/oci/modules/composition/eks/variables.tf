variable "compartment_id" {
  description = "OCID of the compartment to create the OKE cluster in"
  type        = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version, e.g. v1.31.1 (equivalent to AWS cluster_version)"
  type        = string
}

variable "vcn_id" {
  description = "OCID of the existing VCN (created by the vpc-network composition module) - the OKE module never creates its own VCN here"
  type        = string
}

# Existing subnets created by the vpc-network module, reused via the oke
# module's "subnets = { <role> = { id = ..., create = \"never\" } }" pattern
variable "workers_subnet_id" {
  type = string
}

variable "control_plane_subnet_id" {
  type = string
}

variable "public_lb_subnet_id" {
  description = "Subnet for public (internet-facing) OKE load balancers - equivalent to AWS 'kubernetes.io/role/elb' tagged subnets"
  type        = string
}

variable "internal_lb_subnet_id" {
  description = "Subnet for internal OKE load balancers - equivalent to AWS 'kubernetes.io/role/internal-elb' tagged subnets"
  type        = string
  default     = null
}

variable "control_plane_is_public" {
  description = "Whether the Kubernetes API endpoint is public (equivalent to AWS cluster_endpoint_public_access)"
  type        = bool
  default     = false
}

variable "control_plane_allowed_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint when control_plane_is_public = true (equivalent to AWS cluster_endpoint_public_access_cidrs)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cni_type" {
  description = "flannel or npn (Native Pod Networking, OCI's most direct analog to the AWS VPC CNI)"
  type        = string
  default     = "npn"
}

variable "pods_cidr" {
  type    = string
  default = null
}

variable "services_cidr" {
  type    = string
  default = null
}

# -----------------------------------------------------------------------------
# Worker (node) pools
# -----------------------------------------------------------------------------
# Passed straight through to the oke module's `worker_pools` variable (type
# `any`), mirroring how the AWS eks composition module passes `var.node_groups`
# straight through to the base eks module. See
# https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/variables-workers.tf
# for every supported field (shape, size, boot_volume_size, min/max size for
# autoscaling, allow_autoscaler, etc).
variable "worker_pools" {
  description = "Map of worker pool name -> oke module worker pool definition"
  type        = any
  default     = {}
}

variable "ssh_public_key" {
  description = "SSH public key installed on worker nodes"
  type        = string
  default     = null
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
