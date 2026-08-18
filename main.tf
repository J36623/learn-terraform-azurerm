resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    "Environment" = "test"
    "Author"      = "nakano"
  }
}

# virtual network
resource "azurerm_virtual_network" "demo" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Subnet
resource "azurerm_subnet" "demo" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = var.subnet_address_prefix
}

resource "azurerm_subnet" "demo2" {
  name                 = "subnet-handson-demo2"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Storage Account
resource "azurerm_storage_account" "demo" {
  name                     = "${var.storage_account_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_resource_group.demo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Network Security Group：EC2でいうSecurity Group
resource "azurerm_network_security_group" "demo" {
  name                = "nsg-handson-demo-nakano"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "131.229.151.56" # デモ用。本番では自分のIPに絞る
    destination_address_prefix = "*"
  }
}

# NIC：EC2インスタンスに紐づくENIに相当
resource "azurerm_network_interface" "demo" {
  name                = "nic-handson-demo-nakano"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
//    public_ip_address_id          = azurerm_public_ip.demo.id #PIPの情報をコメントアウト
  }
}

# NICとNSGの紐づけ（AWSだとSGをインスタンス作成時に直接指定できるが、Azureは別途アタッチが必要）
resource "azurerm_network_interface_security_group_association" "demo" {
  network_interface_id      = azurerm_network_interface.demo.id
  network_security_group_id = azurerm_network_security_group.demo.id
}

# Linux VM本体：EC2インスタンスに相当
resource "azurerm_linux_virtual_machine" "demo" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.demo.id,
  ]

  admin_password                  = var.admin_password
  disable_password_authentication = false

   os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30               # 任意のサイズ(GB)

  }

  # Ubuntu 22.04 LTS。AWSでいうAMIの指定に相当
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ① 新しいデータディスクを作成
//   resource "azurerm_managed_disk" "demo_data" {
//     name                 = "${var.vm_name}-datadisk-01"
//     resource_group_name  = azurerm_resource_group.demo.name
//     location             = azurerm_resource_group.demo.location
//     storage_account_type = "Standard_LRS"   # 必要に応じて Premium_LRS 等に変更
//     create_option        = "Empty"          # 空のディスクを新規作成
//     disk_size_gb         = 30               # 任意のサイズ(GB)

//   }

//   # ② 作成したデータディスクを既存VMにアタッチ
//   resource "azurerm_virtual_machine_data_disk_attachment" "demo_data" {
//     managed_disk_id    = azurerm_managed_disk.demo_data.id
//     virtual_machine_id = azurerm_linux_virtual_machine.demo.id
//     lun                = 0          # VM内で一意な論理ユニット番号(0から)
//     caching            = "ReadWrite"
//   }
