terraform {
  required_version = ">= 1.5"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
  backend "s3" {
    bucket = "k3s-home-cluster-k8s"
    key = "terraform.tfstate"
    endpoint = "https://storage.shadowmere.akiel.dev/"
    region = "main"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
    force_path_style = true
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}

provider kubernetes {
  config_path = var.kubeconfig
}

provider "kubectl" {
  config_path = var.kubeconfig
}

data "sops_file" "settings" {
  source_file = "settings.sops.yaml"
}
