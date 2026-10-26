variable "environment" {
  description = "Environment name (for example, sandbox, dev, or prod)"
  type        = string
}

variable "region" {
  description = "AWS region. Defaults to the provider region when null"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "app_name" {
  description = "Application name used for resource naming and tagging"
  type        = string
  default     = "invokr"
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "create_database" {
  description = "Whether to create an Aurora PostgreSQL database for Invokr"
  type        = bool
  default     = false
}

variable "database_config" {
  description = "Aurora PostgreSQL configuration. Required when create_database is true. An existing db_cluster_parameter_group_name must already load pg_cron and set cron.database_name to database_name"
  type = object({
    vpc_id                                    = string
    subnet_ids                                = list(string)
    cluster_identifier                        = optional(string)
    cluster_identifier_prefix                 = optional(string)
    database_name                             = optional(string)
    engine                                    = optional(string, "aurora-postgresql")
    engine_version                            = optional(string)
    engine_mode                               = optional(string, "provisioned")
    engine_lifecycle_support                  = optional(string, "open-source-rds-extended-support")
    cluster_scalability_type                  = optional(string)
    master_username                           = optional(string)
    master_password                           = optional(string)
    manage_master_user_password               = optional(bool)
    master_password_secretsmanager_secret_id  = optional(string)
    master_password_secretsmanager_secret_key = optional(string)
    master_user_secret_kms_key_id             = optional(string)
    db_cluster_instance_class                 = optional(string)
    availability_zones                        = optional(list(string))
    allocated_storage                         = optional(number)
    storage_type                              = optional(string)
    iops                                      = optional(number)
    network_type                              = optional(string, "IPV4")
    port                                      = optional(number, 5432)
    create_db_subnet_group                    = optional(bool, true)
    db_subnet_group_name                      = optional(string)
    vpc_security_group_ids                    = optional(list(string), [])
    db_cluster_parameter_group_name           = optional(string)
    db_instance_parameter_group_name          = optional(string)
    backup_retention_period                   = optional(number, 7)
    preferred_backup_window                   = optional(string)
    preferred_maintenance_window              = optional(string)
    skip_final_snapshot                       = optional(bool, false)
    final_snapshot_identifier                 = optional(string)
    snapshot_identifier                       = optional(string)
    copy_tags_to_snapshot                     = optional(bool, true)
    storage_encrypted                         = optional(bool, true)
    deletion_protection                       = optional(bool, false)
    delete_automated_backups                  = optional(bool, true)
    iam_database_authentication_enabled       = optional(bool, false)
    iam_roles                                 = optional(list(string), [])
    domain                                    = optional(string)
    domain_iam_role_name                      = optional(string)
    allow_major_version_upgrade               = optional(bool)
    apply_immediately                         = optional(bool)
    enabled_cloudwatch_logs_exports           = optional(list(string), ["postgresql"])
    performance_insights_enabled              = optional(bool, false)
    performance_insights_kms_key_id           = optional(string)
    performance_insights_retention_period     = optional(number, 7)
    monitoring_interval                       = optional(number, 0)
    monitoring_role_arn                       = optional(string)
    database_insights_mode                    = optional(string, "standard")
    enable_http_endpoint                      = optional(bool, false)
    enable_local_write_forwarding             = optional(bool)
    replication_source_identifier             = optional(string)
    source_region                             = optional(string)
    backtrack_window                          = optional(number, 0)
    ca_certificate_identifier                 = optional(string)
    db_system_id                              = optional(string)
    create_security_group                     = optional(bool, true)
    security_group_name                       = optional(string)
    security_group_description                = optional(string)
    scaling_configuration                     = optional(any)
    serverlessv2_scaling_configuration        = optional(any)
    restore_to_point_in_time                  = optional(any)
    s3_import                                 = optional(any)
    create_global_cluster                     = optional(bool, false)
    global_cluster_identifier                 = optional(string)
    global_deletion_protection                = optional(bool, true)
    enable_global_write_forwarding            = optional(bool, false)
    use_existing_as_global_primary            = optional(bool, false)
    source_db_cluster_identifier              = optional(string)
    create_custom_parameter_group             = optional(bool, false)
    custom_parameter_group_name               = optional(string)
    custom_parameter_group_family             = optional(string)
    custom_parameter_group_description        = optional(string)
    custom_parameter_group_parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    cluster_instances = optional(map(object({
      identifier                            = optional(string)
      identifier_prefix                     = optional(string)
      instance_class                        = string
      engine                                = optional(string)
      engine_version                        = optional(string)
      publicly_accessible                   = optional(bool, false)
      db_parameter_group_name               = optional(string)
      apply_immediately                     = optional(bool)
      monitoring_role_arn                   = optional(string)
      monitoring_interval                   = optional(number, 0)
      promotion_tier                        = optional(number, 0)
      availability_zone                     = optional(string)
      preferred_backup_window               = optional(string)
      preferred_maintenance_window          = optional(string)
      auto_minor_version_upgrade            = optional(bool, true)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number, 7)
      copy_tags_to_snapshot                 = optional(bool, false)
      ca_cert_identifier                    = optional(string)
      custom_iam_instance_profile           = optional(string)
      force_destroy                         = optional(bool, false)
      tags                                  = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  })
  default = null

  validation {
    condition     = var.database_config == null || var.database_config.port >= 1 && var.database_config.port <= 65535
    error_message = "database_config.port must be between 1 and 65535."
  }

  validation {
    condition = (
      var.database_config == null ||
      var.database_config.availability_zones == null ||
      length(var.database_config.availability_zones) >= 2
    )
    error_message = "database_config.availability_zones must contain at least two zones when provided."
  }

  validation {
    condition = (
      var.database_config == null ||
      !var.database_config.create_custom_parameter_group ||
      try(trimspace(var.database_config.custom_parameter_group_family) != "", false)
    )
    error_message = "custom_parameter_group_family is required when create_custom_parameter_group is true."
  }
}

variable "kms" {
  description = "Shared KMS key configuration. Create a key or provide an existing key ARN"
  type = object({
    create                             = optional(bool, false)
    create_replica                     = optional(bool, false)
    primary_key_arn                    = optional(string)
    key_arn                            = optional(string)
    description                        = optional(string)
    multi_region                       = optional(bool, false)
    deletion_window_in_days            = optional(number, 30)
    enable_key_rotation                = optional(bool, true)
    rotation_period_in_days            = optional(number)
    bypass_policy_lockout_safety_check = optional(bool)
    aliases                            = optional(list(string), [])
    aliases_use_name_prefix            = optional(bool, false)
    key_administrators                 = optional(list(string), [])
    key_users                          = optional(list(string), [])
    key_service_users                  = optional(list(string), [])
    key_owners                         = optional(list(string), [])
    source_policy_documents            = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = !(var.kms.create && var.kms.key_arn != null)
    error_message = "kms.create and kms.key_arn are mutually exclusive."
  }

  validation {
    condition = !var.kms.create_replica || (
      var.kms.create &&
      try(trimspace(var.kms.primary_key_arn) != "", false)
    )
    error_message = "KMS replica creation requires kms.create = true and a non-empty kms.primary_key_arn."
  }

  validation {
    condition     = var.kms.create_replica || var.kms.primary_key_arn == null
    error_message = "kms.primary_key_arn may only be supplied when kms.create_replica is true."
  }

  validation {
    condition = alltrue([
      for alias in var.kms.aliases : can(regex("^alias/[A-Za-z0-9/_-]+$", alias))
    ])
    error_message = "Every KMS alias must start with alias/ and contain only letters, numbers, slash, underscore, or hyphen."
  }
}

variable "create_application_secret" {
  description = "Optional bootstrap-configuration container used by External Secrets or another delivery process. Invokr does not read AWS Secrets Manager directly"
  type        = bool
  default     = false
}

variable "existing_application_secret_arn" {
  description = "ARN of an existing Invokr application secret. Mutually exclusive with create_application_secret"
  type        = string
  default     = null
}

variable "application_secret_name" {
  description = "Name of the application secret to create"
  type        = string
  default     = null
}

variable "application_secret_description" {
  description = "Description for the application secret"
  type        = string
  default     = null
}

variable "application_secret_kms_key_id" {
  description = "KMS key for the application secret. Defaults to the effective module KMS key"
  type        = string
  default     = null
}

variable "application_secret_recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before deleting the application secret"
  type        = number
  default     = 7

  validation {
    condition = (
      var.application_secret_recovery_window_in_days == 0 ||
      var.application_secret_recovery_window_in_days >= 7 && var.application_secret_recovery_window_in_days <= 30
    )
    error_message = "application_secret_recovery_window_in_days must be 0 or between 7 and 30."
  }
}

variable "application_secret_tags" {
  description = "Additional tags applied to the application secret"
  type        = map(string)
  default     = {}
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for the Invokr Kubernetes service account"
  type        = bool
  default     = false
}

variable "enable_application_kms_decryption" {
  description = "Attach kms:Decrypt and kms:DescribeKey permissions for Invokr's KMS-enabled image"
  type        = bool
  default     = false
}

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to OIDC providers and Kubernetes service accounts allowed to assume the role"
  type = map(object({
    oidc_provider_arn = string
    service_accounts = list(object({
      namespace = string
      name      = string
    }))
  }))
  default = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM trust-policy statements"
  type        = list(any)
  default     = []
}

variable "assume_role_principals" {
  description = "AWS principal ARNs allowed to assume the role"
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "Custom IAM role name"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Custom IAM role description"
  type        = string
  default     = null
}

variable "role_path" {
  description = "IAM role path"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum IAM role session duration in seconds"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to detach policies before destroying the IAM role"
  type        = bool
  default     = true
}

variable "aws_managed_policy_names" {
  description = "AWS-managed policy names to attach to the role"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "Customer-managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Additional inline IAM policies keyed by policy name"
  type        = map(string)
  default     = {}
}
