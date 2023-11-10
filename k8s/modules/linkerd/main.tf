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
  yaml_body = file("modules/linkerd/intermediate-cert.yaml")
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
