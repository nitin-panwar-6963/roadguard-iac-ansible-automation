
# ==========================================
# RESOURCE GROUP
# ==========================================

resource "azurerm_resource_group" "my_rg" {
  name     = "nitin-terra-india"
  location = "India South Central"

  tags = {
    Project     = "RoadGuardAI"
    Description = "Infrastructure for Ansible and Docker"
  }
}


# ==========================================
# VIRTUAL NETWORK
# ==========================================

resource "azurerm_virtual_network" "my_vpc" {
  name                = "nitin-vpc"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  address_space = ["10.0.0.0/16"]
}


# ==========================================
# SUBNET
# ==========================================

resource "azurerm_subnet" "my_subnet" {
  name                 = "nitin-subnet"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vpc.name

  address_prefixes = ["10.0.1.0/24"]
}


# ==========================================
# PUBLIC IP
# ==========================================

resource "azurerm_public_ip" "public_ip" {
  name                = "nitin-public-ip"
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location

  allocation_method = "Static"
  sku               = "Standard"
}


# ==========================================
# NETWORK SECURITY GROUP
# ==========================================

resource "azurerm_network_security_group" "my_security" {
  name                = "terra-security"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name


  # SSH
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # HTTP
  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # HTTPS
  security_rule {
    name                       = "allow-https"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

  # Streamlit
  security_rule {
    name                       = "allow-8501"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8501"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # FastAPI Backend
  security_rule {
    name                       = "allow-8000"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # MySQL
  security_rule {
    name                       = "allow-3306"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # Port 100
  security_rule {
    name                       = "allow-100"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "100"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # Port 8080
  security_rule {
    name                       = "allow-8080"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # Allow all outbound traffic
  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# ==========================================
# NETWORK INTERFACE
# ==========================================

resource "azurerm_network_interface" "nic" {
  name                = "nitin-nic"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}


# ==========================================
# NSG ASSOCIATION
# ==========================================

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.my_security.id
}


# ==========================================
# LINUX VIRTUAL MACHINE
# ==========================================

resource "azurerm_linux_virtual_machine" "my_vm" {
  name                = "hazardlens"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  # 4 vCPU / 16 GB RAM
  size = "Standard_B4ms"


  # SSH KEY
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
  }


  # OS DISK
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }


  # Ubuntu 24.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}


