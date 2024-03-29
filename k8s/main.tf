module "monitoring" {
  depends_on       = [module.nfs, module.linkerd]
  source           = "./modules/monitoring"
  grafana_password = data.sops_file.settings.data["grafana.password"]
}

module "cloudflare" {
  source                = "./modules/cloudflare"
  cloudflare_account_id = data.sops_file.settings.data["cloudflare.account_id"]
  cloudflare_zone_id    = data.sops_file.settings.data["cloudflare.zone_id"]
  cloudflare_zone       = data.sops_file.settings.data["cloudflare.zone"]
  cloudflare_token      = data.sops_file.settings.data["cloudflare.token"]
  cloudflare_email      = data.sops_file.settings.data["cloudflare.email"]
  name                  = "cloudflare"

  ingresses = {
    "grafana" = {
      "url"    = "http://prometheus-grafana.monitoring.svc:80"
      "secure" = false
    }
    "argo" = {
      "url"    = "http://argocd-server.argocd.svc:80"
      "secure" = false
    }
    "shadowtest" = {
      "url"    = "http://shadowtest.shadowtest.svc:8080"
      "secure" = false
    }
    "prometheus" = {
      "url"    = "http://prometheus-operated.monitoring.svc:9090"
      "secure" = true
    }
    "linkerd-viz" = {
      "url"    = "http://web.linkerd-viz.svc:8084"
      "secure" = true
    }
  }
}

module "nfs" {
  source     = "./modules/nfs-storage"
  nfs_server = "192.168.2.20"
  nfs_path   = "/volume1/k3s"
}

module "argocd" {
  depends_on = [module.monitoring, module.linkerd]
  source     = "./modules/argocd"
}

module "applications" {
  depends_on = [module.argocd]
  source     = "./modules/applications"
}

module "linkerd" {
  depends_on = [module.cert-manager]
  source     = "./modules/linkerd"
}

module "cert-manager" {
  source           = "./modules/cert-manager"
  cloudflare_token = data.sops_file.settings.data["cloudflare.token"]
  email            = data.sops_file.settings.data["cloudflare.email"]
  cloudflare_zone  = data.sops_file.settings.data["cloudflare.zone"]
}

module "loki" {
  depends_on = [module.nfs, module.linkerd]
  source     = "./modules/loki"
}
