variable "cloudflare_token" {
  type        = string
  description = "A cloudflare token with access to the DNS zone"
}

variable "email" {
  type        = string
  description = "The email address associated with the cloudflare account"
}

variable "cloudflare_zone" {
  type        = string
  description = "The DNS zone to add the record to"
}
