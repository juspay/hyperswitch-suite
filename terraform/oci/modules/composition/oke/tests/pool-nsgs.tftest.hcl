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
