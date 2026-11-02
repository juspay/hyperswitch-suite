mock_provider "oci" {
  mock_resource "oci_psql_db_system" {
    defaults = {
      credentials = { password_details = { password = "" } }
    }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{ name = "test-ad" }]
    }
  }

  mock_data "oci_psql_shapes" {
    defaults = {
      shape_collection = [{ items = [{
        id          = "PostgreSQL.VM.Standard.E5.Flex"
        shape       = "VM.Standard.E5.Flex"
        is_flexible = true
      }] }]
    }
  }

  mock_data "oci_psql_default_configurations" {
    defaults = {
      default_configuration_collection = []
    }
  }
}

mock_provider "random" {}

variables {
  compartment_id        = "ocid1.compartment.oc1..test"
  environment           = "test"
  region                = "us-phoenix-1"
  subnet_id             = "ocid1.subnet.oc1.phx.test"
  create_nsg            = false
  is_regionally_durable = false
  pitr_restore_days     = 7
  enable_service_logs   = false
  vault_secret = {
    create         = false
    secret_id      = "ocid1.vaultsecret.oc1.phx.test"
    secret_version = 2
  }
}

run "external_secret_has_no_password_resources" {
  command = apply

  assert {
    condition     = length(random_password.admin) == 0 && length(oci_vault_secret.admin_password) == 0
    error_message = "External credentials must not create password-bearing resources."
  }

  assert {
    condition     = output.admin_password == null && output.vault_secret_id == var.vault_secret.secret_id
    error_message = "Only the external secret reference may be exported."
  }

  assert {
    condition     = oci_psql_db_system.this.credentials[0].password_details[0].password_type == "VAULT_SECRET" && oci_psql_db_system.this.credentials[0].password_details[0].password == "" && oci_psql_db_system.this.credentials[0].password_details[0].secret_version == "2"
    error_message = "Database credentials must contain only a pinned Vault reference."
  }
}

run "reject_external_and_created_secret" {
  command = plan

  variables {
    vault_secret = {
      create    = true
      secret_id = "ocid1.vaultsecret.oc1.phx.test"
      vault_id  = "ocid1.vault.oc1.phx.test"
      key_id    = "ocid1.key.oc1.phx.test"
    }
  }

  expect_failures = [var.vault_secret]
}
