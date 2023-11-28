variables {
  postfix = "3897"
  location = "West US2"
  sku = "Premium"
}
run "container_registry_sku" {
  command = apply #deploys the infrastructure
  #validations to be performed on the main.tf file
  assert {
    condition     = azurerm_container_registry.acr.sku == "${var.sku}"
    error_message = azurerm_container_registry.acr.sku
  }
}
run "container_registry_name" {
  command = plan #does not deploy the infrastructure
  assert {
    condition     = azurerm_container_registry.acr.name == "acr${var.postfix}"
    error_message = "acr name did not match expected"
  }
}
run "container_registry_admin_enabled" {

  assert {
    condition     = alltrue([azurerm_container_registry.acr.admin_enabled])
    error_message = azurerm_container_registry.acr.admin_enabled
  }
}

run "container_registry_login_server" {
  command = apply
  assert {
    condition     = azurerm_container_registry.acr.login_server == output.login_server
    error_message = azurerm_container_registry.acr.login_server
  }
}

run "resource_group_id" {
  command = apply
  assert {
    condition     = azurerm_resource_group.rg.id != ""
    error_message =  azurerm_resource_group.rg.id
  }
}
