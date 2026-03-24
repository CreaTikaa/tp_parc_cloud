# TP 3a - Terraform + Azure

## **I. Network Security Group**

[`network.tf`](http://network.tf) : 

```bash
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
```

→ Rendu dans le repo aussi

Ajout de la conf suivante à mon fichier `variables.tf :` 

```bash
variable "public_ip" {
  type        = string
  description = "Public IP for NSG rules"
}
```

Et la line suivante dans mon `terraform.tfvars` : 

```bash
public_ip = X.X.X.X
```

**3. Proofs !**

Output du apply, un peu cleaned up

```bash
❯ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_linux_virtual_machine.main will be created
  + resource "azurerm_linux_virtual_machine" "main" {
      + admin_username                                         = "crea"
      + location                                               = "denmarkeast"
      + name                                                   = "super-vm"
      + priority                                               = "Regular"
      + resource_group_name                                    = "chat"
      + size                                                   = "Standard_B1s"
      
      + admin_ssh_key {
          + public_key = <<-EOT
                ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaXU03TSF7hpOGcxYvan7TAMC7yj+r4IvlqvYWHAQdq crea@hope
            EOT
          + username   = "crea"
        }

      + source_image_reference {
          + offer     = "almalinux-x86_64"
          + publisher = "almalinux"
          + sku       = "10-gen2"
          + version   = "latest"
        }
    }

  # azurerm_network_interface.main will be created
  + resource "azurerm_network_interface" "main" {
      + accelerated_networking_enabled = false
      + ip_forwarding_enabled          = false
      + location                       = "denmarkeast"
      + name                           = "vm-nic"
      + resource_group_name            = "chat"

      + ip_configuration {
          + name                                               = "internal"
          + private_ip_address_allocation                      = "Dynamic"
          + private_ip_address_version                         = "IPv4"
        }
    }

  # azurerm_network_security_group.vm_nsg will be created
  + resource "azurerm_network_security_group" "vm_nsg" {
      + location            = "denmarkeast"
      + name                = "chat-vm-nsg"
      + resource_group_name = "chat"
    }

  # azurerm_network_security_rule.ssh_only will be created
  + resource "azurerm_network_security_rule" "ssh_only" {
      + access                      = "Allow"
      + destination_address_prefix  = "*"
      + destination_port_range      = "22"
      + direction                   = "Inbound"
      + id                          = (known after apply)
      + name                        = "AllowSSH_From_My_IP"
      + network_security_group_name = "chat-vm-nsg"
      + priority                    = 100
      + protocol                    = "Tcp"
      + resource_group_name         = "chat"
      + source_address_prefix       = "<pub_ip>"
      + source_port_range           = "*"
    }

  # azurerm_public_ip.main will be created
  + resource "azurerm_public_ip" "main" {
      + allocation_method       = "Static"
      + ddos_protection_mode    = "VirtualNetworkInherited"
      + ip_version              = "IPv4"
      + location                = "denmarkeast"
      + name                    = "vm-ip"
      + resource_group_name     = "chat"
      + sku                     = "Standard"
      + sku_tier                = "Regional"
    }

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + location = "denmarkeast"
      + name     = "chat"
    }

  # azurerm_subnet.main will be created
  + resource "azurerm_subnet" "main" {
      + address_prefixes                              = [
          + "10.0.1.0/24",
        ]
      + default_outbound_access_enabled               = true
      + name                                          = "vm-subnet"
      + private_endpoint_network_policies             = "Disabled"
      + private_link_service_network_policies_enabled = true
      + resource_group_name                           = "chat"
      + virtual_network_name                          = "vm-vnet"
    }

  # azurerm_virtual_network.main will be created
  + resource "azurerm_virtual_network" "main" {
      + address_space                  = [
          + "10.0.0.0/16",
        ]
      + location                       = "denmarkeast"
      + name                           = "vm-vnet"
      + private_endpoint_vnet_policies = "Disabled"
      + resource_group_name            = "chat"
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

Commande `az` : 

```bash
az>> az network nic list-effective-nsg --resource-group chat --name vm-nic --query "effectiveSecurityRu
{
  "value": [
    {
      "association": {
        "networkInterface": {
          "id": "/subscriptions/.../resourceGroups/chat/providers/Microsoft.Network/networkInterfaces/vm-nic",
          "resourceGroup": "chat"
        }
      },
      "effectiveSecurityRules": [
        {
          "access": "Allow",
          "destinationAddressPrefix": "0.0.0.0/0",
          "destinationAddressPrefixes": [
            "0.0.0.0/0"
          ],
          "destinationPortRange": "22-22",
          "destinationPortRanges": [
            "22-22"
          ],
          "direction": "Inbound",
          "name": "securityRules/AllowSSH_From_My_IP",
          "priority": 100,
          "protocol": "Tcp",
          "sourceAddressPrefix": "<pub_ip>/32",
          "sourceAddressPrefixes": [
            "<pub_ip>/32"
          ],
          "sourcePortRange": "0-65535",
          "sourcePortRanges": [
            "0-65535"
          ]
        },
```

Avec `ssh` : 

```bash
~/Cours/tp_cloud/tp2 main*                                                                    10:13:45
❯ ssh crea@9.205.153.74 -i ~/.ssh/cloud_tp1
[crea@super-vm ~]$ cat /etc/os-release
NAME="AlmaLinux"
VERSION="10.1 (Heliotrope Lion)"
```

Je change le port SSH pour 2222 dans `sshd_config` 

```bash
[crea@super-vm ~]$ sudo systemctl restart sshd
[crea@super-vm ~]$ sudo systemctl status sshd
● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-03-24 09:20:27 UTC; 4s ago

[crea@super-vm ~]$ sudo ss -lntp
State   Recv-Q   Send-Q     Local Address:Port     Peer Address:Port  Process
LISTEN  0        128              0.0.0.0:2222          0.0.0.0:*      users:(("sshd",pid=2077,fd=7))
LISTEN  0        128                 [::]:2222             [::]:*      users:(("sshd",pid=2077,fd=8))
```

Puis je retente de me co en ssh sur la vm : 

```bash
❯ ssh crea@9.205.153.74 -i ~/.ssh/cloud_tp1 -p 2222
kex_exchange_identification: Connection closed by remote host
Connection closed by 9.205.153.74 port 2222
```

marche po

## **II. Un ptit nom DNS**

### 1. Adapter le plan Terraform[¶](https://parcloud.b2.hita.wtf/tp/3a/2_dns/#1-adapter-le-plan-terraform)

🌞 **Donner un nom DNS à votre VM**

Updated [`main.tf`](http://main.tf) : 

```bash
resource "azurerm_public_ip" "main" {
  name                = "vm-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "meow"
}
```

**2. Ajouter un output custom à `terraform apply`**

Dans [`outputs.tf`](http://outputs.tf) : 

```bash
output "vm_public_ip" {
  description = "IP addr : "
  value       = azurerm_public_ip.main.ip_address
}

output "vm_dns_name" {
  description = "FQDN : "
  value       = azurerm_public_ip.main.fqdn
}
```

**3. Proooofs !**

```bash

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

vm_dns_name = "meow.denmarkeast.cloudapp.azure.com"
vm_public_ip = "9.205.152.239"
```

Test ssh : 

```bash
❯ ssh crea@meow.denmarkeast.cloudapp.azure.com -i ~/.ssh/cloud_tp1

1 device has a firmware upgrade available.
Run `fwupdmgr get-upgrades` for more information.

Last login: Tue Mar 24 09:41:08 2026 from 159.117.224.20
[crea@super-vm ~]$
```

works 👍

## **III. Blob storage**

Création de [`storage.tf`](http://storage.tf) : 

```bash
# storage.tf

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "meowcontainer" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.main.id  
  container_access_type = "private"
}

data "azurerm_virtual_machine" "main" {
  name                = azurerm_linux_virtual_machine.main.name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "vm_blob_access" {
  principal_id = data.azurerm_virtual_machine.main.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.main.id

  depends_on = [
    azurerm_linux_virtual_machine.main
  ]
}

```

Ajout des lignes suivantes dans [`variables.tf`](http://variables.tf) : 

```bash
variable "storage_account_name" {
  type        = string
  description = "Storage acc name"
}

variable "storage_container_name" {
  type        = string
  description = "storage cont name"
}
```

Ajout des lignes suivantes dans `terraform.tfvars` : 

```bash
storage_account_name = "m3g4rand0mnomduturfu67"
storage_container_name = "chatcontainer"
```

**3. Proooooooofs**

🌞 **Prouvez que tout est bien configuré, depuis la VM Azure**

```bash
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

vm_dns_name = "meow.denmarkeast.cloudapp.azure.com"
vm_public_ip = "9.205.156.56
```

Installation `azcopy` : 

```bash
[crea@super-vm ~]$ curl -L https://aka.ms/downloadazcopy-v10-linux -o azcopy.tar.gz
[crea@super-vm ~]$ tar -xvf azcopy.tar.gz
[crea@super-vm ~]$ sudo mv azcopy_linux_amd64_*/azcopy /usr/local/bin/
[crea@super-vm ~]$ azcopy --version
azcopy version 10.32.2
```

• utilisez `azcopy` pour écrire un fichier dans le *Storage Container* que vous avez créé

```bash
[crea@super-vm ~]$ echo miaou > salut.txt
[crea@super-vm ~]$ azcopy copy 'salut.txt' 'https://m3g4rand0mnomduturfu67.blob.core.windows.net/chatcontainer/salut.txt'
INFO: Autologin not specified.
INFO: Authenticating to destination using Azure AD
INFO: Any empty folders will not be processed, because source and/or destination doesn't have full folder support
INFO: Scanning...

Job fa2493d7-e47c-b444-5cae-af64cde5fdb9 has started
Log file is located at: /home/crea/.azcopy/fa2493d7-e47c-b444-5cae-af64cde5fdb9.log

100.0 %, 1 Done, 0 Failed, 0 Pending, 0 Skipped, 1 Total, 2-sec Throughput (Mb/s): 0

Job fa2493d7-e47c-b444-5cae-af64cde5fdb9 summary
Elapsed Time (Minutes): 0.0333
Number of File Transfers: 1
Number of Folder Property Transfers: 0
Number of Symlink Transfers: 0
Total Number of Transfers: 1
Number of File Transfers Completed: 1
Number of Folder Transfers Completed: 0
Number of File Transfers Failed: 0
Number of Folder Transfers Failed: 0
Number of File Transfers Skipped: 0
Number of Folder Transfers Skipped: 0
Number of Symbolic Links Skipped: 0
Number of Hardlinks Converted: 0
Number of Hardlinks Skipped: 0
Number of Special Files Skipped: 0
Total Number of Bytes Transferred: 6
Final Job Status: Completed
```

• utilisez `azcopy` pour lire le fichier que vous venez de push

```bash
[crea@super-vm ~]$ azcopy copy 'https://m3g4rand0mnomduturfu67.blob.core.windows.net/chatcontainer/salut.txt' 'retrieved_salut.txt'
INFO: Autologin not specified.
INFO: Authenticating to source using Azure AD
INFO: Any empty folders will not be processed, because source and/or destination doesn't have full folder support
INFO: Scanning...

Job a75731e4-ccb6-e442-7652-1ead0a6661e5 has started
Log file is located at: /home/crea/.azcopy/a75731e4-ccb6-e442-7652-1ead0a6661e5.log

100.0 %, 1 Done, 0 Failed, 0 Pending, 0 Skipped, 1 Total, 2-sec Throughput (Mb/s): 0

Job a75731e4-ccb6-e442-7652-1ead0a6661e5 summary
Elapsed Time (Minutes): 0.0333
Number of File Transfers: 1
Number of Folder Property Transfers: 0
Number of Symlink Transfers: 0
Total Number of Transfers: 1
Number of File Transfers Completed: 1
Number of Folder Transfers Completed: 0
Number of File Transfers Failed: 0
Number of Folder Transfers Failed: 0
Number of File Transfers Skipped: 0
Number of Folder Transfers Skipped: 0
Number of Symbolic Links Skipped: 0
Number of Hardlinks Converted: 0
Number of Hardlinks Skipped: 0
Number of Special Files Skipped: 0
Total Number of Bytes Transferred: 6
Final Job Status: Completed

[crea@super-vm ~]$ cat retrieved_salut.txt
miaou
```

🌞 **Déterminez comment `azcopy login --identity` vous a authentifié**

> The azcopy login command gets an OAuth token and then puts that token into a secret store on your system. If your operating system doesn't have a secret store, such as a Linux keyring, the azcopy login command doesn't work because there's nowhere to place the token.
> 

Donc en gros, on nous envoi un token OAuth (JWT ici) via la “Managed identity” de la VM sur laquelle on est puis le store chez nous (ou pas si on a pas d’endroit ou store les secrets) et permet de nous id 

🌞 **Requêtez un JWT d'authentification auprès du service que vous venez d'identifier, manuellement**

```bash
[crea@super-vm ~]$ curl -H "Metadata: true" \
> "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/"

{"access_token":"gros_token","client_id":"05d9ffd1-6ac8-4f0c-9b38-95849bf01167","expires_in":"86400","expires_on":"1774436576","ext_expires_in":"86399","not_before":"1774349876","resource":"https://storage.azure.com/","token_type":"Bearer"}
```

🌞 **Expliquez comment l'IP `169.254.169.254` peut être joignable**

```bash
[crea@super-vm ~]$ ip route
default via 10.0.1.1 dev eth0 proto dhcp src 10.0.1.4 metric 100
10.0.1.0/24 dev eth0 proto kernel scope link src 10.0.1.4 metric 100
168.63.129.16 via 10.0.1.1 dev eth0 proto dhcp src 10.0.1.4 metric 100
169.254.169.254 via 10.0.1.1 dev eth0 proto dhcp src 10.0.1.4 metric 100
```

On peut lui parler parle qu’il est directement dans notre table de routage via une IP que l’on peut contacter (10.0.1.1)

## **IV. Monitoring**

**2. Une alerte CPU**

🌞 **Compléter votre plan Terraform et mettez en place une alerte CPU**

On ajoute le si gentillement donné [`monitoring.tf`](http://monitoring.tf) : 

```bash
# monitoring.tf

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.resource_group_name}-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "vm-alerts"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email_address
  }
}

# CPU Metric Alert (using platform metrics)
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "cpu-alert-${azurerm_linux_virtual_machine.main.name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.main.id]
  description         = "Alert when CPU usage exceeds 70%"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  window_size   = "PT5M"
  frequency     = "PT1M"
  auto_mitigate = true

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
```

On update les variables encore : 

[`variables.tf`](http://variables.tf) : 

```bash
variable "alert_email_address" {
  type        = string
  description = "Email of the admin"
}
```

`terraform.tfvars` : 

```bash
alert_email_address = "email@mail.com"
```

**3. Alerte mémoire**

🌞 **Compléter votre plan Terraform et mettez en place une alerte mémoire**

```bash
# monitoring_memory.tf

resource "azurerm_monitor_action_group" "email_alert" {
  name                = "vm-email-actiongroup"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "vmalert"

  email_receiver {
    name                    = "SendToAdmin"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "memory_alert" {
  name                = "low-memory-alert"
  resource_group_name = azurerm_resource_group.main.name

  scopes              = [azurerm_linux_virtual_machine.main.id]
  description         = "Alert RAM less de 512 Mo."

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 536870912
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert.id
  }
}

```

### 4. Proofs

A. Voir les alertes avec `az`

```bash
> az monitor metrics alert list --resource-group chat -o table
AutoMitigate    Description                       Enabled    EvaluationFrequency    Location    Name                ResourceGroup    Severity    TargetResourceRegion    TargetResourceType    WindowSize
--------------  --------------------------------  ---------  ---------------------  ----------  ------------------  ---------------  ----------  ----------------------  --------------------  ------------
True            Alert when CPU usage exceeds 70%  True       0:01:00                global      cpu-alert-super-vm  chat             2                                                         0:05:00
True            Alert RAM less de 512 Mo.         True       0:01:00                global      low-memory-alert    chat             3                                                         0:05:00
```

### B. Stress pour *fire* les alertes

🌞 **Stress de la machine**

```bash
[crea@super-vm ~]$ sudo dnf install stress-ng -y

[crea@super-vm ~]$ stress-ng --cpu 1 --cpu-load 100 --timeout 5m
stress-ng: info:  [2052] setting to a 5 mins run per stressor
stress-ng: info:  [2052] dispatching hogs: 1 cpu
stress-ng: info:  [2052] note: system has only 292 MB of free memory and swap, recommend using --oom-avoid
stress-ng: info:  [2053] cpu: for stable load results, select a specific cpu stress method with --cpu-method other than 'all'

[crea@super-vm ~]$ stress-ng --vm 1 --vm-bytes 700M --timeout 10m
stress-ng: info:  [2084] setting to a 10 mins run per stressor
stress-ng: info:  [2084] dispatching hogs: 1 vm
stress-ng: info:  [2084] note: system has only 465 MB of free memory and swap, recommend using --oom-avoid

```

🌞 **Vérifier que des alertes ont été *fired***

Commande donnait fonctionnait pas chez moi et ce que j’ai trouvé en ligne marchait po non plus donc monsieur GPT m’a give ça : 

```bash
❯ az graph query -q "alertsmanagementresources | where type == 'microsoft.alertsmanagement/alerts' | project AlertName=name, Status=tostring(properties.essentials.monitorCondition), Severity=tostring(properties.essentials.severity), FiredTime=tostring(properties.essentials.startDateTime), TargetVM=tostring(properties.essentials.targetResourceName)" --query "data" -o table
AlertName         Status    Severity    FiredTime                     TargetVM
----------------  --------  ----------  ----------------------------  ----------
low-memory-alert  Fired     Sev3        2026-03-24T12:00:38.1374112Z  super-vm
low-memory-alert  Resolved  Sev3        2026-03-24T11:41:53.4279309Z  super-vm
```

- j’ai filé l’eml du mail reçu dans le repo (j’ai juste remove le subscription_id)

## **V. Azure Vault**

🌞 **Compléter votre plan Terraform et mettez en place une *Azure Key Vault***

et zééééé reparti

[`keyvault.tf`](http://keyvault.tf) : 

```bash
# keyvault.tf

data "azurerm_client_config" "current" {}

resource "random_password" "meow_secret" {
  length           = 16
  special          = true
  override_special = "@#$%^&*()"
}

resource "azurerm_key_vault" "meow_vault" {
  name                       = var.keyvault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine.main.identity[0].principal_id
    secret_permissions = [
      "Get", "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "meow_secret" {
  name         = var.secret_name
  value        = random_password.meow_secret.result
  key_vault_id = azurerm_key_vault.meow_vault.id

  depends_on = [
    azurerm_key_vault.meow_vault
  ]
}
```

[`variables.tf`](http://variables.tf) : 

```bash
variable "keyvault_name" {
  type        = string
  description = "Nom Vault"
}

variable "secret_name" {
  type        = string
  description = "Secret name dans Vault"
}
```

`terraform.tfvars` : 

```bash
keyvault_name = "v4ultd3s4l0p4rd"
secret_name = "my_very_secret_secret"
```

P’tit bonus : `outputs.tf`

```bash
output "key_vault_secret" {
  description = "secret"
  value       = azurerm_key_vault_secret.meow_secret.value
  sensitive = true (sinon monsieur terraform il veut pas)
}
```

```bash
❯ terraform output -raw key_vault_secret
x98YXrGacw4P5mGD
```

**3. Proof proof proof**

🌞 **Avec une commande `az`, afficher le *secret***

```bash
az>> az keyvault secret show --name "my-very-secret-secret" --vault-name "nomdegolmonsamere" --query "value" -o tsv
x98YXrGacw4P5mGD
```

🌞 **Depuis la VM, afficher le secret**

Petit script shell qui s’occupe de le faire (après avoir `sudo dnf install jq -y`)

```bash
#!/bin/bash

VAULT_NAME="nomdegolmonsamere"
SECRET_NAME="my-very-secret-secret"

# demande token id
TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')

# demande secret a l'api avec token en bearer
SECRET_VALUE=$(curl -s -H "Authorization: Bearer $TOKEN" "https://${VAULT_NAME}.vault.azure.net/secrets/${SECRET_NAME}?api-version=7.4" | jq -r '.value')

echo "$SECRET_VALUE"
```

Puis 

```bash
[crea@super-vm ~]$ chmod +x get_secret.sh
[crea@super-vm ~]$ ./retrieve_secret.sh
x98YXrGacw4P5mGD
```

👍
