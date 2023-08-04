module "monitoring" {
  depends_on       = [module.nfs]
  source           = "./modules/monitoring"
  grafana_password = var.grafana_password
}

module "cloudflare" {
  source = "./modules/cloudflare"
}

module "nfs" {
  source     = "./modules/nfs-storage"
  nfs_server = "192.168.2.20"
  nfs_path   = "/volume1/k3s"
}

module "argocd" {
  depends_on    = [module.monitoring]
  source        = "./modules/argocd"
  argo_password = bcrypt(var.argo_password)
}

module "applications" {
  depends_on = [module.argocd]
  source     = "./modules/applications"
}
