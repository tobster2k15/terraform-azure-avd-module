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
 
# data "azuread_group" "avd_group_dev" {
#   for_each         = toset(var.avd_access_dev)
#   display_name     = each.value
#   security_enabled = true
# }

data "azurerm_role_definition" "storage_role" {
  name    = "Storage File Data SMB Share Contributor"
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "template_file" "st_join" {
    template = "${file("st_join.ps1")}"
    vars = {
        
        ClientId                = "${var.ARM_CLIENT_ID}"
        SubscriptionId          = "${var.ARM_SUBSCRIPTION_ID}"
        ResourceGroupName       = "${local.rg_name_shd}"
        StorageAccountName      = "${local.st_name}"
        SamAccountName          = "${local.st_name}"
        DomainAccountType       = "ComputerAccount"
        IdentityServiceProvider = "ADDS"
        OUName                  = "${var.st_ou_path}"
        EncryptionType          = "AES256"
        StorageAccountFqdn      = "${local.st_name}.file.core.windows.net"
  }
}