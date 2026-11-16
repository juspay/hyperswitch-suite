output "project_id" {
  description = "OCID of the DevOps project"
  value       = oci_devops_project.this.id
}

output "project_name" {
  description = "Display name of the DevOps project"
  value       = oci_devops_project.this.name
}

output "build_pipeline_id" {
  description = "OCID of the build pipeline"
  value       = oci_devops_build_pipeline.this.id
}

output "build_pipeline_ocid" {
  description = "Alias for build_pipeline_id"
  value       = oci_devops_build_pipeline.this.id
}

output "build_stage_id" {
  description = "OCID of the managed build stage"
  value       = oci_devops_build_pipeline_stage.managed_build.id
}

output "deliver_stage_id" {
  description = "OCID of the deliver artifact stage"
  value       = oci_devops_build_pipeline_stage.deliver_artifact.id
}

output "deploy_pipeline_id" {
  description = "OCID of the deployment pipeline (null unless created)"
  value       = try(oci_devops_deploy_pipeline.this[0].id, null)
}

output "deploy_environment_id" {
  description = "OCID of the OKE deployment environment"
  value       = try(oci_devops_deploy_environment.oke_cluster[0].id, null)
}

output "deploy_stage_id" {
  description = "OCID of the deploy stage"
  value       = try(oci_devops_deploy_stage.oke_deploy[0].id, null)
}

output "container_artifact_id" {
  description = "OCID of the container image deploy artifact"
  value       = try(oci_devops_deploy_artifact.container_image[0].id, null)
}