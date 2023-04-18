provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  namespace        = "monitoring"
  create_namespace = true

  version = "45.10.1"

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
}
