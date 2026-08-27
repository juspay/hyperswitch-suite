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

  # ==========================================================================
  # Named subnet tiers
  # ==========================================================================
  # GCP subnets are regional (span every zone in the region), so unlike the
  # AWS vpc-network module there is no per-AZ subnet fan-out here: one CIDR
  # per tier is enough. There is also no `eks-control-plane` tier - GKE's
  # control plane lives outside the VPC and is configured via
  # `master_ipv4_cidr_block` on the composition/gke module, not a subnet.
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

  # ==========================================================================
  # Baseline network-wide firewall rules
  # ==========================================================================
  # Module-internal only - cross-module rules belong in
  # composition/firewall-rules, applied last in the deployment order.
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
      },
    ] : []
  )

  egress_rules = [
    {
      name               = "${local.name_prefix}-allow-all-egress"
      description        = "Allow all outbound traffic; scoping is done via per-service firewall-rules"
      priority           = 65534
      destination_ranges = ["0.0.0.0/0"]
      allow              = [{ protocol = "all" }]
    },
  ]
}
