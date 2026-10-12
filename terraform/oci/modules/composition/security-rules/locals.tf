# Translation layer: AWS-shaped inputs become OCI-shaped here.
locals {
  # Protocol names -> IANA numbers. OCI's `protocol` is an IANA number STRING
  # ("6", "17", ...), not a name; translating here, with variable validation
  # rejecting unmapped names, stops a "tcp" value silently becoming a wrong rule.
  protocol_numbers = {
    "tcp"    = "6"
    "udp"    = "17"
    "icmp"   = "1"
    "icmpv6" = "58"
    "-1"     = "all" # AWS "all protocols" sentinel
    "all"    = "all"
  }

  # Service CIDR labels - the OCI replacement for AWS managed prefix lists.
  # OCI exposes exactly the two service-gateway labels per region, no
  # customer-managed named-IP-set, so shared address sets must be repeated as
  # `cidr` lists and expanded at plan time. Discovered at plan time rather
  # than hardcoded, which retires the hand-maintained per-region
  # `s3_prefix_list_id`.
  objectstorage_service_cidrs = [
    for s in data.oci_core_services.available.services :
    s.cidr_block if endswith(s.cidr_block, "-objectstorage")
  ]

  all_services_cidrs = [
    for s in data.oci_core_services.available.services :
    s.cidr_block if endswith(s.cidr_block, "-services-in-oracle-services-network")
  ]

  service_cidr_blocks = merge(
    length(local.objectstorage_service_cidrs) > 0 ? { "objectstorage" = local.objectstorage_service_cidrs[0] } : {},
    length(local.all_services_cidrs) > 0 ? { "all-services" = local.all_services_cidrs[0] } : {},
  )

  # Flatten + fan out. OCI's `source`/`destination` is a single string, so an
  # N-CIDR rule fans out into N resources here, keeping the live `cidr` list.
  # The for_each key hashes a rule's IDENTITY (description, ports, protocol,
  # selector kind) + target, not the whole rule object, so appending/removing/
  # reordering address-list entries touches only the entries that changed.
  # Rule EDITS (port/protocol change) still change the key and are a
  # destroy-then-create with a window where the allow does not exist - runs on
  # a live payments network, so edits on the request path want a maintenance
  # window or an add-before-remove two-apply sequence.
  # `all_ports` exists because OCI's port range is 1-65535 and rejects 0 while
  # AWS writes "all ports" as from_port=0/to_port=65535; omitting the options
  # block is OCI's way of saying "all ports".
  ingress_flat_list = flatten([
    for group_name, group in var.ingress_rules : [
      for rule in group.rules : [
        for idx, target in(
          rule.cidr != null ? rule.cidr :
          rule.nsg_id != null ? rule.nsg_id :
          [rule.service_cidr_label]
          ) : {
          key = "${group.nsg_id}_${sha256(jsonencode({
            description = rule.description
            from_port   = rule.from_port
            to_port     = rule.to_port
            protocol    = rule.protocol
            selector    = rule.cidr != null ? "cidr" : (rule.nsg_id != null ? "nsg" : "service")
          }))}_${substr(sha256(target), 0, 12)}"
          component   = group_name
          nsg_id      = group.nsg_id
          protocol    = local.protocol_numbers[rule.protocol]
          from_port   = rule.from_port
          to_port     = rule.to_port
          all_ports   = rule.from_port <= 0 && rule.to_port >= 65535
          target_type = rule.cidr != null ? "CIDR_BLOCK" : (rule.nsg_id != null ? "NETWORK_SECURITY_GROUP" : "SERVICE_CIDR_BLOCK")
          target = (
            rule.cidr != null || rule.nsg_id != null
            ? target
            : lookup(local.service_cidr_blocks, target, "UNRESOLVED_SERVICE_CIDR_LABEL:${target}")
          )
          fanout_index = idx
          fanout_total = rule.cidr != null ? length(rule.cidr) : (rule.nsg_id != null ? length(rule.nsg_id) : 1)
          # Ordinal-only suffix on fanned-out rules so an address list reads as a
          # group in the console; deliberately NOT "(n/m)" so appends don't churn
          # every sibling's description.
          description = (
            (rule.cidr != null ? length(rule.cidr) : (rule.nsg_id != null ? length(rule.nsg_id) : 1)) > 1
            ? "${rule.description} (${idx + 1})"
            : rule.description
          )
        }
      ]
    ]
  ])

  egress_flat_list = flatten([
    for group_name, group in var.egress_rules : [
      for rule in group.rules : [
        for idx, target in(
          rule.cidr != null ? rule.cidr :
          rule.nsg_id != null ? rule.nsg_id :
          [rule.service_cidr_label]
          ) : {
          key = "${group.nsg_id}_${sha256(jsonencode({
            description = rule.description
            from_port   = rule.from_port
            to_port     = rule.to_port
            protocol    = rule.protocol
            selector    = rule.cidr != null ? "cidr" : (rule.nsg_id != null ? "nsg" : "service")
          }))}_${substr(sha256(target), 0, 12)}"
          component   = group_name
          nsg_id      = group.nsg_id
          protocol    = local.protocol_numbers[rule.protocol]
          from_port   = rule.from_port
          to_port     = rule.to_port
          all_ports   = rule.from_port <= 0 && rule.to_port >= 65535
          target_type = rule.cidr != null ? "CIDR_BLOCK" : (rule.nsg_id != null ? "NETWORK_SECURITY_GROUP" : "SERVICE_CIDR_BLOCK")
          target = (
            rule.cidr != null || rule.nsg_id != null
            ? target
            : lookup(local.service_cidr_blocks, target, "UNRESOLVED_SERVICE_CIDR_LABEL:${target}")
          )
          fanout_index = idx
          fanout_total = rule.cidr != null ? length(rule.cidr) : (rule.nsg_id != null ? length(rule.nsg_id) : 1)
          # Ordinal-only suffix on fanned-out rules so an address list reads as a
          # group in the console; deliberately NOT "(n/m)" so appends don't churn
          # every sibling's description.
          description = (
            (rule.cidr != null ? length(rule.cidr) : (rule.nsg_id != null ? length(rule.nsg_id) : 1)) > 1
            ? "${rule.description} (${idx + 1})"
            : rule.description
          )
        }
      ]
    ]
  ])

  ingress_rules_flat = { for r in local.ingress_flat_list : r.key => r }
  egress_rules_flat  = { for r in local.egress_flat_list : r.key => r }

  all_rules_flat = concat(local.ingress_flat_list, local.egress_flat_list)

  # Every NSG this module writes into, from either direction.
  target_nsg_ids = distinct([for r in local.all_rules_flat : r.nsg_id])

  # Total rules per NSG against OCI's non-increasable 120/NSG ceiling. NOTE:
  # this counts only THIS module's rules; an NSG that also carries rules from
  # its owning module has less headroom than shown here.
  rules_by_nsg = {
    for nsg in local.target_nsg_ids :
    nsg => length([for r in local.all_rules_flat : r.key if r.nsg_id == nsg])
  }

  nsgs_over_rule_limit = [
    for nsg, count in local.rules_by_nsg : nsg if count > var.nsg_rule_limit
  ]

  unresolved_service_labels = distinct([
    for r in local.all_rules_flat : r.target
    if startswith(r.target, "UNRESOLVED_SERVICE_CIDR_LABEL:")
  ])

  # A rule with an EMPTY selector list (cidr = [], nsg_id = []) fans out to zero
  # resources - an allow that quietly does not exist. Fails closed, so surfaced
  # as a warning (check block in guards.tf) rather than an error.
  empty_selector_rules = concat(
    flatten([
      for gname, g in var.ingress_rules : [
        for r in g.rules : "ingress/${gname}/${r.description}"
        if(r.cidr != null && length(coalesce(r.cidr, [])) == 0) || (r.nsg_id != null && length(coalesce(r.nsg_id, [])) == 0)
      ]
    ]),
    flatten([
      for gname, g in var.egress_rules : [
        for r in g.rules : "egress/${gname}/${r.description}"
        if(r.cidr != null && length(coalesce(r.cidr, [])) == 0) || (r.nsg_id != null && length(coalesce(r.nsg_id, [])) == 0)
      ]
    ]),
  )

  has_service_cidr_rules = length([
    for r in local.all_rules_flat : r.key if r.target_type == "SERVICE_CIDR_BLOCK"
  ]) > 0

  assert_default_sl = var.assert_default_security_list_empty && var.default_security_list_id != null

  # The named exceptions to the NSG-only model - see variables.tf
  # `allowed_non_default_security_lists`. Enables the non-default-list guard.
  has_allowed_sl = length(var.allowed_non_default_security_lists) > 0

  # Guard support - see guards.tf. The single data source backs BOTH
  # security-list guards, so it is enabled when either is active.
  discovered_security_lists = (local.assert_default_sl || local.has_allowed_sl) ? data.oci_core_security_lists.vcn[0].security_lists : []

  default_security_list = [
    for sl in local.discovered_security_lists : sl if sl.id == var.default_security_list_id
  ]

  non_default_security_lists = [
    for sl in local.discovered_security_lists : sl if sl.id != var.default_security_list_id
  ]

  # Every non-default list must be a NAMED exception in the allowlist - matched
  # by OCID (an owned list, e.g. vpc-network's bastion) or by well-known display
  # name (a service-created list, e.g. the OCI Cache service's `redis-security-list`).
  # Anything discovered otherwise is an unauthorized fail-open the NSG-only model surfaces.
  allowed_sl_ids = { for _k, v in var.allowed_non_default_security_lists : v.security_list_ocid => _k if v.security_list_ocid != null }

  allowed_sl_names = { for _k, v in var.allowed_non_default_security_lists : v.match_display_name => _k if v.match_display_name != null }

  unauthorized_non_default_security_lists = [
    for sl in local.non_default_security_lists : sl.display_name
    if !(contains(keys(local.allowed_sl_ids), sl.id) || contains(keys(local.allowed_sl_names), sl.display_name))
  ]

  # Per allowlisted list: does its ACTUAL ingress-rule count exceed its budget?
  # Bastion must carry 0 ingress; Redis only its single service-port ingress.
  # `try` defaults a not-yet-discovered list to 0 so an absent exception is not
  # treated as a violation.
  allowed_sl_display_name = {
    for k, v in var.allowed_non_default_security_lists :
    k => (
      v.security_list_ocid != null
      ? lookup({ for s in local.discovered_security_lists : s.id => s.display_name }, v.security_list_ocid, v.match_display_name)
      : v.match_display_name
    )
  }

  allowed_sl_actual_ingress = {
    for k, v in var.allowed_non_default_security_lists :
    k => try(length([
      for sl in local.discovered_security_lists :
      sl if sl.id == (v.security_list_ocid != null ? v.security_list_ocid : "") || sl.display_name == v.match_display_name
    ][0].ingress_security_rules), 0)
  }

  allowed_sl_ingress_violations = compact([
    for k, v in var.allowed_non_default_security_lists :
    (local.allowed_sl_actual_ingress[k] > v.max_ingress_rules
      ? "${k} (${local.allowed_sl_display_name[k]}) has ${local.allowed_sl_actual_ingress[k]} ingress rules (max ${v.max_ingress_rules})"
    : "")
  ])
}
