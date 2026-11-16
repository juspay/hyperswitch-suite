mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        { name = "test:AD-2", id = "ocid1.availabilitydomain.oc1.phx.ad2" },
        { name = "test:AD-3", id = "ocid1.availabilitydomain.oc1.phx.ad3" },
        { name = "test:AD-1", id = "ocid1.availabilitydomain.oc1.phx.ad1" },
      ]
    }
  }

  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock_namespace" }
  }
}

mock_provider "oci" {
  alias = "home"

  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        { name = "test:AD-2", id = "ocid1.availabilitydomain.oc1.phx.ad2" },
        { name = "test:AD-3", id = "ocid1.availabilitydomain.oc1.phx.ad3" },
        { name = "test:AD-1", id = "ocid1.availabilitydomain.oc1.phx.ad1" },
      ]
    }
  }

  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock_namespace" }
  }
}

mock_provider "tls" {}

variables {
  environment          = "sandbox"
  project_name         = "hyperswitch"
  region               = "us-phoenix-1"
  compartment_id       = "ocid1.compartment.oc1..mock"
  tenancy_ocid         = "ocid1.tenancy.oc1..mock"
  image_id             = "ocid1.image.oc1.phx.mock"
  vcn_id               = "ocid1.vcn.oc1.phx.mock"
  subnet_id            = "ocid1.subnet.oc1.phx.mock"
  create_lb            = false
  create_nsg           = false
  create_config_bucket = false
  create_logs_bucket   = false
  generate_ssh_key     = false
  enable_autoscaling   = false
}

run "two_deployments_use_two_distinct_sorted_availability_domains" {
  command = plan

  variables {
    deployments = {
      phx-a = {
        weight                    = 50
        min_replicas              = 1
        max_replicas              = 1
        availability_domain_index = 0
      }
      phx-b = {
        weight                    = 50
        min_replicas              = 1
        max_replicas              = 1
        availability_domain_index = 1
      }
    }
  }

  assert {
    condition = toset([
      for pool in oci_core_instance_pool.this : pool.placement_configurations[0].availability_domain
    ]) == toset(["test:AD-1", "test:AD-2"])
    error_message = "The two pools must be placed in the first two sorted ADs, not the data-source order."
  }

  assert {
    condition = alltrue([
      for key in keys(var.deployments) :
      oci_core_instance_configuration.this[key].instance_details[0].launch_details[0].availability_domain == oci_core_instance_pool.this[key].placement_configurations[0].availability_domain
    ])
    error_message = "Pool and launch-template placement must agree."
  }

  assert {
    condition = output.deployment_availability_domains == {
      phx-a = "test:AD-1"
      phx-b = "test:AD-2"
    }
    error_message = "The effective placement of every deployment must be observable."
  }

  assert {
    condition     = length(oci_autoscaling_auto_scaling_configuration.this) == 0
    error_message = "Two fixed deployment entries must not create an autoscaler."
  }
}

run "legacy_deployment_keeps_first_reported_availability_domain" {
  command = plan

  variables {
    deployments = { stable = { weight = 100 } }
  }

  assert {
    condition     = oci_core_instance_pool.this["stable"].placement_configurations[0].availability_domain == "test:AD-2"
    error_message = "Legacy callers must retain the original first data-source AD selection."
  }

  assert {
    condition     = output.deployment_availability_domains == { stable = "test:AD-2" }
    error_message = "The placement output must include legacy deployments."
  }
}

run "reject_out_of_range_availability_domain_index" {
  command = plan

  variables {
    deployments = {
      stable = {
        weight                    = 100
        availability_domain_index = 3
      }
    }
  }

  expect_failures = [var.deployments]
}

run "reject_duplicate_explicit_availability_domain_indices" {
  command = plan

  variables {
    deployments = {
      phx-a = {
        weight                    = 50
        availability_domain_index = 1
      }
      phx-b = {
        weight                    = 50
        availability_domain_index = 1
      }
    }
  }

  expect_failures = [var.deployments]
}
