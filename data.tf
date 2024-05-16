data "azuread_service_principal" "principal" {
  display_name        = "Azure Virtual Desktop"
}

data "azurerm_role_definition" "avduser_role" {
  name = "Desktop Virtualization User"
}
# Each AAD group needed for permissioning. 
data "azuread_group" "avd_group_prd" {
  for_each         = toset(var.avd_access)
  display_name     = each.value
  security_enabled = true
}

data "azurerm_role_definition" "storage_role" {
  name    = "Storage File Data SMB Share Contributor"
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}
