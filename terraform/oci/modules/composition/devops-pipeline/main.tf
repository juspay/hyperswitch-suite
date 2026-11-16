# =============================================================================
# OCI DevOps Build & Deployment Pipeline - for hyperswitch image building
# =============================================================================
# Port of Terraform resource wrappers for building hyperswitch images and
# deploying to OKE. This is the OCI counterpart of AWS CodeBuild + CodePipeline
# + ECR integration and GCP Cloud Build + Artifact Registry + Deploy.
#
# OCI does not have a "CodeBuild" style continuous build pipeline that runs
# fully in the Terraform module. What OCI offers is the DevOps service:
#   Project -> Build Pipeline -> (Build Stage -> Deliver Artifact -> Trigger
#   Deployment) -> Deployment Pipeline -> OKE environment.
#
# This module creates the DevOps project, build pipeline, build stages,
# artifacts, deployment pipeline and the OKE deployment environment so that
# hyperswitch SDK/router images can be built from source and deployed to OKE.
#
# The build_spec.yaml that drives the actual build lives in the referenced
# code repository (e.g. the hyperswitch repo), NOT here. This module wires the
# OCI-side shell around it.
# =============================================================================

# =============================================================================
# DevOps Project - the container for all pipelines and artifacts
# =============================================================================
resource "oci_devops_project" "this" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-${var.environment}-devops"
  description    = "DevOps project for Hyperswitch ${var.environment} - build and deploy hyperswitch images to OKE"
  notification_config {
    topic_id = var.notification_topic_id
  }
}

# =============================================================================
# Build Pipeline
# =============================================================================
resource "oci_devops_build_pipeline" "this" {
  project_id   = oci_devops_project.this.id
  display_name = "${var.project_name}-${var.environment}-build-pipeline"
  description  = "Build pipeline for Hyperswitch ${var.environment} images"

  dynamic "build_pipeline_parameters" {
    for_each = var.build_pipeline_parameters != {} ? [1] : []
    content {
      items {
        name          = var.build_pipeline_parameters["name"]
        default_value = var.build_pipeline_parameters["default_value"]
        description   = var.build_pipeline_parameters["description"]
      }
    }
  }
}

# =============================================================================
# Build Pipeline Stages
# =============================================================================
# Stage 1: Managed Build - runs the build_spec.yaml from the source repo
resource "oci_devops_build_pipeline_stage" "managed_build" {
  build_pipeline_id         = oci_devops_build_pipeline.this.id
  display_name              = "build"
  description               = "Build hyperswitch ${var.environment} image from source"
  build_pipeline_stage_type = "BUILD"

  build_source_collection {
    items {
      name            = "hyperswitch-source"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      repository_id   = var.source_repository_id
    }
  }

  build_spec_file = var.build_spec_file

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.this.id
    }
  }

  image = var.build_runner_image
}

# Stage 2: Deliver Artifacts - push the built Docker image to OCIR
resource "oci_devops_build_pipeline_stage" "deliver_artifact" {
  build_pipeline_id         = oci_devops_build_pipeline.this.id
  display_name              = "deliver"
  description               = "Deliver hyperswitch ${var.environment} image to OCIR"
  build_pipeline_stage_type = "DELIVER_ARTIFACT"

  deliver_artifact_collection {
    items {
      artifact_name = "hyperswitch-image"
      artifact_id   = var.deliver_artifact_id
    }
  }

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.managed_build.id
    }
  }
}

# Stage 3: Trigger Deployment - deploy the new image to OKE
resource "oci_devops_build_pipeline_stage" "trigger_deploy" {
  count = var.deploy_pipeline_id != null ? 1 : 0

  build_pipeline_id         = oci_devops_build_pipeline.this.id
  display_name              = "deploy"
  description               = "Deploy hyperswitch ${var.environment} image to OKE"
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"

  deploy_pipeline_id = var.deploy_pipeline_id

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.deliver_artifact.id
    }
  }
}

# =============================================================================
# Deployment Pipeline - deploy the Helm chart / manifests to OKE
# =============================================================================
resource "oci_devops_deploy_pipeline" "this" {
  count = var.create_deploy_pipeline ? 1 : 0

  project_id   = oci_devops_project.this.id
  display_name = "${var.project_name}-${var.environment}-deploy-pipeline"
  description  = "Deploy pipeline for Hyperswitch ${var.environment} to OKE"
}

# =============================================================================
# OKE Deployment Environment - the target cluster
# =============================================================================
resource "oci_devops_deploy_environment" "oke_cluster" {
  count = var.create_deploy_pipeline ? 1 : 0

  project_id              = oci_devops_project.this.id
  display_name            = "oke-${var.environment}"
  description             = "OKE cluster deployment target for ${var.environment}"
  deploy_environment_type = "OKE_CLUSTER"

  cluster_id = var.cluster_id
}

# =============================================================================
# Deploy Stage - Apply manifests to the OKE cluster
# =============================================================================
resource "oci_devops_deploy_stage" "oke_deploy" {
  count = var.create_deploy_pipeline ? 1 : 0

  deploy_pipeline_id = oci_devops_deploy_pipeline.this[0].id
  display_name       = "oke-apply"
  description        = "Apply manifests to OKE cluster"
  deploy_stage_type  = "DEPLOY_TO_INGRESS"

  deploy_environment_id = oci_devops_deploy_environment.oke_cluster[0].id

  deploy_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.this[0].id
    }
  }
}

# =============================================================================
# Container Repository Artifact (for the deliver stage to target)
# =============================================================================
resource "oci_devops_deploy_artifact" "container_image" {
  count = var.create_deploy_pipeline ? 1 : 0

  project_id           = oci_devops_project.this.id
  display_name         = "hyperswitch-${var.environment}-container-image"
  deploy_artifact_type = "DOCKER_IMAGE"

  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"

  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = var.image_uri
    image_digest                = var.image_digest
  }
}