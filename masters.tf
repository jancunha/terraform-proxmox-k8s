resource "proxmox_vm_qemu" "masters" {
  # depends_on = [proxmox_vm_qemu.ubuntu_template]
  count = local.masters.count

  target_node = local.proxmox_node
  vmid        = local.masters.vmid_prefix + count.index
  name = format(
    "%s-%s",
    local.masters.name_prefix,
    count.index
  )

  onboot = local.onboot
  clone  = local.template
  agent  = local.agent
  # bios   = local.bios

  cpu {
    type    = local.masters.type
    cores   = local.masters.cores
    sockets = local.masters.sockets
  }
  memory = local.masters.memory

  ciuser     = local.cloud_init.user
  sshkeys    = local.cloud_init.ssh_public_key
  ipconfig0  = local.cloud_init.ipconfig
  cipassword = local.cloud_init.password
  ciupgrade  = true
  # For static IP configuration, uncomment and adjust the following line:
  # ipconfig0 = format(
  #   "ip=%s/24,gw=%s",
  #   cidrhost(
  #     local.cidr,
  #     local.masters.network_last_octect + count.index
  #   ),
  #   cidrhost(local.cidr, 1)
  # )

  network {
    id     = 0
    bridge = local.bridge.interface
    model  = local.bridge.model
  }

  scsihw   = local.scsihw
  bootdisk = local.bootdisk
  vga {
    type = local.vga.type
  }

  serial {
    id   = local.serial.id
    type = local.serial.type
  }

  disk {
    backup  = local.disks.main.backup
    type    = local.disks.main.type
    storage = local.disks.main.storage
    slot    = local.disks.main.slot
    size    = local.masters.disk_size
    discard = local.disks.main.discard
  }

  disk {
    # backup  = local.disks.cloudinit.backup
    type    = local.disks.cloudinit.type
    storage = local.disks.cloudinit.storage
    slot    = local.disks.cloudinit.slot
    # discard = local.disks.cloudinit.discard
  }

  tags = local.masters.tags

  connection {
    type        = "ssh"
    user        = local.cloud_init.user
    private_key = file(var.ssh_private_key_path)
    host        = self.default_ipv4_address
    # host = cidrhost(
    #   local.cidr,
    #   local.masters.network_last_octect + count.index
    # )
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "echo 'VM provisionada com sucesso!'"
    ]
  }
}