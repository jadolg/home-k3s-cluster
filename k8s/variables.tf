variable "grafana_password" {
  type = string
}

variable "kubeconfig" {
  type = string
}

variable "cloudflare_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_zone" {
  type    = string
  default = "r4bbit.net"
}

variable "cloudflare_account_id" {
  type = string
}
