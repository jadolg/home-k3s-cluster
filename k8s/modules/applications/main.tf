terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

resource "kubectl_manifest" "klum" {
  yaml_body = file("modules/applications/klum.yaml")
}

resource "kubectl_manifest" "shadowtest" {
  yaml_body = file("modules/applications/shadowtest.yaml")
}
