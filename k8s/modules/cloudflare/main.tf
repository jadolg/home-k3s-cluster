terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "kubernetes_namespace" "cloudflare" {
  metadata {
    name        = var.namespace
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
  }
}

resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_tunnel" "k3s-home" {
  account_id = var.cloudflare_account_id
  name       = var.name
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_record" "record" {
  for_each        = var.ingresses
  zone_id         = var.cloudflare_zone_id
  name            = each.key
  value           = cloudflare_tunnel.k3s-home.cname
  type            = "CNAME"
  allow_overwrite = true
  proxied         = true
}

resource "cloudflare_tunnel_config" "k3s-home" {
  depends_on = [cloudflare_record.record]
  tunnel_id  = cloudflare_tunnel.k3s-home.id
  account_id = var.cloudflare_account_id
  config {
    dynamic "ingress_rule" {
      for_each = var.ingresses
      content {
        hostname = "${ingress_rule.key}.${var.cloudflare_zone}"
        service  = ingress_rule.value["url"]
      }
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_access_application" "k3s-home" {
  for_each         = {for k, v in var.ingresses : k => v if v["secure"]}
  zone_id          = var.cloudflare_zone_id
  name             = "Access application for ${var.name} - ${each.key}"
  domain           = "${each.key}.${var.cloudflare_zone}"
  session_duration = "1h"
}

resource "cloudflare_access_policy" "k3s-home" {
  for_each       = {for k, v in var.ingresses : k => v if v["secure"]}
  application_id = cloudflare_access_application.k3s-home[each.key].id
  zone_id        = var.cloudflare_zone_id
  name           = "Access policy for ${var.name}"
  precedence     = "1"
  decision       = "allow"
  include {
    email_domain = ["akiel.dev"]
  }
}

resource "kubernetes_manifest" "deployment_cloudflared" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata"   = {
      "name"      = var.name
      "namespace" = var.namespace
    }
    "spec" = {
      "replicas" = 3
      "selector" = {
        "matchLabels" = {
          "app" = var.name
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = var.name
          }
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "tunnel",
                "--no-autoupdate",
                "--metrics",
                "0.0.0.0:2000",
                "run",
                "--token",
                cloudflare_tunnel.k3s-home.tunnel_token,
              ]
              "image"         = "cloudflare/cloudflared:2023.8.2"
              "livenessProbe" = {
                "failureThreshold" = 1
                "httpGet"          = {
                  "path" = "/ready"
                  "port" = 2000
                }
                "initialDelaySeconds" = 10
                "periodSeconds"       = 10
              }
              "name" = var.name
            },
          ]
        }
      }
    }
  }
}
