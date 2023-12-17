variable "domain_name" {
  type = string
  default = "<<<DOMAINNAME>>>-<<<DOMAINSUFFIX>>>"
}

variable "domain_fqdn" {
  type = string
  default = "<<<DOMAINNAME>>>.<<<DOMAINSUFFIX>>>"
}

resource "namecheap_domain_records" "<<<DOMAINNAME>>>" {
  domain = "${var.domain_fqdn}"
  mode = "MERGE"
  email_type = "MX"

  record {
    hostname = "<<<VMNAME>>>"
    type = "A"
     address = azurerm_public_ip.<<<VMNAME>>>_pip.ip_address
  }
}

resource "azurerm_public_ip" "<<<VMNAME>>>" {
  name                = "<<<VMNAME>>>-IP"
  location            = "East US"  # Replace with your desired region
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name
  allocation_method   = "Static"  # Or "Static" if you want a static IP
}



data "http" "current_ip" {
  url = "http://ipv4.icanhazip.com"
}


resource "azurerm_resource_group" "<<<VMNAME>>>" {
  name     = "<<<VMNAME>>>-resources"
#   location = "West Europe"
  location = "East US"
}

resource "azurerm_virtual_network" "<<<VMNAME>>>" {
  name                = "<<<VMNAME>>>-vnet"
  location            = azurerm_resource_group.<<<VMNAME>>>.location
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "<<<VMNAME>>>" {
  name                 = "<<<VMNAME>>>-subnet"
  resource_group_name  = azurerm_resource_group.<<<VMNAME>>>.name
  virtual_network_name = azurerm_virtual_network.<<<VMNAME>>>.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "<<<VMNAME>>>" {
  name                = "<<<VMNAME>>>-nic"
  location            = azurerm_resource_group.<<<VMNAME>>>.location
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.<<<VMNAME>>>.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.<<<VMNAME>>>_pip.id
  }
}


resource "azurerm_public_ip" "<<<VMNAME>>>_pip" {
  name                = "<<<VMNAME>>>-pip"
  location            = azurerm_resource_group.<<<VMNAME>>>.location
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name
  allocation_method   = "Dynamic"
}


resource "azurerm_network_security_group" "my_nsg" {
  name                = "<<<VMNAME>>>-nsg"
  location            = azurerm_resource_group.<<<VMNAME>>>.location
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name

  security_rule {
    name                       = "RDPAccess"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.current_ip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSHAccess"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.current_ip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRMAccessHTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = chomp(data.http.current_ip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRMAccessHTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = chomp(data.http.current_ip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SMTPAccess"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "25"
    source_address_prefix      = chomp(data.http.current_ip.body)
    destination_address_prefix = "*"
  }

  
}


resource "azurerm_windows_virtual_machine" "<<<VMNAME>>>" {
  name                = "<<<VMNAME>>>-vm"
  resource_group_name = azurerm_resource_group.<<<VMNAME>>>.name
  location            = azurerm_resource_group.<<<VMNAME>>>.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.<<<VMNAME>>>.id]
  
  depends_on = [azurerm_network_interface.<<<VMNAME>>>]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = "win10-22h2-avd-m365"
    version   = "latest"
  }
}

# resource "azurerm_virtual_machine_extension" "<<<VMNAME>>>" {
#   name                 = "cloud"
#   virtual_machine_id   = azurerm_windows_virtual_machine.<<<VMNAME>>>.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"

#   settings = jsonencode({
#     "scriptFile" = var.script_url
#   })
}
