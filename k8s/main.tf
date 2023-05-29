module "monitoring" {
  source           = "./modules/monitoring"
  grafana_password = var.grafana_password
}

variable "grafana_password" {
  type = string
}

module "cloudflare" {
  source = "./modules/cloudflare"
}

module "nfs" {
  source = "./modules/nfs-storage"
  nfs_server = "192.168.88.20"
  nfs_path = "/volume1/k3s"
}

variable "argo_password" {
  type = string
  description = "Password for the argo-cd admin user"
}

module "argocd" {
  source = "./modules/argocd"
  argo_password = bcrypt(var.argo_password)
}