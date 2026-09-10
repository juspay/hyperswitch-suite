# Spanner access is entirely IAM - there is no bootstrap user to hand a
# password to, so these grants ARE the authentication story.
#
# The role an application needs to read and write is
# roles/spanner.databaseUser, granted on the database. PGAdapter needs exactly
# the same role: it authenticates as its own service account and proxies the
# client's SQL, so the grant belongs to PGAdapter's identity, not the app's.
#
# Both are non-authoritative *_iam_member resources: each adds one binding and
# leaves bindings made elsewhere alone. An authoritative *_iam_policy here
# would silently strip grants made by other units or by hand.

resource "google_spanner_instance_iam_member" "this" {
  for_each = {
    for m in var.instance_iam_members : "${m.role} ${m.member}" => m
  }

  project  = var.project_id
  instance = google_spanner_instance.this.name
  role     = each.value.role
  member   = each.value.member
}

resource "google_spanner_database_iam_member" "this" {
  for_each = {
    for m in var.database_iam_members : "${m.database} ${m.role} ${m.member}" => m
  }

  project  = var.project_id
  instance = google_spanner_instance.this.name
  database = google_spanner_database.this[each.value.database].name
  role     = each.value.role
  member   = each.value.member
}
