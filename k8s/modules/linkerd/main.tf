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

resource "kubectl_manifest" "root-cert" {
  yaml_body = file("modules/linkerd/root-cert.yaml")
}

resource "kubectl_manifest" "linkerd-cluster-issuer" {
  depends_on = [kubectl_manifest.root-cert]
  yaml_body  = file("modules/linkerd/cluster-issuer.yaml")
}

resource "kubectl_manifest" "intermediate-cert" {
  depends_on = [kubectl_manifest.linkerd-cluster-issuer]
  yaml_body  = file("modules/linkerd/intermediate-cert.yaml")
}

data "kubernetes_secret" "linkerd-identity-issuer" {
  depends_on = [kubectl_manifest.intermediate-cert]
  metadata {
    name      = "linkerd-identity-issuer"
    namespace = "linkerd"
  }
}

resource "helm_release" "linkerd-control-plane" {
  depends_on = [kubectl_manifest.intermediate-cert, helm_release.linkerd-crds]
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-control-plane"
  name       = "linkerd-control-plane"
  namespace  = "linkerd"
  version    = "1.16.4"

  values = [file("modules/linkerd/values-ha.yaml")]

  set {
    name  = "identityTrustAnchorsPEM"
    value = data.kubernetes_secret.linkerd-identity-issuer.data["ca.crt"]
  }

  set {
    name  = "identity.issuer.scheme"
    value = "kubernetes.io/tls"
  }
}

resource "kubernetes_namespace" "grafana-linkerd" {
  metadata {
    name = "grafana-linkerd"
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
  yaml_body = file("modules/linkerd/grafana-access.yaml")
}
