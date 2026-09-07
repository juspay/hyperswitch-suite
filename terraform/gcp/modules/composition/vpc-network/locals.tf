locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # Named subnet tiers. GCP subnets are regional, so one CIDR per tier is
  # enough - there is no per-AZ fan-out. There is no control-plane tier either:
  # GKE's control plane lives outside the VPC, configured via
  # master_ipv4_cidr_block on composition/gke.
  named_subnets = {
    external-incoming = {
      cidr                     = var.external_incoming_subnet_cidr
      private_ip_google_access = false
      purpose                  = null
      secondary_ranges         = []
      description              = "Internet-facing subnet for external load balancers"
    }
    management = {
      cidr                     = var.management_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Bastion / jump-host subnet"
    }
    gke-nodes = {
      cidr                     = var.gke_nodes_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges = [
        { range_name = "${local.name_prefix}-gke-pods", ip_cidr_range = var.gke_pods_secondary_range_cidr },
        { range_name = "${local.name_prefix}-gke-services", ip_cidr_range = var.gke_services_secondary_range_cidr },
      ]
      description = "GKE node pool subnet with pods/services alias ranges"
    }
    database = {
      cidr                     = var.database_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Cloud SQL proxies / private-services consumers"
    }
    locker-database = {
      cidr                     = var.locker_database_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "PCI-DSS scoped locker database subnet"
    }
    locker-server = {
      cidr                     = var.locker_server_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "PCI-DSS scoped locker server subnet"
    }
    memorystore = {
      cidr                     = var.memorystore_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Reserved range for Memorystore direct-peering instances"
    }
    data-stack = {
      cidr                     = var.data_stack_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Kafka / Cassandra / ClickHouse / OpenSearch data-stack subnet"
    }
    incoming-envoy = {
      cidr                     = var.incoming_envoy_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Envoy ingress proxy subnet"
    }
    outgoing-proxy = {
      cidr                     = var.outgoing_proxy_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Squid egress proxy subnet"
    }
    utils = {
      cidr                     = var.utils_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Shared utility workloads subnet"
    }
    serverless-connector = {
      cidr                     = var.serverless_connector_subnet_cidr
      private_ip_google_access = true
      purpose                  = null
      secondary_ranges         = []
      description              = "Serverless VPC Access connector subnet for Cloud Functions/Cloud Run"
    }
  }

  custom_subnets = {
    for key, subnet in var.custom_subnets : key => {
      cidr                     = subnet.cidr
      private_ip_google_access = try(subnet.private_ip_google_access, true)
      purpose                  = try(subnet.purpose, null)
      secondary_ranges         = try(subnet.secondary_ranges, [])
      description              = try(subnet.description, "Custom subnet: ${key}")
    }
  }

  all_subnets = merge(local.named_subnets, local.custom_subnets)

  subnets_list = [
    for tier, subnet in local.all_subnets : {
      subnet_name           = "${local.name_prefix}-${tier}"
      subnet_ip             = subnet.cidr
      subnet_region         = var.region
      subnet_private_access = tostring(subnet.private_ip_google_access)
      subnet_flow_logs      = tostring(var.enable_flow_logs)
      description           = subnet.description
      purpose               = subnet.purpose
    }
    if subnet.cidr != null
  ]

  secondary_ranges = {
    for tier, subnet in local.all_subnets :
    "${local.name_prefix}-${tier}" => subnet.secondary_ranges
    if subnet.cidr != null && length(subnet.secondary_ranges) > 0
  }

  gke_nodes_subnet_name = "${local.name_prefix}-gke-nodes"

  # Cloud NAT subnet scoping, only used when var.nat_subnetwork_tiers is set
  # (LIST_OF_SUBNETWORKS mode). Unknown or CIDR-less tier names are dropped
  # rather than erroring, so a typo fails closed - that tier gets no NAT route.
  nat_subnetworks_list = var.nat_subnetwork_tiers == null ? [] : [
    for tier in var.nat_subnetwork_tiers : {
      name                     = "${local.name_prefix}-${tier}"
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    }
    if contains(keys(local.all_subnets), tier) && local.all_subnets[tier].cidr != null
  ]

  # Baseline network-wide firewall rules. Module-internal only - cross-module
  # rules belong in composition/firewall-rules.
  ingress_rules = concat(
    [
      {
        name          = "${local.name_prefix}-allow-internal"
        description   = "Allow all traffic between resources inside the VPC"
        priority      = 1000
        source_ranges = values(var.vpc_internal_ranges)
        allow = [
          { protocol = "tcp", ports = ["0-65535"] },
          { protocol = "udp", ports = ["0-65535"] },
          { protocol = "icmp" },
        ]
      },
      {
        name          = "${local.name_prefix}-allow-health-checks"
        description   = "Allow Google Cloud health check probes"
        priority      = 1000
        source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
        allow         = [{ protocol = "tcp" }]
      },
      {
        name          = "${local.name_prefix}-allow-iap-ssh"
        description   = "Allow SSH from Identity-Aware Proxy for bastion access"
        priority      = 1000
        source_ranges = ["35.235.240.0/20"]
        target_tags   = ["iap-ssh"]
        allow         = [{ protocol = "tcp", ports = ["22"] }]
      },
    ],
    var.enable_default_deny_ingress ? [
      {
        name          = "${local.name_prefix}-deny-all-ingress"
        description   = "Default-deny all other ingress traffic"
        priority      = 65534
        source_ranges = ["0.0.0.0/0"]
        deny          = [{ protocol = "all" }]
        log_config    = { metadata = "INCLUDE_ALL_METADATA" }
      },
    ] : []
  )

  egress_rules = concat(
    var.enable_default_deny_egress ? [] : [
      {
        name               = "${local.name_prefix}-allow-all-egress"
        description        = "Allow all outbound traffic; scoping is done via per-service firewall-rules"
        priority           = 65534
        destination_ranges = ["0.0.0.0/0"]
        allow              = [{ protocol = "all" }]
      },
    ],
    # The two rules below only matter once the deny-all-egress rule at
    # priority 65534 is active; they sit at priority 1000, ahead of it.
    #
    # Not covered here, and required before enable_default_deny_egress is safe:
    # an egress allow to the GKE master's master_ipv4_cidr_block (ports 443,
    # 10250, 8132). GKE auto-creates only the ingress side of master<->node
    # traffic, and this module cannot see master_ipv4_cidr_block, so that rule
    # belongs in composition/firewall-rules. Without it, nodes go NotReady once
    # their kubelet lease expires after apply.
    var.enable_default_deny_egress ? [
      {
        name               = "${local.name_prefix}-allow-egress-internal"
        description        = "Allow egress between resources inside the VPC (node<->node, node<->pod, pod<->service) - mirrors allow-internal, which is ingress-only"
        priority           = 1000
        destination_ranges = values(var.vpc_internal_ranges)
        allow = [
          { protocol = "tcp", ports = ["0-65535"] },
          { protocol = "udp", ports = ["0-65535"] },
          { protocol = "icmp" },
        ]
        log_config = { metadata = "INCLUDE_ALL_METADATA" }
      },
    ] : [],
    var.enable_default_deny_egress && var.enable_psc_google_apis ? [
      {
        name               = "${local.name_prefix}-allow-egress-psc-google-apis"
        description        = "Allow egress to the Private Service Connect Google APIs endpoint (Artifact Registry, Secret Manager, etc.) - required once default-deny-egress is on"
        priority           = 1000
        destination_ranges = ["${var.psc_google_apis_ip}/32"]
        allow              = [{ protocol = "tcp", ports = ["443"] }]
        log_config         = { metadata = "INCLUDE_ALL_METADATA" }
      },
    ] : [],
    var.enable_default_deny_egress ? [
      {
        name               = "${local.name_prefix}-deny-all-egress"
        description        = "Default-deny all other egress traffic - add specific destination allows in composition/firewall-rules"
        priority           = 65534
        destination_ranges = ["0.0.0.0/0"]
        deny               = [{ protocol = "all" }]
        log_config         = { metadata = "INCLUDE_ALL_METADATA" }
      },
    ] : []
  )
}
