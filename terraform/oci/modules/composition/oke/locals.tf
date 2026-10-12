# =============================================================================
# oke - derived configuration
# =============================================================================

locals {
  cluster_name = coalesce(var.cluster_name, format("%s-%s-oke", var.project_name, var.environment))

  # ---------------------------------------------------------------------------
  # Fault domains - resolved live, never spelled out
  # ---------------------------------------------------------------------------
  # See data.tf for why these are looked up and why the intersection (rather
  # than one AD's set) is the correct list for a managed OKE node pool.
  #
  # `values(...)...` expands the per-AD sets into setintersection's arguments.
  # A region always publishes at least one AD, so the expansion is never empty;
  # terraform_data.validate asserts the resolved list is non-empty anyway,
  # because an empty list here would silently become "OKE chooses" rather than
  # an error.
  fault_domain_names_by_ad = {
    for ad_name, fds in data.oci_identity_fault_domains.this :
    ad_name => toset([for fd in fds.fault_domains : fd.name])
  }

  region_fault_domains = sort(tolist(
    setintersection(values(local.fault_domain_names_by_ad)...)
  ))

  # Per pool: the caller's explicit pin, or every fault domain the region has.
  # An empty per-pool list is the "spread across all" default, matching
  # kafka/cassandra/clickhouse's var.fault_domains contract exactly.
  node_pool_fault_domains = {
    for name, pool in var.node_pools :
    name => length(pool.fault_domains) > 0 ? pool.fault_domains : local.region_fault_domains
  }

  common_freeform_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "oke"
    },
    var.freeform_tags,
  )

  # With VCN-native pod networking every pod takes an address from a real
  # subnet. Falling back to the worker subnet is legal and is the registry
  # module's own default, but it means the worker tier must be sized for
  # nodes + (nodes x max_pods_per_node). See the pod_subnet_id variable.
  pod_subnet_id = var.cni_type == "npn" ? coalesce(var.pod_subnet_id, var.worker_subnet_id) : null

  # OKE records one default service-LB subnet on the cluster; individual
  # Services override it with the oci.oraclecloud.com/load-balancer-subnet
  # annotation. There is no AWS-style subnet-tag discovery (vpc-network.md 4.7).
  load_balancers = (
    var.public_lb_subnet_id != null && var.internal_lb_subnet_id != null ? "both" :
    var.public_lb_subnet_id != null ? "public" : "internal"
  )

  # ---------------------------------------------------------------------------
  # Subnets handed to the registry module.
  #
  # Every entry is `create = "never"` plus an OCID, or `create = "never"` with
  # nothing. Nothing here is ever created: composition/vpc-network owns the CIDR
  # plan, the route tables and the emptied default security list. `bastion` and
  # `operator` are absent because their components are switched off in main.tf;
  # `fss` is absent because the key's mere presence is what enables the File
  # Storage subnet in the registry module.
  # ---------------------------------------------------------------------------
  subnets = merge(
    {
      cp      = { create = "never", id = var.control_plane_subnet_id }
      workers = { create = "never", id = var.worker_subnet_id }
    },
    var.cni_type == "npn" ? { pods = { create = "never", id = local.pod_subnet_id } } : {},
    var.internal_lb_subnet_id != null ? { int_lb = { create = "never", id = var.internal_lb_subnet_id } } : {},
    var.public_lb_subnet_id != null ? { pub_lb = { create = "never", id = var.public_lb_subnet_id } } : {},
  )

  # ---------------------------------------------------------------------------
  # NSGs handed to the registry module.
  #
  # A role present in var.nsg_ids is attached by OCID and nothing is created for
  # it - and, importantly, no baseline rules are written into it either, so the
  # caller then owns the full OKE rule set for that role. A role absent from
  # var.nsg_ids is created here with Oracle's own baseline. `security-rules`
  # (phase 5) adds cross-module rules to whichever NSG ends up in place; on OCI
  # an NSG rule is a standalone resource, so the two states do not contend.
  # ---------------------------------------------------------------------------
  nsg_roles = compact([
    "cp",
    "workers",
    var.cni_type == "npn" ? "pods" : "",
    var.internal_lb_subnet_id != null ? "int_lb" : "",
    var.public_lb_subnet_id != null ? "pub_lb" : "",
  ])

  nsgs = merge(
    { for role in local.nsg_roles : role => (
      contains(keys(var.nsg_ids), role)
      ? { create = "never", id = var.nsg_ids[role] }
      : { create = "always" }
    ) },
    # Components that do not exist in this deployment.
    { bastion = { create = "never" }, operator = { create = "never" } },
  )

  # ---------------------------------------------------------------------------
  # Node pools -> the registry module's `worker_pools` shape.
  #
  # `ignore_initial_pool_size = true` routes the pool to the registry module's
  # `autoscaled_workers` resource, which carries
  # `lifecycle { ignore_changes = [node_config_details[0].size] }`. That is the
  # OCI analogue of the AWS module's
  # `ignore_changes = [scaling_config[0].desired_size]` and is what stops
  # Terraform reverting the autoscaler's own scaling decisions - Oracle warns
  # about exactly this ("Terraform might revert changes to the size of a node
  # pool made by the Kubernetes Cluster Autoscaler").
  #
  # It does NOT create a floor or a ceiling. There is none to create - see the
  # node_pools variable's block comment and eks.md gap 4.5.
  # ---------------------------------------------------------------------------
  worker_pools = {
    for name, pool in var.node_pools : name => {
      create = true
      mode   = "node-pool"

      shape  = pool.shape
      ocpus  = pool.ocpus
      memory = pool.memory_in_gbs

      size                     = pool.size
      allow_autoscaler         = pool.enable_autoscaler
      ignore_initial_pool_size = pool.enable_autoscaler

      boot_volume_size = pool.boot_volume_size_in_gbs
      image_type       = pool.image_type
      image_id         = pool.image_id

      # One availability domain in ap-mumbai-1, so the only in-region spread
      # available is across fault domains within it.
      #
      # REAL NAMES ONLY. The registry module passes this straight through to
      # `oci_containerengine_node_pool.node_config_details.placement_configs
      # [].fault_domains` with no translation
      # (`modules/workers/nodepools.tf`: `fault_domains =
      # try(each.value.placement_fds, null)`), so anything that is not a live
      # `oci_identity_fault_domains[*].name` is a 400 at apply time.
      placement_fds = local.node_pool_fault_domains[name]

      node_labels       = pool.node_labels
      max_pods_per_node = pool.max_pods_per_node
      subnet_id         = coalesce(pool.subnet_id, var.worker_subnet_id)
      nsg_ids           = pool.nsg_ids
      cloud_init        = pool.cloud_init

      kubernetes_version = coalesce(pool.kubernetes_version, var.kubernetes_version)
      volume_kms_key_id  = pool.volume_kms_key_id != null ? pool.volume_kms_key_id : var.worker_volume_kms_key_id

      freeform_tags = local.common_freeform_tags
    }
  }

  # Advisory bounds, exported for whichever autoscaler ends up enforcing them.
  # Nothing in this module or in OCI enforces them. See eks.md gap 4.5.
  autoscaler_bounds = {
    for name, pool in var.node_pools : name => {
      min_size = pool.min_size
      max_size = pool.max_size
    } if pool.enable_autoscaler
  }

  ssh_public_key = var.create_ssh_key ? trimspace(tls_private_key.node_pool[0].public_key_openssh) : var.ssh_public_key
}
