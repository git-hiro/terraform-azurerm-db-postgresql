output "psql" {
  value = "${
    map(
      "name", "${azurerm_postgresql_server.psql.name}",
    )
  }"
}
