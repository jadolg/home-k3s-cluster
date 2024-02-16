terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
  }
}

resource "helm_release" "linkerd-crds" {
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-crds"
  name       = "linkerd-crds"
  namespace  = "linkerd"
  version    = "1.8.0"
}

data "kubectl_path_documents" "certificates-manifests" {
  pattern = "modules/linkerd/certificates.yaml"
}

resource "kubectl_manifest" "certificates" {
  count     = length(data.kubectl_path_documents.certificates-manifests.documents)
  yaml_body = element(data.kubectl_path_documents.certificates-manifests.documents, count.index)
}

resource "helm_release" "linkerd-control-plane" {
  depends_on = [kubectl_manifest.certificates, helm_release.linkerd-crds]
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-control-plane"
  name       = "linkerd-control-plane"
  namespace  = "linkerd"
  version    = "1.16.4"

  values = [file("modules/linkerd/values-ha.yaml")]

  set {
    name  = "identity.externalCA"
    value = true
  }

  set {
    name  = "identity.issuer.scheme"
    value = "kubernetes.io/tls"
  }
}

resource "kubernetes_namespace" "grafana-linkerd" {
  depends_on = [helm_release.linkerd-control-plane]
  metadata {
    name        = "grafana-linkerd"
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

data "http" "grafana-values" {
  url = "https://raw.githubusercontent.com/linkerd/linkerd2/main/grafana/values.yaml"
}

resource "helm_release" "grafana-linkerd" {
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  name       = "grafana"
  namespace  = "grafana-linkerd"
  version    = "7.0.3"

  values = [data.http.grafana-values.response_body]
}

resource "kubernetes_namespace" "linkerd-viz" {
  metadata {
    name = "linkerd-viz"
  }
}

resource "helm_release" "linkerd-viz" {
  depends_on = [kubernetes_namespace.linkerd-viz, helm_release.linkerd-control-plane]
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-viz"
  name       = "linkerd-viz"
  namespace  = "linkerd-viz"
  version    = "30.12.4"

  set {
    name  = "dashboard.enforcedHostRegexp"
    value = ".*"
  }

  set {
    name  = "grafana.url"
    value = "grafana.grafana-linkerd.svc:3000"
  }
}

resource "kubectl_manifest" "grafana-access" {
  depends_on = [helm_release.grafana-linkerd, helm_release.linkerd-control-plane]
  yaml_body  = file("modules/linkerd/grafana-access.yaml")
}
