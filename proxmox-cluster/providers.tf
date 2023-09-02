terraform {
  required_version = ">= 1.5"
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

data "sops_file" "settings" {
  source_file = "settings.sops.yaml"
}
