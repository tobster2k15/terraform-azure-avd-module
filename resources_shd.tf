resource "azurerm_resource_group" "myrg_shd" {
  count    = var.fslogix == true ? 1 : 0
  name     = var.rg_name_shd
  location = var.location
  tags     = var.tags
}

# resource "azurerm_user_assigned_identity" "aib" {
#   name                = local.managed_id_name
#   resource_group_name = azurerm_resource_group.myrg_shd.name
#   location            = azurerm_resource_group.myrg_shd.location
#   tags                = var.tags
# }

# resource "azurerm_role_definition" "aib" {
#   name        = local.rbac_name
#   scope       = data.azurerm_subscription.current.id
#   description = "Azure Image Builder AVD"

#   permissions {
#     actions = [
#       "Microsoft.Authorization/*/read",
#       "Microsoft.Compute/images/write",
#       "Microsoft.Compute/images/read",
#       "Microsoft.Compute/images/delete",
#       "Microsoft.Compute/galleries/read",
#       "Microsoft.Compute/galleries/images/read",
#       "Microsoft.Compute/galleries/images/versions/read",
#       "Microsoft.Compute/galleries/images/versions/write",
#       "Microsoft.Storage/storageAccounts/blobServices/containers/read",
#       "Microsoft.Storage/storageAccounts/blobServices/containers/write",
#       "Microsoft.Storage/storageAccounts/blobServices/read",
#       "Microsoft.ContainerInstance/containerGroups/read",
#       "Microsoft.ContainerInstance/containerGroups/write",
#       "Microsoft.ContainerInstance/containerGroups/start/action",
#       "Microsoft.ManagedIdentity/userAssignedIdentities/*/read",
#       "Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action",
#       "Microsoft.Authorization/*/read",
#       "Microsoft.Resources/deployments/*",
#       "Microsoft.Resources/deploymentScripts/read",
#       "Microsoft.Resources/deploymentScripts/write",
#       "Microsoft.Resources/subscriptions/resourceGroups/read",
#       "Microsoft.VirtualMachineImages/imageTemplates/run/action",
#       "Microsoft.VirtualMachineImages/imageTemplates/read",
#       "Microsoft.Network/virtualNetworks/read",
#       "Microsoft.Network/virtualNetworks/subnets/join/action"
#     ]
#     not_actions = []
#   }

#   assignable_scopes = [
#     data.azurerm_subscription.current.id,
#     azurerm_resource_group.myrg_shd.id
#   ]
# }

# resource "azurerm_role_assignment" "aib" {
#   scope              = azurerm_resource_group.myrg_shd.id
#   role_definition_id = azurerm_role_definition.aib.role_definition_resource_id
#   principal_id       = azurerm_user_assigned_identity.aib.principal_id
# }

# resource "time_sleep" "aib" {
#   depends_on      = [azurerm_role_assignment.aib]
#   create_duration = "60s"
# }

# resource "azurerm_shared_image_gallery" "aib" {
#   name                = local.img_gal_name
#   resource_group_name = azurerm_resource_group.myrg_shd.name
#   location            = azurerm_resource_group.myrg_shd.location
#   tags                = var.tags
# }

# resource "azurerm_shared_image" "aib" {
#   name                = local.img_version =! null ? var.img_version : null
#   gallery_name        = azurerm_shared_image_gallery.aib.name
#   resource_group_name = azurerm_resource_group.myrg_shd.name
#   location            = azurerm_resource_group.myrg_shd.location
#   os_type             = "Windows"
#   hyper_v_generation  = "V2"
#   tags                = var.tags

#   identifier {
#     publisher = var.publisher
#     offer     = var.offer
#     sku       = var.sku
#   }
# }

############################################################################################################
############################################### SQL DB #####################################################
############################################################################################################

### DNS Settings for SQL DB ###
# resource "azurerm_private_dns_zone" "mydnszone_sql" {
#   name                = var.sql_enabled == true ? "privatelink.mysql.database.azure.com" : null
#   resource_group_name = var.vnet_rg
#   tags                = var.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "mylink_sql" {
#   name                  = var.sql_enabled == true ? "azsqllink-${var.business_unit}" : null
#   private_dns_zone_name = azurerm_private_dns_zone.mydnszone_sql.name
#   virtual_network_id    = var.vnet_id
#   resource_group_name   = var.vnet_rg
#   tags                  = var.tags
# }

# resource "azurerm_private_endpoint" "endpoint_sql" {
#   name                = var.sql_enabled == true ? "${local.pep_name}-sql" : null
#   location            = azurerm_resource_group.myrg_shd.location
#   resource_group_name = var.vnet_rg
#   subnet_id           = var.subnet_id
#   tags                = var.tags

#   private_service_connection {
#     name                           = "${local.psc_name}-sql"
#     private_connection_resource_id = azurerm_mysql_flexible_server.mysql.id
#     is_manual_connection           = false
#     subresource_names              = ["mysqlServer"]
#   }
#   private_dns_zone_group {
#     name                 = "dns-mysqlServer-${var.business_unit}-sql"
#     private_dns_zone_ids = azurerm_private_dns_zone.mydnszone_sql.*.id
#   }
# }

# resource "azurerm_private_dns_a_record" "dnszone_sql" {
#   name                = var.sql_enabled == true ? "${local.sql_name}.mysql.database.azure.com" : null
#   zone_name           = azurerm_private_dns_zone.mydnszone_sql.name
#   resource_group_name = var.vnet_rg
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.endpoint_sql.private_service_connection.0.private_ip_address]
#   tags                = var.tags
# }

