variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID the temporary build instance and the resulting custom image are created in."
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for the temporary build instance, e.g. \"Niou:AP-MUMBAI-1-AD-1\". AD names carry a tenancy-specific opaque prefix (\"Niou:\" here) and are NOT portable between tenancies - read it from `oci iam availability-domain list` rather than copying it from another tenancy's docs. ap-mumbai-1 has exactly one."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet the temporary build instance launches into. Needs (a) outbound internet for apt, the Vector repo and the OCI CLI installer, and (b) an inbound SSH path from wherever `packer build` runs. ../build-network/create.sh makes a disposable VCN that satisfies both - see its header for why that is preferred over the live vpc-network's subnets."
}

variable "region" {
  type        = string
  description = "OCI region. Overrides the region in the OCI config file profile."
  default     = "ap-mumbai-1"
}

variable "access_cfg_file_account" {
  type        = string
  description = "Profile name in ~/.oci/config the build authenticates as. NOTE the argument name: the oracle-oci builder calls this `access_cfg_file_account`, not `config_file_profile` (which is the Terraform provider's name for the same idea) and not `profile`. Verified by reading builder/oci/config.go on hashicorp/packer-plugin-oracle main: `AccessCfgFileAccount string \\`mapstructure:\"access_cfg_file_account\"\\``, defaulted to \"DEFAULT\" when empty."
  default     = "devuser"
}

variable "base_image_ocid" {
  type        = string
  description = "Explicit base image OCID. Leave empty to resolve one through base_image_filter instead, which is the default and does not rot when Canonical publishes a new build. Empty string rather than null on purpose: the builder's own check is `c.BaseImageID == \"\"` (builder/oci/config.go), and a null would have to be coerced anyway."
  default     = ""
}

variable "base_image_operating_system" {
  type        = string
  description = "Base image OS for the filter path."
  default     = "Canonical Ubuntu"
}

variable "base_image_operating_system_version" {
  type        = string
  description = "Base image OS version for the filter path. Exactly \"26.04\" (resolute) - matching the GCP images' ubuntu-2604-lts so the provisioner scripts stay identical. Note that OCI reports the Minimal variants as \"26.04 Minimal\" and the ARM ones share the plain \"26.04\" string, so this filter alone does not exclude aarch64; the `shape` entry in base_image_filter does. Upgraded from 24.04 on 2026-10-12 per user request."
  default     = "26.04"
}

variable "shape" {
  type        = string
  description = "Shape for the temporary build instance. Also the architecture filter for base_image_filter: an x86 shape here excludes the aarch64 base images that share the same operating_system_version string."
  default     = "VM.Standard.E5.Flex"
}

variable "shape_ocpus" {
  type        = number
  description = "OCPUs for the temporary build instance. 1 is the E5.Flex floor and is plenty for an apt-driven build; this instance lives for minutes."
  default     = 1
}

variable "shape_memory_in_gbs" {
  type        = number
  description = "Memory for the temporary build instance."
  default     = 8
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size for the build instance, and therefore for the resulting image. WATCH THE ARGUMENT NAME IT FEEDS: the oracle-oci builder calls this `disk_size`, not `boot_volume_size_in_gbs` (builder/oci/config.go: `BootVolumeSizeInGBs int64 `+\"`\"+`mapstructure:\"disk_size\"`+\"`\"+`) - the Go field is named after the OCI concept and the HCL argument after Packer's. Must be >= 50: OCI will not create a boot volume smaller than the base image's own 50 GB, unlike GCP where 20 GB was accepted."
  default     = 50
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
  description = "Prefix for the resulting custom image's name. OCI has no image-family concept the way GCE does - there is no `image_family` field on oci_core_image and no \"newest in family\" resolution - so the consuming unit takes an image OCID, and this prefix exists only to keep `oci compute image list` readable."
  default     = "hyperswitch-squid"
}

variable "squid_port" {
  type        = number
  description = "Port Squid listens on, opened in ufw. Must match the squid-proxy unit's squid_port input, the http_port directive in the delivered squid.conf, and the NLB listener port."
  default     = 3128
}

variable "ssh_username" {
  type        = string
  description = "SSH user on the base image. Canonical's OCI Ubuntu images create `ubuntu`, not `opc` (which is Oracle Linux's) and not `packer` (which the GCP builder creates for itself)."
  default     = "ubuntu"
}

variable "assign_public_ip" {
  type        = bool
  description = "Give the temporary build instance a public IP so `packer build` can SSH to it from outside the VCN. True is the only working setting today: the oracle-oci builder has no OCI Bastion support (there is no bastion argument anywhere in builder/oci/config.go), and no Bastion service instance exists in this tenancy to tunnel through even via Packer's generic ssh_bastion_* communicator settings. This is a property of the ten-minute build instance ONLY - both proxy composition modules set assign_public_ip = false on their instance configurations and place them in subnets with prohibit_public_ip_on_vnic = true."
  default     = true
}

variable "vector_loki_endpoint" {
  type        = string
  description = "Loki endpoint Vector ships squid's access.log to. NOT REACHABLE from this OCI environment as of 2026-09-05, and unlike the GCP case this is certain rather than likely: no Loki is deployed on OCI at all (it is a phase-3 application unit and phase 3 currently contains only oke-workload-identity). Vector still starts and tails the log correctly - see healthcheck.enabled = false in scripts/vector.toml.pkrtpl.hcl. Baked in at build time; changing it needs a rebuild, not a live-layer edit."
  default     = "http://loki.hyperswitch.internal"
}

variable "selftest_allowlist_domain" {
  type        = string
  description = "Domain temporarily added to the allowlist during the build's own health assertion, to prove an ALLOWED CONNECT tunnels (TCP_TUNNEL/200). Removed again before the image is captured."
  default     = "github.com"
}

variable "selftest_denied_domain" {
  type        = string
  description = "Domain deliberately NOT on the allowlist during the build's health assertion, to prove a non-allowlisted CONNECT is refused (TCP_DENIED/403). Mirrors the exact pair the GCP squid image was live-tested with on 2026-08-20."
  default     = "example.org"
}
