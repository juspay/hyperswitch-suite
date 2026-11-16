variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID the temporary build instance and the resulting custom image are created in."
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for the temporary build instance, e.g. \"Niou:AP-MUMBAI-1-AD-1\". AD names carry a tenancy-specific opaque prefix and are NOT portable between tenancies - read it from `oci iam availability-domain list`. ap-mumbai-1 has exactly one."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet the temporary build instance launches into. Needs outbound internet (apt, Docker Hub, the Vector repo, the OCI CLI installer) and an inbound SSH path from wherever `packer build` runs. ../build-network/create.sh makes a disposable VCN that satisfies both."
}

variable "region" {
  type        = string
  description = "OCI region. Overrides the region in the OCI config file profile."
  default     = "ap-mumbai-1"
}

variable "access_cfg_file_account" {
  type        = string
  description = "Profile name in ~/.oci/config the build authenticates as. The oracle-oci builder calls this `access_cfg_file_account`, not `config_file_profile` (the Terraform provider's name) and not `profile` (the CLI's). Session-token profiles work: the builder delegates to the OCI Go SDK's file configuration provider, which returns an ST$-prefixed key ID when the profile carries `security_token_file`."
  default     = "devuser"
}

variable "base_image_ocid" {
  type        = string
  description = "Explicit base image OCID. Leave empty to resolve one through base_image_filter, which is the default and does not rot when Canonical publishes a new build."
  default     = ""
}

variable "base_image_operating_system" {
  type        = string
  description = "Base image OS for the filter path."
  default     = "Canonical Ubuntu"
}

variable "base_image_operating_system_version" {
  type        = string
  description = "Base image OS version for the filter path. \"26.04\" (resolute), matching GCP's ubuntu-2604-lts so the provisioner scripts stay identical. OCI's aarch64 images share this exact version string, so the `shape` entry in base_image_filter - not this - is what excludes ARM. Upgraded from 24.04 on 2026-10-12 per user request."
  default     = "26.04"
}

variable "shape" {
  type        = string
  description = "Shape for the temporary build instance, and the architecture filter for base_image_filter."
  default     = "VM.Standard.E5.Flex"
}

variable "shape_ocpus" {
  type        = number
  description = "OCPUs for the temporary build instance. 2 rather than the squid build's 1: this build pulls and unpacks the ~500 MB envoyproxy/envoy Docker image, which is the slowest step in either template."
  default     = 2
}

variable "shape_memory_in_gbs" {
  type        = number
  description = "Memory for the temporary build instance."
  default     = 16
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size for the build instance and therefore for the image. Feeds the builder's `disk_size` argument (the Go field is BootVolumeSizeInGBs but its mapstructure tag is `disk_size`). Must be >= 50, the base image's own size."
  default     = 50
}

variable "envoy_version" {
  type        = string
  description = "Envoy release tag to install, matching a tag on the OFFICIAL envoyproxy/envoy Docker Hub image - NOT an apt package version. The binary is extracted from that image at build time and run as a native systemd service, never as a container. See the step-1 provisioner comment for the three install routes that were tried and rejected on the GCP side; all three rejections are about upstream packaging, not about GCP, so they hold here unchanged. KEPT FOR HUMANS - the machine reference for the pull/install is envoy_image_digest."
  default     = "v1.39.0"
}

variable "envoy_image_digest" {
  type        = string
  description = "Content digest (by digest) of the envoyproxy/envoy image to pull and extract - control 12a/13a pins the build to an immutable hash rather than a mutating tag. Set to the digest for the current envoy_version tag. Default is the digest of envoyproxy/envoy:v1.39.0 (recorded 2026-10-09). The build pulls envoyproxy/envoy@<this digest>; the step-2 provisioner fails closed if this is still the placeholder."
  default     = "sha256:d59f7f5fa10cff6d5892b6c5e7df5c9297ddfb2c3683e33fbfb82da24de4fa66"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, sandbox, prod). Goes into the image name and its freeform tags."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name, used in image freeform tags."
  default     = "hyperswitch"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the resulting image name. OCI has no image-family concept - there is no `image_family` field on oci_core_image and no newest-in-family resolution - so the consuming unit takes an OCID and this prefix only keeps `oci compute image list` readable."
  default     = "hyperswitch-envoy"
}

variable "envoy_http_port" {
  type        = number
  description = "Envoy's plain-HTTP listener port, opened in ufw. MUST match the envoy-proxy unit's `backend_port` (8080) - that is the port the load balancer's backend set and its HTTP health check both target, so a mismatch shows up as a permanently unhealthy backend set rather than as an obvious error."
  default     = 8080
}

variable "envoy_https_port" {
  type        = number
  description = "Envoy's HTTPS listener port, opened in ufw."
  default     = 8443
}

variable "envoy_mtls_port" {
  type        = number
  description = "Envoy's mTLS listener port, opened in ufw. Corresponds to the unit's mtls_listener, which is disabled in dev."
  default     = 8444
}

variable "envoy_admin_port" {
  type        = number
  description = "Envoy's admin listener port. NOT opened in ufw and deliberately bound to 127.0.0.1 in the baked-in config: the admin API can drain listeners and dump the full config. Vector scrapes it over loopback."
  default     = 9901
}

variable "vector_prometheus_port" {
  type        = number
  description = "Port Vector's prometheus_exporter sink listens on, opened in ufw. Matches address = \"0.0.0.0:9273\" in scripts/vector.toml."
  default     = 9273
}

variable "ssh_username" {
  type        = string
  description = "SSH user on the base image. Canonical's OCI Ubuntu images create `ubuntu` - not `opc` (Oracle Linux's) and not `packer` (which the GCE builder creates for itself)."
  default     = "ubuntu"
}

variable "assign_public_ip" {
  type        = bool
  description = "Give the temporary build instance a public IP so `packer build` can reach it. True is the only working setting today: the oracle-oci builder has no OCI Bastion support (no bastion argument exists anywhere in builder/oci/config.go) and no Bastion service instance exists in this tenancy. A build-instance property only - the envoy-proxy module sets assign_public_ip = false on its instance configuration and places the fleet in a subnet with prohibit_public_ip_on_vnic = true."
  default     = true
}
