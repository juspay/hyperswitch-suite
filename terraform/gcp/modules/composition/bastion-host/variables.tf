variable "project_id" {
  description = "GCP project ID where the bastion is created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "region" {
  description = "Region for regional resources"
  type        = string
}

variable "zone" {
  description = "Zone to create the bastion instance in"
  type        = string
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "subnet" {
  description = "Self-link of the subnetwork for the bastion (typically the management tier)"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the bastion instance"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Persistent disk type"
  type        = string
  default     = "pd-balanced"
}

variable "image" {
  description = "Specific image self-link to boot from. Null uses image_family/image_project instead"
  type        = string
  default     = null
}

variable "image_family" {
  description = "Image family to boot from, used when image is null"
  type        = string
  default     = "debian-12"
}

variable "image_project" {
  description = "Project the boot image/family belongs to"
  type        = string
  default     = "debian-cloud"
}

variable "members" {
  description = "List of IAM members (users/groups/service accounts) granted IAP-tunnel SSH access to the bastion"
  type        = list(string)
  default     = []
}

variable "enable_session_logging" {
  description = "Whether to create a GCS bucket + log sink capturing bastion session/audit logs"
  type        = bool
  default     = true
}

variable "log_bucket_location" {
  description = "Location for the session log bucket"
  type        = string
  default     = "US"
}

variable "session_log_retention_days" {
  description = "Number of days to retain session log objects before deletion"
  type        = number
  default     = 365
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Data-store connectivity (tunnel targets)
# ==============================================================================
# The management subnet this bastion sits in has NO internet route - Cloud NAT
# is restricted to the outgoing-proxy (Squid) tier only, and the VPC runs
# default-deny egress. A stock Debian image therefore cannot apt-install
# postgresql-client or valkey-tools at boot, and Squid's domain allowlist (shared
# with the AWS sandbox/prod fleets) carries no Debian repo entries.
#
# So this module deliberately installs NOTHING. The bastion is used purely as an
# SSH local-port-forward jump host - which needs nothing on the VM beyond sshd -
# and the client tooling stays on the operator's laptop. connection_targets is
# what turns that from tribal knowledge into a runnable command: the live layer
# feeds it the real endpoints from the alloydb/valkey units' outputs, and the
# tunnel_commands output hands back a ready-to-paste `gcloud compute ssh ... -L`
# line per target, so nobody has to go rediscover a private IP first.
#
# This variable is purely informational - it creates no resources and grants no
# access. Reachability comes from the VPC's firewall rules, not from here.
variable "connection_targets" {
  description = "Data stores reachable by port-forwarding through this bastion, keyed by a short name. Drives the tunnel_commands output only - it creates no resources and opens no firewall paths."
  type = map(object({
    host        = string
    port        = number
    local_port  = optional(number)
    description = optional(string)
  }))
  default = {}
}

variable "additional_service_account_roles" {
  description = "Extra project-level IAM roles granted to the bastion's own service account, on top of the logging.logWriter/monitoring.metricWriter baseline this module always sets"
  type        = list(string)
  default     = []
}
