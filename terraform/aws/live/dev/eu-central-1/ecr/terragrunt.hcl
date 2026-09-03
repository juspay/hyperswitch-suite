include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/ecr"
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  repositories = {
    hyperswitch-app = {
      name                 = "dev-hyperswitch-app"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = "AES256"
      force_delete         = false
    }
    hyperswitch-web = {
      name                 = "dev-hyperswitch-web"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = "AES256"
      force_delete         = false
    }
    hyperswitch-control-center = {
      name                 = "dev-hyperswitch-control-center"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      encryption_type      = "AES256"
      force_delete         = false
    }
  }

  tags = {
    ManagedBy   = "terraform"
    Environment = "dev"
    Project     = "hyperswitch"
  }
}
