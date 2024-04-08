###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
### Variables - Required
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
variable "rg" {
  type        = string
  description = "Name of the resource group."
  default     = null 
}
variable "region" {
  type        = string
  description = "The desired Azure region for the pool. See also var.region_prefix_map."
  validation {
    condition = anytrue([
      lower(var.region) == "ne",
      lower(var.region) == "we"
    ])
    error_message = "Please select one of the approved regions:ne(northeurope) or we (westeurope)."
  }
}
variable "pool_type" {
  type        = string
  description = "The pool type."
  default     = "Pooled"
}
variable "pool_number" {
  type        = number
  description = "The number of this pool. Use to avoid name collision."
}
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
### Variables - Optional
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
# An awkward limitation due to variable validation limitations: https://github.com/hashicorp/terraform/issues/25609#issuecomment-1136340278.
variable "aad_group_desktop" {
  type        = string
  description = "The desktop pool's assignment AAD group. Required if var.pool_type != application."
  default     = null
}
# An awkward limitation due to variable validation limitations: https://github.com/hashicorp/terraform/issues/25609#issuecomment-1136340278.
variable "application_map" {
  type = map(object({
    app_name     = string
    local_path   = string
    cmd_argument = string
    avd_access   = list(string)
  }))
  description = "A map of all applications and metadata. Required if var.pool_type == application."
  default     = null
}

variable "ARM_SUBSCRIPTION_ID" {
  type        = string
  description = "Subscription ID"
  default     = null
}

variable "desktop_assignment_type" {
  type        = string
  description = "Sets the personal desktop assignment type."
  default     = "Automatic"
  validation {
    condition = anytrue([
      lower(var.desktop_assignment_type) == "automatic",
      lower(var.desktop_assignment_type) == "direct",
    ])
    error_message = "The var.desktop_assignment_type input was incorrect. Please select automatic or direct."
  }
}
variable "load_balancer_type" {
  type        = string
  description = "The method of load balancing the pool with use to distribute users across sessionhosts."
  default     = "DepthFirst"
  validation {
    condition = anytrue([
      lower(var.load_balancer_type) == "breadthfirst",
      lower(var.load_balancer_type) == "depthfirst",
      lower(var.load_balancer_type) == "persistent"
    ])
    error_message = "The var.load_balancer_type input was incorrect. Please select breadthfirst, depthfirst, or persistent."
  }
}
variable "validate_environment" {
  type        = bool
  description = "Set as true to enable validation environment."
  default     = false
}
variable "maximum_sessions_allowed" {
  type        = number
  description = "The maximum number of concurrent sessions on a single sessionhost"
  default     = 3
}
# https://learn.microsoft.com/en-us/azure/virtual-desktop/rdp-properties
variable "rdp_properties" {
  type        = string
  description = "Sets custom RDP properieties for the pool"
  default     = null
}
variable "enable_agent_update_schedule" {
  type        = bool
  description = "When enabled, the pool will only perform updates on the sessionhost agents at the selected time."
  default     = true
}
variable "timezone" {
  type        = string
  description = "The timezone used to schedule updates for the AVD, Geneva agent, and side-by-side stack agent."
  default     = "Central Standard Time"
}
variable "tags" {
  type        = map(any)
  description = "The tags for the virtual machines and their subresources."
  default     = { Warning = "No tags" }
}
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
### Variables - Naming
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
variable "region_prefix_map" {
  type        = map(any)
  description = "A list of prefix strings to concat in locals. Can be replaced or appended."
  default = {
    westeurope       = "we"
    northeurope      = "ne"
  }
}
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
### Variables - Virtual Machines
###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###>-<###
variable "vmcount" {
  type        = number
  description = "The number of VMs requested for this pool."
  default     = 0
  validation {
    condition = (
      var.vmcount >= 0 &&
      var.vmcount <= 99
    )
    error_message = "The number of VMs must be between 0 and 99."
  }
}
variable "secure_boot" {
  type        = bool
  description = "Controls the trusted launch settings for the sessionhost VMs."
  default     = true
}
# To-do 
variable "market_place_image" {
  type        = map(any)
  description = "The publisher, offer, sku, and version of an image in Azure's market place. Only used if var.custom_image is null."
  default = {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }
}
variable "managed_image_id" {
  type        = any
  description = "The ID of an Azure Compute Gallery image."
  default     = null
}
variable "network_data" {
  type        = any
  description = "The network data needed for sessionhost connectivity."
  default     = null
}
variable "local_admin" {
  type        = string
  description = "The local administrator username."
  default     = null
}
variable "local_pass" {
  type        = string
  description = "The local administrator password."
  default     = null
  sensitive   = true
}
variable "domain" {
  type        = string
  description = "Domain name string."
  default     = null
}
variable "domain_user" {
  type        = string
  description = "The identity that will join the VM to the domain. Omit the domain name itself."
  default     = null
}
variable "domain_pass" {
  type        = string
  description = "Password for var.domain_user"
  sensitive   = true
  default     = null
}
variable "workspace_id" {
  type        = string
  description = "The ID of the Log Analytics Workspace that will collect the data."
  default     = null
}
variable "workspace_key" {
  type        = string
  description = "The Log Analytics Workspace key."
  sensitive   = true
  default     = null
}
variable "vmsize" {
  type        = string
  description = "The VM SKU desired for the pool. If none are selected, VMSize will be chosen based on var.pool_type."
  default     = "Standard_D2as_v4"
}
# To-do Azure Automation runbook to key off OU VM tag. This will be included within another repository.
variable "ou" {
  type        = string
  description = "The OU a VM should be placed within."
  default     = "" # Currently does not work, needs blank string to create VMs.
}

