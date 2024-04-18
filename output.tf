# output "hp_output" {
#   description = "Hostpool information for consumption by an independent sessionhost module."
#   value = {
#     v = {
#       workspace_prefix = "${local.workspace_prefix}"
#       region_prefix    = "${local.region_prefix}"
#       pool_type_prefix = "${local.pool_type_prefix}"
#       pool_number      = "${format("%02d", var.pool_number)}"
#       pool_name        = "${azurerm_virtual_desktop_host_pool.pool.name}"
#     }
#   }
# }
output "token" {
  description = "The hostpool token created for this pool."
  value       = local.token
  sensitive   = true
}
output "pool" {
  description = "The pool created by this module"
  value       = azurerm_virtual_desktop_host_pool.pool
}
output "workspace" {
  description = "The workspace created by this module"
  value       = azurerm_virtual_desktop_workspace.workspace
}
output "applications" {
  description = "The application group(s) created by this module"
  value       = azurerm_virtual_desktop_application_group.applicationgroup[*]
}
output "rg" {
  description = "The resource group selected for this pool"
  value       = var.rg
}
output "region" {
  description = "The Azure region selected for this pool"
  value       = var.region
}
output "timezone" {
  description = "The timezone selected for this pool"
  value       = var.timezone
}

output "myrg" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.myrg.name
}

output "myrg_location" {
  description = "Resource Group Location"
  value       = azurerm_resource_group.myrg.location
}

output "hostpool" {
  description = "Hostpool ID"
  value       = azurerm_virtual_desktop_host_pool.pool.id
}

output "vm_id" {
  description = "VM ID"
  value       = azurerm_windows_virtual_machine.vm[*].id
}

output "myrg_shd" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.myrg_shd[*].name
}
output "st_name" {
  description = "Storage Account Name"
  value       = azurerm_storage_account.storage[*].name
}