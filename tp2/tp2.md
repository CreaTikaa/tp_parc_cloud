# TP 2 - Azure First Steps

## SSH Keys

On utilise ed25519 parce que c’est plus strong + c’est recommandé par l’ANSSI et plein de gens qui font des super recommendations

```powershell
❯ ssh-keygen -t ed25519
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/crea/.ssh/id_ed25519): cloud_tp1
Enter passphrase (empty for no passphrase): <truc>
Enter same passphrase again: <le_meme_truc>
Your identification has been saved in cloud_tp1
Your public key has been saved in cloud_tp1.pub
```

**Configurer un agent SSH sur votre poste**

~/.ssh/config

```powershell
Host a1
    Hostname 0.0.0.0
    User crea
    IdentityFile ~/.ssh/cloud_tp1
    ForwardAgent yes
```

## **II. Spawn des VMs**

```powershell
❯ ssh az1
The authenticity of host '9.205.88.15 (9.205.88.15)' can't be established.
ED25519 key fingerprint is SHA256:PgMzPUNUXyV7v4lYuUSDnB1sVGmXPLjg5Y4Xl8/DEzI.
This key is not known by any other names.

Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.17.0-1008-azure x86_64)

 [...]

crea@az1:~$

```

**2. `az` : a programmatic approach**

🌞 **Créez une VM depuis le Azure CLI**

```powershell
az>> az vm create -g cloud_tp -n meowVM --size Standard_B1s --image almalinux:almalinux-x86_64:10-gen2:10.1.202512150 --admin-username crea --ssh-key-values /tmp/ssh/cloud_tp1.pub
Consider upgrading security for your workloads using Azure Trusted Launch VMs. To know more about Trusted Launch, please visit https://aka.ms/TrustedLaunch.
{
  "fqdns": "",
  "id": "/subscriptions/.../resourceGroups/cloud_tp/providers/Microsoft.Compute/virtualMachines/meowVM",
  "location": "denmarkeast",
  "macAddress": "7C-ED-8D-6A-87-94",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.5",
  "publicIpAddress": "9.205.154.139",
  "resourceGroup": "cloud_tp"
}
```

 **Assurez-vous que vous pouvez vous connecter à la VM en SSH sur son IP publique**

```powershell
Host meowVM
    Hostname 9.205.154.139 
    User crea
    IdentityFile ~/.ssh/cloud_tp1
```

```powershell
❯ ssh meowVM
The authenticity of host '9.205.154.139 (9.205.154.139)' can't be established.
ED25519 key fingerprint is SHA256:5Cvpgwk/+pRruQQ70nWjBi7XfUTyazrEMG+LkbtBoDs.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.154.139' (ED25519) to the list of known hosts.
[crea@meowVM ~]$
```

🌞 **Une fois connecté, prouvez la présence...**

• **...du service `waagent.service`**

```bash
[crea@meowVM ~]$ systemctl status waagent.service
● waagent.service - Azure Linux Agent
     Loaded: loaded (/usr/lib/systemd/system/waagent.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-03-23 09:30:31 UTC; 6min ago
```

• **...du service `cloud-init.service`**

```bash
[crea@meowVM ~]$ systemctl status cloud-init.service
● cloud-init.service - Cloud-init: Network Stage
     Loaded: loaded (/usr/lib/systemd/system/cloud-init.service; enabled; preset: enabled)
     Active: active (exited) since Mon 2026-03-23 09:30:31 UTC; 7min ago
 Invocation: 04894c0e5a464a4fa2067d945fbd2329
   Main PID: 946 (code=exited, status=0/SUCCESS)
   Mem peak: 49.7M
        CPU: 951ms
```

## **3. Terraforming ~~planets~~ infrastructures**

🌞 **Utilisez Terraform pour créer une VM dans Azure**

TODO : rendre main.tf

```bash
❯ terraform apply 
[...]
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Still creating... [00m10s elapsed]
azurerm_resource_group.main: Still creating... [00m20s elapsed]
azurerm_resource_group.main: Creation complete after 24s [id=/subscriptions//resourceGroups/meow]
azurerm_virtual_network.main: Creating...
azurerm_public_ip.main: Creating...
azurerm_public_ip.main: Creation complete after 3s [id=/subscriptions//resourceGroups/meow/providers/Microsoft.Network/publicIPAddresses/vm-ip]
azurerm_virtual_network.main: Still creating... [00m10s elapsed]
azurerm_virtual_network.main: Creation complete after 10s [id=/subscriptions/resourceGroups/meow/providers/Microsoft.Network/virtualNetworks/vm-vnet]
azurerm_subnet.main: Creating...
azurerm_subnet.main: Still creating... [00m10s elapsed]
azurerm_subnet.main: Creation complete after 11s [id=/subscriptions/resourceGroups/meow/providers/Microsoft.Network/virtualNetworks/vm-vnet/subnets/vm-subnet]
azurerm_network_interface.main: Creating...
azurerm_network_interface.main: Creation complete after 3s [id=/subscriptions//resourceGroups/meow/providers/Microsoft.Network/networkInterfaces/vm-nic]
azurerm_linux_virtual_machine.main: Creating...
azurerm_linux_virtual_machine.main: Still creating... [00m10s elapsed]
azurerm_linux_virtual_machine.main: Still creating... [00m20s elapsed]
azurerm_linux_virtual_machine.main: Still creating... [00m30s elapsed]
azurerm_linux_virtual_machine.main: Still creating... [00m40s elapsed]
azurerm_linux_virtual_machine.main: Creation complete after 49s [id=/subscriptions//resourceGroups/meow/providers/Microsoft.Compute/virtualMachines/super-vm]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

```bash
~/Cours/tp_cloud/tp2                                                                                                                                                                                    12:26:11
❯ ssh 9.205.153.237 -i ~/.ssh/cloud_tp1
The authenticity of host '9.205.153.237 (9.205.153.237)' can't be established.
ED25519 key fingerprint is SHA256:VCFT754zV0g+k4+iWnDCbnrdhybQDlRbtRI3XHNjDlo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.153.237' (ED25519) to the list of known hosts.
[crea@super-vm ~]$
```
