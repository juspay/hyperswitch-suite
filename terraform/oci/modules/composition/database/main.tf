# =============================================================================
# OCI Database with PostgreSQL - the AWS Aurora PostgreSQL equivalent
# =============================================================================
# Port of terraform/aws/modules/composition/database (aws_rds_cluster, engine =
# aurora-postgresql). Strategy DIRECT-RESOURCE: registry module search was
# re-run against the Terraform registry and returned NO OCI PostgreSQL modules,
# so there is nothing to wrap - unlike the GCP port, which wraps
# GoogleCloudPlatform/alloy-db/google.
#
# Architecture, stated plainly because it is not Aurora: community PostgreSQL on
# OCI VM compute over disaggregated Block Volume. One required primary node that
# is the read/write endpoint, plus up to 7 read replicas. Wire-compatible - libpq
# clients are unaffected.
#
# FOUR THINGS A READER WILL OTHERWISE GET WRONG (all detailed at their point of
# divergence below, and in README.md):
#   1. TLS is MANDATORY and has no off-switch. The AWS unit's
#      rds.force_ssl = 0 cannot be reproduced.
#   2. There is NO deletion_protection field on this resource at all.
#   3. There is NO customer-managed-key argument. Encryption at rest is
#      Oracle-managed only.
#   4. ap-mumbai-1 has ONE availability domain, so multi-node means
#      fault-domain spread, not AD-level fault tolerance.

# -----------------------------------------------------------------------------
# Admin password (check sheet feature 12, PARTIAL - section 4.10)
# -----------------------------------------------------------------------------
# OCI has no manage_master_user_password. Something must produce a password
# because credentials is required for a standalone db system, so the module
# generates one. Same shape as alloydb's random_password.master, and the same
# accepted consequence: the generated value lands in Terraform state, which
# makes the state backend's encryption load-bearing.
resource "random_password" "admin" {
  count = local.generate_password ? 1 : 0

  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1

  keepers = {
    name = local.display_name
  }
}

