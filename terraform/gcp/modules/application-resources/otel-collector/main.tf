# ============================================================================
# OpenTelemetry Collector (GCP equivalent of application-resources/otel-collector)
# ============================================================================
# GSA + Workload Identity binding with the roles the collector needs to
# write metrics/traces/logs to Cloud Operations, mirroring the AWS module's
# IRSA role with CloudWatch/X-Ray-equivalent permissions.
#
# Usage:
#   module "otel_collector" {
#     source = "../../modules/application-resources/otel-collector"
#
#     project_id    = "hyperswitch-dev"
#     environment   = "dev"
#     project_name  = "hyperswitch"
#     cluster_name  = module.gke.cluster_name
#     cluster_location = module.gke.location
#     k8s_namespace = "observability"
#   }
# ============================================================================

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "otel-collector"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = concat([
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
  ], var.additional_project_roles)

  labels = var.labels
}
