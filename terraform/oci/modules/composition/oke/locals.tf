# oke - derived configuration.

locals {
  cluster_name = coalesce(var.cluster_name, format("%s-%s-oke", var.project_name, var.environment))

  # Fault domains, resolved live. `values(...)...` expands the per-AD sets into
  # setintersection's arguments; a region always publishes at least one AD.
  # terraform_data.validate asserts the result is non-empty, because an empty
  # list here would silently become "OKE chooses" rather than an error.
  fault_domain_names_by_ad = {
    for ad_name, fds in data.oci_identity_fault_domains.this :
    ad_name => toset([for fd in fds.fault_domains : fd.name])
  }

  region_fault_domains = sort(tolist(
    setintersection(values(local.fault_domain_names_by_ad)...)
  ))

  # An empty per-pool list is the "spread across all" default.
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
  # subnet; falling back to the worker subnet means sizing it for
  # nodes + (nodes x max_pods_per_node). See the pod_subnet_id variable.
  pod_subnet_id = var.cni_type == "npn" ? coalesce(var.pod_subnet_id, var.worker_subnet_id) : null

  # OKE records one default service-LB subnet; Services override it with the
  # oci.oraclecloud.com/load-balancer-subnet annotation.
  load_balancers = (
    var.public_lb_subnet_id != null && var.internal_lb_subnet_id != null ? "both" :
    var.public_lb_subnet_id != null ? "public" : "internal"
  )

  # Subnet OCIDs handed to the registry module. Every entry is
  # `create = "never"`: composition/vpc-network owns the CIDR plan.
  subnets = merge(
    {
      cp      = { create = "never", id = var.control_plane_subnet_id }
      workers = { create = "never", id = var.worker_subnet_id }
    },
    var.cni_type == "npn" ? { pods = { create = "never", id = local.pod_subnet_id } } : {},
    var.internal_lb_subnet_id != null ? { int_lb = { create = "never", id = var.internal_lb_subnet_id } } : {},
    var.public_lb_subnet_id != null ? { pub_lb = { create = "never", id = var.public_lb_subnet_id } } : {},
  )

  # NSG roles handed to the registry module. A role present in var.nsg_ids is
  # attached by OCID with no baseline rules written into it; a role absent is
  # created here with Oracle's own baseline.
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

  # `ignore_initial_pool_size = true` routes the pool to the registry module's
  # `autoscaled_workers` resource, which carries
  # `lifecycle { ignore_changes = [node_config_details[0].size] }` - the OCI
  # analogue of AWS's `ignore_changes = [scaling_config[0].desired_size]`, so
  # Terraform never reverts the autoscaler's own scaling decisions. It creates
  # no floor or ceiling - none exists (see the node_pools variable comment).
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

      # REAL NAMES ONLY: the registry module passes this straight through to
      # `oci_containerengine_node_pool.placement_configs[].fault_domains` with
      # no translation, so anything not a live `oci_identity_fault_domains`
      # name is a 400 at apply time.
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

  # Advisory bounds, exported for whichever autoscaler enforces them; nothing in
  # this module or in OCI enforces them.
  autoscaler_bounds = {
    for name, pool in var.node_pools : name => {
      min_size = pool.min_size
      max_size = pool.max_size
    } if pool.enable_autoscaler
  }

  ssh_public_key = var.create_ssh_key ? trimspace(tls_private_key.node_pool[0].public_key_openssh) : var.ssh_public_key
}
