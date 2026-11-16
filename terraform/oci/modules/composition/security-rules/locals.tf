# =========================================================================
# TRANSLATION LAYER
# =========================================================================
# Everything AWS-shaped on the way in becomes OCI-shaped here, so the live
# layer keeps one vocabulary across all three clouds.
# =========================================================================

locals {
  # -----------------------------------------------------------------------
  # Protocol names -> IANA numbers.
  #
  # RISK this table exists to close: OCI's `protocol` is an IANA number
  # STRING ("6", "17", "1", "58", "all"), not a name. A rule written with
  # protocol = "tcp" plans cleanly against the OCI API's string field and
  # produces a rule for IP protocol... nothing sane. Translating here, with a
  # variable `validation` rejecting unmapped names, is what keeps that from
  # being a silent semantic drift. Any "tcp" string reaching a plan is a bug.
  # -----------------------------------------------------------------------
  protocol_numbers = {
    "tcp"    = "6"
    "udp"    = "17"
    "icmp"   = "1"
    "icmpv6" = "58"
    "-1"     = "all" # AWS "all protocols" sentinel
    "all"    = "all"
  }

  # -----------------------------------------------------------------------
  # Service CIDR labels - the OCI replacement for AWS managed prefix lists.
  #
  # PARTIAL (sheet §4.2). AWS prefix lists are a general named-IP-set
  # abstraction with a customer-managed flavour; OCI has exactly the two
  # labels a service gateway exposes per region and no customer-managed
  # equivalent. Consequence, recorded at the point of divergence: an address
  # set shared across N rules (office IPs, VPN ranges, PSP ranges) cannot be
  # defined once on the platform - it is repeated as a `cidr` list and
  # expanded at plan time, so the OCI console shows N unrelated-looking rules
  # where AWS showed one prefix-list reference. Mitigated by the "n/m"
  # description suffix applied below.
  #
  # Discovered at plan time rather than hardcoded, which also retires the
  # hand-maintained per-region `s3_prefix_list_id` root local (pl-8da045e4,
  # pl-c3aa4faa).
  # -----------------------------------------------------------------------
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

  # -----------------------------------------------------------------------
  # Flatten + fan out.
  #
  # AWS: one `aws_security_group_rule` can carry a LIST of CIDRs.
  # OCI: `source` / `destination` is a single string, so an N-CIDR rule
  # becomes N resources (PARTIAL, sheet §4.1). The fan-out is done here, not
  # in the live layer, so the live rule set keeps `cidr = [...]` and ports
  # mechanically.
  #
  # The for_each key is "<target_nsg>_<sha256(rule identity)>_<sha256(target)>".
  #
  # DEVIATION from the check sheet's illustrative key
  # ("${nsg_id}_${sha256(jsonencode(rule))}_${idx}"), made to actually deliver
  # what §4.1 promises: "adding an office IP creates one resource and leaves
  # the other 116 untouched." Hashing the WHOLE rule object does not achieve
  # that, because the rule object contains the cidr list - so appending an
  # eleventh office IP rehashes the ten siblings and destroys and recreates
  # every one of them. Hashing only the rule's IDENTITY (description, ports,
  # protocol, selector kind) and keying the fan-out on the TARGET rather than
  # its list position makes appending, removing and reordering address-list
  # entries all touch exactly the entries that changed. Rule count is
  # unaffected; this is purely about churn.
  #
  # Rule EDITS (a port change, a protocol change) still change the key and so
  # are a destroy-then-create with a window where the allow does not exist.
  # That is AWS-equivalent, not a regression - but this applies to a live
  # payments network, so edits on the request path want a maintenance window
  # or an add-before-remove two-apply sequence.
  #
  # `all_ports` exists because OCI's port range is 1-65535 and rejects 0,
  # while AWS writes "all ports" as from_port = 0 / to_port = 65535. Omitting
  # the options block entirely is OCI's way of saying "all ports", so that is
  # what the sentinel maps to.
  # -----------------------------------------------------------------------
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
          # Ordinal-only suffix on fanned-out rules, so a ten-entry office-IP
          # list is legible as a group in the OCI console - the §4.2 mitigation
          # for losing AWS's customer-managed prefix lists. Deliberately NOT
          # "(n/m)": the total changes whenever the list grows, which would make
          # every sibling's description churn on an append. With the ordinal
          # alone, appending is a no-op for existing rules.
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
          # Ordinal-only suffix on fanned-out rules, so a ten-entry office-IP
          # list is legible as a group in the OCI console - the §4.2 mitigation
          # for losing AWS's customer-managed prefix lists. Deliberately NOT
          # "(n/m)": the total changes whenever the list grows, which would make
          # every sibling's description churn on an append. With the ordinal
          # alone, appending is a no-op for existing rules.
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

  # Total rules per NSG, counted against OCI's non-increasable 120/NSG ceiling.
  # NOTE: this counts only the rules THIS module creates. An NSG that also
  # carries rules from its owning module has less headroom than shown here.
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

  # A rule whose selector list is EMPTY (cidr = [], nsg_id = []) fans out to
  # zero resources. It fails closed - an allow that does not exist - but it does
  # so silently, and the usual cause is a stack that did not set `values.ip_list`.
  # Surfaced as a warning rather than an error so a wave-1 plan is not blocked by
  # a stack value that has not landed yet; see the check block in guards.tf.
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
  # `allowed_non_default_security_lists`. The data source backing the
  # non-default-list guard is enabled when the allowlist is non-empty.
  has_allowed_sl = length(var.allowed_non_default_security_lists) > 0

  # Default-security-list guard support - see guards.tf. The single data source
  # backs BOTH security-list guards (default-list-emptiness and the
  # allowed-non-default-list allowlist), so it is enabled when either is active.
  discovered_security_lists = (local.assert_default_sl || local.has_allowed_sl) ? data.oci_core_security_lists.vcn[0].security_lists : []

  default_security_list = [
    for sl in local.discovered_security_lists : sl if sl.id == var.default_security_list_id
  ]

  non_default_security_lists = [
    for sl in local.discovered_security_lists : sl if sl.id != var.default_security_list_id
  ]

  # Every non-default list must be a NAMED exception in the allowlist. A list is
  # allowed if it matches any entry by OCID (an owned list, e.g. vpc-network's
  # bastion) or by well-known display name (a service-created list, e.g. the OCI
  # Cache/Valkey service's `redis-security-list`). Anything discovered otherwise
  # is an unauthorized second/Nth non-default list - the fail-open the NSG-only
  # model (section 5) exists to surface.
  allowed_sl_ids = { for _k, v in var.allowed_non_default_security_lists : v.security_list_ocid => _k if v.security_list_ocid != null }

  allowed_sl_names = { for _k, v in var.allowed_non_default_security_lists : v.match_display_name => _k if v.match_display_name != null }

  unauthorized_non_default_security_lists = [
    for sl in local.non_default_security_lists : sl.display_name
    if !(contains(keys(local.allowed_sl_ids), sl.id) || contains(keys(local.allowed_sl_names), sl.display_name))
  ]

  # Per allowlisted list: does its ACTUAL ingress-rule count exceed its budget?
  # Bastion must carry 0 ingress (egress-only); Redis may carry only its single
  # service-port ingress. Any list over its budget is a guarded failure.
  #
  # Resolve each allowlist entry to the discovered list's display name (OCID
  # match -> that list's name; display-name match -> the same value), then read
  # its live ingress count. `try` defaults a not-yet-discovered list to 0 so an
  # absent exception is not treated as a violation.
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
