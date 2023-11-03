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
    namespace = "certmanager"
  }
  type = "Opaque"
  data = {
    apiToken : var.cloudflare_token
  }
}

resource "kubectl_manifest" "certmanager" {
  yaml_body = file("modules/certmanager/certmanager.yaml")
}

resource "kubectl_manifest" "clusterissuer" {
  depends_on = [kubectl_manifest.certmanager, kubernetes_secret.cloudflare]
  yaml_body  = templatefile("modules/certmanager/clusterissuer.yaml", {email= var.email, zone= var.cloudflare_zone})
}
