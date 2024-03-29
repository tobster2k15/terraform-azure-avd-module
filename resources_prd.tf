###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
### Resources
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
resource "azurerm_resource_group" "myrg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
# The hostpool uses logic from var.pool_type to set the majority of the fields. 
# Description and RDP properties are "changed" every deployment. Lifecycle block prevents this update. 
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool.html
resource "azurerm_virtual_desktop_host_pool" "pool" {
  resource_group_name              = azurerm_resource_group.myrg.name
  location                         = azurerm_resource_group.myrg.location
  name                             = local.vdpool_name
  friendly_name                    = "Production Hostpool"
  validate_environment             = var.validate_environment
  custom_rdp_properties            = var.custom_rdp_properties
  description                      = "Hostpool für ${var.usecase}."
  type                             = var.pool_type != "Personal" ? "Pooled" : null
  maximum_sessions_allowed         = var.maximum_sessions_allowed
  personal_desktop_assignment_type = var.pool_type == "Desktop" ? var.desktop_assignment_type : null
  start_vm_on_connect              = var.start_on_connect
  load_balancer_type               = var.load_balancer_type
  scheduled_agent_updates {
    timezone = var.timezone
    enabled  = true
    schedule {
      day_of_week = "Saturday"
      hour_of_day = 2
    }
  }
  lifecycle {
    ignore_changes = [
      description,
      custom_rdp_properties
    ]
  }
  tags = var.tags
}
# The hostpools registration token. Used by the DSC extension/AVD agent to tie the virtual machine to the hostpool as a "Sessionhost."
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info
resource "azurerm_virtual_desktop_host_pool_registration_info" "token" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.pool.id
  expiration_date = timeadd(timestamp(), "2h")
}
# Functionally, workspaces have a 1-to-1 relationship with the hostpool. The friendly_name field is surfaced to the end user.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = local.workspace
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  friendly_name       = var.usecase
  description         = "Workspace for ${var.usecase}"
  tags                = var.tags
}

# The application group. In this module it is limited to a single AAD group. You can use outputs to add additional groups from the root module.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group
resource "azurerm_virtual_desktop_application_group" "applicationgroup" {
  name                = local.app_group_name
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  type                = var.app_type != "RemoteApp" ? "Desktop" : "RemoteApp"
  host_pool_id        = azurerm_virtual_desktop_host_pool.pool.id
  friendly_name       = "${var.usecase}"
  description         = "Production Environment for ${var.usecase}"
  tags                = var.tags
}
# # The association object ties the application group(s) to the workspace.
# # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association
resource "azurerm_virtual_desktop_workspace_application_group_association" "association" {
  for_each             = toset(var.avd_access)
  application_group_id = azurerm_virtual_desktop_application_group.applicationgroup.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}
# AAD group role and scope assignment.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
resource "azurerm_role_assignment" "rbac" {
  for_each           = toset(var.avd_access)
  scope              = azurerm_virtual_desktop_application_group.applicationgroup.id
  role_definition_id = data.azurerm_role_definition.avduser_role.id
  principal_id       = data.azuread_group.avd_group_prd[each.value].id
}
# Applications for RAIL pools.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application
resource "azurerm_virtual_desktop_application" "application" {
  for_each                     = local.applications
  name                         = replace(each.value["app_name"], " ", "")
  friendly_name                = each.value["app_name"]
  description                  = "${each.value["app_name"]} application - created with Terraform."
  application_group_id         = azurerm_virtual_desktop_application_group.applicationgroup.id
  path                         = each.value["local_path"]
  command_line_argument_policy = each.value["cmd_argument"] != null ? "DoNotAllow" : "Require"
  command_line_arguments       = each.value["cmd_argument"]
  show_in_portal               = true
  icon_path                    = each.value["local_path"]
  icon_index                   = 0
  lifecycle {
    ignore_changes = [
      description
    ]
  }
}
# The virtual machine and disk.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine.html
resource "azurerm_windows_virtual_machine" "vm" {
  count                 = var.vmcount
  name                  = "${local.vm_name}-${format("%03d", count.index + 1)}"
  resource_group_name   = azurerm_resource_group.myrg.name
  location              = azurerm_resource_group.myrg.location
  size                  = var.vmsize
  network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
  provision_vm_agent    = true
  secure_boot_enabled   = var.secure_boot
  admin_username        = var.local_admin
  admin_password        = var.local_pass
  os_disk {
    name                 = "${local.osd_name}${format("%03d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.managed_image_id
  dynamic "source_image_reference" {
    for_each = var.managed_image_id == null ? ["var.managed_image_id is null, single loop!"] : []
    content {
      publisher = var.market_place_image.publisher
      offer     = var.market_place_image.offer
      sku       = var.market_place_image.sku
      version   = var.market_place_image.version
    }
  }
  boot_diagnostics {
    storage_account_uri = ""
  }
  depends_on = [
    azurerm_network_interface.nic
  ]
  tags = merge(var.tags, {
    Automation = "OU check - AVD"
  })
  lifecycle {
    ignore_changes = [identity]
  }
}
# The sessionhost's NIC.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "nic" {
  count               = var.vmcount
  name                = "${local.nic_name}-${format("%03d", count.index + 1)}"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  ip_configuration {
    name                          = "${local.ipc_name}${format("%03d", count.index + 1)}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
# Required extension - the DSC installs all three agents and passes the registration token to the AVD agent.
# As local.token is updated dynamically, the lifecycle block is used to prevent needless recreation of the resource.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension.html
resource "azurerm_virtual_machine_extension" "vm_dsc_ext" {
  count                      = var.vmcount
  name                       = "register-session-host-vmext"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  settings                   = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.pool.name}"
      }
    }
SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.token}"
    }
  }
PROTECTED_SETTINGS
  depends_on = [
    azurerm_virtual_desktop_host_pool.pool
  ]
  lifecycle {
    ignore_changes = [
      protected_settings,
    ]
  }
}
# Optional extension - only created if var.domain does not equal null.
# The lifecycle block prevents recreation for the existing VMs ext. when credentials are updated.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension.html
resource "azurerm_virtual_machine_extension" "domain_join_ext" {
  count                      = local.extensions.domain_join
  name                       = "join-domain"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
    {
      "Name": "${var.domain}",
      "OUPath": "${var.ou}",
      "User": "${var.domain_user}@${var.domain}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
    {
      "Password": "${var.domain_pass}"
    }
PROTECTED_SETTINGS
  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}
