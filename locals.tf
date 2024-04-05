# This local is used to create the workspace prefix.
locals {
  list = {
    prod_workspace  = terraform.workspace == "default" ? "${var.environment}" : ""
    dev_workspace   = terraform.workspace == "development" ? "dev" : ""
    uat_workspace   = terraform.workspace == "uat" ? "UT" : ""
    other_workspace = terraform.workspace != "default" && terraform.workspace != "development" && terraform.workspace != "uat" ? "TE" : ""
  }
  workspace_prefix = coalesce(local.list.prod_workspace, local.list.dev_workspace, local.list.uat_workspace, local.list.other_workspace)
}

# Locates unique AAD groups for application group for_each loop. 
locals {
  aad_group_list = var.application_map != null ? distinct(flatten([for k, v in var.application_map : toset(v.avd_access)])) : [var.aad_group_desktop]
  # aad_group_list = var.application_map != null ? distinct(values({ for k, v in var.application_map : k => toset(v.avd_access_${var.environment}) })) : ["${var.aad_group_desktop}"]
  applications       = var.application_map != null ? var.application_map : tomap({}) # Null is not accepted as for_each value, substituing for an empty map if null.
}
# Calculates if an extension type is needed for this pool's sessionhosts.
locals {
  extensions = {
    domain_join = var.domain != null ? var.vmcount : 0
    # sql_db      = var.sql_db != null ? toset(var.sql_db) : 0
  }
}
# VM Size 
locals {
  size_selected   = var.vmsize != null ? var.vmsize : "Standard_D2as_v4"
  size_unselected = lower(var.pool_type) == "desktop" ? "Standard_D2as_v4" : "Standard_D4as_v4"
  vmsize          = coalesce(local.size_selected, local.size_unselected)
}

locals {
  token = azurerm_virtual_desktop_host_pool_registration_info.token.token
}

#Namingconvention: Counter wird bei den einzelnen Namen mit angegeben
locals {
#Prod Naming
rg_name             =   "rg-${var.usecase}-${var.environment}-001" #bei count => 2 muss instance auskommentiert werden
vm_name             =   "vm${var.usecase_for_vm}${var.environment}" #${var.instance}
ipc_name            =   "ipc-nic-${var.environment}-" #${var.instance}
rt_name             =   "rt-${var.usecase}-default"
osd_name            =   "osdisk${local.vm_name}"
vdpool_name         =   "vdpool-${var.usecase}-${var.environment}-001"
nic_name            =   "nic-${var.usecase}-${var.environment}" #${var.instance} #Resource Group for 
vds_name            =   "vdscaling-${var.usecase}-${var.environment}-001"
app_group_name      =   "vdpool-${var.usecase}-DAG"
vdscaling_schedule  =   "vdpool-${var.usecase}-${var.environment}-schedule"
#Network Naming
rg_vnet_name        =   "rg-vnet-${var.usecase}-${var.environment}-${var.region}-001"
vnet_name           =   "vnet-${var.usecase}-${var.environment}-${var.region}-001"
snet_name           =   "snet-${var.usecase}-${var.environment}-001"
snet_name_dev       =   "snet-${var.usecase}-${var.environment}-001"
snet_name_shd       =   "snet-${var.usecase}-shd-"
nsg_name            =   "nsg-${var.usecase}-${var.environment}-${var.region}-001"
pip_name            =   "pip-${var.usecase}-${var.environment}-001" #${var.instance}
pep_name            =   "pep-${var.usecase}-shd-${var.region}"
psc_name            =   "psc-${var.usecase}-${var.environment}-${var.region}"
#DEV Naming
rg_name_dev         =   "rg-${var.usecase}-${var.environment}-001"
vm_name_dev         =   "vm${var.usecase_for_vm}${var.environment}-001" 
ipc_name_dev        =   "ipc-nic-dev" 
osd_name_dev        =   "osdisk${local.vm_name_dev}001"
vdpool_name_dev     =   "vdpool-${var.usecase}-${var.environment}-001"
nic_name_dev        =   "nic-${var.usecase}-dev"
app_group_name_dev  =   "vdpool-${var.usecase}-${var.environment}-DAG"
#SHD Naming
workspace           =   "vdws-${var.usecase}-${var.environment}-001"
workspace_dev       =   "vdws-${var.usecase}-${var.environment}-001"
rg_name_shd         =   "rg-${var.usecase}-shd-001"
st_name             =   "st${var.usecase}vdi${var.environment}001"
st_share_name       =   "share${var.usecase}fslogix01"
sql_name            =   "sql-${var.usecase}-shd-001"
sql_db_prd          =   "sqldb-${var.usecase}-production"
sql_db_archive      =   "sqldb-${var.usecase}-archive"
bck_vault_name      =   "bvault-${var.usecase}-shd-001"
image_builder_name  =   "aib-${var.usecase}-${var.environment}-${local.current_day}-001" 
managed_id_name     =   "id-aib-${var.usecase}-${var.environment}"
rbac_name           =   "id-RBAC-${var.usecase}-${var.environment}"
img_gal_name        =   "gal_${var.usecase}_shd"
img_version         =   "it-${var.usecase}-shd-001"

current_timestamp   =   timestamp()
current_day         =   formatdate("YYYY-MM-DD-hh-mm", local.current_timestamp)

}