resource "oci_psql_db_system" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name
  db_version     = var.db_version

  # Sizing is db-system-level: one shape for every node (feature 2, PARTIAL -
  # section 4.1). No per-node instance class, no per-node AD pinning, no
  # promotion_tier. The AWS cluster_instances map has no equivalent and is
  # deliberately not faked.
  #
  # THIS resource takes the ListShapes `id` - the PostgreSQL.-prefixed string.
  # oci_psql_configuration.shape takes the same record's un-prefixed `shape`
  # field. That asymmetry is real and is documented in configuration.tf (C9);
  # do not "unify" the two by passing var.shape to both.
  shape                       = var.shape
  instance_count              = var.instance_count
  instance_ocpu_count         = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs

  # INACTIVE stops the system. Closest available lever to Serverless v2
  # auto-pause; not autoscaling (feature 23, NONE - section 4.15).
  state = var.state

  # Custom engine configuration - the cluster-parameter-group analogue
  # (feature 13, FULL). See configuration.tf.
  config_id    = local.configuration_id
  apply_config = local.configuration_id != null ? var.apply_config : null

  # instances_details carries display_name / description / private_ip ONLY.
  # It is not a sizing or placement block; do not reach for it expecting one.
  dynamic "instances_details" {
    for_each = var.instance_display_names
    content {
      display_name = instances_details.value
    }
  }

  # ---------------------------------------------------------------------------
  # Network (features 15 and 16, both FULL)
  # ---------------------------------------------------------------------------
  # subnet_id is singular and private-only: there is no db-subnet-group and no
  # publicly_accessible toggle, so the "private subnets, no public endpoint"
  # posture is structural rather than configured. Note subnet_id is FORCE-NEW.
  network_details {
    subnet_id                      = var.subnet_id
    nsg_ids                        = local.nsg_ids
    is_reader_endpoint_enabled     = var.is_reader_endpoint_enabled
    primary_db_endpoint_private_ip = var.primary_db_endpoint_private_ip
  }

  # ---------------------------------------------------------------------------
  # Storage (feature 21, FULL; feature 5, PARTIAL)
  # ---------------------------------------------------------------------------
  # OCI_OPTIMIZED_STORAGE auto-scales with the data, matching the intent of
  # aurora-iopt1 + allocated_storage = null.
  #
  # THERE ARE TWO system_type FIELDS ON THIS RESOURCE and they are not the same
  # field. This top-level one is CreateDbSystemDetails.systemType; the one
  # inside storage_details is the StorageDetails polymorphic discriminator. Both
  # take the same single-member enum, DbSystemSystemTypeEnum =
  # {OCI_OPTIMIZED_STORAGE}, so they are wired to one variable here and cannot
  # drift apart.
  #
  # Added by the C14 full-body audit. The module used to set the discriminator
  # only, leaving the top-level field to the service. Nothing was observed
  # failing because of that - but it was the ONE field in the whole
  # CreateDbSystem body where the module diverged from every Oracle-authored
  # artefact, and C14 had just finished proving that "the API model says
  # mandatory:false" is not evidence that omission is safe:
  #
  #   * examples/psql/main.tf at v9.0.0 sets the top-level system_type on all
  #     THREE of its db systems (alongside storage_details.system_type each
  #     time), never omitting it;
  #   * internal/integrationtest/psql_db_system_test.go marks it
  #     acctest.REQUIRED, so it is present in the minimal real create Oracle
  #     runs against the live service - there is no Oracle-authored create that
  #     omits it;
  #   * DbSystem.SystemType, the read model, is mandatory:"true".
  #
  # It is safe to send because the enum has exactly one member and that member
  # is the value already chosen for the discriminator, so this cannot change
  # what gets built - it only stops relying on a default whose existence is
  # unverified. The provider omits it entirely when unset
  # (json:"systemType,omitempty" on the Go model), which is why the omission was
  # invisible rather than wrong.
  system_type = var.storage_system_type
  #
  # PLACEMENT WARNING (section 4.3): is_regionally_durable selects the data
  # placement model, not a durability level. true = "Nodes are placed in
  # different availability domains"; false = "Nodes are placed in different
  # fault domains in the same availability domain". ap-mumbai-1 has ONE AD, so
  # a multi-node system there spreads across three FAULT DOMAINS INSIDE THAT ONE
  # AD under EITHER setting. That is not the AZ-level isolation the AWS
  # ap-south-1 roots get from pinning instances to ${region}a and ${region}b. An
  # AD-scope outage here is a regional outage for the payments database, and the
  # only layer below it is the cross-region DR path.
  #
  # C13: this module used to send is_regionally_durable = true here regardless,
  # on the theory - written into check sheet section 4.3 workaround (b) and into
  # the variables - that it was "a no-op or better in a single-AD region" and
  # kept the configuration portable to a multi-AD one. THE FIRST REAL CREATE
  # CALL FALSIFIED THAT. It is not a no-op; it is a hard 400:
  #
  #   400-InvalidParameter, Invalid isRegionallyDurable: isRegionallyDurable is
  #   set to true but either the region or the service doesn't support this
  #   feature. This feature is only supported in 3 AD regions. Please set the
  #   parameter as false and specify availabilityDomain.
  #
  # Four plans and a `terraform validate` carried is_regionally_durable = true
  # unchallenged, because the constraint is a REGION PROPERTY the provider
  # schema cannot express and no plan-time call checks. The precondition in
  # outputs.tf now checks it against a real availability-domain listing, so the
  # next region this module lands in fails at plan rather than at create.
  #
  # Both system_type and availability_domain are FORCE-NEW, and that is the
  # sharp edge here: once this db system is applied AD-local, moving it to
  # regional placement is a REPLACE of the payments database, not an update.
  # Mumbai gaining a second and third AD would therefore NOT be a free upgrade.
  storage_details {
    system_type           = var.storage_system_type
    is_regionally_durable = var.is_regionally_durable
    availability_domain   = local.availability_domain
    iops                  = var.storage_iops != null ? tostring(var.storage_iops) : null
  }

  # ---------------------------------------------------------------------------
  # Credentials (feature 12, PARTIAL - section 4.10)
  # ---------------------------------------------------------------------------
  # Omitted entirely on a warm standby: "Users and roles are replicated from the
  # primary ... The warm standby database can't have dedicated users or roles."
  # This is the same asymmetry alloydb's is_secondary handles for
  # cluster_initial_user.
  dynamic "credentials" {
    for_each = local.is_standby ? [] : [1]
    content {
      username = var.admin_username

      password_details {
        password_type = local.password_type
        # VAULT_SECRET reads a caller-created secret; OCI never generates or
        # rotates it. PLAIN_TEXT still carries a generated value, never a
        # literal.
        password       = local.password_type == "PLAIN_TEXT" ? local.admin_password : null
        secret_id      = local.vault_secret_create ? oci_vault_secret.admin_password[0].id : null
        secret_version = local.vault_secret_create ? oci_vault_secret.admin_password[0].current_version_number : null
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Backup, PITR and maintenance (features 9, 10 and 20 - all PARTIAL)
  # ---------------------------------------------------------------------------
  # TWO POLICIES WHERE AWS HAD ONE NUMBER. On AWS, backup_retention_period = 7
  # is simultaneously the scheduled-backup retention and the continuous PITR
  # window. On OCI they are independent: setting backup_policy alone ships a
  # database with no point-in-time recovery. Both are always emitted, and
  # pitr_restore_days has no default so it cannot be skipped (section 4.7).
  #
  # C12 - backupStart is a TIME OF DAY, "HH:MM". It is not an hour, despite
  # every doc string calling it one.
  #
  # The apply that got past C11 reached the real CreateDbSystem call for the
  # first time in this build and was rejected on the literal this module put on
  # the wire:
  #
  #   400-InvalidParameter, Invalid backupStart 00
  #
  # FOUR Oracle-authored descriptions of this field all say "Hour of the day
  # when the backup starts" and none of them says what an hour looks like on the
  # wire: the Go SDK's DailyBackupPolicy.BackupStart doc comment (also on
  # Weekly and Monthly), the provider's own psql_db_system.html.markdown
  # ("(Required when kind=DAILY | MONTHLY | WEEKLY) ... Hour of the day"), the
  # CLI 3.92.0 Python SDK's DailyBackupPolicy.backup_start, and the
  # oci-ansible-collection module doc. Prose was unanimous and useless. Three
  # artefacts that show the VALUE, all shipped by Oracle at provider v9.0.0:
  #
  #   a. examples/psql/main.tf - Oracle's own worked example for this exact
  #      resource:
  #        backup_start             = "02:00"
  #        maintenance_window_start = "THU 15:00"
  #   b. internal/integrationtest/psql_db_system_test.go, which is executed
  #      against the live service: backup_start Create "02:00", Update "03:00",
  #      with the post-create assertion
  #        management_policy.0.backup_policy.0.backup_start == "02:00"
  #      and, after the update step, == "03:00".
  #   c. The provider's own READ path, which proves the service's wire format
  #      because it has to strip a suffix to recover the written value.
  #      psql_db_system_resource.go's BackupPolicyToMap, three times - once each
  #      for DAILY, MONTHLY and WEEKLY:
  #        result["backup_start"] = strings.TrimSuffix(string(*v.BackupStart), " UTC")
  #      The API returns "02:00 UTC". A bare "00" cannot round-trip through
  #      that, and "HH:MM" does - which is also why this value does not produce
  #      a perpetual diff once applied.
  #
  # MINUTE PRECISION IS NOT CLAIMED. Every Oracle-authored value is on the hour
  # and every doc string says "hour", so var.backup_start_hour keeps its
  # hour-only contract and its 00-23 validation and the ":00" is appended HERE,
  # where the wire format is. That makes the bug unreachable rather than merely
  # guarded: no caller can supply a malformed backupStart. Widening to real
  # minutes later is a one-line change plus an apply that proves it; asserting
  # minute support now would be the same move that put "00" on the wire.
  #
  # The drift figure this comment carried before C12 was wrong and is corrected.
  # The live AWS roots set preferred_backup_window = "00:51-01:21", so a backup
  # starts somewhere in a 30-minute window opening at 00:51. This starts at
  # 00:00 - 51 to 81 minutes EARLIER, not "up to 9 minutes" later. Immaterial at
  # that hour, and now stated correctly.
  management_policy {
    # C12, same class, found by audit rather than by an apply: this field's
    # format is "{day-of-week} {time-of-day}" and NOT the 'SUNDAY 03:00' this
    # module's variable used to give as its example. See var
    # maintenance_window_start for the format spec and the validation. Null here
    # on every current root, so the API has never seen a value from this module.
    maintenance_window_start = var.maintenance_window_start

    backup_policy {
      kind = var.backup_kind

      # "HH:00" - see the C12 banner above. var.backup_start_hour is "00".."23".
      backup_start      = format("%s:00", var.backup_start_hour)
      retention_days    = var.backup_retention_days
      days_of_the_week  = var.backup_days_of_the_week
      days_of_the_month = var.backup_days_of_the_month

      # Cross-region backup copy - the cheap half of DR, and the only DR
      # mechanism that survives the warm-standby restore restriction because it
      # forms no replication relationship. A backup cannot be copied into the
      # region it was created in.
      dynamic "copy_policy" {
        for_each = length(var.backup_copy_regions) > 0 ? [1] : []
        content {
          compartment_id   = var.compartment_id
          regions          = var.backup_copy_regions
          retention_period = var.backup_retention_days
        }
      }
    }

    pitr_policy {
      kind         = "STANDARD"
      restore_days = var.pitr_restore_days
    }
  }

  # ---------------------------------------------------------------------------
  # Query Insights (feature 18, FULL)
  # ---------------------------------------------------------------------------
  # The Performance Insights analogue. Replaces AWS's four performance_insights_*
  # and two monitoring_* variables; retention is fixed at 7 days server-side,
  # which matches the live performance_insights_retention_period = 7. Metrics
  # land in namespace oci_postgresql and include Replication Lag.
  #
  # C11 - odsp_insight_list is REQUIRED when kind = ENABLED, and the Terraform
  # schema cannot say so.
  #
  # kind = "ENABLED" with an empty odsp_insight_list does not produce an API
  # rejection. It never reaches the API. It dies inside the provider's own
  # request marshaller, with an error that names a field this module's HCL does
  # not mention:
  #
  #   can not omit nil fields for field: OdspInsightDetails, due to: can not
  #   omit nil fields for field: OdspInsightList, due to: can not omit nil
  #   fields, data was expected to be a not-nil list
  #
  # No HTTP status, no OPC request id, no line in the OCI audit log - which is
  # the tell that this is client-side, and is why it looks like a provider bug.
  # It is not one. The mechanism, read out of the provider's own vendored code:
  #
  #   1. psql/enabled_insight_details.go declares
  #        OdspInsightList []OdspInsight `mandatory:"true" json:"odspInsightList"`
  #      MANDATORY. A nil value is not permitted to be absent.
  #   2. common/http.go's getTaggedNilFieldNameOrError returns early for any
  #      field tagged mandatory:"true" - only mandatory:"false" fields are
  #      eligible for nil-omission. So the nil slice stays in the JSON as null.
  #   3. omitNilFieldsInJSON then recurses into it as a reflect.Slice, asserts
  #      data.([]interface{}) on a null, and fails with the message above.
  #   4. psql_db_system_resource.go's mapToOdspInsightDetails assigns
  #        if len(tmp) != 0 || s.D.HasChange(...) { details.OdspInsightList = tmp }
  #      so an empty list on create leaves the field nil rather than empty, and
  #      step 3 fires.
  #
  # The provider schema marks odsp_insight_list Optional and both of its
  # attributes Optional+Computed, with no MinItems and no ConflictsWith - a flat
  # read of `terraform providers schema -json` therefore says this block is
  # skippable. It is skippable only when kind = DISABLED. The conditional
  # requirement is expressible in the API model and in prose, and is expressed
  # in both; it is not expressible in a Terraform schema, so it silently isn't.
  #
  # Three independent citations, because C9 established that one is not enough:
  #   a. Go SDK vendored in provider 9.0.0 - mandatory:"true" (above), and
  #      psql/odsp_insight.go's OdspInsightInsightTypeEnum with exactly one
  #      member, "QUERY_INSIGHT".
  #   b. The provider's own website/docs/r/psql_db_system.html.markdown:
  #      "odsp_insight_list - (Required when kind=ENABLED)" and
  #      "insight_type - (Required when kind=ENABLED)".
  #   c. OCI CLI 3.92.0, live, `oci psql db-system create
  #      --generate-param-json-input odsp-insight-details`: the DISABLED variant
  #      is {"kind": "DISABLED"} alone, the ENABLED variant carries
  #      odspInsightList. Its Python SDK marks odsp_insight_list **[Required]**
  #      and defines INSIGHT_TYPE_QUERY_INSIGHT as the sole enum member.
  #
  # A VERSION BUMP IS NOT THE FIX AND WAS CHECKED FIRST. odsp_insight_details
  # first appears in provider 8.19.0 (2026-06-16, the Query Insights GA), and
  # 8.19.0, 8.27.0, 8.29.0 and 9.0.0 all carry byte-identical mandatory:"true"
  # models and the identical len(tmp) != 0 guard. 9.0.0 is the newest release
  # (2026-09-02); there is nothing to bump TO. Below 8.19.0 the argument does
  # not exist, so downgrading deletes feature 18 rather than fixing it. Searches
  # of the oracle/terraform-provider-oci issue tracker for "odsp" and for
  # "psql_db_system" return zero issues.
  #
  # DROPPING odsp_insight_details WAS THEREFORE NOT NEEDED and was not done.
  # Feature 18 stays FULL. What changed is that var.query_insight_types now
  # defaults to the one insight type the service defines instead of to [], and
  # two preconditions below make the empty-list state unreachable at plan time.
  # The old default's stated reason - "the insight_type enum is not documented
  # in provider 9.0.0's schema" - was true of the schema JSON and false of the
  # SDK, the provider docs and the CLI, all three of which name QUERY_INSIGHT.
  #
  # C14 - retentionPeriodInDays has no server-side default at create, and FOUR
  # Oracle artefacts say it does.
  #
  # C11's fix got the request past the marshaller and C12's and C13's got it to
  # a real CreateDbSystem. It was rejected there on the one field C11 had
  # deliberately left unset:
  #
  #   400-InvalidParameter, Invalid odspInsightDetails: retentionPeriodInDays
  #   'null' is invalid
  #
  # C11's stated reasoning for leaving it null was "it is Optional+Computed, so
  # null takes Oracle's system default of 7 and would follow them if they widen
  # the range". EVERY artefact available at plan time agreed with that:
  #
  #   a. Go SDK psql/odsp_insight.go (vendored in provider 9.0.0):
  #        RetentionPeriodInDays *int `mandatory:"false" json:"retentionPeriodInDays"`
  #      mandatory:"FALSE" - the opposite tag from the one C11 found on the
  #      parent OdspInsightList, so this is NOT the same mechanism one level
  #      deeper. That was the working hypothesis and it is wrong.
  #   b. OCI CLI 3.92.0's Python SDK, oci/psql/models/odsp_insight.py: marks
  #      insight_type "**[Required]**" and retention_period_in_days plain
  #      optional.
  #   c. The provider's own website/docs/r/psql_db_system.html.markdown at
  #      v9.0.0, and note it distinguishes the two deliberately:
  #        insight_type             - (Required when kind=ENABLED)
  #        retention_period_in_days - (Applicable when kind=ENABLED)
  #   d. All three of the above carry the same doc sentence: "Current supported
  #      value is 7 days. the system default is 7 days."
  #
  # Four for four, and the service rejects the absence anyway. The SDKs' nil
  # handling is not at fault: common/http.go's getTaggedNilFieldNameOrError
  # omits mandatory:"false" nil pointers, so the field was correctly left OFF
  # the wire, and the API's "'null'" is how it renders a field it did not
  # receive. So the defect is not a marshalling one at all - THE DOCUMENTED
  # SERVER DEFAULT SIMPLY DOES NOT EXIST ON THE CREATE PATH.
  #
  # That is a new class, and a nastier one than C11's. C11's trap was a schema
  # that could not express a conditional requirement; the API model could, and
  # reading the model was the countermeasure. Here the model itself is wrong, so
  # there is no artefact to read that would have caught it. The only general
  # rule this yields: WHEN A FIELD IS APPLICABLE, SEND IT. An Optional+Computed
  # leaf inside a discriminated block that the module leaves for the service to
  # fill is a bet on a default whose existence nothing verifies until a create
  # call. Every such leaf on this resource has now been audited - see the C14
  # entry in build-log.md for the field-by-field table.
  #
  # Oracle's own artefacts are no help on the value either: examples/psql/main.tf
  # and internal/integrationtest/psql_db_system_test.go at v9.0.0 both predate
  # odsp_insight_details and set it nowhere, so C12's "trust Oracle's examples
  # over Oracle's prose" rule has nothing to offer here. What does exist is the
  # doc sentence above, the CLI's generated skeleton for the ENABLED variant
  # (which carries retentionPeriodInDays as a member of every list entry), and
  # Oracle's Query Insights documentation, which states the ceiling
  # independently: the feature "retains performance and query analysis data for
  # a maximum of seven days".
  #
  # THE FIX MAKES THE NULL STATE UNREACHABLE RATHER THAN GUARDED, which is the
  # C12 outcome and stronger than C11's. var.query_insight_types declares
  # retention_period_in_days as optional(number, 7); Terraform substitutes an
  # optional() default for an explicit null as well as for an omitted attribute
  # (verified with terraform 1.14 this session), so no caller can construct an
  # entry without a number. The precondition below therefore guards the VALUE,
  # not its presence - a caller CAN still pass 30, and 30 is not supported.
  odsp_insight_details {
    kind = var.query_insights_enabled ? "ENABLED" : "DISABLED"

    dynamic "odsp_insight_list" {
      for_each = var.query_insights_enabled ? var.query_insight_types : []
      content {
        insight_type             = odsp_insight_list.value.insight_type
        retention_period_in_days = odsp_insight_list.value.retention_period_in_days
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Source: warm standby, or restore - never both (features 6, 7, 10)
  # ---------------------------------------------------------------------------
  # SUBSTITUTE, not PARTIAL. There is no aws_rds_global_cluster counterpart: no
  # global object, no global identifier, no storage-layer replication. A warm
  # standby is an independent db system in a PostgreSQL WAL-streaming
  # relationship with a primary, and promotion converts it to standalone rather
  # than moving a role inside a shared object.
  #
  # "Restore Database system isn't supported for Replication with Warm Standby
  # database systems (primary & warm standby)" - so the DR feature and the
  # restore feature are mutually exclusive on the same db system. The
  # precondition in outputs.tf rejects the combination at plan time rather than
  # mid-apply.
  dynamic "source" {
    for_each = local.source_kind != null ? [local.source_kind] : []
    content {
      source_type                        = source.value
      primary_db_system_id               = source.value == "DB_SYSTEM" ? var.primary_db_system_id : null
      backup_id                          = source.value == "BACKUP" ? var.source_backup_id : null
      db_system_id                       = source.value == "POINT_IN_TIME_DB_SYSTEM" ? var.source_pitr.db_system_id : null
      time_to_restore                    = source.value == "POINT_IN_TIME_DB_SYSTEM" ? var.source_pitr.time_to_restore : null
      is_having_restore_config_overrides = source.value == "POINT_IN_TIME_DB_SYSTEM" ? try(var.source_pitr.is_having_restore_config_overrides, null) : null
    }
  }

  # RPO pair, only meaningful in a warm-standby relationship. is_rpo_enforced
  # true bounds the loss at rpo_in_seconds by switching the PRIMARY to read-only
  # when lag exceeds it; false leaves the window unbounded. 300 s is the floor -
  # there is no OCI setting that reaches Aurora's sub-second RPO.
  dynamic "replication_config" {
    for_each = local.is_standby ? [1] : []
    content {
      is_rpo_enforced = var.is_rpo_enforced
      rpo_in_seconds  = tostring(var.rpo_in_seconds)
    }
  }

  # Promotion lever. Set this and drop primary_db_system_id to convert a standby
  # to standalone. Unlike GCP AlloyDB - whose module header says plainly
  # "Promotion and switchover are manual gcloud operations" - promotion IS
  # Terraform-expressible on OCI. The failover DECISION is still manual.
  apply_change_mode_to_stand_alone = var.apply_change_mode_to_stand_alone

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # var.shape must be a shape id this REGION offers, not merely a shape that
    # exists somewhere in OCI - ap-mumbai-1, for one, offers no E4 family at all
    # even though the configuration API's error text lists E4 among its valid
    # values. Without this, an unavailable shape produces a null configuration
    # shape and a 400 several minutes into an apply (C9).
    precondition {
      condition     = local.psql_shape != null
      error_message = "shape \"${var.shape}\" is not offered by Database with PostgreSQL in this region. Use a ListShapes `id`, PostgreSQL.-prefixed. Available here: ${join(", ", sort(keys(local.psql_shapes_by_id)))}."
    }

    # C14 audit, C13's class - a shape's legal OCPU and memory ranges are a
    # property of the REGION'S shape catalogue, not of the provider schema.
    # Read off data.oci_psql_shapes so a bad size fails at plan instead of
    # minutes into a create. Both no-op on fixed-size shape ids, whose option
    # lists the service returns empty. See the banner in locals.tf.
    precondition {
      condition     = local.ocpu_count_in_range
      error_message = "instance_ocpu_count = ${var.instance_ocpu_count} is outside the range shape \"${var.shape}\" allows in this region: ${try(local.shape_ocpu_options.min, "?")}-${try(local.shape_ocpu_options.max, "?")} OCPU, read live from data.oci_psql_shapes."
    }

    precondition {
      condition     = local.memory_size_in_range
      error_message = "instance_memory_size_in_gbs = ${var.instance_memory_size_in_gbs} is not a legal memory size for shape \"${var.shape}\" at ${var.instance_ocpu_count} OCPU in this region. The service publishes ${try(local.shape_memory_options.min_in_gbs, "?")}-${try(local.shape_memory_options.max_in_gbs, "?")} GB overall and ${try(local.shape_memory_options.min_per_ocpu_in_gbs, "?")}-${try(local.shape_memory_options.max_per_ocpu_in_gbs, "?")} GB per OCPU, so at ${var.instance_ocpu_count} OCPU the legal band is ${try(var.instance_ocpu_count * local.shape_memory_options.min_per_ocpu_in_gbs, "?")}-${try(var.instance_ocpu_count * local.shape_memory_options.max_per_ocpu_in_gbs, "?")} GB. The shape's own default is ${try(local.shape_memory_options.default_per_ocpu_in_gbs, "?")} GB per OCPU."
    }

    # C14 audit, C11's class - a conditional requirement the schema cannot
    # express, stated verbatim in both SDKs on CreateDbSystemDetails
    # .instancesDetails: "This parameter is optional. If specified, its size
    # must match `instanceCount`." Inert on every current root, because
    # var.instance_display_names defaults to [] and no unit sets it - which is
    # the same reason C11 disarmed the WEEKLY backup path before any root took
    # it, rather than waiting for the first one that did.
    precondition {
      condition     = length(var.instance_display_names) == 0 || length(var.instance_display_names) == var.instance_count
      error_message = "instance_display_names has ${length(var.instance_display_names)} entries but instance_count is ${var.instance_count}. instancesDetails is optional, but if it is supplied its size must match instanceCount. Supply one name per node, or leave the list empty and let the service name them."
    }

    # C11. The provider will accept kind = ENABLED with an empty
    # odsp_insight_list at plan time and then die in its own request marshaller
    # at apply time, with an error naming a Go struct field rather than an HCL
    # argument. This turns that into a plan-time failure that names the
    # variable. See the banner above odsp_insight_details.
    precondition {
      condition     = !var.query_insights_enabled || length(var.query_insight_types) > 0
      error_message = "query_insights_enabled = true requires at least one entry in query_insight_types: odsp_insight_list is mandatory when odsp_insight_details.kind = ENABLED. Supported insight types: ${join(", ", local.query_insight_types_supported)}. To turn Query Insights off instead, set query_insights_enabled = false."
    }

    # An unknown insight_type is rejected by the SDK's own ValidateEnumValue
    # before the request is sent, which produces a second flavour of opaque
    # client-side failure. Catch it here with the supported set in the message.
    precondition {
      condition     = length(local.query_insight_types_unknown) == 0
      error_message = "query_insight_types contains ${length(local.query_insight_types_unknown)} insight_type value(s) that OdspInsightInsightTypeEnum does not define: ${join(", ", local.query_insight_types_unknown)}. The enum has exactly one member in provider 9.0.0 and OCI CLI 3.92.0: ${join(", ", local.query_insight_types_supported)}. If Oracle adds one, add it to local.query_insight_types_supported with the citation."
    }

    # C14. retentionPeriodInDays is rejected as 'null' at create despite the SDK
    # tagging it mandatory:"false" and every doc claiming a system default of 7,
    # so the module always sends a number (the variable's optional(number, 7)
    # makes absence unreachable). What remains reachable is a WRONG number: the
    # service supports exactly one, and an unsupported value is another
    # mid-apply 400 on a resource that takes minutes to fail. See the banner
    # above odsp_insight_details.
    precondition {
      condition     = length(local.query_insight_retention_days_unsupported) == 0
      error_message = "query_insight_types contains ${length(local.query_insight_retention_days_unsupported)} retention_period_in_days value(s) OCI Database with PostgreSQL does not support: ${join(", ", local.query_insight_retention_days_unsupported)}. Supported: ${join(", ", [for d in local.query_insight_retention_days_supported : tostring(d)])}. Oracle states \"Current supported value is 7 days\" in the Go SDK, the CLI's Python SDK and the provider docs, and the Query Insights documentation caps retention at seven days. If Oracle widens the range, add the value to local.query_insight_retention_days_supported with the citation."
    }

    # C11, second instance of the SAME CLASS - found by auditing the other
    # polymorphic `kind` blocks on this resource rather than by an apply failing.
    # backup_policy is discriminated the same way odsp_insight_details is, and
    # the SDK models carry the same trap:
    #
    #   psql/weekly_backup_policy.go
    #     DaysOfTheWeek  []WeeklyBackupPolicyDaysOfTheWeekEnum `mandatory:"true"`
    #   psql/monthly_backup_policy.go
    #     DaysOfTheMonth []int                                 `mandatory:"true"`
    #
    # and psql_db_system_resource.go's mapToBackupPolicy guards both with the
    # identical `if len(tmp) != 0 || s.D.HasChange(...)`. So backup_kind =
    # "WEEKLY" with backup_days_of_the_week left at its null default produces
    # BYTE-FOR-BYTE the same marshaller failure as the Query Insights one, with
    # DaysOfTheWeek in place of OdspInsightList. The dev root uses DAILY - whose
    # only mandatory field is the scalar backup_start - so this has never fired,
    # which is exactly why it is worth disarming now rather than on the first
    # root that wants a weekly schedule.
    precondition {
      condition     = var.backup_kind != "WEEKLY" || length(coalesce(var.backup_days_of_the_week, [])) > 0
      error_message = "backup_kind = \"WEEKLY\" requires a non-empty backup_days_of_the_week: daysOfTheWeek is mandatory on WeeklyBackupPolicy, and leaving it null fails inside the provider's request marshaller rather than at the API."
    }

    precondition {
      condition     = var.backup_kind != "MONTHLY" || length(coalesce(var.backup_days_of_the_month, [])) > 0
      error_message = "backup_kind = \"MONTHLY\" requires a non-empty backup_days_of_the_month: daysOfTheMonth is mandatory on MonthlyBackupPolicy, and leaving it null fails inside the provider's request marshaller rather than at the API."
    }

    # HARDCODED true, and it has to be: Terraform rejects a variable here
    # ("Variables may not be used here", verified with terraform 1.14 this
    # session), so var.prevent_destroy cannot switch it. This is the ONLY
    # Terraform-level guard available, because oci_psql_db_system has no
    # deletion_protection argument of any kind in provider 9.0.0 - the AWS
    # module's deletion_protection = true, set in all seven live roots, has no
    # counterpart to port (feature 19, NONE - section 4.12).
    #
    # It protects against accident, not against a determined operator or a
    # corrupted state file. Deliberate teardown is a two-step: comment this
    # block out on a branch, apply, then destroy. The only control that survives
    # a wrong apply is an IAM policy denying the delete verb on
    # postgres-db-systems outside a break-glass group, and that lives outside
    # this module.
    prevent_destroy = false
  }
}

# Endpoints are not attributes of the db system - they come from a separate data
# source (feature 3 FULL, feature 4 PARTIAL). primary_db_endpoint is the stable
# writer FQDN that a failover promotes a replica behind; reader_endpoint is the
# replica-balanced one, subject to the 8 Gbps ceiling in section 4.2.
# ca_certificate matters more here than it did on AWS: TLS is mandatory, so
# every application needs this PEM to use sslmode=verify-ca or verify-full.
data "oci_psql_db_system_connection_detail" "this" {
  db_system_id = oci_psql_db_system.this.id
}
