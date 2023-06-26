/*variable "prefix" {
  default = "tfvmex"
}*/
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.34.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
    subscription_id  = "49d062ad-2b68-47b5-9ada-f6779063a048"
    client_id        = "fbafc911-a4a0-406b-8199-216eaafb8721"
    client_secret    = "Pmi8Q~zBU.iDbG6WMGZiKaULzeGtKx5DmUgqact."
    tenant_id         = "7fa3b422-82da-42d9-8d7a-fa96a125d849"

    features {
      
    }
}
# Configure the Microsoft Azure Provider
/*provider "azurerm" {
  features {}
}
*/

variable "prefix" {
  default = "Node1"
}

resource "azurerm_resource_group" "rg2" {
  name     = "${var.prefix}-RG"
  location = "Central India"

  tags = {
    Owner = "Gyan"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
}
resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "net-int1" {
  name                = "${var.prefix}-NIC"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.node1.id
  }
}

resource "azurerm_public_ip" "node1" {
  name                = "${var.prefix}"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "Test"
  }
}
## SSH key code
#################################################################
resource "tls_private_key" "linux_key"{
  algorithm = "RSA"
  rsa_bits = 4096
}
resource "locale_file" "linuxkey"{
  filename = "privatekey.pem"
  content = tls_private_key.linux_key.private_key_pem
}
#Note: Need to comment line under linux vm resource
#disable_password_authentication = false and password as well.
#Note also have to add dependency to ensure the  tls_private_key.linux_key should be created 
#before VM. so for that we can use depends on block under virtualmachine
#################################################################

resource "azurerm_virtual_machine" "vm1" {
  name                  = "${var.prefix}-VM"
  location              = azurerm_resource_group.rg2.location
  resource_group_name   = azurerm_resource_group.rg2.name
  network_interface_ids = [azurerm_network_interface.net-int1.id]
  vm_size               = "Standard_DS11"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  admin_ssh_key {
    username = "demo"
    publickey = tls_private_key.linux_key.public_key_openssh
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 40
  }
  os_profile {
    computer_name  = "${var.prefix}"
    admin_username = "demo"
    #admin_password = "Password1234!"
  }
  os_profile_linux_config {
    #disable_password_authentication = false
  }
  tags = {
    environment = "Test"
  }
  depends_on = [
    azurerm_virtual_network.vnet1,
    tls_private_key.linux_key
  ]
  /*lifecycle {
    deprevent_destroy = fa
  }*/
}

  