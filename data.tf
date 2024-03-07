data "azurerm_role_definition" "avduser_role" {
  name = "Desktop Virtualization User"
}
# Each AAD group needed for permissioning. 
data "azuread_group" "avd_group_prd" {
  for_each         = toset(var.avd_access_prd)
  display_name     = each.value
  security_enabled = true
}

data "azurerm_role_definition" "storage_role" {
  name    = "Storage File Data SMB Share Contributor"
}
