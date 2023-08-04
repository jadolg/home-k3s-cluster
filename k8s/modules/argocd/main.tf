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
  version    = "5.42.1"

  values = [file("modules/argocd/values.yaml")]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argo_password
  }
}

terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