variable "ou_dev" {
  type        = string
  description = "The OU a VM should be placed within."
  default     = "" # Currently does not work, needs blank string to create VMs.
}
variable "start_on_connect"{
  type        = bool
  description = "Start the VM when a user connects."
  default     = true
}

variable "fslogix_enabled"{
  type        = bool
  description = "Enable FSLogix for the pool."
  default     = false
}

variable "vnet_rg"{
  type        = string
  description = "The resource group of the virtual network."
  nullable    = false
}

variable "sql_enabled" {
  type        = bool
  description = "Enable SQL for the pool."
  default     = false
}

variable "vnet_id" {
  type        = string
  description = "The ID of the virtual network."
  nullable    = false
}

variable "location"{ 
  type        = string
  description = "The location of the virtual network."
  default     = "westeurope"
}

variable "st_account_kind"{ 
  type        = string
  description = "The kind of storage account."
  default     = "FileStorage"
}

variable "st_account_tier"{ 
  type        = string
  description = "The tier of the storage account."
  default     = "Premium"
}

variable "st_replication"{ 
  type        = string
  description = "The replication of the storage account."
  default     = "LRS"
}

variable "business_unit" {
  type        = string
  description = "The business unit of the pool."
  default     = "IT"
}

variable "usecase" {
  type        = string
  description = "The usecase of the pool."
  default     = "vdi"
}

variable "usecase_for_vm" {
  type        = string
  description = "The usecase of the pool."
  default     = "vdi"
}

variable "subnet_id_shd" {
  type        = string
  description = "The ID of the subnet."
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet."
  default     = null
}

variable "resource_group_name"{
  type        = string
  description = "The name of the resource group."
  default     = null
}

variable "st_name" {
  type        = string
  description = "The name of the storage account."
  default     = null
}

variable "rg_name_shd" {
  type        = string
  description = "The name of the storage share."
  default     = "rg-test-001"
}

variable "st_access_prd" {
  type = string
  description = "The access tier of the storage account."
  default     = null
}

variable "st_access_dev" {
  type = string
  description = "The access tier of the storage account."
  default     = null
}

variable "avd_access" {
  type        = list(string)
  description = "The access tier of the productive AVD."
  default     = null
}

variable "img_builder_enabled" {
  type        = bool
  description = "Enable the image builder."
  default     = false
}

variable "publisher" {
  type        = string
  description = "The publisher of the image."
  default     = "microsoftwindowsdesktop"
}

variable "offer" {
  type        = string
  description = "The offer of the image."
  default     = "windows-11"
}

variable "sku" {
  type        = string
  description = "The sku of the image."
  default     = "win11-23h2-avd"
}

variable "app_type" {
  type        = string
  description = "The type of the application."
  default     = "RemoteApp"
}

variable "img_language"{
  type        = string
  description = "The language of the image."
  default     = "English (United States)"
}

variable "aib_api_version" {
  type        = string
  description = "The API version of the image builder."
  default     = "2022-07-01"
}

variable "ARM_CLIENT_ID"{
  type        = string
  description = "Client ID"
  default     = null
}

variable "ARM_TENANT_ID"{
  type        = string
  description = "Tenant ID"
  default     = null
}

variable "ARM_CLIENT_SECRET"{
  type        = string
  description = "Client Secret"
  default     = null
}

variable "dev_hostpool_enabled" {
  type        = bool
  description = "Enable the dev hostpool."
  default     = false
}

variable "sql_db" {
  type        = list(string)
  description = "The name of the SQL database."
  default     = null
}

variable "subnet_id_dev"{ 
  type        = string
  description = "The ID of the subnet."
  default     = null
}

variable "vmsize_dev"{
  type        = string
  description = "The VM SKU desired for the pool. If none are selected, VMSize will be chosen based on var.pool_type."
  default     = "Standard_D2as_v4"
}

variable "vmcount_dev" {
  type        = number
  description = "The number of VMs requested for this pool."
  default     = 0
}

variable "st_ou_path" {
  type        = string
  description = "The OU path of the storage account."
  default     = ""
}

variable "environment" {
  type        = string
  description = "The environment of the pool."
  default     = "prd"
}

variable "share_size" {
  type        = string
  description = "The size of the share."
  default     = "100"
}

variable "sql_charset" {
  type        = string
  description = "The charset of the SQL database."
  default     = "utf8mb3"
}

variable "sql_collation" {
  type        = string
  description = "The collation of the SQL database."
  default     = "utf8mb3_unicode_ci"
}

variable "sql_version" {
  type        = string
  description = "The version of the SQL database."
  default     = "8.0.21"
}

variable "sql_sku" {
  type        = string
  description = "The SKU of the SQL database."
  default     = "B_Standard_B1s"
}

variable "db_count" {
  type        = number
  description = "The number of databases."
  default     = 0
}

variable "db_count_archive" {
  type        = number
  description = "The number of databases."
  default     = 0
}

variable "sql_storage" {
  type        = number
  description = "The size of the SQL database."
  default     = 25
}

variable "sql_zone" {
  type        = string
  description = "The zone of the SQL database."
  default     = "1"
}

variable "random_name" {
  type        = bool
  description = "The random name of the SQL database."
  default     = false
}

variable "additional_shares" {
  type        = number
  description = "The additional shares."
  default     = 0
}

variable "scaling_plan_enabled" {
  type        = bool
  description = "Enable the scaling plan."
  default     = false
}

variable "img_gallery_enabled" {
  type        = bool
  description = "Enable the image gallery."
  default     = false
}