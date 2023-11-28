resource "azurerm_resource_group" "rg" {
  name     = "terratest-acr-rg-${var.postfix}"
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY AN AZURE CONTAINER REGISTRY
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.postfix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku           = var.sku
  admin_enabled = true

  tags = {
    Environment = "Development"
  }
}