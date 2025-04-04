resource "azurerm_resource_group" "myrg_shd" {
  count    = var.img_builder_enabled == true || var.img_gallery_enabled == true ? 1 : 0
  name     = local.rg_name_shd
  location = var.location
  tags     = var.tags
}

############################################################################################################
##########################################  Image Builder ##################################################
############################################################################################################

resource "azurerm_user_assigned_identity" "aib" {
  count               = var.img_builder_enabled == true ? 1 : 0
  name                = local.managed_id_name
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  location            = azurerm_resource_group.myrg_shd[count.index].location
  tags                = var.tags
}

resource "azurerm_role_definition" "aib" {
  count       = var.img_builder_enabled == true ? 1 : 0
  name        = local.rbac_name
  scope       = data.azurerm_subscription.current.id
  description = "Azure Image Builder AVD"

  permissions {
    actions = [
      "Microsoft.Authorization/*/read",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete",
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Storage/storageAccounts/blobServices/read",
      "Microsoft.ContainerInstance/containerGroups/read",
      "Microsoft.ContainerInstance/containerGroups/write",
      "Microsoft.ContainerInstance/containerGroups/start/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action",
      "Microsoft.Authorization/*/read",
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/deploymentScripts/read",
      "Microsoft.Resources/deploymentScripts/write",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.VirtualMachineImages/imageTemplates/run/action",
      "Microsoft.VirtualMachineImages/imageTemplates/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
    azurerm_resource_group.myrg_shd[count.index].id
  ]
}

resource "azurerm_role_assignment" "aib" {
  count              = var.img_builder_enabled == true ? 1 : 0
  scope              = azurerm_resource_group.myrg_shd[count.index].id
  role_definition_id = azurerm_role_definition.aib[count.index].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.aib[count.index].principal_id
}

resource "time_sleep" "aib" {
  count           = var.img_builder_enabled == true ? 1 : 0
  depends_on      = [azurerm_role_assignment.aib]
  create_duration = "60s"
}

resource "azurerm_shared_image_gallery" "aib" {
  count               = var.img_builder_enabled == true || var.img_gallery_enabled == true ? 1 : 0
  name                = local.img_gal_name
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  location            = azurerm_resource_group.myrg_shd[count.index].location
  tags                = var.tags
}

resource "azurerm_shared_image" "aib" {
  count               = var.img_builder_enabled == true || var.img_gallery_enabled == true ? 1 : 0
  name                = local.img_version
  gallery_name        = azurerm_shared_image_gallery.aib[count.index].name
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  location            = azurerm_resource_group.myrg_shd[count.index].location
  accelerated_network_support_enabled = var.image_acc_network
  trusted_launch_enabled              = var.image_trusted_launch
  os_type             = "Windows"
  hyper_v_generation  = "V2"
  tags                = var.tags

  identifier {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
  }
}

resource "azurerm_resource_group_template_deployment" "aib" {
  count               = var.img_builder_enabled == true ? 1 : 0
  name                = local.image_builder_name
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "imageTemplateName" = {
      value = local.image_builder_name
    },
    "api-version" = {
      value = var.aib_api_version
    }
    "svclocation" = {
      value = var.location
    }
  })

  template_content = <<TEMPLATE
  {
    "$schema": "http://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "imageTemplateName": {
        "type": "string"
      },
      "api-version": {
        "type": "string"
      },
      "svclocation": {
        "type": "string"
      }
    },
  
    "variables": {},
  
    "resources": [
      {
        "name": "[parameters('imageTemplateName')]",
        "type": "Microsoft.VirtualMachineImages/imageTemplates",
        "apiVersion": "[parameters('api-version')]",
        "location": "[parameters('svclocation')]",
        "dependsOn": [],
        "tags": {
          "imagebuilderTemplate": "AzureImageBuilderSIG",
          "userIdentity": "enabled"
        },
        "identity": {
          "type": "UserAssigned",
          "userAssignedIdentities": {
            "${azurerm_user_assigned_identity.aib[count.index].id}": {}
          }
        },
  
        "properties": {
          "buildTimeoutInMinutes": 200,
  
          "vmProfile": {
            "vmSize": "Standard_DS4_v2",
            "osDiskSizeGB": 127
          },
  
          "source": {
            "type": "PlatformImage",
            "publisher": "${var.publisher}",
            "offer": "${var.offer}",
            "sku": "${var.sku}",
            "version": "latest"
          },
          
          "customize": [
            {
            "name": "avdBuiltInScript_installLanguagePacks",
            "type": "File",
            "destination": "C:\\AVDImage\\installLanguagePacks.ps1",
            "sourceUri": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/InstallLanguagePacks.ps1"
            },
          {
            "name": "avdBuiltInScript_installLanguagePacks-parameter",
            "type": "PowerShell",
            "inline": [
              "C:\\AVDImage\\installLanguagePacks.ps1 -LanguageList \"${var.img_language}\""
            ],
            "runAsSystem": true,
            "runElevated": true
          },
          {
            "name": "avdBuiltInScript_installLanguagePacks-windowsUpdate",
            "type": "WindowsUpdate"
          },
          {
            "name": "avdBuiltInScript_installLanguagePacks-windowsRestart",
            "type": "WindowsRestart",
            "restartCheckCommand": "",
            "restartCommand": "",
            "restartTimeout": "10m"
          },
          {
            "name": "avdBuiltInScript_setDefaultLanguage",
            "type": "File",
            "destination": "C:\\AVDImage\\setDefaultLanguage.ps1",
            "sourceUri": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/SetDefaultLang.ps1"
          },
          {
            "name": "avdBuiltInScript_setDefaultLanguage-parameter",
            "type": "PowerShell",
            "inline": [
              "C:\\AVDImage\\setDefaultLanguage.ps1 -Language \"${var.img_language}\""
            ],
            "runAsSystem": true,
            "runElevated": true
          },
          {
            "name": "avdBuiltInScript_setDefaultLanguage-windowsUpdate",
            "type": "WindowsUpdate"
          },
          {
            "name": "avdBuiltInScript_setDefaultLanguage-windowsRestart",
            "type": "WindowsRestart",
            "restartCheckCommand": "",
            "restartCommand": "",
            "restartTimeout": "5m"
          },
          {
            "name": "avdBuiltInScript_timeZoneRedirection",
            "runElevated": true,
            "runAsSystem": true,
            "scriptUri": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/TimezoneRedirection.ps1",
            "type": "PowerShell"
          },
          {
            "destination": "C:\\AVDImage\\windowsOptimization.ps1",
            "name": "avdBuiltInScript_windowsOptimization",
            "sourceUri": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/WindowsOptimization.ps1",
            "type": "File"
          },
          {
            "inline": [
              "C:\\AVDImage\\windowsOptimization.ps1 -Optimizations \"WindowsMediaPlayer\",\"ScheduledTasks\",\"DefaultUserSettings\",\"Autologgers\",\"Services\",\"NetworkOptimizations\",\"DiskCleanup\",\"RemoveLegacyIE\""
            ],
            "name": "avdBuiltInScript_windowsOptimization-parameter",
            "runAsSystem": true,
            "runElevated": true,
            "type": "PowerShell"
          },
          {
            "name": "avdBuiltInScript_removeAppxPackages",
            "type": "File",
            "destination": "C:\\AVDImage\\removeAppxPackages.ps1",
            "sourceUri": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/RemoveAppxPackages.ps1"
          },
          {
            "name": "avdBuiltInScript_removeAppxPackages-parameter",
            "type": "PowerShell",
            "inline": [
              "C:\\AVDImage\\removeAppxPackages.ps1 -AppxPackages \"Microsoft.BingNews\",\"Clipchamp.Clipchamp\",\"Microsoft.BingWeather\",\"Microsoft.GetHelp\",\"Microsoft.GamingApp\",\"Microsoft.Getstarted\",\"Microsoft.MicrosoftOfficeHub\",\"Microsoft.Office.OneNote\",\"Microsoft.MicrosoftSolitaireCollection\",\"Microsoft.MicrosoftStickyNotes\",\"Microsoft.MSPaint\",\"Microsoft.People\",\"Microsoft.PowerAutomateDesktop\",\"Microsoft.ScreenSketch\",\"Microsoft.SkypeApp\",\"Microsoft.Todos\",\"Microsoft.WindowsAlarms\",\"Microsoft.WindowsCamera\",\"Microsoft.windowscommunicationsapps\",\"Microsoft.WindowsFeedbackHub\",\"Microsoft.WindowsMaps\",\"Microsoft.WindowsSoundRecorder\",\"Microsoft.Xbox.TCUI\",\"Microsoft.XboxGameOverlay\",\"Microsoft.XboxGamingOverlay\",\"Microsoft.XboxIdentityProvider\",\"Microsoft.XboxSpeechToTextOverlay\",\"Microsoft.YourPhone\",\"Microsoft.ZuneMusic\",\"Microsoft.ZuneVideo\",\"Microsoft.XboxApp\""
            ],
            "runAsSystem": true,
            "runElevated": true
          },
          {
            "name": "avdBuiltInScript_windowsUpdate",
            "type": "WindowsUpdate"
          },
          {
            "name": "avdBuiltInScript_windowsUpdate-windowsRestart",
            "type": "WindowsRestart"
          }
          ],
          "distribute": [
            {
              "type": "SharedImage",
              "galleryImageId": "${azurerm_shared_image.aib[count.index].id}",
              "runOutputName": "[parameters('imageTemplateName')]",
              "artifactTags": {
                "source": "azureVmImageBuilder",
                "baseosimg": "windows11"
              },
              "replicationRegions": [${join(",", formatlist("\"%s\"", var.location))}]
            }
          ]
        }
      }
    ]
  }
