variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name identifier for the listener (used in tags)"
  type        = string
}

variable "load_balancer_arn" {
  description = "ARN of the load balancer"
  type        = string
}

variable "port" {
  description = "Port on which the load balancer is listening"
  type        = number

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535"
  }
}

variable "protocol" {
  description = "Protocol for connections from clients to the load balancer"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP"], var.protocol)
    error_message = "Protocol must be one of: HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP"
  }
}

variable "ssl_policy" {
  description = "Name of the SSL Policy for the listener (required for HTTPS/TLS)"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "certificate_arn" {
  description = "ARN of the default SSL server certificate (required for HTTPS/TLS)"
  type        = string
  default     = null
}

variable "alpn_policy" {
  description = "Name of the Application-Layer Protocol Negotiation (ALPN) policy"
  type        = string
  default     = null
}

variable "default_action_type" {
  description = "Type of default action (forward, redirect, fixed-response)"
  type        = string
  default     = "forward"

  validation {
    condition     = contains(["forward", "redirect", "fixed-response"], var.default_action_type)
    error_message = "Default action type must be one of: forward, redirect, fixed-response"
  }
}

variable "target_group_arn" {
  description = "ARN of the target group (required if default_action_type is 'forward')"
  type        = string
  default     = null
}

variable "redirect_config" {
  description = "Redirect configuration (used if default_action_type is 'redirect')"
  type = object({
    protocol    = optional(string, "#{protocol}")
    port        = optional(string, "#{port}")
    host        = optional(string, "#{host}")
    path        = optional(string, "/#{path}")
    query       = optional(string, "#{query}")
    status_code = optional(string, "HTTP_301")
  })
  default = {
    protocol    = "#{protocol}"
    port        = "#{port}"
    host        = "#{host}"
    path        = "/#{path}"
    query       = "#{query}"
    status_code = "HTTP_301"
  }
}

variable "fixed_response_config" {
  description = "Fixed response configuration (used if default_action_type is 'fixed-response')"
  type = object({
    content_type = optional(string, "text/plain")
    message_body = optional(string, null)
    status_code  = optional(string, "200")
  })
  default = {
    content_type = "text/plain"
    status_code  = "200"
  }
}

variable "tags" {
  description = "Map of tags to apply to the listener"
  type        = map(string)
  default     = {}
}
