terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource kubernetes_secret "cloudflare" {
  metadata {
    name      = "cloudflare-key"
    namespace = "cert-manager"
  }
  type = "Opaque"
  data = {
    apiToken : var.cloudflare_token
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubectl_manifest" "cert-manager" {
  depends_on = [kubernetes_namespace.cert-manager]
  yaml_body = file("modules/certmanager/certmanager.yaml")
}

resource "kubectl_manifest" "cert-manager-trust" {
    depends_on = [kubectl_manifest.cert-manager]
  yaml_body = file("modules/certmanager/cert-manager-trust.yaml")
}

resource "kubectl_manifest" "clusterissuer" {
  depends_on = [kubectl_manifest.cert-manager, kubernetes_secret.cloudflare]
  yaml_body  = templatefile("modules/certmanager/clusterissuer.yaml", {email= var.email, zone= var.cloudflare_zone})
}
