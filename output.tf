output "masters_ips" {
  description = "Endereços IP dos nós masters."
  value       = proxmox_vm_qemu.masters.*.default_ipv4_address
}

output "workers_ips" {
  description = "Endereços IP dos nós workers."
  value       = proxmox_vm_qemu.workers.*.default_ipv4_address
}
