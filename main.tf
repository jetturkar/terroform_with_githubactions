terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.57.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = "b514f69e-afe0-4e7f-a09a-b1e6c08b304c"
  client_id = "3967d0e7-e1be-4e4c-92fb-2a4a520110c5"
  client_secret = "ifM8Q~ZdNXBqRIweT9bybGMLFaejLSKuw3uEfbWq"
  tenant_id = "8fb29e9b-018d-4c75-89ef-a5407037d535"
  features {}

}
resource "azurerm_resource_group" "myapplication" {
  name     = "test-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "myapplication" {
   name                = "test-vnet"
   address_space       = ["10.0.0.0/16"]
   location            = azurerm_resource_group.myapplication.location
   resource_group_name = azurerm_resource_group.myapplication.name
 }

 resource "azurerm_subnet" "myapplication" {
   name                 = "test-subnet"
   resource_group_name  = azurerm_resource_group.myapplication.name
   virtual_network_name = azurerm_virtual_network.myapplication.name
   address_prefixes     = ["10.0.2.0/24"]
 }

 
resource "azurerm_public_ip" "myapplication" {
   name                         = "test-pip"
   location                     = azurerm_resource_group.myapplication.location
   resource_group_name          = azurerm_resource_group.myapplication.name
   allocation_method            = "Static"
 }

 resource "azurerm_lb" "myapplication" {
   name                = "test-lb"
   location            = azurerm_resource_group.myapplication.location
   resource_group_name = azurerm_resource_group.myapplication.name

   frontend_ip_configuration {
     name                 = "test-pip"
     public_ip_address_id = azurerm_public_ip.myapplication.id
   }
 }

 resource "azurerm_lb_backend_address_pool" "myapplication" {
   loadbalancer_id     = azurerm_lb.myapplication.id
   name                = "test-bp"
 }

 resource "azurerm_public_ip" "publicip" {
    name                    = "test-pip${count.index}"
    location                = azurerm_resource_group.myapplication.location
    resource_group_name     = azurerm_resource_group.myapplication.name
    allocation_method       = "Dynamic"
    count                   = 2
}

resource "azurerm_network_interface" "myapplication" {
   count               = 2
   name                = "test-nic${count.index}"
   location            = azurerm_resource_group.myapplication.location
   resource_group_name = azurerm_resource_group.myapplication.name

   ip_configuration {
     name                          = "nic-ip-Configuration"
     subnet_id                     = azurerm_subnet.myapplication.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = "${azurerm_public_ip.publicip[count.index].id}"
    
   }
 }

  resource "azurerm_managed_disk" "myapplication" {
   count                = 2
   name                 = "test-datadisk${count.index}"
   location             = azurerm_resource_group.myapplication.location
   resource_group_name  = azurerm_resource_group.myapplication.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "32"
 }

 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = azurerm_resource_group.myapplication.location
   resource_group_name          = azurerm_resource_group.myapplication.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
 }

 resource "azurerm_virtual_machine" "myapplication" {
   count                 = 2
   name                  = "test-vm${count.index}"
   location              = azurerm_resource_group.myapplication.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.myapplication.name
   network_interface_ids = [element(azurerm_network_interface.myapplication.*.id, count.index)]
   vm_size               = "Standard_B2ms"

   storage_image_reference {
     publisher = "MicrosoftWindowsServer"
     offer     = "WindowsServer"
     sku       = "2016-Datacenter"
     version   = "latest"
   }
   storage_os_disk {
     name              = "test-osdisk${count.index}"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   storage_data_disk {
     name            = element(azurerm_managed_disk.myapplication.*.name, count.index)
     managed_disk_id = element(azurerm_managed_disk.myapplication.*.id, count.index)
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = element(azurerm_managed_disk.myapplication.*.disk_size_gb, count.index)
   }

   os_profile {
    computer_name  = "hostname"
     admin_username = "azure"
     admin_password = "Qwerty@123456"
   }
   os_profile_windows_config {
  }
 }

backend "azurerm" {
  resource_group_name  = "test-rg"
  storage_account_name = "testacc26"
  container_name       = "terraformcontainer"
  key                  = "terraformcontainer.tfstate"
}
