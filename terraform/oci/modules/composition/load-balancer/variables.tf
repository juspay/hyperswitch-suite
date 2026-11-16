# =============================================================================
# Identity / naming
# =============================================================================

variable "compartment_id" {
  description = "OCID of the compartment that holds the load balancer and its NSG. OCI's scoping context; the AWS module used vpc_id for both scope and placement, which splits here into compartment_id (ownership) and subnet_ids (placement)."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment (or root tenancy) OCID, e.g. ocid1.compartment.oc1..aaaa..."
  }
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod). Used for naming and freeform tags."
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and freeform tags."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1), used for freeform tags only. Placement is decided by subnet_ids."
  type        = string
  default     = null
}

variable "name" {
  description = "Short role name for this load balancer, e.g. \"utils\". Combined into <project>-<env>-<name>. Mirrors the AWS module's `name`. This module is NOT a singleton - the AWS estate instantiates it once per role per live root (utils-load-balancer, management-stack/load-balancer), and a second OCI unit must be able to instantiate it again."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Full display name override. Leave null to use <project>-<env>-<name>."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Extra freeform tags merged onto the load balancer and the NSG. Replaces the AWS module's `tags`. Note that listeners, backend sets, backends, hostnames and rule sets are sub-resources of the load balancer and are NOT independently taggable on OCI - AWS's per-listener tags have no counterpart."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Placement and shape
# =============================================================================

variable "subnet_ids" {
  description = <<-EOT
    Subnet OCIDs the load balancer's VNICs live in. Placement is never
    hardcoded - pass a tier from vpc-network's subnets_by_tier map
    ("external-incoming" for internet-facing, "utils" for internal).

    A LIST, not the AWS module's `subnets` list-of-AZ-subnets: OCI wants ONE
    regional subnet, or two AD-specific subnets for the legacy non-regional
    layout. vpc-network builds regional subnets only (one availability domain
    in ap-mumbai-1, and Oracle recommends regional), so in this platform this
    list always has exactly one element. AWS's requirement of >= 2 subnets in
    >= 2 AZs has nothing to translate to.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1 && length(var.subnet_ids) <= 2
    error_message = "subnet_ids must hold 1 regional subnet, or 2 AD-specific subnets. More than 2 is not a shape OCI accepts."
  }
}

variable "vcn_id" {
  description = "OCID of the VCN, needed only to create the module-owned NSG. Null is fine when create_nsg = false."
  type        = string
  default     = null
}

variable "is_private" {
  description = "Private (VCN-internal) load balancer. The direct counterpart of the AWS module's `internal`. Note the AWS module defaults this to false; the default here is true, so an internet-facing load balancer is an explicit act rather than what you get by forgetting."
  type        = bool
  default     = true
}

variable "shape" {
  description = "Load balancer shape. Only \"flexible\" is a real choice: the fixed shapes (10/100/400/8000 Mbps) were deprecated in May 2023 per the provider's own argument documentation. Exposed rather than hardcoded solely so an existing fixed-shape load balancer can be imported without a module fork."
  type        = string
  default     = "flexible"
}

variable "minimum_bandwidth_in_mbps" {
  description = "Lower bound of the flexible shape's bandwidth range. No AWS counterpart - an ALB has no bandwidth dial at all - so this is new surface the port must give a value to, not a ported variable. 10 is OCI's floor."
  type        = number
  default     = 10
}

variable "maximum_bandwidth_in_mbps" {
  description = "Upper bound of the flexible shape's bandwidth range, and therefore the cost ceiling. Kept modest by default; a stack raises it per environment."
  type        = number
  default     = 100
}

variable "reserved_ip_id" {
  description = <<-EOT
    OCID of a Reserved Public IP to assign, instead of letting OCI allocate an
    ephemeral one. Null means ephemeral.

    Worth setting for anything DNS points at. OCI load balancers get real IPs
    (unlike an ALB, which only ever has a hostname), which is what lets the
    `dns` module point a plain A record at the apex with no ALIAS pseudo-record
    - but an ephemeral IP changes if the load balancer is recreated, and the A
    record would then be stale. A reserved IP is the thing that makes the
    A-record substitute for ALIAS actually safe.

    Ignored when is_private = true.
  EOT
  type        = string
  default     = null
}

variable "ip_mode" {
  description = "\"IPV4\" or \"IPV6\". No AWS counterpart in this module (the AWS ALB's ip_address_type is not exposed by it)."
  type        = string
  default     = "IPV4"
}

# =============================================================================
# Network access control
# =============================================================================

variable "create_nsg" {
  description = "Create an EMPTY network security group for this load balancer. The counterpart of the AWS module's dedicated aws_security_group (feature 2, required). Empty on purpose: catalog/units/oci/security-rules, the security-last stack phase, writes the rules into it, exactly as it does for the database and oci-cache-valkey modules. Do not add rules here - that reintroduces the dependency cycle the security-last split exists to break."
  type        = bool
  default     = true
}

