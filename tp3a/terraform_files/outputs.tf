# outputs.tf

output "vm_public_ip" {
  description = "IP addr : "
  value       = azurerm_public_ip.main.ip_address
}

output "vm_dns_name" {
  description = "FQDN : "
  value       = azurerm_public_ip.main.fqdn
}

output "key_vault_secret" {
  description = "secret"
  value       = azurerm_key_vault_secret.meow_secret.value
  sensitive = true
}
