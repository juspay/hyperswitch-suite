mock_provider "oci" {
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
  compartment_id  = "ocid1.compartment.oc1..test"
  environment     = "test"
  region          = "us-phoenix-1"
  cluster_ids     = ["ocid1.cluster.oc1.phx.test"]
  create_database = true
  database_config = {
    subnet_id             = "ocid1.subnet.oc1.phx.test-original"
    create_nsg            = false
    is_regionally_durable = false
    enable_service_logs   = false
    admin_username        = "test_admin"
    vault_secret = {
      create         = false
      secret_id      = "ocid1.vaultsecret.oc1.phx.test"
      secret_version = 2
    }
  }
}

run "default_without_backup" {
  command = plan

  assert {
    condition     = var.database_config.source_backup_id == null
    error_message = "An omitted backup source must default to null."
  }

  assert {
    condition     = output.database_created && output.database_vault_secret_id == var.database_config.vault_secret.secret_id && output.database_admin_username == var.database_config.admin_username
    error_message = "The nested database must preserve the external credential reference and admin username."
  }
}

run "supplied_backup" {
  command = plan

  variables {
    database_config = {
      source_backup_id      = "ocid1.postgresqlbackup.oc1.phx.test"
      subnet_id             = "ocid1.subnet.oc1.phx.test-requested"
      create_nsg            = false
      is_regionally_durable = false
      enable_service_logs   = false
      admin_username        = "test_admin"
      vault_secret = {
        create         = false
        secret_id      = "ocid1.vaultsecret.oc1.phx.test"
        secret_version = 2
      }
    }
  }

  assert {
    condition     = output.database_created && output.database_vault_secret_id == var.database_config.vault_secret.secret_id && output.database_admin_username == var.database_config.admin_username
    error_message = "A backup source must not change the database owner or external credential metadata."
  }
}

run "database_disabled" {
  command = plan

  variables {
    create_database = false
    database_config = {
      source_backup_id = "ocid1.postgresqlbackup.oc1.phx.test"
    }
  }

  assert {
    condition     = !output.database_created && output.database_db_system_id == null && output.database_vault_secret_id == null
    error_message = "Disabling database creation must omit the nested database even with a backup source."
  }
}
