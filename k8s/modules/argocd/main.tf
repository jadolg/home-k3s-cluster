resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "5.46.8"

  values = [file("modules/argocd/values.yaml")]
}

terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