TEMPLATE

  depends_on = [
    time_sleep.aib,
    azurerm_shared_image.aib
  ]
}

resource "null_resource" "install_az_cli" {
  count     = var.img_builder_enabled == true ? 1 : 0
  provisioner "local-exec" {
    command = <<EOF
      . /etc/lsb-release
      wget https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/azure-cli_2.36.0-1~$${DISTRIB_CODENAME}_all.deb
      mkdir ./env && dpkg -x *.deb ./env
      ./env/usr/bin/az login --service-principal -u "${var.ARM_CLIENT_ID}" -p "${var.ARM_CLIENT_SECRET}" -t "${var.ARM_TENANT_ID}"
      ./env/usr/bin/az account show
    EOF
  }
  provisioner "local-exec" {
    command = <<EOF
    ./env/usr/bin/az resource invoke-action --resource-group ${azurerm_resource_group.myrg_shd[count.index].name} --resource-type Microsoft.VirtualMachineImages/imageTemplates -n ${local.image_builder_name} --action Run
    EOF
  }
  depends_on = [
    azurerm_resource_group_template_deployment.aib,
  ]
  triggers = {
    always_run = uuid()
  }
}

############################################################################################################
############################################### SQL DB #####################################################
############################################################################################################

### DNS Settings for SQL DB ###
# resource "azurerm_private_dns_zone" "mydnszone_sql" {
#   count               = var.sql_enabled == true ? 1 : 0
#   name                = "privatelink.mysql.database.azure.com"
#   resource_group_name = var.vnet_rg
#   tags                = var.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "mylink_sql" {
#   count                 = var.sql_enabled == true ? 1 : 0
#   name                  = "azsqllink-${var.business_unit}"
#   private_dns_zone_name = azurerm_private_dns_zone.mydnszone_sql[count.index].name
#   virtual_network_id    = var.vnet_id
#   resource_group_name   = var.vnet_rg
#   tags                  = var.tags
# }

