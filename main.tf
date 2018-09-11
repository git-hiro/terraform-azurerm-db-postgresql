locals {
  sku_params     = "${split("_", var.psql["sku_name"])}"
  sku_tier_short = "${element(local.sku_params, 0)}"
  sku_family     = "${element(local.sku_params, 1)}"
  sku_capacity   = "${element(local.sku_params, 2)}"

  sku_tier = "${
    local.sku_tier_short == "B" ? "Basic" : 
    local.sku_tier_short == "GP" ? "GeneralPurpose" : 
    local.sku_tier_short == "MO" ? "MemoryOptimized" : 
    ""}"

}

terraform {
  backend "azurerm" {}
}

resource "azurerm_resource_group" "resourecegroup" {
  name     = "${var.psql["resource_group_name"]}"
  location = "North Europe"
}

resource "azurerm_postgresql_server" "psql" {
  #resource_group_name = "${var.psql["resource_group_name"]}"
  resource_group_name = "${azurerm_resource_group.resourecegroup.name}"
  name     = "${var.psql["name"]}"
  location = "${var.psql["location"]}"

  sku {
    name     = "${var.psql["sku_name"]}"
    tier     = "${local.sku_tier}"
    family   = "${local.sku_family}"
    capacity = "${local.sku_capacity}"
  }

  storage_profile {
    storage_mb            = "${var.psql["storage_gb"] * 1024}"
    backup_retention_days = "${var.psql["backup_retention_days"]}"
    geo_redundant_backup  = "${var.psql["geo_redundant_backup"]}"
  }

  administrator_login          = "${var.psql["administrator"]}"
  administrator_login_password = "${var.psql["administrator_password"]}"
  version                      = "${var.psql["version"]}"
  ssl_enforcement              = "${var.psql["ssl_enforcement"]}"
}

resource "azurerm_postgresql_configuration" "configs" {
  count = "${length(keys(var.config))}"

  resource_group_name = "${azurerm_postgresql_server.psql.resource_group_name}"
  server_name         = "${azurerm_postgresql_server.psql.name}"

  name  = "${element(keys(var.config), count.index)}"
  value = "${lookup(var.config, element(keys(var.config), count.index))}"
}
