terraform {

  backend "azurerm" {
  resource_group_name  = "test-rg"
  storage_account_name = "testacc26"
  container_name       = "terraformcontainer"
  key                  = "terraformcontainer.tfstate"
}

}
resource "azurerm_resource_group" "myapplication" {
  name     = "test-rg"
  location = "East US"
}
