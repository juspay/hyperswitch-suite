mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{ name = "test:AD-1", ad_number = 1 }]
    }
  }
  mock_data "oci_identity_fault_domains" {
    defaults = {
      fault_domains = [{ name = "FAULT-DOMAIN-1" }]
    }
  }
  mock_data "oci_core_vcn" {
    defaults = { cidr_blocks = ["10.0.0.0/16"] }
  }
  mock_data "oci_core_services" {
    defaults = {
      services = [{ id = "ocid1.service.mock.osn", cidr_block = "all-test-services-in-oracle-services-network" }]
    }
  }
}

mock_provider "cloudinit" {}
mock_provider "helm" {}
mock_provider "http" {}
mock_provider "null" {}
mock_provider "random" {}
mock_provider "time" {}
mock_provider "tls" {}

override_resource {
  target          = module.oke.module.network.oci_core_network_security_group.pods[0]
  override_during = plan
  values          = { id = "ocid1.networksecuritygroup.mock.baseline-pods" }
}

override_resource {
  target          = module.oke.module.network.oci_core_network_security_group.workers[0]
  override_during = plan
  values          = { id = "ocid1.networksecuritygroup.mock.baseline-workers" }
}

variables {
  project_name              = "test"
  environment               = "dev"
  region                    = "ap-mumbai-1"
  compartment_id            = "ocid1.compartment.mock.test"
  tenancy_id                = "ocid1.tenancy.mock.test"
  vcn_id                    = "ocid1.vcn.mock.test"
  control_plane_subnet_id   = "ocid1.subnet.mock.cp"
  worker_subnet_id          = "ocid1.subnet.mock.workers"
  pod_subnet_id             = "ocid1.subnet.mock.pods"
  internal_lb_subnet_id     = "ocid1.subnet.mock.lb"
  additional_worker_nsg_ids = ["ocid1.networksecuritygroup.mock.shared-workers"]
  additional_pod_nsg_ids    = ["ocid1.networksecuritygroup.mock.shared-pods"]
  node_pools = {
    card-vault = {
      size        = 1
      image_type  = "custom"
      image_id    = "ocid1.image.mock.worker"
      nsg_ids     = ["ocid1.networksecuritygroup.mock.card-vault"]
      pod_nsg_ids = ["ocid1.networksecuritygroup.mock.card-vault"]
    }
    autoscaled = {
      size              = 2
      enable_autoscaler = true
      min_size          = 2
      max_size          = 3
      image_type        = "custom"
      image_id          = "ocid1.image.mock.worker"
      nsg_ids           = ["ocid1.networksecuritygroup.mock.autoscaled"]
      pod_nsg_ids       = ["ocid1.networksecuritygroup.mock.autoscaled"]
    }
    systems = {
      size       = 1
      image_type = "custom"
      image_id   = "ocid1.image.mock.worker"
    }
  }
}

run "pool_nsgs_are_additive" {
  command = plan

  assert {
    condition     = length(oci_core_network_security_group.workers) == 0 && length(oci_core_network_security_group.pods) == 0 && length(output.node_pool_nsg_ids) == 0
    error_message = "Pools must not create dedicated groups unless explicitly opted in."
  }

  assert {
    condition     = toset(local.worker_pools["card-vault"].nsg_ids) == toset(["ocid1.networksecuritygroup.mock.card-vault"])
    error_message = "The worker addition must reach the registry module's additive input."
  }
  assert {
    condition = toset(local.worker_pools["card-vault"].pod_nsg_ids) == toset([
      "ocid1.networksecuritygroup.mock.baseline-pods",
      "ocid1.networksecuritygroup.mock.shared-pods",
      "ocid1.networksecuritygroup.mock.card-vault",
    ])
    error_message = "Dedicated pods must retain baseline and shared NSGs."
  }
  assert {
    condition = toset(local.worker_pools["autoscaled"].pod_nsg_ids) == toset([
      "ocid1.networksecuritygroup.mock.baseline-pods",
      "ocid1.networksecuritygroup.mock.shared-pods",
      "ocid1.networksecuritygroup.mock.autoscaled",
    ])
    error_message = "Autoscaled pools must receive the same additive pod NSG handling."
  }
  assert {
    condition     = length(local.worker_pools["systems"].nsg_ids) == 0 && !contains(keys(local.worker_pools["systems"]), "pod_nsg_ids")
    error_message = "Empty additions must preserve the registry defaults."
  }
}

