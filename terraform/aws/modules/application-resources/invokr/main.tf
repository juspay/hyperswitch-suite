resource "terraform_data" "database_validation" {
  count = var.create_database ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.database_config != null
      error_message = "database_config must be provided when create_database is true."
    }

    precondition {
      condition     = try(trimspace(var.database_config.database_name) != "", false)
      error_message = "database_config.database_name must be non-empty when create_database is true."
    }

    precondition {
      condition     = try(length(var.database_config.cluster_instances) > 0, false)
      error_message = "database_config.cluster_instances must contain at least one instance when create_database is true."
    }

    precondition {
      condition = try(
        var.database_config.db_cluster_parameter_group_name != null
        ? trimspace(var.database_config.db_cluster_parameter_group_name) != ""
        : (
          var.database_config.create_custom_parameter_group &&
          anytrue([
            for parameter in var.database_config.custom_parameter_group_parameters :
            contains(
              [
                for library in split(",", parameter.value) :
                lower(trimspace(library))
              ],
              "pg_cron"
            ) if parameter.name == "shared_preload_libraries"
          ]) &&
          anytrue([
            for parameter in var.database_config.custom_parameter_group_parameters :
            trimspace(parameter.value) == trimspace(var.database_config.database_name)
            if parameter.name == "cron.database_name"
          ])
        ),
        false
      )
      error_message = "Invokr requires either an existing db_cluster_parameter_group_name already configured for pg_cron, or a custom parameter group with shared_preload_libraries containing pg_cron and cron.database_name equal to database_config.database_name."
    }
  }
}

resource "terraform_data" "application_secret_validation" {
  count = local.application_secret_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.create_application_secret && var.existing_application_secret_arn != null)
      error_message = "create_application_secret and existing_application_secret_arn are mutually exclusive."
    }

    precondition {
      condition     = !var.create_application_secret || try(trimspace(var.application_secret_name) != "", false)
      error_message = "application_secret_name must be provided when create_application_secret is true."
    }
  }
}
