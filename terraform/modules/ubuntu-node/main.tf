terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.13"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.2.161:8006/api2/json"
}

resource "proxmox_vm_qemu" "ubuntu-nodes" {
  count = var.nodes
  name = "${var.name_prefix}${count.index+1}"
  desc = "ubuntu node"
  target_node = "jotun"
  onboot = true

  clone = "ubuntu-22.10-cloudimg"
  clone_wait = 60

  cores = 4
  sockets = 1
  memory = 8192

  scsihw = "virtio-scsi-pci"

  disk {
    type = "scsi"
    storage = "data01"
    size = "50G"
  }

  provisioner "remote-exec" {
    inline = ["ls"]
  }

  connection {
    type     = "ssh"
    host     = "${var.ip_prefix}${count.index+1}"
    user     = "ubuntu"
    port     = 22
  }

  lifecycle {
    ignore_changes = [
      network,
      qemu_os,
      sshkeys
    ]
  }

  ipconfig0 = "ip=${var.ip_prefix}${count.index+1}/24,gw=192.168.2.1"
}
