module "monitoring" {
  depends_on       = [module.nfs]
  source           = "./modules/monitoring"
  grafana_password = var.grafana_password
}

module "cloudflare" {
  source                = "./modules/cloudflare"
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_zone       = var.cloudflare_zone
  cloudflare_token      = var.cloudflare_token
}

module "nfs" {
  source     = "./modules/nfs-storage"
  nfs_server = "192.168.2.20"
  nfs_path   = "/volume1/k3s"
}

module "argocd" {
  depends_on = [module.monitoring]
  source     = "./modules/argocd"
}

module "applications" {
  depends_on = [module.argocd]
  source     = "./modules/applications"
}
