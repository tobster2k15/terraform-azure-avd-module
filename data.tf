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

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "template_file" "st_join" {
    template = "${file("${path.root}/scripts/st_join.ps1")}"
    vars = {
        
        ClientId                = "${var.ARM_CLIENT_ID}"
        SubscriptionId          = "${var.ARM_SUBSCRIPTION_ID}"
        ResourceGroupName       = "${azurerm_resource_group.myrg_shd.name}"
        StorageAccountName      = "${local.st_name}"
        SamAccountName          = "${local.st_name}"
        DomainAccountType       = "ComputerAccount"
        IdentityServiceProvider = "ADDS"
        OUName                  = "${var.st_ou_path}"
        EncryptionType          = "AES256"
        StorageAccountFqdn      = "${azurerm_private_dns_a_record.dnszone_st.name}"
  }
}