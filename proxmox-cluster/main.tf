module "ubuntu-node" {
  source = "./modules/ubuntu-node"

  name_prefix = "kube00"
  ip_prefix   = "192.168.2.5"
  nodes = 3
  pm_api_token_id = data.sops_file.settings.data["proxmox.token_id"]
  pm_api_token_secret = data.sops_file.settings.data["proxmox.token_secret"]
  pm_api_url = data.sops_file.settings.data["proxmox.api_url"]
}

resource "local_file" "hosts_cfg" {
  depends_on = [
    module.ubuntu-node
  ]
  content = templatefile("${path.module}/templates/inventory.cfg",
    {
      nodes       = join("\n", slice(module.ubuntu-node.servers_addresses, 1, length(module.ubuntu-node.servers_addresses) ))
      master_node = module.ubuntu-node.servers_addresses[0]
    }
  )
  filename = "../install-k3s/inventory/hosts.ini"
}
