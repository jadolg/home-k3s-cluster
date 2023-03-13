module "monitoring" {
  source           = "./modules/monitoring"
  grafana_password = var.grafana_password
}

variable "grafana_password" {
  type = string
}