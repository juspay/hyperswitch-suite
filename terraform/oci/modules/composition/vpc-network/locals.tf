locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # OCI DNS labels are alphanumeric only, max 15 chars, must start with a
  # letter, and are NOT updatable - changing one replaces the VCN or subnet.
  vcn_dns_label = coalesce(
    var.vcn_dns_label,
    substr(replace(lower("${var.project_name}${var.environment}"), "/[^a-z0-9]/", ""), 0, 15)
  )

  #############################################################################
  # Named subnet tiers - 13 tiers, one REGIONAL subnet each
  #
  # availability_domain is deliberately never set (Oracle recommends regional
  # subnets). prohibit_public_ip_on_vnic is STRONGER than AWS's
  # map_public_ip_on_launch: it forbids a public IP on any VNIC in the subnet
  # outright, and is therefore true on every tier except external-incoming.
  # prohibit_internet_ingress is never set alongside it - the provider states
  # only one or the other flag should be specified.
  #############################################################################
  named_subnets = {
    external-incoming = {
      cidr                       = var.external_incoming_subnet_cidr
      prohibit_public_ip_on_vnic = false
      route_table                = "common-internet"
      dns_label                  = "extincoming"
      description                = "Internet-facing subnet for public load balancers"
    }
    management = {
      cidr                       = var.management_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "common-local-osn"
      dns_label                  = "mgmt"
      description                = "Bastion / jump-host subnet - PRIVATE (correction C7). Reached through the managed OCI Bastion service's private endpoint, never a public IP; keeps the private service-gateway path to Oracle services that the public table could not carry."
    }
    oke-nodes = {
      cidr                       = var.oke_nodes_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "oke-nodes"
      dns_label                  = "okenodes"
      description                = "OKE worker node subnet - no internet route, egress via the Squid proxy only"
    }
    oke-pods = {
      cidr                       = var.oke_pods_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "oke-nodes"
      dns_label                  = "okepods"
      description                = "OKE pod IPs under the VCN-native CNI - one VCN IP per pod"
    }
    # Always-private, static; the public path is a separate, additive subnet.
    oke-api-endpoint = {
      cidr                       = var.oke_api_endpoint_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "oke-api-endpoint"
      dns_label                  = "okeapi"
      description                = "Private OKE Kubernetes API endpoint VNIC; the control plane itself is Oracle-managed and outside the VCN"
    }

    # This subnet CANNOT be toggled public/private in place: prohibit_public_ip_on_vnic is
    # ForceNew, and OCI refuses the destroy/recreate while the cluster's own
    # Oracle-managed Service VNIC still lives in it. That VNIC only detaches
    # once the cluster's endpoint_config is repointed elsewhere, which requires
    # a subnet that must already exist - so recreating the subnet the cluster
    # actively uses is an ordering deadlock. Fix: a second, always-additive
    # public subnet (a null-CIDR tier is simply not created - see all_subnets).
    oke-api-endpoint-public = {
      cidr                       = var.oke_api_endpoint_is_public ? var.oke_api_endpoint_public_subnet_cidr : null
      prohibit_public_ip_on_vnic = false
      route_table                = "oke-api-endpoint-public"
      dns_label                  = "okeapipub"
      description                = "Public OKE Kubernetes API endpoint VNIC - additive, only exists when oke_api_endpoint_is_public = true"
    }
    database = {
      cidr                       = var.database_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "db"
      dns_label                  = "db"
      description                = "Primary database subnet"
    }
    locker-database = {
      cidr                       = var.locker_database_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "locker-db"
      dns_label                  = "lockerdb"
      description                = "PCI-DSS scoped locker database subnet - fully isolated, no gateway routes at all"
    }
    locker-server = {
      cidr                       = var.locker_server_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "locker-server-osn"
      dns_label                  = "lockersrv"
      description                = "PCI-DSS scoped locker server subnet"
    }
    cache = {
      cidr                       = var.cache_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "cache"
      dns_label                  = "cache"
      description                = "OCI Cache (Valkey) subnet - replaces the AWS elasticache tier"
    }
    data-stack = {
      cidr                       = var.data_stack_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "data-stack-osn"
      dns_label                  = "datastack"
      description                = "Kafka / Cassandra / ClickHouse / OpenSearch data-stack subnet"
    }
    incoming-envoy = {
      cidr                       = var.incoming_envoy_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "common-local-nat-osn"
      dns_label                  = "envoyin"
      description                = "Envoy ingress proxy subnet"
    }
    outgoing-proxy = {
      cidr                       = var.outgoing_proxy_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "proxy-peering-nat"
      dns_label                  = "proxyout"
      description                = "Squid egress proxy subnet - the only tier carrying a NAT route"
    }
    utils = {
      cidr                       = var.utils_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "common-local-nat-osn"
      dns_label                  = "utils"
      description                = "Shared utility workloads subnet"
    }
  }

  # OKE control-plane endpoint subnet CIDR, following the public/private toggle.
  # The Bastion-service egress rule (security-lists.tf) must target whichever
  # subnet actually hosts the endpoint VNIC: the public variant when
  # oke_api_endpoint_is_public, else the private one.
  cp_subnet_cidr_for_bastion = (
    var.oke_api_endpoint_is_public
    ? try(local.named_subnets["oke-api-endpoint-public"].cidr, var.oke_api_endpoint_public_subnet_cidr)
    : try(local.named_subnets["oke-api-endpoint"].cidr, var.oke_api_endpoint_subnet_cidr)
  )

  custom_subnets = {
    for key, subnet in var.custom_subnets : key => {
      cidr                       = subnet.cidr
      prohibit_public_ip_on_vnic = subnet.prohibit_public_ip_on_vnic
      route_table                = subnet.route_table
      dns_label                  = coalesce(subnet.dns_label, substr(replace(lower(key), "/[^a-z0-9]/", ""), 0, 15))
      description                = coalesce(subnet.description, "Custom subnet: ${key}")
    }
  }

  # A tier with a null CIDR is simply not created, so one module serves
  # environments that do not need every tier.
  all_subnets = {
    for tier, subnet in merge(local.named_subnets, local.custom_subnets) :
    tier => subnet if subnet.cidr != null
  }

  #############################################################################
  # Service gateway CIDR label
  #
  # The two service CIDR labels are MUTUALLY EXCLUSIVE: "Because Object Storage
  # is covered by both ... a service gateway can use only one of those service
  # CIDR labels. Likewise, a route table can have a single rule for one of the
  # service CIDR labels." So there is exactly ONE service CIDR to route to, and
  # a route table cannot grant Object-Storage-only access while another grants
  # full OSN access - the choice is VCN-wide. Per-tier denial is still available
  # by omitting the service route from a tier's route table.
  #############################################################################
  object_storage_services = [
    for s in data.oci_core_services.this.services :
    s if length(regexall("(?i)^oci .* object storage$", s.name)) > 0
  ]

  all_osn_services = [
    for s in data.oci_core_services.this.services :
    s if length(regexall("(?i)services in oracle services network", s.name)) > 0
  ]

  service_gateway_enabled = var.enable_service_gateway_object_storage || var.enable_service_gateway_all_services

  selected_service = (
    var.enable_service_gateway_all_services
    ? try(local.all_osn_services[0], null)
    : try(local.object_storage_services[0], null)
  )

  selected_service_id   = try(local.selected_service.id, null)
  selected_service_cidr = try(local.selected_service.cidr_block, null)

  # Exported as object_storage_service_cidr for contract compatibility. When the
  # all-services label is in use this is the OSN superset, which includes Object
  # Storage - NSG egress rules to SERVICE_CIDR_BLOCK need this value either way.
  object_storage_service_cidr = try(local.object_storage_services[0].cidr_block, null)

  #############################################################################
  # Route-table catalogue
  #
  # 12 named, shared route tables carrying the egress policy, associated to
  # tiers rather than one table per subnet. "osn" in a name means "carries a
  # service route". AWS's per-AZ ProxyPeeringNAT tables collapse into one
  # proxy-peering-nat: the OCI NAT gateway is regional and limited to 1 per VCN.
  #
  # PCI control: the oke-nodes table has NO 0.0.0.0/0 rule of any kind. OKE
  # workers reach Oracle services over the service gateway and everything else
  # through the Squid proxy in outgoing-proxy, the only tier on a NAT-bearing
  # table.
  #############################################################################
  route_tables = {
    common-internet = {
      internet    = true
      nat         = false
      service     = false
      description = "Public tier: default route via the internet gateway"
    }
    # common-internet-osn was removed (correction C7): its only tier became
    # private, and under the all-services label its service rule was suppressed,
    # leaving it byte-identical to common-internet. Re-add deliberately, with a
    # tier attached, if the object-storage label is ever selected and a public
    # tier needs the private Object Storage path.
    common-local = {
      internet    = false
      nat         = false
      service     = false
      description = "Fully isolated: intra-VCN routing only, no gateway of any kind"
    }
    common-local-osn = {
      internet    = false
      nat         = false
      service     = true
      description = "Isolated except for private access to Oracle services"
    }
    common-local-nat-osn = {
      internet    = false
      nat         = true
      service     = true
      description = "Private tier with NAT egress and private access to Oracle services"
    }
    proxy-peering-nat = {
      internet    = false
      nat         = true
      service     = true
      description = "Squid egress proxy: the sanctioned internet egress path, plus peer routes"
    }
    oke-nodes = {
      internet    = false
      nat         = false
      service     = true
      description = "OKE workers and pods: NO internet route at all (PCI control, feature 12); Oracle services via the service gateway, everything else via the Squid proxy"
    }
    oke-api-endpoint = {
      internet    = false
      nat         = false
      service     = true
      description = "Private OKE API endpoint: Oracle services only"
    }
    # C33 - see the subnet-side comment. Always defined; genuinely unused
    # (no route rules bind to a nonexistent subnet) whenever
    # oke_api_endpoint_is_public = false. An idle route table costs nothing.
    oke-api-endpoint-public = {
      internet    = true
      nat         = false
      service     = true
      description = "Public OKE API endpoint route table - only has a subnet attached when oke_api_endpoint_is_public = true"
    }
    db = {
      internet    = false
      nat         = false
      service     = true
      description = "Database tier: Oracle services only (backups to Object Storage)"
    }
    cache = {
      internet    = false
      nat         = false
      service     = true
      description = "Cache tier: Oracle services only"
    }
    locker-db = {
      internet    = false
      nat         = false
      service     = false
      description = "PCI-DSS locker database: no gateway routes at all"
    }
    locker-server-osn = {
      internet    = false
      nat         = false
      service     = true
      description = "PCI-DSS locker server: Oracle services only"
    }
    data-stack-osn = {
      internet    = false
      nat         = false
      service     = true
      description = "Data stack: Oracle services only"
    }
  }

  # Named groups a peering entry may target instead of listing tables. Group
  # names are preserved so peering config migrates.
  route_table_groups = {
    all = keys(local.route_tables)
    # `public` is a one-element group since C7 dropped common-internet-osn; kept
    # so peering config written against the group vocabulary still migrates.
    public           = ["common-internet"]
    private-nat      = ["common-local-nat-osn", "proxy-peering-nat"]
    private-isolated = ["common-local", "common-local-osn", "oke-api-endpoint"]
    database         = ["db", "cache", "locker-db", "locker-server-osn", "data-stack-osn"]
    oke-nodes        = ["oke-nodes"]
  }

  #############################################################################
  # Peer route expansion
  #
  # Two OCI-forced changes: the requester/accepter split disappears (an LPG is
  # symmetric, so one pass covers both sides), and a cross-region route's
  # network_entity_id is the DRG, not the remote peering connection.
  #############################################################################
  lpg_peering_routes = var.enable_peering_routes ? flatten([
    for name, peer in var.local_peering_gateways : [
      for rt in distinct(flatten([
        for entry in peer.route_tables :
        contains(keys(local.route_table_groups), entry) ? local.route_table_groups[entry] : [entry]
        ])) : [
        for cidr in peer.peer_cidrs : {
          route_table = rt
          destination = cidr
          entity_id   = oci_core_local_peering_gateway.this[name].id
          description = "Peer ${name} via local peering gateway"
        }
      ] if contains(keys(local.route_tables), rt)
    ]
  ]) : []

  rpc_peering_routes = var.enable_peering_routes ? flatten([
    for name, peer in var.remote_peering_connections : [
      for rt in distinct(flatten([
        for entry in peer.route_tables :
        contains(keys(local.route_table_groups), entry) ? local.route_table_groups[entry] : [entry]
        ])) : [
        for cidr in peer.peer_cidrs : {
          route_table = rt
          destination = cidr
          entity_id   = local.effective_drg_id
          description = "Peer ${name} via DRG remote peering connection"
        }
      ] if contains(keys(local.route_tables), rt)
    ]
  ]) : []

  peering_routes = concat(local.lpg_peering_routes, local.rpc_peering_routes)

  #############################################################################
  # Internet gateway / service gateway route-rule conflict - GUARDRAIL
  #
  # Oracle rejects a route table that sets ALL of: internet gateway target,
  # all-services service-gateway destination, in the same table
  # (400-InvalidParameter, enforced on create - only an apply catches it; neither
  # validate nor plan sees it). This is distinct from the mutually-exclusive-
  # labels rule on the service_gateway resource: that governs which label the
  # GATEWAY carries, this governs which rules may coexist in one ROUTE TABLE.
  #
  # As of correction C7 this suppression fires for NOTHING - no table carries
  # both `internet = true` and `service = true` - but it is deliberately KEPT:
  # the Oracle rule is permanent, and the next public+service table (via
  # var.custom_subnets or a future catalogue entry) would otherwise fail at apply
  # time. The suppression turns that into a visible, planned, non-fatal omission.
  #
  # It is LABEL-SPECIFIC (conditioned on enable_service_gateway_all_services;
  # an Object-Storage label rule is permitted in a public table) and NAT-safe
  # (only an internet-gateway target conflicts; NAT + all-services in one table
  # is Oracle's own private-subnet pattern, so common-local-nat-osn and
  # proxy-peering-nat keep both rules). The capability is not lost, it moves: a
  # suppressed public tier still reaches Oracle services over the gateway's
  # public endpoint, TLS preserved; only the PRIVATE path for that tier is lost.
  #
  # Deliberately NOT a lifecycle.precondition - that would hard-fail every plan
  # selecting the all-services label, since `service = true` on an internet-
  # bearing table is a static fact of this catalogue. Suppression plus the
  # service_route_suppressed_route_tables output makes the loss visible in every
  # plan; when this local is empty by construction, a NON-empty value is the
  # signal someone has reintroduced a public service-bearing table.
  #############################################################################
  service_route_suppressed_route_tables = var.enable_service_gateway_all_services ? sort([
    for name, rt in local.route_tables : name
    if rt.internet && rt.service && var.create_internet_gateway
  ]) : []

  #############################################################################
  # Assembled route rules, per table
  #############################################################################
  route_table_rules = {
    for name, rt in local.route_tables : name => concat(
      rt.internet && var.create_internet_gateway ? [{
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.this[0].id
        description       = "Default route via the internet gateway"
      }] : [],
      rt.nat && var.enable_nat_gateway ? [{
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_nat_gateway.this[0].id
        description       = "Default route via the NAT gateway"
      }] : [],
      # Suppressed on internet-gateway-bearing tables under the all-services
      # label - see the igw/sgw conflict block above. Oracle rejects the pair at
      # create time with 400-InvalidParameter.
      rt.service && local.service_gateway_enabled && !contains(local.service_route_suppressed_route_tables, name) ? [{
        destination       = local.selected_service_cidr
        destination_type  = "SERVICE_CIDR_BLOCK"
        network_entity_id = oci_core_service_gateway.this[0].id
        description       = "Private route to Oracle services via the service gateway"
      }] : [],
      [
        for route in local.peering_routes : {
          destination       = route.destination
          destination_type  = "CIDR_BLOCK"
          network_entity_id = route.entity_id
          description       = route.description
        } if route.route_table == name
      ]
    )
  }
}
