variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the target group"
  type        = string
}

variable "port" {
  description = "Port on which targets receive traffic"
  type        = number

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535"
  }
}

variable "protocol" {
  description = "Protocol to use for routing traffic to the targets"
  type        = string
  default     = "TCP"

  validation {
    condition     = contains(["TCP", "UDP", "TCP_UDP", "TLS", "HTTP", "HTTPS"], var.protocol)
    error_message = "Protocol must be one of: TCP, UDP, TCP_UDP, TLS, HTTP, HTTPS"
  }
}

variable "vpc_id" {
  description = "VPC ID where the target group will be created"
  type        = string
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda, alb)"
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "Target type must be one of: instance, ip, lambda, alb"
  }
}

variable "deregistration_delay" {
  description = "Time in seconds for target deregistration"
  type        = number
  default     = 300
}

variable "health_check" {
  description = "Health check configuration"
  type = object({
    enabled             = optional(bool, true)
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
    timeout             = optional(number, 10)
    interval            = optional(number, 30)
    port                = optional(string, "traffic-port")
    protocol            = optional(string, "TCP")
    path                = optional(string, null)
    matcher             = optional(string, null)
  })
  default = {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
  }
}

variable "stickiness" {
  description = "Stickiness configuration"
  type = object({
    enabled         = optional(bool, false)
    type            = optional(string, "lb_cookie")
    cookie_duration = optional(number, 86400)
  })
  default = {
    enabled = false
  }
}

variable "tags" {
  description = "Map of tags to apply to the target group"
  type        = map(string)
  default     = {}
}
