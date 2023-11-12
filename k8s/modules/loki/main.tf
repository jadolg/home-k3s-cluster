resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "helm_release" "loki" {
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  name       = "loki"
  namespace  = "loki"
  version    = "5.36.3"
  values = [file("modules/loki/values-loki.yaml")]
}

resource "helm_release" "promtail" {
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  name       = "promtail"
  namespace  = "loki"
  version    = "6.15.3"
  values = [file("modules/loki/values-promtail.yaml")]
}
