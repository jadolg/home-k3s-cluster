variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_token" {
  type = string
}

variable "cloudflare_zone" {
  type = string
}

variable "enable_security" {
  type    = bool
  default = false
}

variable "ingresses" {
  type = map(map(any))
}

variable "name" {
  default = "cloudflared"
}

variable "namespace" {
  default = "cloudflare"
}