# resource "azurerm_private_endpoint" "endpoint_sql" {
#   count               = var.sql_enabled == true ? 1 : 0
#   name                = "${local.pep_name}-sql"
#   location            = azurerm_resource_group.myrg_shd[count.index].location
#   resource_group_name = var.vnet_rg
#   subnet_id           = var.subnet_id_shd
#   tags                = var.tags

#   private_service_connection {
#     name                           = "${local.psc_name}-sql"
#     private_connection_resource_id = azurerm_mysql_flexible_server.mysql[count.index].id
#     is_manual_connection           = false
#     subresource_names              = ["mysqlServer"]
#   }
#   private_dns_zone_group {
#     name                 = "dns-mysqlServer-${var.business_unit}-sql"
#     private_dns_zone_ids = azurerm_private_dns_zone.mydnszone_sql[count.index].*.id
#   }
# }

# resource "azurerm_private_dns_a_record" "dnszone_sql" {
#   count               = var.sql_enabled == true ? 1 : 0
#   name                = local.sql_name
#   zone_name           = azurerm_private_dns_zone.mydnszone_sql[count.index].name
#   resource_group_name = var.vnet_rg
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.endpoint_sql[count.index].private_service_connection.0.private_ip_address]
#   tags                = var.tags
# }

# # ### SQL DB Server ### login and pw in tf cloud 
# resource "random_password" "sql" {
#   count   = var.sql_enabled == true && var.sql_pass == null ? 1 : 0
#   length  = 16
#   special = true
# }

# resource "azurerm_mysql_flexible_server" "mysql" {
#   count                        = var.sql_enabled == true ? 1 : 0
#   name                         = local.sql_name
#   resource_group_name          = azurerm_resource_group.myrg_shd[count.index].name
#   location                     = azurerm_resource_group.myrg_shd[count.index].location
#   administrator_login          = var.sql_admin
#   administrator_password       = var.sql_pass == null ? random_password.sql[count.index].result : var.sql_pass
#   sku_name                     = var.sql_sku
#   version                      = var.sql_version
#   zone                         = var.sql_zone
#   backup_retention_days        = 30
#   geo_redundant_backup_enabled = false
#   tags                         = var.tags
#   storage {
#     size_gb            = var.sql_storage
#     io_scaling_enabled = true
#   }
#   depends_on = [azurerm_private_dns_zone_virtual_network_link.mylink_sql]
# }

# resource "azurerm_mysql_flexible_database" "mysqldb_prd" {
#   count               = var.sql_enabled == true ? var.db_count : 0
#   name                = "${local.sql_db_prd}-${format("%03d", count.index + 1)}"
#   resource_group_name = element(azurerm_resource_group.myrg_shd[*].name, count.index)
#   server_name         = element(azurerm_mysql_flexible_server.mysql[*].name, count.index)
#   charset             = var.sql_charset
#   collation           = var.sql_collation
# }

# resource "azurerm_mysql_flexible_database" "mysqldb_archive" {
#   count               = var.sql_enabled == true ? var.db_count_archive : 0
#   name                = "${local.sql_db_archive}-${format("%03d", count.index + 1)}"
#   resource_group_name = element(azurerm_resource_group.myrg_shd[*].name, count.index)
#   server_name         = element(azurerm_mysql_flexible_server.mysql[*].name, count.index)
#   charset             = var.sql_charset
#   collation           = var.sql_collation
# }