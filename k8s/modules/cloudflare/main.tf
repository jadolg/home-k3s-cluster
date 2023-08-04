provider kubernetes {
  config_path = var.kubeconfig
}

resource "kubernetes_namespace" "cloudflare" {
  metadata {
    name = "cloudflare"
  }
}

resource "kubernetes_secret" "tunnel-credentials" {
  metadata {
    namespace = "cloudflare"
    name      = "tunnel-credentials"
  }

  type = "Opaque"

  data = {
    "credentials.json" = file("${path.module}/credentials.json")
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
      "replicas" = 2
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
                "--config",
                "/etc/cloudflared/config/config.yaml",
                "run",
              ]
              "image"         = "cloudflare/cloudflared:2023.4.1"
              "livenessProbe" = {
                "failureThreshold" = 1
                "httpGet"          = {
                  "path" = "/ready"
                  "port" = 2000
                }
                "initialDelaySeconds" = 10
                "periodSeconds"       = 10
              }
              "name"         = "cloudflared"
              "volumeMounts" = [
                {
                  "mountPath" = "/etc/cloudflared/config"
                  "name"      = "config"
                  "readOnly"  = true
                },
                {
                  "mountPath" = "/etc/cloudflared/creds"
                  "name"      = "creds"
                  "readOnly"  = true
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name"   = "creds"
              "secret" = {
                "secretName" = "tunnel-credentials"
              }
            },
            {
              "configMap" = {
                "items" = [
                  {
                    "key"  = "config.yaml"
                    "path" = "config.yaml"
                  },
                ]
                "name" = "cloudflared"
              }
              "name" = "config"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "configmap_cloudflared" {
  manifest = {
    "apiVersion" = "v1"
    "data"       = {
      "config.yaml" = <<-EOT
      tunnel: cloudflare-tunnel
      credentials-file: /etc/cloudflared/creds/credentials.json
      metrics: 0.0.0.0:2000
      no-autoupdate: true
      ingress:
      - hostname: grafana.r4bbit.net
        service: http://prometheus-grafana.monitoring.svc:80
      - hostname: shadowtest.r4bbit.net
        service: http://shadowtest.shadowtest.svc:8080
      - hostname: argo.r4bbit.net
        service: http://argocd-server.argocd.svc:80
      # This rule matches any traffic which didn't match a previous rule, and responds with HTTP 404.
      - service: http_status:404

      EOT
    }
    "kind"     = "ConfigMap"
    "metadata" = {
      "name"      = "cloudflared"
      "namespace" = "cloudflare"
    }
  }
}
