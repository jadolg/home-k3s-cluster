variable "name_prefix" {
  type = string
}

variable "ip_prefix" {
  type = string
}

variable "nodes" {
  default = 5
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type = string
}

variable "pm_api_url" {
  type = string
}
