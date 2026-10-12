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
  # Named subnet tiers
  #
  # 13 tiers, one REGIONAL subnet each - availability_domain is deliberately
  # never set (check sheet feature 8 / section 4.2). AWS builds every tier once
  # per AZ (26 subnets); ap-mumbai-1 has one availability domain and Oracle
  # recommends regional subnets, so per-AZ fan-out has nothing to fan out over.
  #
  # prohibit_public_ip_on_vnic is STRONGER than AWS's map_public_ip_on_launch:
  # AWS only changes the default and an EIP can still be attached, whereas this
  # forbids a public IP on any VNIC in the subnet outright. It is therefore
  # true on TWELVE of the thirteen tiers - every one except external-incoming,
  # which holds public load balancers and is genuinely internet-facing.
  # prohibit_internet_ingress is never set alongside it - the provider states
  # "Only one or the other flag should be specified".
  #
  # CORRECTION C7 (2026-09-04, oracle gate). `management` used to be the second
  # public tier, on an internet-gateway route table, because the AWS module
  # labels its management_subnets "Public - for Bastion with Elastic IP". That
  # label was ported without checking whether anything consumed it, and nothing
  # does:
  #   - AWS's real jump host is NOT in management. terraform/catalog/units/
  #     jump-host reads utils_subnet_ids[0], and AWS associates the utils tier
  #     with CommonLocalS3 - a private-isolated table with no internet route.
  #     AWS's management_subnet_ids output has zero consumers in the whole
  #     catalog.
  #   - This port's bastion is the MANAGED OCI Bastion service, not a public
  #     jump box. bastion-host's assign_public_ip defaults false and its own
  #     variable description says it "should stay false"; the OCI bastion-host
  #     unit sets it false explicitly. The Bastion service reaches the instance
  #     through a private endpoint VNIC it places in this subnet, so a public
  #     IP is never used.
  # So `management` is now private (prohibit_public_ip_on_vnic = true) on
  # common-local-osn, which is the exact analogue of AWS's CommonLocalS3 that
  # AWS's actual jump host sits on. This is the change that genuinely resolves
  # the C6 route-rule conflict - see the igw/sgw block near the bottom of this
  # file. Anything that later needs a reachable public host belongs in
  # external-incoming or behind the load balancer, not here.
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
    # 2026-09-06: reverted back to always-private, static (see the real, live
    # finding on oke_api_endpoint_is_public below for why this cannot itself
    # flip). This subnet's identity is stable for the life of the
    # environment; the public path is a SEPARATE, additive subnet instead.
    oke-api-endpoint = {
      cidr                       = var.oke_api_endpoint_subnet_cidr
      prohibit_public_ip_on_vnic = true
      route_table                = "oke-api-endpoint"
      dns_label                  = "okeapi"
      description                = "Private OKE Kubernetes API endpoint VNIC; the control plane itself is Oracle-managed and outside the VCN"
    }

    # 2026-09-06 (real, live finding, C33): this CANNOT be the same subnet
    # toggled public/private in place. `prohibit_public_ip_on_vnic` is
    # ForceNew on `oci_core_subnet` - flipping it destroys and recreates the
    # subnet - and OCI refuses that destroy outright while the OKE cluster's
    # OWN Oracle-managed Service VNIC still lives in it (confirmed live: a
    # `terraform apply` hung for 3+ minutes calling DeleteSubnet in a silent
    # retry loop against a subnet that never left AVAILABLE, while
    # `oci network private-ip list` on that subnet showed a real, live
    # "Service VNIC for cluster <ocid>" still attached). That VNIC only
    # detaches once the CLUSTER's own endpoint_config is repointed elsewhere
    # - which requires a subnet to repoint it TO already existing. Recreating
    # the SAME subnet the cluster is actively using is a genuine ordering
    # deadlock, not a sequencing mistake to fix by reordering applies.
    #
    # Fix: a second, always-additive subnet, created only when
    # oke_api_endpoint_is_public = true (a tier with a null CIDR is simply
    # not created - see all_subnets below). The `oke` unit's
    # control_plane_subnet_id picks between this and the private subnet
    # above based on the same toggle. `oci_containerengine_cluster.
    # endpoint_config.subnet_id` is NOT ForceNew (already proven live: this
    # port's own C-numbered history shows `is_public_ip_enabled` updating
    # in-place via UpdateClusterEndpointConfig with 0 destroy), so pointing
    # the cluster at a different, already-existing subnet is a normal,
    # in-place, non-destructive change - unlike recreating the one it is
    # already using.
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
  # VERIFIED DIVERGENCE from the check sheet section 4.3, which says to "enable
  # both service CIDR labels on the single service gateway". Oracle forbids it:
  # "Because Object Storage is covered by both OCI <region> Object Storage and
  # All <region> Services in Oracle Services Network, a service gateway can use
  # only one of those service CIDR labels. Likewise, a route table can have a
  # single rule for one of the service CIDR labels."
  # (docs.oracle.com .../Network/Tasks/servicegateway.htm)
  #
  # So the two booleans are mutually exclusive and there is exactly ONE service
  # CIDR to route to. Consequence, worse than section 4.3 states: a route table
  # cannot grant Object-Storage-only access while another grants full OSN
  # access - the choice is VCN-wide. Per-tier denial is still available by
  # omitting the service route from that tier's route table, which remains the
  # strongest control OCI offers here.
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

  # Exported as object_storage_service_cidr for contract compatibility. When
  # the all-services label is in use this CIDR is the OSN superset, which
  # includes Object Storage - consumers writing NSG egress rules to
  # SERVICE_CIDR_BLOCK need this value either way.
  object_storage_service_cidr = try(local.object_storage_services[0].cidr_block, null)

  #############################################################################
  # Route-table catalogue
  #
  # 12 named, shared route tables carrying the egress policy, associated to
  # tiers rather than one table per subnet - the AWS design, ported. Names are
  # OCI-cased equivalents of the AWS ones (CommonInternet -> common-internet,
  # EKSWorker -> oke-nodes, ...). The AWS S3-gateway-endpoint route becomes the
  # service-gateway route; "osn" in a name means "carries a service route".
  #
  # AWS's ProxyPeeringNAT-A/B/C collapse into ONE proxy-peering-nat table: the
  # OCI NAT gateway is regional and limited to 1 per VCN (section 4.1), so
  # there is nothing per-AZ to point three tables at.
  #
  # PCI control, ported unchanged (feature 12): the oke-nodes table has NO
  # 0.0.0.0/0 rule of any kind. OKE workers reach Oracle services over the
  # service gateway and everything else through the Squid proxy in
  # outgoing-proxy, which is the only tier on a NAT-bearing table.
  #############################################################################
  route_tables = {
    common-internet = {
      internet    = true
      nat         = false
      service     = false
      description = "Public tier: default route via the internet gateway"
    }
    # REMOVED in correction C7 (2026-09-04, oracle gate): common-internet-osn,
    # the 1:1 port of AWS's CommonInternetS3 (IGW default route + S3 GATEWAY
    # endpoint route). Its only tier was `management`, which is now private and
    # on common-local-osn, and under the all-services label its service rule was
    # suppressed anyway (C6), leaving it byte-identical to common-internet
    # above. A route table with no subnet, no distinct rule set and no consumer
    # is not a divergence worth keeping - re-add it deliberately, with a tier
    # attached, if the object-storage label is ever selected and a genuinely
    # public tier genuinely needs the private Object Storage path.
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

  # Named groups a peering entry may target instead of listing tables, ported
  # from the AWS module's route_tables = ["all" | "public" | ...] convention.
  # "eks-workers" is renamed "oke-nodes"; the AWS group names are otherwise
  # preserved so peering config migrates verbatim.
  route_table_groups = {
    all = keys(local.route_tables)
    # `public` is a one-element group since C7 dropped common-internet-osn. Kept
    # as a group rather than collapsed to the bare table name so peering config
    # written against the AWS group vocabulary still migrates verbatim.
    public           = ["common-internet"]
    private-nat      = ["common-local-nat-osn", "proxy-peering-nat"]
    private-isolated = ["common-local", "common-local-osn", "oke-api-endpoint"]
    database         = ["db", "cache", "locker-db", "locker-server-osn", "data-stack-osn"]
    oke-nodes        = ["oke-nodes"]
  }

  #############################################################################
  # Peer route expansion
  #
  # Same shape as the AWS module's peering_route_expanded /
  # accepter_peering_route_expanded, with two changes forced by OCI:
  #   - the requester/accepter split disappears (an LPG is symmetric), so one
  #     pass covers both sides;
  #   - a cross-region route's network_entity_id is the DRG, not the remote
  #     peering connection - the RPC is the session, the DRG is the target.
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
  # Internet gateway / service gateway route-rule conflict - GUARDRAIL, not a
  # live workaround
  #
  # READ THIS FIRST. As of correction C7 this suppression fires for NOTHING:
  # after `management` was made private and common-internet-osn was dropped from
  # the catalogue, no table in this module carries both `internet = true` and
  # `service = true`, so service_route_suppressed_route_tables evaluates to []
  # in every plan. It is deliberately KEPT rather than reverted, because the
  # Oracle rule below is permanent and the catalogue is not: the next table that
  # sets both flags - via var.custom_subnets pointing at a new public tier, or a
  # future catalogue entry - would otherwise fail at apply time exactly as the
  # first live apply did. The suppression turns that from an apply-time
  # 400 into a visible, non-fatal, planned-and-reported omission.
  #
  # VERIFIED DIVERGENCE, found by a real apply and not by plan or validate.
  # The first live apply of this module into dev/ap-mumbai-1 created 12 of the
  # 13 route tables and then failed on the 13th with:
  #
  #   Error: 400-InvalidParameter, Internet Gateway target cannot be used
  #   together with Service Gateway target for All Services in the same
  #   routing table
  #
  # This is an API-side semantic rule. `terraform validate` cannot see it and
  # `terraform plan` cannot see it - the rule is enforced on create, so only an
  # apply hits it. It is DISTINCT from the mutually-exclusive-labels rule
  # documented on the service_gateway resource in gateways.tf: that one is about
  # which label the GATEWAY carries, this one is about which rules may coexist
  # in one ROUTE TABLE.
  #
  # Oracle, verbatim (docs.oracle.com/en-us/iaas/Content/Network/Reference/
  # known_issues_for_networking.htm, "Issues with access to your public
  # instances from Oracle services through a service gateway"):
  #
  #   "If the route table associated with your public subnet in a VCN includes
  #    the following two conflicting route rules, Oracle services might be
  #    unable to access your public instances in that subnet.
  #      1. Route rule with the Target Type set as internet gateway.
  #      2. Route rule with the Destination Service set as All <region>
  #         Services in Oracle Services Network and the Target Type set as
  #         service gateway.
  #    The foregoing two route rules can lead to asymmetric routing when Oracle
  #    services initiate connections to public instances in your VCN. Oracle
  #    Cloud Infrastructure does not support these rules simultaneously within
  #    the same route table. Oracle has updated the service APIs and the Console
  #    to disable support for this configuration."
  #
  # and its recommended workaround, which is what the suppression below
  # implements when it has anything to act on:
  #
  #   "We recommend that you remove the route rule that has the Destination
  #    Service set as All <region> Services in Oracle Services Network and the
  #    Target Type set as service gateway ... With this change, your public
  #    instances retain access to all Oracle services through the internet
  #    gateway ... This known issue applies only to public subnets that have
  #    access to an internet gateway. Regarding private subnets: you can still
  #    configure a private subnet's route table to provide access to All
  #    <region> Services in Oracle Services Network or to OCI <region> Object
  #    Storage through the VCN's service gateway."
  #
  # Three consequences worth stating plainly rather than burying:
  #
  #   1. The rule is LABEL-SPECIFIC. It bites only on the all-services label.
  #      Oracle's same workaround explicitly permits an `OCI <region> Object
  #      Storage` rule in a public route table, which is the exact analogue of
  #      the AWS S3 gateway-endpoint route CommonInternetS3 carried. So the
  #      suppression below is conditioned on
  #      var.enable_service_gateway_all_services, not applied unconditionally.
  #   2. It is NAT-safe. Only an INTERNET GATEWAY target conflicts. NAT gateway
  #      + all-services service gateway in one table is Oracle's own documented
  #      private-subnet pattern, so common-local-nat-osn and proxy-peering-nat
  #      are untouched and keep both rules.
  #   3. The capability is not lost, it moves. A public instance suppressed here
  #      still reaches every Oracle service - over the internet gateway, on the
  #      services' public endpoints, still TLS. What is lost is the PRIVATE path
  #      for that one tier. No tier is in that position today (C7), and feature
  #      12's PCI control on oke-nodes is untouched either way because that
  #      table has no internet route by construction.
  #
  # WHY THIS WAS NOT THE FIX. Suppression alone was the first response to the
  # failed apply, and the oracle gate rejected it as the resting state: it
  # preserved an internet-gateway route that served no instance (the only tier
  # on that table was a bastion tier that has never held a public IP, and whose
  # module documents that it should not) at the cost of the private
  # Oracle-services path that same tier actually wants. Retargeting the tier is
  # the fix; this block is the guardrail left behind it.
  #
  # Deliberately NOT implemented as a lifecycle.precondition. A precondition
  # would hard-fail every plan that selects the all-services label, since
  # `service = true` on an internet-bearing table is a static fact of this
  # module's catalogue rather than something an operator asked for. Suppression
  # plus the service_route_suppressed_route_tables output makes the loss visible
  # in every plan instead of silent - and, now that the local is empty by
  # construction, a NON-empty value in a plan is itself the signal that someone
  # has reintroduced a public service-bearing table.
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
