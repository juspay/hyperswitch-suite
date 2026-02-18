provider "aws" {
  region = var.region
}

# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = var.repositories

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.kms_key
  }

  # Image tag mutability exclusion filters
  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = each.value.image_tag_mutability_exclusion_filters
    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }

  tags = merge(local.common_tags, {
    Name = each.value.name
  })
}

# ECR Repository Policies
resource "aws_ecr_repository_policy" "policies" {
  for_each = { for k, v in var.repositories : k => v if v.repository_policy != null }

  repository = aws_ecr_repository.repositories[each.key].name
  policy     = jsonencode(each.value.repository_policy)
}