variable "network_security_group_ids" {
  description = "Additional, externally-owned NSG OCIDs to attach alongside the module's own - typically the OKE module's public_lb_nsg_id or internal_lb_nsg_id when this load balancer fronts cluster workloads. OCI caps a VNIC at 5 NSGs; the module's own counts against that."
  type        = list(string)
  default     = []
}

# =============================================================================
# Backend sets and backends
# =============================================================================

variable "backend_sets" {
  description = <<-EOT
    Map of backend-set name to configuration.

    NEW RESPONSIBILITY versus the AWS module, and the one place this port's
    module boundary genuinely moves. AWS's composition/load-balancer creates
    only the ALB and its listeners; target groups are somebody else's problem,
    which is legal because an aws_lb_listener's forward action can name a
    target group ARN created anywhere. OCI's listener REQUIRES
    default_backend_set_name, and a backend set is a sub-resource of the load
    balancer itself - it cannot exist before or outside it. So the listener-to-
    backend chain that AWS split across two modules has to live in one here.

    `policy` is OCI's load-balancing algorithm: ROUND_ROBIN, LEAST_CONNECTIONS
    or IP_HASH.
  EOT

  type = map(object({
    policy = optional(string, "ROUND_ROBIN")

    health_checker = object({
      protocol            = string # HTTP | HTTPS | TCP | UDP | DNS
      port                = optional(number)
      url_path            = optional(string)
      return_code         = optional(number)
      interval_ms         = optional(number, 10000)
      timeout_in_millis   = optional(number, 3000)
      retries             = optional(number, 3)
      response_body_regex = optional(string)
      is_force_plain_text = optional(bool)
    })

    # Static backends. Left empty for anything OKE registers dynamically
    # through its own cloud-controller-manager - registering the same endpoint
    # from both places is how a backend set ends up flapping.
    backends = optional(map(object({
      ip_address      = string
      port            = number
      weight          = optional(number, 1)
      backup          = optional(bool, false)
      drain           = optional(bool, false)
      offline         = optional(bool, false)
      max_connections = optional(number)
    })), {})

    # Cookie-based stickiness. AWS's stickiness lives on the target group, so
    # this module never carried it; included because on OCI the backend set is
    # this module's, and omitting it would push a consumer out of the module.
    session_persistence_cookie_name = optional(string)

    # Re-encryption to the backend. Distinct from the listener's
    # ssl_configuration, which terminates TLS from the client.
    backend_ssl_certificate_name = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, bs in var.backend_sets : contains(["ROUND_ROBIN", "LEAST_CONNECTIONS", "IP_HASH"], bs.policy)
    ])
    error_message = "backend_sets[*].policy must be ROUND_ROBIN, LEAST_CONNECTIONS or IP_HASH."
  }

  validation {
    condition = alltrue([
      for k, bs in var.backend_sets : contains(["HTTP", "HTTPS", "TCP", "UDP", "DNS"], bs.health_checker.protocol)
    ])
    error_message = "backend_sets[*].health_checker.protocol must be one of HTTP, HTTPS, TCP, UDP, DNS."
  }
}

# =============================================================================
# Listeners
# =============================================================================

