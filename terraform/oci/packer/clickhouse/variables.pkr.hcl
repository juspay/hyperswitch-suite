variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID the temporary build instance and the resulting custom image are created in."
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for the temporary build instance, e.g. \"Niou:PHX-AD-1\" (this tenancy's actual prefix - verified 2026-11-17 via `oci iam availability-domain list --profile produser`). AD names carry a tenancy-specific opaque prefix and are NOT portable between tenancies. us-phoenix-1 has three; any of them works for a single-node build."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet the temporary build instance launches into. Needs outbound internet (apt, packages.clickhouse.com, the Vector repo, the OCI CLI installer) and an inbound SSH path from wherever `packer build` runs. ../build-network/create.sh makes a disposable VCN that satisfies both."
}

variable "region" {
  type        = string
  description = "OCI region. Overrides the region in the OCI config file profile. Prod default: the image is built DIRECTLY in us-phoenix-1 (gate decision 2 of .omo/plans/oci-kafka-clickhouse-images.md - no build-region promotion ladder)."
  default     = "us-phoenix-1"
}

variable "access_cfg_file_account" {
  type        = string
  description = "Profile name in ~/.oci/config the build authenticates as. The oracle-oci builder calls this `access_cfg_file_account`, not `config_file_profile` (the Terraform provider's name) and not `profile` (the CLI's). Session-token profiles work: the builder delegates to the OCI Go SDK's file configuration provider, which returns an ST$-prefixed key ID when the profile carries `security_token_file` (../README.md records the full argument)."
  default     = "produser"
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
  description = "Base image OS version for the filter path. \"26.04\" (resolute), matching the envoy/squid images so the shared provisioner scripts stay identical. OCI's aarch64 images share this exact version string, so the `shape` entry in base_image_filter - not this - is what excludes ARM. CIS seam (plan risk section): the pinned UBUNTU24-CIS role already ran successfully on this 26.04 base in the envoy/squid builds, so no fallback to 24.04 is needed; if a future build proves otherwise, this one line is the documented fallback."
  default     = "26.04"
}

variable "shape" {
  type        = string
  description = "Shape for the temporary build instance, and the architecture filter for base_image_filter."
  default     = "VM.Standard.E5.Flex"
}

variable "shape_ocpus" {
  type        = number
  description = "OCPUs for the temporary build instance. 2 matches the runtime server sizing the catalog unit will use (2 OCPU / 16 GB), so the in-build selftest runs on the same resources the real node gets."
  default     = 2
}

variable "shape_memory_in_gbs" {
  type        = number
  description = "Memory for the temporary build instance."
  default     = 16
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size for the build instance and therefore for the image. Feeds the builder's `disk_size` argument (the Go field is BootVolumeSizeInGBs but its mapstructure tag is `disk_size`). Must be >= 50, the base image's own size. The runtime data volumes are separate block volumes attached by the composition module - nothing of the workload lives here."
  default     = 50
}

variable "clickhouse_version" {
  type        = string
  description = "Exact version of the ClickHouse LTS debs to install (clickhouse-server, clickhouse-client and the clickhouse-common-static dependency), pinned so the image is reproducible and the chain of custody is the signed packages.clickhouse.com LTS repo + an immutable version string. Keeper ships INSIDE the server deb (clickhouse-keeper + its service unit + keeper_config.xml are symlink/unit members of clickhouse-server - build-verified 2026-11-17; the standalone clickhouse-keeper deb Conflicts clickhouse-server and exists only for keeper-only nodes). Re-check the LTS channel on build day (`curl -sL https://packages.clickhouse.com/deb/dists/lts/main/binary-amd64/Packages`) and pin the newest version. Recorded 2026-11-17: 26.8.39.19 is the current LTS patch (plan §0 gate decision 1 says 'latest patched lines' - this supersedes the plan text's day-of 26.8.36.3)."
  default     = "26.8.39.19"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, sandbox, prod). Goes into the image name and its freeform tags. Prod default per plan gate decision 2."
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Project name, used in image freeform tags."
  default     = "hyperswitch"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the resulting image name. OCI has no image-family concept - there is no `image_family` field on oci_core_image and no newest-in-family resolution - so the consuming unit takes an OCID and this prefix only keeps `oci compute image list` readable."
  default     = "hyperswitch-clickhouse"
}

variable "clickhouse_http_port" {
  type        = number
  description = "ClickHouse HTTP interface port (/ping lives here), opened in ufw. MUST match the clickhouse unit's `clickhouse_port` (8123) - that is the port the load balancer's backend set and its /ping health check both target."
  default     = 8123
}

variable "clickhouse_tcp_port" {
  type        = number
  description = "ClickHouse native TCP protocol port, opened in ufw (client and interserver traffic)."
  default     = 9000
}

variable "clickhouse_keeper_port" {
  type        = number
  description = "ClickHouse Keeper client port, opened in ufw. UNUSED in the single-node cut (keeper_count = 0 - the plan's gate decision 3); ships open so a later keeper scale-up does not need an image rebuild. The plan's step-10 delta lists it explicitly."
  default     = 9181
}

variable "vector_prometheus_port" {
  type        = number
  description = "Port Vector's prometheus_exporter sink listens on. NOT opened in ufw (the plan's step-10 delta lists exactly 8123/9000/9181, and unlike the envoy image nothing has been confirmed scraping a clickhouse node yet - opening a port nothing scrapes is how a firewall rule outlives its reason). Binds 0.0.0.0 in vector.toml for recipe parity; scrape it on-box or open the port when a scraper exists."
  default     = 9273
}

variable "ssh_username" {
  type        = string
  description = "SSH user on the base image. Canonical's OCI Ubuntu images create `ubuntu` - not `opc` (Oracle Linux's) and not `packer` (which the GCE builder creates for itself)."
  default     = "ubuntu"
}

variable "assign_public_ip" {
  type        = bool
  description = "Give the temporary build instance a public IP so `packer build` can reach it. True is the only working setting today: the oracle-oci builder has no OCI Bastion support (no bastion argument exists anywhere in builder/oci/config.go) and no Bastion service instance exists in this tenancy. A build-instance property only - the clickhouse composition module places its instances in a subnet with prohibit_public_ip_on_vnic = true."
  default     = true
}

variable "prod_vcn_cidr" {
  type        = string
  description = "CIDR the ufw SSH rule allows from, defence-in-depth under the build network's own security list. The prod VCN CIDR (values.vcn_cidr_prefix = \"10.91\" in hyperswitch-infra's live prod values, vpc-network unit => 10.91.0.0/16). The envoy recipe used the dev VCN's 10.90.0.0/16 the same way."
  default     = "10.91.0.0/16"
}
