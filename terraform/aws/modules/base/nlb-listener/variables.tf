variable "name" {
  description = "Name identifier for the listener (used in tags)"
  type        = string
}

variable "load_balancer_arn" {
  description = "ARN of the network load balancer"
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
  default     = "TCP"

  validation {
    condition     = contains(["TCP", "TLS", "UDP", "TCP_UDP"], var.protocol)
    error_message = "Protocol must be one of: TCP, TLS, UDP, TCP_UDP"
  }
}

variable "ssl_policy" {
  description = "Name of the SSL Policy for the listener (required for TLS)"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "certificate_arn" {
  description = "ARN of the default SSL server certificate (required for TLS)"
  type        = string
  default     = null
}

variable "alpn_policy" {
  description = "Name of the Application-Layer Protocol Negotiation (ALPN) policy"
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "ARN of the target group to forward traffic to"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to the listener"
  type        = map(string)
  default     = {}
}
