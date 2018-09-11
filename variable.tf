variable "psql" {
  default = {
    resource_group_name = "az-ndap-nonprod-pgsql-rg"

    name     = "az-ndap-pgsql-db"
    location = "north europe"

    sku_name   = "B_Gen5_2"
    storage_gb = 5

    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"

    administrator          = "sapientteam"
    administrator_password = "Sapient123!"

    version         = "9.6"
    ssl_enforcement = "Enabled"
  }
}

variable "config" {
  default = {}
}
