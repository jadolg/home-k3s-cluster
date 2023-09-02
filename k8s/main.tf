module "monitoring" {
  depends_on       = [module.nfs]
  source           = "./modules/monitoring"
  grafana_password = data.sops_file.settings.data["grafana.password"]
}

module "cloudflare" {
  source                = "./modules/cloudflare"
  cloudflare_account_id = data.sops_file.settings.data["cloudflare.account_id"]
  cloudflare_zone_id    = data.sops_file.settings.data["cloudflare.zone_id"]
  cloudflare_zone       = data.sops_file.settings.data["cloudflare.zone"]
  cloudflare_token      = data.sops_file.settings.data["cloudflare.token"]

  ingresses = {
    "grafana"    = "http://prometheus-grafana.monitoring.svc:80"
    "argo"       = "http://argocd-server.argocd.svc:80"
    "shadowtest" = "http://shadowtest.shadowtest.svc:8080"
  }
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
