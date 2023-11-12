terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

locals {
  namespaces = toset(["klum", "shadowtest"])
}

resource "kubernetes_namespace" "namespaces" {
  for_each = local.namespaces
  metadata {
    name = each.value
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "kubectl_manifest" "klum" {
  depends_on = [kubernetes_namespace.namespaces]
  yaml_body  = file("modules/applications/klum.yaml")
}

resource "kubectl_manifest" "shadowtest" {
  depends_on = [kubernetes_namespace.namespaces]
  yaml_body  = file("modules/applications/shadowtest.yaml")
}
