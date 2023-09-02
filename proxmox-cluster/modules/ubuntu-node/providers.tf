terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.13"
    }
  }
}

provider "proxmox" {
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_api_url = var.pm_api_url
}
