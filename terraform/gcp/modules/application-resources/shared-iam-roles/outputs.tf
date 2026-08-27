output "role_ids" {
  description = "Map of logical name to the custom role's fully qualified ID"
  value       = { for k, v in google_project_iam_custom_role.this : k => v.id }
}

output "role_names" {
  description = "Map of logical name to the custom role's role_id (used in google_project_iam_member.role)"
  value       = { for k, v in google_project_iam_custom_role.this : k => v.role_id }
}
