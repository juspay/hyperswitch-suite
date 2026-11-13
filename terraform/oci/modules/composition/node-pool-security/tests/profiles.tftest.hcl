mock_provider "oci" {
  override_during = plan
}

variables {
  compartment_id = "ocid1.compartment.oc1..mock"
  vcn_id         = "ocid1.vcn.oc1.phx.mock"
  environment    = "prd"
  profiles       = ["card-vault", "ordinary"]
}

run "multiple_profiles" {
  command = apply

  assert {
    condition     = length(oci_core_network_security_group.workers) == 2 && length(oci_core_network_security_group.pods) == 2
    error_message = "Each profile must have exactly one worker and one pod NSG."
  }

  assert {
    condition     = oci_core_network_security_group.workers["card-vault"].display_name == "hyperswitch-prd-oke-card-vault-workers-nsg" && oci_core_network_security_group.pods["card-vault"].display_name == "hyperswitch-prd-oke-card-vault-pods-nsg"
    error_message = "Naming must preserve the project, environment, and profile."
  }

  assert {
    condition = alltrue([for profile in var.profiles :
      oci_core_network_security_group.workers[profile].compartment_id == var.compartment_id &&
      oci_core_network_security_group.pods[profile].vcn_id == var.vcn_id &&
      output.profiles[profile].worker_nsg_id == oci_core_network_security_group.workers[profile].id &&
      output.profiles[profile].pod_nsg_id == oci_core_network_security_group.pods[profile].id &&
      output.profiles[profile].worker_nsg_id != output.profiles[profile].pod_nsg_id
    ])
    error_message = "Placement and output identity must match each profile's separate groups."
  }

  assert {
    condition     = toset(keys(output.profiles)) == var.profiles && oci_core_network_security_group.workers["ordinary"].freeform_tags == tomap({ environment = "prd", project = "hyperswitch", component = "node-pool-security", managed_by = "terraform" })
    error_message = "Output keys and standard tags must match the profiles."
  }
}

run "empty_profiles" {
  command = plan
  variables {
    profiles = []
  }
  assert {
    condition     = length(oci_core_network_security_group.workers) == 0 && length(oci_core_network_security_group.pods) == 0 && length(output.profiles) == 0
    error_message = "An empty set must create nothing."
  }
}

run "generic_names_and_tag_overrides" {
  command = plan
  variables {
    environment  = "dev"
    project_name = "example"
    profiles     = ["ordinary", "ordinary"]
    freeform_tags = {
      owner     = "platform"
      component = "custom"
    }
  }
  assert {
    condition     = length(output.profiles) == 1 && oci_core_network_security_group.workers["ordinary"].display_name == "example-dev-oke-ordinary-workers-nsg" && oci_core_network_security_group.pods["ordinary"].display_name == "example-dev-oke-ordinary-pods-nsg"
    error_message = "Profiles must deduplicate and support generic identifiers."
  }
  assert {
    condition     = oci_core_network_security_group.pods["ordinary"].freeform_tags["owner"] == "platform" && oci_core_network_security_group.pods["ordinary"].freeform_tags["component"] == "custom" && oci_core_network_security_group.pods["ordinary"].freeform_tags["managed_by"] == "terraform"
    error_message = "Caller tags must override defaults without dropping other tags."
  }
}

run "empty_name_rejected" {
  command = plan
  variables {
    profiles = [""]
  }
  expect_failures = [var.profiles]
}

run "blank_name_rejected" {
  command = plan
  variables {
    profiles = [" \t\n"]
  }
  expect_failures = [var.profiles]
}

run "null_name_rejected" {
  command = plan
  variables {
    profiles = [null]
  }
  expect_failures = [var.profiles]
}
