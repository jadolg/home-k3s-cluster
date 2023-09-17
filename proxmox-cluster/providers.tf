terraform {
  backend "s3" {
    bucket = "k3s-home-cluster"
    key = "terraform.tfstate"
    endpoint = "https://storage.shadowmere.akiel.dev/"
    region = "main"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
    force_path_style = true
  }
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
