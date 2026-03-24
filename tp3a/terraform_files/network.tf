resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.resource_group_name}-vm-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "ssh_only" {
  name                        = "AllowSSH_From_My_IP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.public_ip
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
} 

# On applique les regles sur l'interface de la vm
resource "azurerm_network_interface_security_group_association" "vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
