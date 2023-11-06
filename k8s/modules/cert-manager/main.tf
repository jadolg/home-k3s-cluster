terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource kubernetes_secret "cloudflare" {
  depends_on = [kubernetes_namespace.cert-manager]
  metadata {
    name      = "cloudflare-key"
    namespace = "cert-manager"
  }
  type = "Opaque"
  data = {
    apiToken : var.cloudflare_token
  }
}

resource "kubectl_manifest" "cert-manager" {
  depends_on = [kubernetes_namespace.cert-manager]
  yaml_body  = file("modules/cert-manager/cert-manager.yaml")
}

resource "kubectl_manifest" "clusterissuer" {
  depends_on = [kubectl_manifest.cert-manager, kubernetes_secret.cloudflare]
  yaml_body  = templatefile("modules/cert-manager/clusterissuer.yaml", { email = var.email, zone = var.cloudflare_zone })
}

resource "kubectl_manifest" "selfsigned" {
  depends_on = [kubectl_manifest.cert-manager, kubernetes_secret.cloudflare]
  yaml_body  = file("modules/cert-manager/clusterissuer-selfsigned.yaml")
}
