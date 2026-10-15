# =========================================================================
# State migration: count -> for_each on the replication IAM resources
# =========================================================================
# The single replication role/policy moved from a count index [0] to the
# for_each key "fwd" (the source -> replica direction). These moved blocks keep
# existing one-way deployments from destroying and recreating the role/policy on
# upgrade; the forward role name is unchanged, so this is a pure state rename.
#
# (The aws_iam_policy_document data sources also changed from count to for_each,
# but data sources are re-read every plan and have no persisted state to migrate,
# so they need no moved blocks.)
moved {
  from = aws_iam_role.replication[0]
  to   = aws_iam_role.replication["fwd"]
}

moved {
  from = aws_iam_role_policy.replication[0]
  to   = aws_iam_role_policy.replication["fwd"]
}
