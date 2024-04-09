
# AVD Module 
Based on [ColeHeard's](https://github.com/ColeHeard/terraform-azurerm-avd/) AVD module. Has been updated, changed and expanded to fit the needs for the company I'm currently working for.
### Please note I'm not a developer, I'm coding to the best of my ability
I'm coding to the best of my abilities which doesn't mean that it's good or that I will optimize my code as of right now, functionality is what I'm aiming for.

# Naming convention
This may not be the CAF standard but it's designed in a way it's compatible and uniquely identifiable.

[https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming] and [https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations] have been used to create our naming convention.

## Required variables
| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| Naming convention | |  |
| `usecase` | `string` |  Workload/ Application for product like `excel` |
| `business_unit` | `strring` |  Business unit which this hostpool is made for, usually shortened to 3 letters. |
|  | |  |
| `region` | `strring` |  *Only used for naming convention*. Shortened to 2 letters. **Currently only regions are supported as to our usecase are limited to North Europe (ne) and West Europe (we)**.  |
|  | |  |
| `location` | `strring` |  Region where resources are being deployed usually. Shortened to 2 letters. **Currently only regions are supported as to our usecase are limited to North Europe (ne) and West Europe (we)**.  |
|  | |  |
| `environment` | `strring` |  Environment of variables. Like `prd`, `dev`, etc.  |
|  | |  |