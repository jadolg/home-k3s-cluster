resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  name  = "argocd"
  namespace = "argocd"


  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argo_password
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = true
  }

  set {
    name  = "dex.enabled"
    value = false
  }

  set {
    name  = "controller.metrics.enabled"
    value = true
  }
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "klum" {
  yaml_body = file("modules/argocd/applications/klum.yaml")
}

resource "kubectl_manifest" "shadowtest" {
  yaml_body = file("modules/argocd/applications/shadowtest.yaml")
}
