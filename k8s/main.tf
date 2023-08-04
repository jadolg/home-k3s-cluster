module "monitoring" {
  source           = "./modules/monitoring"
  grafana_password = var.grafana_password
  kubeconfig = var.kubeconfig
}

variable "grafana_password" {
  type = string
}

module "cloudflare" {
  source = "./modules/cloudflare"
  kubeconfig = var.kubeconfig
}

module "nfs" {
  source = "./modules/nfs-storage"
  nfs_server = "192.168.2.20"
  nfs_path = "/volume1/k3s"
  kubeconfig = var.kubeconfig
}

variable "argo_password" {
  type = string
  description = "Password for the argo-cd admin user"
}

module "argocd" {
  source = "./modules/argocd"
  argo_password = bcrypt(var.argo_password)
  kubeconfig = var.kubeconfig
}

variable "kubeconfig" {
  type = string
}
