variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "otel-collector"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# EKS OIDC Configuration
# =========================================================================

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name)"
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM assume role policy statements to append"
  type        = list(any)
  default     = []
}

# =========================================================================
# IAM Role Configuration
# =========================================================================

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role"
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
  description = "Maximum session duration for the role (in seconds)"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies when destroying the role"
  type        = bool
  default     = true
}

# =========================================================================
# Assume Role Principals
# =========================================================================

variable "assume_role_principals" {
  description = "List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root'])"
  type        = list(string)
  default     = []
}

# =========================================================================
# Policy Attachments
# =========================================================================

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

# =========================================================================
# OpenTelemetry Collector Specific Permissions
# =========================================================================

variable "create_otel_collector_policy" {
  description = "Whether to create the default OpenTelemetry Collector IAM policy"
  type        = bool
  default     = true
}

# CloudWatch Logs Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable permissions for sending logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_log_group_arn" {
  description = "ARN of the CloudWatch Logs log group (for scoped permissions). If null, allows all log groups"
  type        = string
  default     = null
}

# CloudWatch Metrics Configuration
variable "enable_cloudwatch_metrics" {
  description = "Enable permissions for sending metrics to CloudWatch"
  type        = bool
  default     = true
}

variable "cloudwatch_metrics_namespace" {
  description = "CloudWatch metrics namespace for the OpenTelemetry Collector"
  type        = string
  default     = "OpenTelemetryCollector"
}

# X-Ray Tracing Configuration
variable "enable_xray_tracing" {
  description = "Enable permissions for sending traces to AWS X-Ray"
  type        = bool
  default     = true
}

# S3 Export Configuration
variable "enable_s3_export" {
  description = "Enable permissions for exporting telemetry data to S3"
  type        = bool
  default     = false
}

variable "s3_export_bucket_arn" {
  description = "ARN of the S3 bucket for telemetry data export (for scoped permissions). If null, allows all buckets"
  type        = string
  default     = null
}

# Kinesis Data Firehose Configuration
variable "enable_kinesis_firehose" {
  description = "Enable permissions for sending telemetry data to Kinesis Data Firehose"
  type        = bool
  default     = false
}

variable "kinesis_firehose_stream_arn" {
  description = "ARN of the Kinesis Data Firehose delivery stream (for scoped permissions). If null, allows all streams"
  type        = string
  default     = null
}
