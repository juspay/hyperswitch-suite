# =============================================================================
# istio - the OCI port of application-resources/istio
# =============================================================================
# Check sheet: docs/multi-cloud-parity/oci/modules/istio.md
# Network:     docs/multi-cloud-parity/oci/network-security-model.md (Option A)
#
# THE ONLY MODULE IN THIS BATCH WITH NO CLOUD IDENTITY. identity-model.md
# section 1.2 row 13 records it plainly: Istio needs no pod identity, "helm
# only". It emits an empty `policy_statements` list for uniformity with its
# siblings and nothing else - see outputs.tf.
#
# THE HEADLINE CHANGE: `alb-controller` DISAPPEARS AS A CONCEPT.
#
#   AWS deploys the gateway Service as `type = ClusterIP` and puts a
#   `kubernetes_ingress_v1` with `ingress_class_name = "alb"` in front of it.
#   That class only resolves because a SECOND module - `alb-controller` - is
#   running the community AWS Load Balancer Controller in the same cluster.
#   This module is that controller's only consumer in the whole platform.
#
#   Every OKE cluster already ships the OCI Cloud Controller Manager. A Service
#   of `type = LoadBalancer` becomes a working OCI Load Balancer with no Helm
#   chart, no IAM role and no ServiceAccount to create. So there is NO `Ingress`
#   object in this module, no `ingress_annotations` variable, and no
#   `alb-controller` equivalent to build. The AWS `alb.ingress.kubernetes.io/*`
#   annotation surface becomes `oci.oraclecloud.com/*` and
#   `service.beta.kubernetes.io/oci-load-balancer-*`.
#
#   That is a SIMPLIFICATION - one fewer controller to keep patched - and the
#   sibling `alb-controller` port is deliberately not built (all five of its
#   features land on NONE).
# =============================================================================

# -----------------------------------------------------------------------------
# Placement
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = "OCID of the compartment the NSG and reserved IP are created in. New input with no AWS counterpart - every OCI resource is compartment-scoped."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "environment" {
  description = "Short environment name (dev / integ / sandbox / prod)."
  type        = string
}

variable "project_name" {
  description = "Project name prefix used in resource naming."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Echoed as an output, unchanged from the AWS module."
  type        = string
}

