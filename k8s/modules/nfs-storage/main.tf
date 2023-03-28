provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "nfs" {
  name      = "nfs"
  namespace = "nfs"

  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"

  create_namespace = true

  version = "4.0.18"

  set {
    name  = "nfs.server"
    value = var.nfs_server
  }

  set {
    name  = "nfs.path"
    value = var.nfs_path
  }

  set {
    name  = "storageClass.name"
    value = "nfs"
  }
}