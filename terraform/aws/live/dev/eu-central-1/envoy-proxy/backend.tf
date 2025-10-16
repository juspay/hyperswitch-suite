# Development environment uses LOCAL backend
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
