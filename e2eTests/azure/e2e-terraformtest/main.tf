resource "random_integer" "rand" {
  min = 1000
  max = 9999
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-terratest-sample-${random_integer.rand.result}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terratest-sample"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

## Linux VM 1

resource "azurerm_public_ip" "pip" {
  name                    = "pip-vm-linux-1"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic-vm-linux-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-terraform-sample"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic1-nsg" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm-linux-1"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    when    = create
    command = "sleep 60"
  }
  depends_on = [azurerm_linux_virtual_machine.vm2]
}
resource "null_resource" "ssh_vm1" {
  provisioner "local-exec" {
    connection {
      host        = azurerm_network_interface.nic1.private_ip_address
      type        = "ssh"
      user        = "azureuser"
      private_key = file(var.ssh_private_key_file)
    }

    command = <<-EOT
      ssh-keyscan -H ${azurerm_network_interface.nic2.ip_configuration[0].private_ip_address} >> ~/.ssh/known_hosts
      VM2_PRIVATE_IP= ${azurerm_network_interface.nic2.ip_configuration[0].private_ip_address}
      ping -c 1 $VM2_PRIVATE_IP >>vm2_localfile.txt
      ls>>vm1_localfile.txt
      EOT

  }
  depends_on = [azurerm_linux_virtual_machine.vm1]
}

## Linux VM 2

resource "azurerm_network_interface" "nic2" {
  name                = "nic-vm-linux-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm-linux-2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_file)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "null_resource" "copy_output_to_local" {
  provisioner "local-exec" {
    command = "scp -i .//.ssh//id_rsa azureuser@${azurerm_public_ip.pip.ip_address}:vm1_localfile.txt ./vm2_localfile.txt"
  }

  depends_on = [azurerm_linux_virtual_machine.vm1]
}