variable "cluster_id" {
  description = <<-EOT
    OCID of the OKE cluster Istio is installed on. Replaces AWS's
    `eks_cluster_name` plus its `data "aws_eks_cluster"` /
    `"aws_eks_cluster_auth"` pair - the data sources disappear because this
    module does not configure its own Kubernetes provider (versions.tf).

    Used for naming and as an output; nothing here reads the cluster's
    attributes.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.cluster\\.", var.cluster_id))
    error_message = "cluster_id must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "vcn_id" {
  description = "OCID of the VCN the gateway NSG is created in. Required when `create_gateway_nsg` is true - an `oci_core_network_security_group` is a VCN-scoped object."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Helm releases (check sheet features 1, 2, 8, 9 - all FULL)
# -----------------------------------------------------------------------------

variable "create_helm_releases" {
  description = <<-EOT
    Master switch for the three Helm releases. Unchanged in shape from AWS.

    Every one of the seven AWS live roots that instantiates this module sets it
    FALSE - ArgoCD owns the Helm installs there, and this module's actual
    Terraform footprint in production is the security group alone. Default false
    here for the same reason; flip it per environment if ArgoCD-on-OCI is not
    ready.
  EOT
  type        = bool
  default     = false
}

variable "istio_namespace" {
  description = "Namespace the Istio components install into."
  type        = string
  default     = "istio-system"
}

variable "istio_base" {
  description = "The `base` chart (CRDs). Chart plumbing is cloud-agnostic and unchanged from both the AWS and GCP modules - same repo, same structure, same dependency chain."
  type = object({
    enabled       = optional(bool, true)
    release_name  = optional(string, "istio-base")
    chart_repo    = optional(string, "https://istio-release.storage.googleapis.com/charts")
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = {}
}

variable "istiod" {
  description = "The `istiod` control-plane chart. Installs after `base`."
  type = object({
    enabled       = optional(bool, true)
    release_name  = optional(string, "istiod")
    chart_repo    = optional(string, "https://istio-release.storage.googleapis.com/charts")
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = {}
}

variable "istio_gateway" {
  description = <<-EOT
    The `gateway` data-plane chart. Installs after `istiod`.

    THE ONE PLACE THE CHART VALUES DIVERGE FROM AWS: this module renders
    `service.type = "LoadBalancer"` plus the OCI CCM annotation map (locals.tf)
    into the values, where AWS renders `type = "ClusterIP"` and puts a separate
    `kubernetes_ingress_v1` in front. Caller-supplied `values` are merged AFTER
    the generated block, so they win - which also means a caller can override
    `service.type` and break the exposure path. Do not.

    NOT USING THE OKE ISTIO CLUSTER ADD-ON (`oci_containerengine_addon`,
    `addon_name = "Istio"`), which is real and would be less operational toil.
    It restricts configuration to Oracle-"approved" key/value pairs,
    auto-upgrades istiod and the gateway on Oracle's schedule, and is mutually
    exclusive with a standalone Helm install. Direct Helm matches both the AWS
    and GCP precedents exactly and keeps version and values control. Check sheet
    section 8 item 4 - a genuine architecture fork, oracle gate NOT YET
    CONSULTED.
  EOT
  type = object({
    enabled       = optional(bool, true)
    release_name  = optional(string, "istio-gateway")
    chart_repo    = optional(string, "https://istio-release.storage.googleapis.com/charts")
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Gateway exposure (check sheet features 3, 4, 5, 7)
# -----------------------------------------------------------------------------

variable "load_balancer_type" {
  description = <<-EOT
    `lb` for an L7 OCI Load Balancer (the CCM default), `nlb` for an L4 Network
    Load Balancer.

    AN UNRESOLVED FORK BETWEEN THE TWO EXISTING PRECEDENTS, defaulted rather
    than decided. AWS terminates TLS at an L7 ALB and forwards plain HTTP to the
    gateway; GCP uses an L4 passthrough NLB and terminates TLS inside Envoy via
    Istio's own Gateway resource and SDS. Both work; they disagree.

    `lb` is the default here because it is the shape this stack already
    operates, and because it keeps certificate lifecycle in one place - whatever
    `acm.md`'s self-managed-ACME or private-CA path produces, fed into a single
    Kubernetes Secret - rather than inside the mesh's SDS machinery. Check sheet
    section 9 Q2 and section 8 item 5, oracle gate NOT YET CONSULTED.
  EOT
  type        = string
  default     = "lb"

  validation {
    condition     = contains(["lb", "nlb"], var.load_balancer_type)
    error_message = "load_balancer_type must be `lb` (L7 OCI Load Balancer) or `nlb` (L4 Network Load Balancer)."
  }
}

variable "tls_secret_ref" {
  description = <<-EOT
    `<namespace>/<secretName>` of the Kubernetes Secret carrying the gateway's
    certificate, rendered into
    `service.beta.kubernetes.io/oci-load-balancer-tls-secret`.

    NEW, with no AWS counterpart, and this is where `acm.md`'s certificate-trust
    gap actually lands for this module. AWS's ALB references an ACM certificate
    by ARN; the OCI CCM references a KUBERNETES SECRET, not a
    Certificates-Management OCID - a different attachment mechanism from the
    OCID-reference pattern `load-balancer.md` established for a STANDALONE
    `oci_load_balancer_load_balancer`, because that is a different resource.

    Only meaningful when `load_balancer_type = "lb"`. Null leaves TLS to be
    terminated inside the mesh.
  EOT
  type        = string
  default     = null
}

variable "create_gateway_nsg" {
  description = <<-EOT
    Create the module-owned Network Security Group for the gateway's load
    balancer, and attach it via
    `oci.oraclecloud.com/oci-network-security-groups`. Renamed from AWS's
    `create_lb_security_group`; every AWS live root sets that true.

    CREATED EMPTY. See network-security.tf - the rules are written by
    `composition/security-rules` in the security-last phase, not here.
  EOT
  type        = bool
  default     = true
}

variable "gateway_nsg_ids" {
  description = "Additional, pre-existing NSG OCIDs to attach to the gateway's load balancer alongside the module-owned one. The BYO path, renamed from AWS's `lb_security_groups`. Note OCI's hard cap of 5 NSGs per VNIC."
  type        = list(string)
  default     = []
}

variable "nsg_display_name" {
  description = "Display name for the module-owned NSG. Defaults to `<env>-<project>-istio-gateway-nsg`."
  type        = string
  default     = null
}

variable "create_gateway_reserved_ip" {
  description = <<-EOT
    Reserve a stable public IP for the gateway (`oci_core_public_ip`,
    `lifetime = "RESERVED"`) and pin the load balancer to it via
    `oci.oraclecloud.com/reserved-ips`.

    NAMED AFTER OCI'S CONCEPT, NOT AWS'S. AWS feature 7 is "a stable network
    ADDRESS", delivered implicitly as the ALB's persistent DNS hostname - there
    is nothing to create and nothing to name. OCI's equivalent is a stable IP,
    which is a real resource, and DNS points an A record at it rather than a
    CNAME at a hostname. This mirrors GCP's `google_compute_address` +
    `loadBalancerIP` almost exactly.
  EOT
  type        = bool
  default     = true
}

variable "gateway_service_annotations" {
  description = "Additional annotations merged onto the gateway Service, after the module's own CCM annotation map. A caller-supplied key with the same name wins - including the security-list-management-mode key, which should not be overridden (see locals.tf)."
  type        = map(string)
  default     = {}
}

variable "external_traffic_policy" {
  description = <<-EOT
    `Cluster` (default) or `Local` on the gateway Service.

    NOT A COSMETIC KNOB HERE. A CCM-provisioned load balancer targets worker-node
    NodePorts, not pod IPs, and its default health check verifies that a NODE can
    proxy for the Service (kube-proxy's endpoint on 10256) rather than that a
    gateway POD is ready - coarser than AWS's ALB, which health-checks
    `/healthz/ready` on 15021 against the pods directly (check sheet section 4.2,
    PARTIAL). `Local` changes the health-check target to a per-node
    pod-presence check and preserves the client source IP, at the cost of
    uneven traffic distribution.

    Neither the AWS nor the GCP module sets this explicitly, so neither is a
    precedent. Check sheet section 9 Q3, unresolved; null leaves the chart's own
    default alone rather than asserting one.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.external_traffic_policy == null || contains(["Cluster", "Local"], coalesce(var.external_traffic_policy, "Cluster"))
    error_message = "external_traffic_policy must be Cluster, Local, or null."
  }
}

# -----------------------------------------------------------------------------
# Passthrough (check sheet feature 10, FULL)
# -----------------------------------------------------------------------------

variable "host_domains" {
  description = "Map of logical name to hostname(s) served through this gateway. Echoed unchanged as `host_domains_map`; no cloud resource behind it on any cloud."
  type        = map(list(string))
  default     = {}
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "freeform_tags" {
  description = "Freeform tags merged onto the OCI resources this module creates. The AWS `tags` / GCP `labels` analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags, keyed \"namespace.key\". Passed through untouched."
  type        = map(string)
  default     = {}
}

# =============================================================================
# DROPPED, with no replacement:
#
#   lb_subnet_ids       Check sheet section 4.4, PARTIAL. The OCI equivalent,
#                       `oci_containerengine_cluster.options.service_lb_subnet_ids`,
#                       is a CLUSTER-LEVEL field shared by every Service-type
#                       LoadBalancer in the cluster - there is no per-Service
#                       subnet-placement annotation in the CCM's documented
#                       surface. Placement is now `oke`'s responsibility. A real
#                       narrowing of this module's authority, harmless while the
#                       stack has one LB-subnet tier per environment.
#
#   ingress_annotations No `Ingress` object exists to annotate (feature 3).
#
#   eks_cluster_name +  Replaced by `cluster_id`; the data sources disappear
#   the aws_eks_cluster  because this module configures no Kubernetes provider
#   data sources        of its own (versions.tf).
# =============================================================================
