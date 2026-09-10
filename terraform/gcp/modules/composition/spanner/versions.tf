terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # Floor covers every Spanner surface this module touches:
      # google_spanner_instance's `edition` and `default_backup_schedule_type`,
      # google_spanner_database's `database_dialect` and
      # `enable_drop_protection`, and the google_spanner_backup_schedule
      # resource. The live GCP tree currently resolves 8.2.0.
      version = ">= 6.20, < 9.0"
    }
    # google_project_service_identity (kms.tf) is beta-only.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.20, < 9.0"
    }
  }
}