run "flannel_rejects_pod_nsgs" {
  command = plan
  variables {
    cni_type = "flannel"
  }
  expect_failures = [terraform_data.validate]
}

run "dedicated_pool_nsgs" {
  command = plan

  variables {
    node_pools = {
      dedicated = {
        size        = 1
        image_type  = "custom"
        image_id    = "ocid1.image.mock.worker"
        create_nsg  = true
        nsg_ids     = ["ocid1.networksecuritygroup.mock.caller-workers"]
        pod_nsg_ids = ["ocid1.networksecuritygroup.mock.caller-pods"]
      }
      autoscaled = {
        size              = 2
        image_type        = "custom"
        image_id          = "ocid1.image.mock.worker"
        create_nsg        = true
        enable_autoscaler = true
        min_size          = 1
        max_size          = 3
      }
      systems = {
        size       = 1
        image_type = "custom"
        image_id   = "ocid1.image.mock.worker"
        create_nsg = false
      }
    }
  }

  override_resource {
    target          = oci_core_network_security_group.workers["dedicated"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.owned-workers" }
  }
  override_resource {
    target          = oci_core_network_security_group.pods["dedicated"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.owned-pods" }
  }
  override_resource {
    target          = oci_core_network_security_group.workers["autoscaled"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.autoscaled-workers" }
  }
  override_resource {
    target          = oci_core_network_security_group.pods["autoscaled"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.autoscaled-pods" }
  }

  assert {
    condition     = toset(keys(oci_core_network_security_group.workers)) == toset(["dedicated", "autoscaled"]) && toset(keys(oci_core_network_security_group.pods)) == toset(["dedicated", "autoscaled"])
    error_message = "Only opted-in pools must own one worker and one pod group each."
  }
  assert {
    condition = alltrue([for name in ["dedicated", "autoscaled"] :
      oci_core_network_security_group.workers[name].compartment_id == var.compartment_id &&
      oci_core_network_security_group.pods[name].compartment_id == var.compartment_id &&
      oci_core_network_security_group.workers[name].vcn_id == var.vcn_id &&
      oci_core_network_security_group.pods[name].vcn_id == var.vcn_id &&
      oci_core_network_security_group.workers[name].display_name == "test-dev-oke-${name}-workers-nsg" &&
      oci_core_network_security_group.pods[name].display_name == "test-dev-oke-${name}-pods-nsg" &&
      oci_core_network_security_group.pods[name].freeform_tags == tomap(local.common_freeform_tags) &&
      output.node_pool_nsg_ids[name].worker_nsg_id == oci_core_network_security_group.workers[name].id &&
      output.node_pool_nsg_ids[name].pod_nsg_id == oci_core_network_security_group.pods[name].id
    ]) && toset(keys(output.node_pool_nsg_ids)) == toset(["dedicated", "autoscaled"])
    error_message = "Owned groups must preserve placement, names, tags and the per-pool output contract."
  }
  assert {
    condition = toset(local.worker_pools["dedicated"].nsg_ids) == toset([
      "ocid1.networksecuritygroup.mock.caller-workers", "ocid1.networksecuritygroup.mock.owned-workers"
      ]) && toset(local.worker_pools["dedicated"].pod_nsg_ids) == toset([
      "ocid1.networksecuritygroup.mock.baseline-pods", "ocid1.networksecuritygroup.mock.shared-pods",
      "ocid1.networksecuritygroup.mock.caller-pods", "ocid1.networksecuritygroup.mock.owned-pods"
    ])
    error_message = "Dedicated groups must add to caller, shared and baseline groups."
  }
  assert {
    condition = toset(local.worker_pools["autoscaled"].pod_nsg_ids) == toset([
      "ocid1.networksecuritygroup.mock.baseline-pods", "ocid1.networksecuritygroup.mock.shared-pods",
      "ocid1.networksecuritygroup.mock.autoscaled-pods"
    ]) && local.worker_pools["autoscaled"].ignore_initial_pool_size && length(local.worker_pools["systems"].nsg_ids) == 0 && !contains(keys(local.worker_pools["systems"]), "pod_nsg_ids")
    error_message = "Autoscaled pools must attach owned groups and unrelated pools must retain upstream defaults."
  }
}

run "flannel_rejects_owned_groups" {
  command = plan
  variables {
    cni_type = "flannel"
    node_pools = {
      dedicated = { size = 1, image_type = "custom", image_id = "ocid1.image.mock.worker", create_nsg = true }
    }
  }
  expect_failures = [terraform_data.validate]
}

run "worker_vnic_cap" {
  command = plan
  variables {
    additional_worker_nsg_ids = ["ocid1.networksecuritygroup.mock.one", "ocid1.networksecuritygroup.mock.two", "ocid1.networksecuritygroup.mock.three", "ocid1.networksecuritygroup.mock.four", "ocid1.networksecuritygroup.mock.five"]
  }
  expect_failures = [terraform_data.validate]
}

run "pod_vnic_cap" {
  command = plan
  variables {
    additional_pod_nsg_ids = ["ocid1.networksecuritygroup.mock.one", "ocid1.networksecuritygroup.mock.two", "ocid1.networksecuritygroup.mock.three", "ocid1.networksecuritygroup.mock.four", "ocid1.networksecuritygroup.mock.five"]
  }
  expect_failures = [terraform_data.validate]
}

run "effective_nsg_cap_deduplicates" {
  command = plan
  variables {
    nsg_ids = {
      workers = "ocid1.networksecuritygroup.mock.shared-workers"
      pods    = "ocid1.networksecuritygroup.mock.shared-pods"
    }
    additional_worker_nsg_ids = ["ocid1.networksecuritygroup.mock.shared-workers", "ocid1.networksecuritygroup.mock.shared-workers", "ocid1.networksecuritygroup.mock.shared-workers", "ocid1.networksecuritygroup.mock.shared-workers", "ocid1.networksecuritygroup.mock.shared-workers"]
    additional_pod_nsg_ids    = ["ocid1.networksecuritygroup.mock.shared-pods", "ocid1.networksecuritygroup.mock.shared-pods", "ocid1.networksecuritygroup.mock.shared-pods", "ocid1.networksecuritygroup.mock.shared-pods", "ocid1.networksecuritygroup.mock.shared-pods"]
  }
  assert {
    condition     = contains(local.worker_pools["card-vault"].pod_nsg_ids, "ocid1.networksecuritygroup.mock.shared-pods")
    error_message = "Caller-owned baselines must survive and duplicate IDs must not exhaust the VNIC cap."
  }
}

run "owned_worker_group_counts_toward_cap" {
  command = plan
  variables {
    additional_worker_nsg_ids = ["ocid1.networksecuritygroup.mock.one", "ocid1.networksecuritygroup.mock.two", "ocid1.networksecuritygroup.mock.three", "ocid1.networksecuritygroup.mock.four"]
    node_pools = {
      dedicated = { size = 1, image_type = "custom", image_id = "ocid1.image.mock.worker", create_nsg = true }
    }
  }
  override_resource {
    target          = oci_core_network_security_group.workers["dedicated"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.owned-workers" }
  }
  expect_failures = [terraform_data.validate]
}

run "owned_pod_group_counts_toward_cap" {
  command = plan
  variables {
    additional_pod_nsg_ids = ["ocid1.networksecuritygroup.mock.one", "ocid1.networksecuritygroup.mock.two", "ocid1.networksecuritygroup.mock.three", "ocid1.networksecuritygroup.mock.four"]
    node_pools = {
      dedicated = { size = 1, image_type = "custom", image_id = "ocid1.image.mock.worker", create_nsg = true }
    }
  }
  override_resource {
    target          = oci_core_network_security_group.pods["dedicated"]
    override_during = plan
    values          = { id = "ocid1.networksecuritygroup.mock.owned-pods" }
  }
  expect_failures = [terraform_data.validate]
}

run "empty_pools" {
  command = plan
  variables {
    node_pools = {}
  }
  assert {
    condition     = length(output.node_pool_nsg_ids) == 0 && length(oci_core_network_security_group.workers) == 0 && length(oci_core_network_security_group.pods) == 0
    error_message = "No pools must create no dedicated groups."
  }
}

run "flannel_without_pod_additions" {
  command = plan
  variables {
    cni_type = "flannel"
    node_pools = {
      systems = { size = 1, image_type = "custom", image_id = "ocid1.image.mock.worker" }
    }
  }
  assert {
    condition     = length(output.node_pool_nsg_ids) == 0 && !contains(keys(local.worker_pools["systems"]), "pod_nsg_ids")
    error_message = "Existing Flannel pools without paired NSGs must remain supported."
  }
}