variable "listeners" {
  description = <<-EOT
    Map of listener name to configuration, mirroring the AWS module's
    map-of-listeners shape.

    THREE PARITY NOTES, each a real difference and each commented again at the
    resource in listeners.tf:

    1. There is no `default_action_type`. An OCI listener's only native
       default action is forwarding to a backend set (load-balancer.md
       feature 3, PARTIAL). AWS's `redirect` default action is reproduced by
       attaching a rule set - see `rule_sets` and `rule_set_names` below,
       which VERIFIES the check sheet's open question 1: oci_load_balancer_
       rule_set does carry a REDIRECT action with redirect_uri and
       response_code. AWS's `fixed-response` default action - the AWS module's
       own default listener ships one, a static 200 "OK" - has NO equivalent:
       the rule set's only body-less status response is
       CONTROL_ACCESS_USING_HTTP_METHODS' `status_code`, which is a rejection
       code on a method filter, not an arbitrary served response. Replace a
       fixed-response listener with a trivial always-healthy backend set.

    2. `certificate_ids` accepts ONE id (load-balancer.md feature 5, PARTIAL).
       The provider states it outright: "Currently only a single Id may be
       passed". AWS's aws_lb_listener_certificate takes unlimited additional
       SNI certificates. Multi-hostname designs need hostname_names plus
       oci_load_balancer_hostname, whose exact certificate relationship is
       still unverified (that check sheet's open question 2, still open).

    3. HTTP/2 is not a toggle. AWS has enable_http2 on the load balancer; no
       equivalent argument exists on either OCI resource, and whether HTTP/2
       is an always-on property of the HTTP listener or unsupported was not
       resolved (open question 3, still open). Nothing here claims it.
  EOT

  type = map(object({
    port     = number
    protocol = optional(string, "HTTP") # HTTP | HTTPS | TCP
    # Must name a key of var.backend_sets, or an externally-created set.
    default_backend_set_name = string

    # TLS termination. Exactly one id - see note 2 above.
    # certificate_ids  -> a Certificates Management OCID, i.e.
    #                     certificates-management's certificate_ids output.
    # certificate_name -> a classic oci_load_balancer_certificate, uploaded
    #                     PEM. The escape hatch for a publicly-trusted cert
    #                     that nobody wants to put through Certificates
    #                     Management (see certificates-management's README).
    certificate_ids                   = optional(string)
    certificate_name                  = optional(string)
    ssl_protocols                     = optional(list(string))
    cipher_suite_name                 = optional(string)
    verify_peer_certificate           = optional(bool)
    verify_depth                      = optional(number)
    trusted_certificate_authority_ids = optional(list(string))
    has_session_resumption            = optional(bool)

    # AWS caps idle_timeout at 4000s; OCI allows up to 7200s. 60s is OCI's
    # default for HTTP.
    idle_timeout_in_seconds = optional(number)

    # Routing. rule_set_names is how a redirect default action is reproduced.
    hostname_names      = optional(list(string), [])
    path_route_set_name = optional(string)
    routing_policy_name = optional(string)
    rule_set_names      = optional(list(string), [])
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, l in var.listeners : !(l.certificate_ids != null && l.certificate_name != null)
    ])
    error_message = "listeners[*] must set at most one of certificate_ids (Certificates Management OCID) and certificate_name (a classic uploaded oci_load_balancer_certificate) - they are two routes to the same ssl_configuration and OCI accepts only one."
  }

  validation {
    condition = alltrue([
      for k, l in var.listeners : contains(["HTTP", "HTTPS", "TCP"], l.protocol)
    ])
    error_message = "listeners[*].protocol must be HTTP, HTTPS or TCP. This module builds the L7 OCI Load Balancer; UDP and ICMP belong to the Network Load Balancer, which is deliberately not built - see main.tf."
  }
}

variable "hostnames" {
  description = "Map of hostname resource name to the virtual hostname it matches, for host-header routing on a shared listener. Referenced from listeners[*].hostname_names. The closest OCI has to AWS's host-based listener rules; whether it also resolves the one-certificate-per-listener limit is unverified."
  type        = map(string)
  default     = {}
}

variable "rule_sets" {
  description = <<-EOT
    Map of rule-set name to its items, referenced from
    listeners[*].rule_set_names.

    This is the mechanism that recovers AWS's `redirect` listener default
    action (load-balancer.md feature 3). A bare-HTTP-to-HTTPS redirect is:

      rule_sets = {
        redirect-to-https = {
          items = [{
            action        = "REDIRECT"
            response_code = 301
            conditions    = [{ attribute_name = "PATH", attribute_value = "/", operator = "FORCE_LONGEST_PREFIX_MATCH" }]
            redirect_uri  = { protocol = "HTTPS", host = "{host}", port = 443, path = "/{path}", query = "?{query}" }
          }]
        }
      }

    Kept as a generic passthrough rather than a purpose-built
    `redirect_to_https = true` flag, because the same resource also carries
    header manipulation and access control, and a single-purpose flag would
    have to be widened the first time anything else is needed.
  EOT

  type = map(object({
    items = list(object({
      action                         = string
      allowed_methods                = optional(list(string))
      are_invalid_characters_allowed = optional(bool)
      description                    = optional(string)
      header                         = optional(string)
      prefix                         = optional(string)
      response_code                  = optional(number)
      status_code                    = optional(number)
      suffix                         = optional(string)
      value                          = optional(string)

      conditions = optional(list(object({
        attribute_name  = string
        attribute_value = string
        operator        = optional(string)
      })), [])

      redirect_uri = optional(object({
        host     = optional(string)
        path     = optional(string)
        port     = optional(number)
        protocol = optional(string)
        query    = optional(string)
      }))
    }))
  }))

  default = {}
}

variable "certificates" {
  description = <<-EOT
    Classic PEM certificates uploaded directly to the load balancer, keyed by
    certificate_name and referenced from listeners[*].certificate_name.

    The second of the two TLS routes, and the honest one for a publicly-trusted
    certificate: OCI cannot issue one (see the certificates-management module),
    so a real public certificate always originates from an external ACME client
    or a purchased CA, and this uploads that PEM straight to the load balancer
    without a round trip through Certificates Management. Prefer
    certificate_ids where Certificates Management is already in play - one
    place to look, one place to alarm on expiry.

    Renewal is self-managed either way. There is no Oracle-side safety net.
  EOT

  type = map(object({
    public_certificate = string
    private_key        = optional(string)
    ca_certificate     = optional(string)
    passphrase         = optional(string)
  }))

  default = {}
}

# =============================================================================
# Lifecycle
# =============================================================================

variable "is_delete_protection_enabled" {
  description = "Direct counterpart of AWS's enable_deletion_protection (feature 9, FULL)."
  type        = bool
  default     = false
}

variable "is_request_id_enabled" {
  description = "Have the load balancer stamp a unique request id header on every request. No AWS counterpart in this module (the ALB emits x-amzn-trace-id unconditionally); additive."
  type        = bool
  default     = false
}

variable "request_id_header" {
  description = "Header name used when is_request_id_enabled is true. Null uses OCI's default (X-Request-Id)."
  type        = string
  default     = null
}