# ### SQL DB Server ### login and pw in tf cloud 
# resource "azurerm_mysql_flexible_server" "mysql" {
#   name                          = var.sql_enabled == true ? local.sql_name : null
#   resource_group_name           = azurerm_resource_group.myrg_shd.name
#   location                      = azurerm_resource_group.myrg_shd.location
#   administrator_login           = var.sql_enabled == true ? "admin123" : null
#   administrator_password        = var.sql_enabled == true ? "Start123$" : null
#   sku_name                      = var.sql_enabled == true ? "B_Standard_B2ms" : null
#   version                       = var.sql_enabled == true ? "8.0.21" : null
#   zone                          = "1"
#   backup_retention_days         = 30
#   geo_redundant_backup_enabled  = false
#   tags                          = var.tags
#   storage{
#     size_gb           = 25
#     io_scaling_enabled = true
#   }
#   depends_on = [azurerm_private_dns_zone_virtual_network_link.mylink_sql]
# }

# resource "azurerm_mysql_flexible_database" "mysqldb_prd" {
#   name                = local.sql_db_prd
#   resource_group_name = azurerm_resource_group.myrg_shd.name
#   server_name         = azurerm_mysql_flexible_server.mysql.name
#   charset             = var.sql_charset
#   collation           = var.sql_collation
# }

# resource "azurerm_mysql_flexible_database" "mysqldb_archive" {
#   name                = local.sql_db_archive
#   resource_group_name = azurerm_resource_group.myrg_shd.name
#   server_name         = azurerm_mysql_flexible_server.mysql.name
#   charset             = var.sql_charset
#   collation           = var.sql_collation
# }

############################################################################################################
########################################  Storage Account ##################################################
############################################################################################################

resource "azurerm_user_assigned_identity" "mi" {
  count               = var.fslogix == true ? 1 : 0
  name                = "id-avd-fslogix-we-${var.business_unit}"
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  location            = azurerm_resource_group.myrg_shd[count.index].location
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "storage" {
  count                             = var.fslogix == true ? 1 : 0
  name                              = var.st_name
  resource_group_name               = azurerm_resource_group.myrg_shd[count.index].name
  location                          = azurerm_resource_group.myrg_shd[count.index].location
  min_tls_version                   = "TLS1_2"
  account_kind                      = var.st_account_kind
  account_tier                      = var.st_account_tier
  account_replication_type          = var.st_replication
  public_network_access_enabled     = true #Needs to be changed later on (portal), otherwise share can't be created
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  enable_https_traffic_only         = true
  large_file_share_enabled          = true
  tags                              = var.tags
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_share" "FSShare" {
  name             = "fslogix"
  quota            = "100"
  enabled_protocol = "SMB"


  storage_account_name = azurerm_storage_account.storage[count.index].name
  depends_on           = [azurerm_storage_account[count.index].storage]
  lifecycle { ignore_changes = [name, quota, enabled_protocol] }
}

# resource "azurerm_role_assignment" "af_role_prd" {
#   scope              = azurerm_storage_account.storage.id
#   role_definition_id = data.azurerm_role_definition.storage_role.id
#   principal_id       = data.azuread_group.user_group_prd.id
# }

# resource "azurerm_role_assignment" "af_role_dev" {
#   scope              = azurerm_storage_account.storage.id
#   role_definition_id = data.azurerm_role_definition.storage_role.id
#   principal_id       = data.azuread_group.user_group_dev.id
# }


#Get Private DNS Zone for the Storage Private Endpoints
resource "azurerm_private_dns_zone" "dnszone_st" {
  count               = var.fslogix == true ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.vnet_rg
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "dnszone_st" {
  count               = var.fslogix == true ? 1 : 0
  name                = "${var.st_name}.file.core.windows.net"
  zone_name           = azurerm_private_dns_zone.dnszone_st.name[count.index]
  resource_group_name = var.vnet_rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.endpoint_st.private_service_connection.0.private_ip_address]
  tags                = var.tags
}

resource "azurerm_private_endpoint" "endpoint_st" {
  count               = var.fslogix == true ? 1 : 0
  name                = local.pep_name
  location            = azurerm_resource_group.myrg_shd[count.index].location
  resource_group_name = azurerm_resource_group.myrg_shd[count.index].name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = local.psc_name
    private_connection_resource_id = azurerm_storage_account.storage[count.index].id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  private_dns_zone_group {
    name                 = "dns-file-${var.business_unit}"
    private_dns_zone_ids = azurerm_private_dns_zone.dnszone_st.*.id
  }
}

# Deny Traffic from Public Networks with white list exceptions
resource "azurerm_storage_account_network_rules" "stfw" {
  storage_account_id              = azurerm_storage_account.storage.id
  default_action                  = "Deny"
  bypass                          = ["AzureServices", "Metrics", "Logging"]
  depends_on                      = [azurerm_storage_share.FSShare,
    azurerm_private_endpoint.endpoint_st
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "filelink" {
  count                 = var.fslogix == true ? 1 : 0
  name                  = "azfilelink-${var.business_unit}"
  resource_group_name   = var.vnet_rg
  private_dns_zone_name = azurerm_private_dns_zone.dnszone_st[count.index].name
  virtual_network_id    = var.vnet_id

  lifecycle { ignore_changes = [tags] }
}