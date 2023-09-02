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
