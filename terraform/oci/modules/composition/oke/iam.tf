# =============================================================================
# oke - identity (AWS features 3, 5, 17)
# =============================================================================
# This file intentionally declares NO resources. It exists so the identity
# decisions are findable at the point a reader looks for them, rather than
# only in a check sheet in the other repository.
#
# -----------------------------------------------------------------------------
# Feature 3 - cluster IAM role: SUBSTITUTE, owned elsewhere (gap 4.1)
# -----------------------------------------------------------------------------
# AWS: `aws_iam_role.cluster` + `aws_iam_policy.cluster_custom` + attachments -
# a role EKS assumes to call EC2/ELB on your behalf.
# OCI: no assumable cluster role exists. The control plane's cross-service
# permissions are compartment- or tenancy-scoped `oci_identity_policy`
# statements written against the `oke` SERVICE PRINCIPAL
# (`allow service oke to ... in compartment ...`), applied once for the tenancy
# rather than once per cluster. The registry module has no
# `create_iam_cluster_policy` toggle - contrast its `create_iam_operator_policy`,
# `create_iam_worker_policy`, `create_iam_autoscaler_policy`,
# `create_iam_karpenter_policy` and `create_iam_kms_policy`, all of which exist.
#
# Therefore: authored in the phase-0 compartment/IAM bootstrap
# (master-checksheet.md P5), not here. Two statements that bootstrap must carry
# for this module's configuration specifically:
#   - `manage network-security-groups` for `request.principal.type = 'cluster'`,
#     which OKE needs to manage service load-balancer backend NSGs;
#   - if `cluster_kms_key_id` is set, `use keys ... where target.key.id = <ocid>`
#     for the cluster's dynamic group.
#
# -----------------------------------------------------------------------------
# Feature 17 - node-group IAM role: SUBSTITUTE, mostly absent (gap 4.6)
# -----------------------------------------------------------------------------
# AWS: `aws_iam_role.node_group` with managed + custom policies attached, shared
# by every node group.
# OCI: instance permissions come from DYNAMIC GROUP membership (a matching rule
# over instance OCIDs or tags) plus a policy written against that group; there
# is no role object to attach a policy list to. For OKE-MANAGED node pools -
# which is what `worker_pool_mode = "node-pool"` produces - the baseline (join
# cluster, pull images, attach volumes) comes from the service and needs no
# dynamic group at all; the registry module's `create_iam_worker_policy = "auto"`
# only fires for self-managed workers.
#
# What that means for the AWS `node_group_custom_policy_json` in use today
# (observability actions plus an ECR pull-through-cache grant): those must be
# re-expressed as statements against a worker dynamic group in the IAM
# bootstrap. OPEN QUESTION carried from eks.md section 9 item 1: whether OCIR
# has a pull-through-cache equivalent to grant at all is unverified.
#
# NOTE the distinction, because conflating them is a real trap: this dynamic
# group is INFRASTRUCTURE identity (the node VM). It is a different OCI
# primitive from OKE Workload Identity, which is what identity-model.md picks
# for POD identity, and Oracle documents that the two are mutually exclusive:
# "You cannot currently use workload identities with dynamic groups."
#
# -----------------------------------------------------------------------------
# Feature 5 - cross-account CI/CD administration: PENDING ORACLE GATE (gap 4.3)
# -----------------------------------------------------------------------------
# AWS: `aws_iam_role.cross_account` whose trust policy admits ArgoCD's and
# Atlantis's role ARNs from the management account, so cross-account CI/CD can
# administer this cluster.
# OCI: no counterpart. IAM policies and dynamic groups are tenancy-scoped and
# there is no AssumeRole-across-accounts primitive. Two candidate mechanisms,
# architecturally different from each other:
#   (a) if the management cluster relocates to OCI, this collapses to a
#       same-tenancy dynamic group + policy (trivial);
#   (b) if it stays on AWS, OIDC federation via the cluster's
#       `oidc_token_authentication_config` is the only documented path found,
#       and it needs its own validation before a payments platform's CI/CD
#       access path is built on it.
# The choice depends on a decision outside this module's scope. It is an
# oracle-gate item (framework.md 4.4; eks.md section 8 item 3) and is NOT
# guessed here. `var.create_cross_account_admin_access` is kept as a
# named-but-unimplemented input that hard-errors if set, so the gap stays
# visible instead of quietly disappearing from the input surface.
#
# -----------------------------------------------------------------------------
# Feature 4 - cluster access entries: SUBSTITUTE, split across two modules
# -----------------------------------------------------------------------------
# AWS's EKS Access Entries API expresses "this principal gets
# AmazonEKSClusterAdminPolicy" as one API object. OCI needs two layers, both
# hand-authored: an `oci_identity_policy` gating whether the principal may call
# the OKE control-plane API at all, and a native Kubernetes
# ClusterRoleBinding/RoleBinding naming the IAM group's OCID as subject. There
# is no managed ClusterAdmin/View/Edit policy bundle to reference.
# Per gap 4.2 the seam is: IAM half in the IAM bootstrap, RBAC half in
# `oke-kubernetes-resources` (via a `cluster_access_bindings` variable). Neither
# half belongs here, and this module deliberately exposes no
# `cluster_access_entries` analogue rather than implementing half of one.
#
# -----------------------------------------------------------------------------
# VERIFIED BLOCKER, 2026-09-03: the tenancy OKE service policy is missing
# -----------------------------------------------------------------------------
# Measured against the real account while validating this module, not inferred.
#
#   $ oci ce cluster-options get --cluster-option-id all
#     -> succeeds (control-plane versions v1.33.0 ... v1.36.1)
#
#   $ oci ce node-pool-options get --node-pool-option-id all
#     -> 400 RelatedResourceNotAuthorizedOrNotFound
#        "Unable to retrieve required tenancy details - please ensure OKE
#         service policy is set up correctly."
#
# The Terraform data source `oci_containerengine_node_pool_option` does not
# surface that error - it reads "successfully" and returns an EMPTY image set.
# The failure therefore appears far from its cause, as
#
#   Error: Invalid function argument, modules/workers/locals.tf line 129
#   setintersection(...): argument must not be null
#
# during the registry module's OKE image lookup. Symptom, cause and remedy are
# recorded here so the next person does not spend the debug cycle.
#
# Remedy (phase-0 IAM bootstrap, tenancy root compartment):
#   Allow service OKE to manage all-resources in tenancy
# or the narrower per-service statements Oracle documents for OKE.
#
# Workaround until that policy exists: set `image_type = "custom"` and an
# explicit `image_id` on every entry of `var.node_pools`. Verified to plan
# cleanly - the image lookup is the only thing the missing policy breaks.
