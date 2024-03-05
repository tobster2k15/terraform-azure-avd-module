data "azurerm_role_definition" "avduser_role" {
  name = "Desktop Virtualization User"
}
# Each AAD group needed for permissioning. 
data "azuread_group" "avd_group_prd" {
  for_each         = toset(local.aad_group_list)
  display_name     = each.value
  security_enabled = true
}

data "azurerm_role_definition" "storage_role" {
  name    = "Storage File Data SMB Share Contributor"
}

data "azuread_group" "st_group" {
  for_each         = var.st_access
  display_name     = each.value
  security_enabled = true
}