# =========================================================================
# REQUIRED VARIABLES
# =========================================================================

variable "create_alb" {
  description = "Whether to create the Application Load Balancer. When false, Route53 records and listeners are also skipped."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the load balancer"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
}

# =========================================================================
# OPTIONAL VARIABLES
# =========================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "enable_waf_fail_open" {
  description = "Enable WAF fail open mode"
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid header fields"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds"
  }
}

variable "access_logs" {
  description = "Access logs configuration"
  type = object({
    enabled = optional(bool, false)
    bucket  = optional(string, null)
    prefix  = optional(string, null)
  })
  default = {
    enabled = false
  }
}

variable "ingress_rules" {
  description = "Map of ingress rules for the load balancer security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    "http" = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP traffic"
    }
    "https" = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS traffic"
    }
  }
}

variable "egress_rules" {
  description = "Map of egress rules for the load balancer security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port                = number
    protocol            = string
    ssl_policy          = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    certificate_arn     = optional(string, null)
    alpn_policy         = optional(string, null)
    default_action_type = optional(string, "forward")
    target_group_arn    = optional(string, null)
    redirect_config = optional(object({
      protocol    = optional(string, "#{protocol}")
      port        = optional(string, "#{port}")
      host        = optional(string, "#{host}")
      path        = optional(string, "/#{path}")
      query       = optional(string, "#{query}")
      status_code = optional(string, "HTTP_301")
    }), null)
    fixed_response_config = optional(object({
      content_type = optional(string, "text/plain")
      message_body = optional(string, null)
      status_code  = optional(string, "200")
    }), null)
  }))
  default = {
    "http" = {
      port                = 80
      protocol            = "HTTP"
      default_action_type = "fixed-response"
      fixed_response_config = {
        content_type = "text/plain"
        message_body = "OK"
        status_code  = "200"
      }
    }
  }

  validation {
    condition = alltrue([
      for key, listener in var.listeners : contains(["HTTP", "HTTPS"], listener.protocol)
    ])
    error_message = "Listener protocol must be one of: HTTP, HTTPS"
  }

  validation {
    condition = alltrue([
      for key, listener in var.listeners : contains(["forward", "redirect", "fixed-response"], listener.default_action_type)
    ])
    error_message = "Default action type must be one of: forward, redirect, fixed-response"
  }
}

variable "additional_certificates" {
  description = "Map of additional certificates to attach to listeners"
  type = map(object({
    listener_key    = string
    certificate_arn = string
  }))
  default = {}
}


variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# ROUTE53 HOSTED ZONE CONFIGURATION
# =========================================================================

variable "route53_zone" {
  description = "Route53 hosted zone configuration. Either provide an existing zone_id or create a new zone"
  type = object({
    create            = optional(bool, false)
    zone_id           = optional(string, null)
    name              = optional(string, null)
    comment           = optional(string, "Managed by Terraform")
    force_destroy     = optional(bool, false)
    delegation_set_id = optional(string, null)
    # VPC configuration for private hosted zones
    vpc = optional(object({
      vpc_id     = optional(string, null)
      vpc_region = optional(string, null)
    }), null)
    tags = optional(map(string), {})
  })
  default = {
    create = false
  }
}

variable "route53_records" {
  description = "Map of Route53 DNS records to create for the load balancer. When create_as_alias is true, creates an alias record pointing to the ALB. When false, creates a standard record with ttl that defaults to ALB DNS."
  type = map(object({
    name                         = string
    type                         = optional(string, "A")
    create_as_alias              = optional(bool, false)
    ttl                          = optional(number, null)
    alias_evaluate_target_health = optional(bool, true)
    allow_overwrite              = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, record in var.route53_records : (
        !record.create_as_alias ? record.ttl != null : true
      )
    ])
    error_message = "When create_as_alias is false, ttl must be provided."
  }
}

variable "enable_alb_access_logs" {
  description = "Enable KMS-encrypted CloudWatch access logging for module-managed or supplied Kubernetes ALBs."
  type        = bool
  default     = false
}

variable "alb_access_logs_retention_days" {
  description = "CloudWatch retention period for ALB access logs."
  type        = number
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.alb_access_logs_retention_days)
    error_message = "alb_access_logs_retention_days must be a supported CloudWatch Logs retention period."
  }
}

variable "alb_access_logs_load_balancer_arns" {
  description = "Existing ALB ARNs keyed by stable names. Used for Kubernetes-managed load balancers without importing their resources."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for arn in values(var.alb_access_logs_load_balancer_arns) : can(regex("^arn:[^:]+:elasticloadbalancing:[^:]+:[0-9]{12}:loadbalancer/app/", arn))])
    error_message = "Each alb_access_logs_load_balancer_arns value must be an Application Load Balancer ARN."
  }
}

variable "alb_access_logs_log_group_name" {
  description = "Optional custom CloudWatch log group name for ALB access logs."
  type        = string
  default     = null
}

variable "alb_access_logs_kms_key_arn" {
  description = "Optional existing KMS key ARN for ALB access logs. A rotating key is created when null."
  type        = string
  default     = null
  validation {
    condition     = var.alb_access_logs_kms_key_arn == null ? true : can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.alb_access_logs_kms_key_arn))
    error_message = "alb_access_logs_kms_key_arn must be a KMS key ARN."
  }
}

variable "create_alb_access_logs_s3_bucket" {
  description = "Create an SSE-S3 encrypted ALB access log bucket, including for controller-managed ALBs."
  type        = bool
  default     = false
}

variable "alb_access_logs_s3_bucket_name" {
  description = "Optional name for the managed ALB access log bucket."
  type        = string
  default     = null
}

variable "alb_access_logs_s3_prefix" {
  description = "S3 key prefix for ALB access logs. Must not contain AWSLogs."
  type        = string
  default     = "alb"
  validation {
    condition     = !strcontains(var.alb_access_logs_s3_prefix, "AWSLogs") && trim(var.alb_access_logs_s3_prefix, "/") == var.alb_access_logs_s3_prefix
    error_message = "The prefix must not contain AWSLogs or start/end with a slash."
  }
}
