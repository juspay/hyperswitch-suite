variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

variable "create_alb" {
  description = "Whether to create the Application Load Balancer"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the load balancer"
  type        = string
  default     = null
}

variable "internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
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
}

variable "additional_certificates" {
  description = "Map of additional certificates to attach to listeners"
  type = map(object({
    listener_key    = string
    certificate_arn = string
  }))
  default = {}
}

variable "route53_zone" {
  description = "Route53 hosted zone configuration"
  type = object({
    create            = optional(bool, false)
    zone_id           = optional(string, null)
    name              = optional(string, null)
    comment           = optional(string, "Managed by Terraform")
    force_destroy     = optional(bool, false)
    delegation_set_id = optional(string, null)
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
  description = "Map of Route53 DNS records to create for the load balancer"
  type = map(object({
    name                         = string
    type                         = optional(string, "A")
    create_as_alias              = optional(bool, false)
    ttl                          = optional(number, null)
    alias_evaluate_target_health = optional(bool, true)
    allow_overwrite              = optional(bool, true)
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
