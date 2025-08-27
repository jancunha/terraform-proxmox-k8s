locals {
  # global configurations
  agent        = 1
  cidr         = "192.168.1.0/24"
  onboot       = true
  proxmox_node = "pve"
  scsihw       = "virtio-scsi-pci"
  template     = "ubuntu-2204-cloud-init-zfs"
  bios         = "ovmf"

  bridge = {
    id        = 0
    interface = "vmbr0"
    model     = "virtio"
  }
  disks = {
    main = {
      backup  = true
      type    = "disk"
      storage = "zfs-vm"
      slot    = "scsi0"
      discard = true
    }
    cloudinit = {
      type    = "cloudinit"
      storage = "zfs-vm"
      slot    = "ide2"
    }
  }
  # --- Configurações de Boot e Console (baseado no clone manual) ---
  bootdisk = "scsi0"
  vga = {
    type = "serial0"
  }
  # serial is needed to connect via WebGUI console
  serial = {
    id   = 0
    type = "socket"
  }

  # cloud init information to be injected
  cloud_init = {
    user           = var.ci_user
    password       = var.ci_password
    ssh_public_key = var.ssh_public_key
    ipconfig       = "ip=dhcp"
  }

  # master specific configuration
  masters = {
    # how many nodes?
    count = 1

    name_prefix = "k8s-master"
    vmid_prefix = 300

    # hardware info
    cores     = 4
    disk_size = "32G"
    memory    = 2048
    sockets   = 1
    type      = "host"

    # 192.168.0.7x and so on...
    network_last_octect = 70
    tags                = "masters"
  }

  # worker specific configuration
  workers = {
    count = 2

    name_prefix = "k8s-worker"
    vmid_prefix = 400

    cores     = 2
    disk_size = "32G"
    memory    = 2048
    sockets   = 1
    type      = "host"

    network_last_octect = 90
    tags                = "workers"
  }
}