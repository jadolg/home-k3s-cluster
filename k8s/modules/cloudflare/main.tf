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

locals {
  ingresses = {
    "grafana"    = "http://prometheus-grafana.monitoring.svc:80"
    "argo"       = "http://argocd-server.argocd.svc:80"
    "shadowtest" = "http://shadowtest.shadowtest.svc:8080"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "kubernetes_namespace" "cloudflare" {
  metadata {
    name = "cloudflare"
  }
}

resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_tunnel" "k3s-home" {
  account_id = var.cloudflare_account_id
  name       = "k3s-home"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_record" "record" {
  for_each        = local.ingresses
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
      for_each = local.ingresses
      content {
        hostname = "${ingress_rule.key}.${var.cloudflare_zone}"
        service  = ingress_rule.value
      }
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_access_application" "k3s-home" {
  zone_id          = var.cloudflare_zone_id
  name             = "Access application for k3s-home"
  domain           = "*.${var.cloudflare_zone}"
  session_duration = "1h"
}

resource "cloudflare_access_policy" "k3s-home" {
  application_id = cloudflare_access_application.k3s-home.id
  zone_id        = var.cloudflare_zone_id
  name           = "Access policy for k3s-home"
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
      "name"      = "cloudflared"
      "namespace" = "cloudflare"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "cloudflared"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "cloudflared"
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
              "name" = "cloudflared"
            },
          ]
        }
      }
    }
  }
}
