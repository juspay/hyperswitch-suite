variable "compartment_id" {
  description = "OCID of the compartment for DevOps resources"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for naming"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment (dev, sandbox, prodt)"
  type        = string

  validation {
    condition     = contains(["dev", "sandbox", "integ", "prod"], var.environment)
    error_message = "environment must be one of dev, sandbox, integ, prod"
  }
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "namespace" {
  description = "Object Storage / OCIR tenancy namespace"
  type        = string
}

variable "notification_topic_id" {
  description = "OCID of the ONS topic for build notifications (null = no notifications)"
  type        = string
  default     = null
}

variable "build_pipeline_parameters" {
  description = "Pipeline parameters map (name/default_value/description)"
  type = object({
    name          = string
    default_value = string
    description   = optional(string)
  })
  default = null
}

variable "source_repository_id" {
  description = "OCID of the DevOps code repository (or connection) used as the build source"
  type        = string
}

variable "build_spec_file" {
  description = "Path to the build_spec.yaml in the source repo (null = default build_spec.yaml)"
  type        = string
  default     = null
}

variable "build_runner_image" {
  description = "OCI Build runner image OCID"
  type        = string
  default     = "ol7.ci-image.base.latest"
}

variable "deliver_artifact_id" {
  description = "OCID of the artifact (container repository) the built image is pushed to"
  type        = string
}

variable "image_uri" {
  description = "Full OCIR image URI for the deliver stage, e.g. ap-mumbai-1.ocir.io/<namespace>/<env>/hyperswitch/router"
  type        = string
}

variable "image_digest" {
  description = "Container image digest (optional for latest)"
  type        = string
  default     = null
}

variable "cluster_id" {
  description = "OCID of the OKE cluster to deploy to"
  type        = string
  default     = null
}

variable "create_deploy_pipeline" {
  description = "Whether to create the deployment pipeline (needs OKE cluster)"
  type        = bool
  default     = false
}

variable "deploy_pipeline_id" {
  description = "Pre-created deploy pipeline OCID to trigger (null = create from this module)"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags for all resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for all resources"
  type        = map(string)
  default     = {}
}