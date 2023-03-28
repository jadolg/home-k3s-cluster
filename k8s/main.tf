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