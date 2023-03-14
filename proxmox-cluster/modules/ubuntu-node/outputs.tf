output "servers_addresses" {
  value = formatlist("${var.ip_prefix}%s", range(1, var.nodes + 1))
}