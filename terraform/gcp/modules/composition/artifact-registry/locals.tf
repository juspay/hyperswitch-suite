locals {
  common_labels = merge(
    {
      "environment" = var.environment
      "managed_by"  = "terraform"
    },
    var.labels
  )

  repository_iam_flat = merge([
    for repo, members in var.repository_iam : {
      for member in members :
      "${repo}-${member.role}-${member.member}" => {
        repository = repo
        role       = member.role
        member     = member.member
      }
    }
  ]...)
}
