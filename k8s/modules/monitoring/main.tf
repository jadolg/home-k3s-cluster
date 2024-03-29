resource "kubernetes_namespace" "monitoring" {
  metadata {
    name        = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  namespace = "monitoring"

  version = "52.1.0"

  values = [file("modules/monitoring/values.yaml")]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = false
  }
  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = false
  }
  set {
    name  = "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"
    value = false
  }

}
