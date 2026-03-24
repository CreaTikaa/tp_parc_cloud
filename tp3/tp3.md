## **TP3B Part1 - Create the base VM**

**2. Feu patate**

🌞 **Créez une VM azure** (une commande `az`)

```bash
az>> az vm create -g miaou -n meowVM --size Standard_B1s --image almalinux:almalinux-x86_64:10-gen2:10.1.202512150 --admin-username crea --ssh-key-values /tmp/ssh/cloud_tp1.pub
Consider upgrading security for your workloads using Azure Trusted Launch VMs. To know more about Trusted Launch, please visit https://aka.ms/TrustedLaunch.
{
  "fqdns": "",
  "id": "/subscriptions/.../resourceGroups/miaou/providers/Microsoft.Compute/virtualMachines/meowVM",
  "location": "denmarkeast",
  "macAddress": "7C-ED-8D-6B-01-4B",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.4",
  "publicIpAddress": "9.205.154.33",
  "resourceGroup": "miaou"
}
```

🌞 **Connexion SSH**

```bash
❯ ssh miaou
The authenticity of host '9.205.154.33 (9.205.154.33)' can't be established.
ED25519 key fingerprint is SHA256:SWDzsPCFXPW+lNBvVzZLETdI07WJkBieXzYAtbEWH20.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.154.33' (ED25519) to the list of known hosts.

1 device has a firmware upgrade available.
Run `fwupdmgr get-upgrades` for more information.

[crea@meowVM ~]$
```

## **TP3B Part2 - Prepare the VM**

**1. Poser notre conf custom**

```bash
[crea@meowVM ~]$ sudo dnf update -y && sudo dnf install -y htop vim bind-utils iputils
AlmaLinux 10 - AppStream                                               1.8 MB/s | 2.3 MB     00:01
AlmaLinux 10 - BaseOS                                                   22 MB/s |  18 MB     00:00
AlmaLinux 10 - CRB                                                     1.5 MB/s | 523 kB     00:00
AlmaLinux 10 - Extras                                                   40 kB/s |  12 kB     00:00
Dependencies resolved.
[...]

```

htop pas dispo donc 

```bash
[crea@meowVM ~]$ sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb && sudo dnf install -y htop
```

### **2. Clean la VM**

On a 3 trucs à faire :

- **réinitialiser `cloud-init`** : pour qu'il puisse re-run au prochain boot
- **clean le système** : effacer l'historique de commandes, les logs, etc
- **réinitialiser `waagent`** : l'agent Azure qui gère la VM

```bash
[crea@meowVM ~]$ sudo cloud-init clean --logs
[crea@meowVM ~]$ sudo rm -rf /var/lib/cloud/*
[crea@meowVM ~]$ sudo systemctl enable cloud-init
```

```bash
[crea@meowVM ~]$ sudo rm -rf /var/log/* 
[crea@meowVM ~]$ cat /dev/null > ~/.bash_history
[crea@meowVM ~]$ history -c
```

(version gros bourrin, on pourrait faire `sudo journalctl --rotate` & `sudo journalctl --vacuum-time=1s` pour etre plus clean au niveau du journal systemd mais la on delete tout d’un coup (meme les logs root)

```bash
[crea@meowVM ~]$ sudo dnf clean all
[crea@meowVM ~]$ sudo rm -rf /var/lib/waagent/*
[crea@meowVM ~]$ sudo waagent -deprovision+user -force
```

## **TP3B Part3 - Create a template**

**1. Créer le template**

```bash
az>> vm deallocate --resource-group miaou --name meowVM

az>> vm generalize --resource-group miaou --name meowVM

az>> image create --resource-group miaou --name  mega_miaou --source meowVM --hyper-v-generation V2

{
  "hyperVGeneration": "V2",
  "id": "/subscriptions/.../resourceGroups/miaou/providers/Microsoft.Compute/images/mega_miaou",
  "location": "denmarkeast",
  "name": "mega_miaou",
  "provisioningState": "Succeeded",
  "resourceGroup": "miaou",
  "sourceVirtualMachine": {
    "id": "/subscriptions/.../resourceGroups/miaou/providers/Microsoft.Compute/virtualMachines/meowVM",
    "resourceGroup": "miaou"
  },
  "storageProfile": {
    "dataDisks": [],
    "osDisk": {
      "caching": "ReadWrite",
      "diskSizeGB": 30,
      "managedDisk": {
        "id": "/subscriptions/.../resourceGroups/miaou/providers/Microsoft.Compute/disks/meowVM_disk1_d3f5c598539a44bba7550743e99624a4",
        "resourceGroup": "miaou"
      },
      "osState": "Generalized",
      "osType": "Linux",
      "storageAccountType": "Premium_LRS"
    }
  },
  "tags": {},
  "type": "Microsoft.Compute/images"
}
```

**2. Tester le template**

🌞 **Lancer une VM à partir de votre template**

```bash
az>> az vm create -g miaou -n CHAT_GOAT --size Standard_B1s --image mega_miaou --admin-username crea --ssh-key-values /tmp/ssh/cloud_tp1.pub
{
  "fqdns": "",
  "id": "/subscriptions/.../resourceGroups/miaou/providers/Microsoft.Compute/virtualMachines/CHAT_GOAT",
  "location": "denmarkeast",
  "macAddress": "7C-ED-8D-6A-B5-43",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.5",
  "publicIpAddress": "9.205.156.84",
  "resourceGroup": "miaou"
}
```

🌞 **Vérification !**

```bash
❯ ssh mega_miaou
The authenticity of host '9.205.156.84 (9.205.156.84)' can't be established.
ED25519 key fingerprint is SHA256:pSLO66gpCS3aMBrjbPqABTZXthLloOtWDxSeEVJB5wA.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.156.84' (ED25519) to the list of known hosts.

[crea@CHATGOAT ~]$ which htop
/usr/bin/htop
[crea@CHATGOAT ~]$ systemctl status cloud-init.service
● cloud-init.service - Cloud-init: Network Stage
     Loaded: loaded (/usr/lib/systemd/system/cloud-init.service; enabled; preset: enabled)
     Active: active (exited) since Mon 2026-03-23 13:44:23 UTC; 2min 10s ago
 Invocation: 4244600b31134d478d918e95dc44fbc2
   Main PID: 947 (code=exited, status=0/SUCCESS)
   Mem peak: 48.1M
        CPU: 819ms

[...]
Mar 23 13:44:23 CHATGOAT systemd[1]: Finished cloud-init.service - Cloud-init: Network Stage.

[crea@CHATGOAT ~]$ systemctl status waagent
● waagent.service - Azure Linux Agent
     Loaded: loaded (/usr/lib/systemd/system/waagent.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-03-23 13:44:23 UTC; 2min 14s ago
 Invocation: c52e45c59dd44fa2b8239782b017faaa
   Main PID: 1322 (python3)
      Tasks: 6 (limit: 5158)
     Memory: 49.2M (peak: 51.2M)
        CPU: 1.528s
     CGroup: /azure.slice/waagent.service
             ├─1322 /usr/bin/python3 -u /usr/sbin/waagent -daemon
             └─1452 /usr/bin/python3 -u bin/WALinuxAgent-2.15.0.1-py3.12.egg -run-exthandlers
```

## **TP3B Part4 - Hardened template**

**Setup ur env**

🌞 **Créez une VM qui servira à créer le template**

```bash
az>> az vm create -g MIAOU-SOLIDE -n petit_miaou_deviendra_grand_miaou --size Standard_B1s --image almalinux:almalinux-x86_64:10-gen2:10.1.202512150 --admin-username crea --ssh-key-values /tmp/ssh/cloud_tp1.pub
{
  "fqdns": "",
  "id": "/subscriptions/.../resourceGroups/MIAOU-SOLIDE/providers/Microsoft.Compute/virtualMachines/petit_miaou_deviendra_grand_miaou",
  "location": "denmarkeast",
  "macAddress": "7C-ED-8D-6A-B4-FE",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.4",
  "publicIpAddress": "9.205.155.3",
  "resourceGroup": "MIAOU-SOLIDE"
}
```

### **TP3B Part4 - A. Firewalling baby**

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo dnf update -y && sudo dnf install firewalld

[crea@petitmiaoudeviendragrandmiaou ~]$ sudo systemctl start firewalld
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo systemctl enable firewalld
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --list-all
public (default, active)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: eth0
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules: -y
```

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --zone=work --remove-service=ssh --permanent
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --zone=public --remove-service=ssh --perman>
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --zone=public --remove-service=cockpit --pe>
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --reload
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --list-all
public (default, active)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: eth0
  sources:
  services:
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --reload
success
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo firewall-cmd --list-all
public (default, active)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: eth0
  sources:
  services:
  ports: 22/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

### **TP3B Part4 - B. Stronk SSH**

Recommandations suivies : 

https://messervices.cyber.gouv.fr/documents-guides/NT_OpenSSH.pdf

https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-18-04

```bash
Include /etc/ssh/sshd_config.d/*.conf

Port 22

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers recommandés par l'ANSSI + pas de banner pr pas donner des infos pr rien
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
Banner none

# Logging
SyslogFacility AUTH
LogLevel INFO

# strict mode + pas permit root login & gracetime permet d'éviter des DoS
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
LoginGraceTime 20

# pubkey auth
PubkeyAuthentication yes
AuthorizedKeysFile	.ssh/authorized_keys

# pas besoin de tout ça ici donc on disable
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
X11Forwarding no
AllowTcpForwarding no
# pas besoin de gui pr un serveur a priori + disable forwarding tant que c'est pas use

# pas autorisé password, only pubkey & on change pas les variable d'env !!
PasswordAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
PermitUserEnvironment no

#AllowAgentForwarding yes
#AllowTcpForwarding yes

# ssh propose aussi un serveur sftp pour download/upload des files, ne requiert pas d'accès shell donc on chroot tout les users qui utilisent que sftp
Subsystem	sftp	/usr/libexec/openssh/sftp-server
Match group sftp-users
ForceCommand internal-sftp
ChrootDirectory /sftp-home/\%u
```

→ Lire tout moche ici ou voir file `sshd_config` dans dépôt 

### **TP3B Part4 - C. fail2ban**

🌞 **Installer et configurer `fail2ban`**

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo dnf install epel-release -y
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo dnf install fail2ban -y
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo nano /etc/fail2ban/jail.d/sshd.conf
```

```bash
[sshd]
enabled = true
port = ssh
mode = aggressive # sinon ça marche po pr ban vu que y'a juste un denied si ya la mauvaise pubkey
maxretry = 2 # 2 retry
findtime = 3600 # droit a 2 try en 1h pr pas que le bruteforcer essaye juste d'attendre 10m que ça passe mdrr
bantime = -1 # ban def
```

On active la conf mtn : 

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo systemctl enable fail2ban --now
Created symlink '/etc/systemd/system/multi-user.target.wants/fail2ban.service' → '/usr/lib/systemd/system/fail2ban.service'.
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo systemctl start fail2ban

```

🌞 **Prouvez que `fail2ban` fonctionne**

Maintenant on va se faire ban pour le love of the game (j’ai demandé à amir de ce faire ban pr moi parce que j’avais trop la flemme de devoir aller sur la web ui)

Before : 

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- Journal matches:	_SYSTEMD_UNIT=sshd.service + _COMM=sshd + _COMM=sshd-session
`- Actions
   |- Currently banned:	0
   |- Total banned:	0
   `- Banned IP list:	
```

After : 

```bash
[crea@petitmiaoudeviendragrandmiaou jail.d]$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	2
|  `- Journal matches:	_SYSTEMD_UNIT=sshd.service + _COMM=sshd + _COMM=sshd-session
`- Actions
   |- Currently banned:	1
   |- Total banned:	1
   `- Banned IP list:	185.165.243.172
```

### **TP3B Part4 - D. Harden kernel parameters**

**2. Setup**

```bash
# Restreint l'accès au buffer dmesg
kernel.dmesg_restrict=1

# Cache les addresses kernel dans /proc et les différentes autres interfaces
kernel.kptr_restrict=2

# Spécifie explicitement le nb d'id de process supportés
kernel.pid_max=32768

# Restreint l'utilisation du sous-système perf
kernel.perf_cpu_time_max_percent=1
kernel.perf_event_max_sample_rate=1

# Interdit l'accès non privilégié à l'appel système perf_event_open()
kernel.perf_event_paranoid=2

# Active l'ASLR
kernel.randomize_va_space=2

# Désactive les combinaisons des Magic System Request Key
kernel.sysrq=0

# Restreint l'usage du BPF noyau aux utilisateurs privilégiés
kernel.unprivileged_bpf_disabled=1

# Arrête complètement le système en cas de comportement inattendu du noyau Linux
kernel.panic_on_oops=1

# Atténuation de l'effet de dispersion du JIT noyau au coût d'un compromis sur
# les performances associées.
net.core.bpf_jit_harden=2

# Pour un serveur qui n'a pas besoin de faire du routage
net.ipv4.ip_forward=0
net.ipv4.conf.all.accept_local=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.shared_media=0
net.ipv4.conf.default.shared_media=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
# Empêche le noyau Linux de gérer la table ARP global
net.ipv4.conf.all.arp_filter=1
# Eviter du traffic arp bizarre hors lan
net.ipv4.conf.all.arp_ignore=2
# pr éviter arp poisoning
net.ipv4.conf.all.drop_gratuitous_arp=1
# Ignorer les réponses non conformes à la RFC 1122
net.ipv4.icmp_ignore_bogus_error_responses=1
# RFC 1337
net.ipv4.tcp_rfc1337=1
# Eviter attaque type SYN flood.
net.ipv4.tcp_syncookies=1

# Pas besoin d'ipv6 si notre serveu est full setup ipv4, mais a remove dans le cas ou on introduit del'ipv6
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.all.disable_ipv6=1

# Restreint la création de liens symboliques à des fichiers dont l'utilisateur est propriétaire
fs.protected_symlinks=1
# Restreint la création de liens durs à des fichiers dont l'utilisateur est propriétaire
fs.protected_hardinks=1
```

Pareil, tout moche ici, mais voir `sysctl.conf` dans le repo pour plus clean.

Ressources : https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

### **TP3B Part4 - E. IDS**

**2. Setup simple**

🌞 **Installer l'IDS AIDE**

```bash
crea@petitmiaoudeviendragrandmiaou ~]$ sudo dnf install aide
======================================================================================================
 Package           Architecture        Version                           Repository              Size
======================================================================================================
Installing:
 aide              x86_64              0.18.6-8.el10_1.2                 appstream              145 k
[...]
Installed:
  aide-0.18.6-8.el10_1.2.x86_64
```

🌞 **Initialiser la base de données AIDE**

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo aide --init
Start timestamp: 2026-03-23 15:49:23 +0000 (AIDE 0.18.6)
AIDE successfully initialized database.
New AIDE database written to /var/lib/aide/aide.db.new.gz

Number of entries:	21

---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------

/var/lib/aide/aide.db.new.gz
 MD5       : GgbJasCIEWayWq4JVj14vw==
 SHA1      : 1s47b7krprQoVG8FHg6b6LIz9jM=
 SHA256    : Dlm9HzB/MKaSPI/KoccIdvPUgVv0KKGo
             TgcONHhdL3o=
 SHA512    : a7BKbqwBi4EPqbrR5C2gR9ewsDRYSdPQ
             ukoHggHJv1kn4jz/w4H/hTatNQYnrW9W
             1rtwDZw4Lvgp+mDDtamJiA==
 RMD160    : J5SHBF9uzhU08IXmPOpuHZTiWVQ=

End timestamp: 2026-03-23 15:49:23 +0000 (run time: 0m 0s)

[crea@petitmiaoudeviendragrandmiaou ~]$ sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo aide --check
Start timestamp: 2026-03-23 15:49:37 +0000 (AIDE 0.18.6)
AIDE found NO differences between database and filesystem. Looks okay!!

Number of entries:	21

---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------

/var/lib/aide/aide.db.gz
 MD5       : GgbJasCIEWayWq4JVj14vw==
 SHA1      : 1s47b7krprQoVG8FHg6b6LIz9jM=
 SHA256    : Dlm9HzB/MKaSPI/KoccIdvPUgVv0KKGo
             TgcONHhdL3o=
 SHA512    : a7BKbqwBi4EPqbrR5C2gR9ewsDRYSdPQ
             ukoHggHJv1kn4jz/w4H/hTatNQYnrW9W
             1rtwDZw4Lvgp+mDDtamJiA==
 RMD160    : J5SHBF9uzhU08IXmPOpuHZTiWVQ=

End timestamp: 2026-03-23 15:49:37 +0000 (run time: 0m 0s)
```

🌞 **Proposer une conf AIDE**

Ma configuration AIDE dans `/etc/aide.conf` : 

```bash
# Example configuration file for AIDE.

@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide

# The location of the database to be read.
database_in=file:@@{DBDIR}/aide.db.gz

# The location of the database to be written.
#database_out=sql:host:port:database:login_name:passwd:table
#database_out=file:aide.db.new
database_out=file:@@{DBDIR}/aide.db.new.gz

# Whether to gzip the output to database
gzip_dbout=yes

# Default.
log_level=warning
report_level=changed_attributes

report_url=file:@@{LOGDIR}/aide.log
report_url=stdout

FIPSR = p+i+n+u+g+s+acl+selinux+xattrs+sha256
# NORMAL
NORMAL = FIPSR+sha512
# SECURE = full checking with multiple hashes
SECURE = p+i+n+u+g+s+m+c+sha256+sha512

/etc/exports  NORMAL
/etc/fstab    NORMAL
/etc/passwd   NORMAL
/etc/group    NORMAL
/etc/gshadow  NORMAL
/etc/shadow   NORMAL
/etc/security/opasswd   NORMAL

/etc/sysctl.conf SECURE
/etc/ssh/sshd_config SECURE
/etc/ssh/ssh_config SECURE
/etc/ssh/sshd_config.d/ SECURE
/etc/sysctl.d/ SECURE
```

🌞 **Jouer avec les tests d'intégrité AIDE**

Before : 

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo aide --check
Start timestamp: 2026-03-23 15:55:53 +0000 (AIDE 0.18.6)
AIDE found NO differences between database and filesystem. Looks okay!!

Number of entries:	22

---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------

/var/lib/aide/aide.db.gz
 MD5       : lou9eFmicmtbEeiDHIdfow==
 SHA1      : xca5tLNLrAJLO8DpODl6NGGhTqQ=
 SHA256    : LoC7c8DfIN5GGJ9QgEepIqGNg98qKFTn
             RhQMlpAT9bE=
 SHA512    : JUCi/aawVIwZyFdbnO4yJXfrB/HgLbMD
             iMQfn0kepsrIqv8bXJYUbiTGmX4+liRg
             0g3o6IflgnMww09TbIjdeA==
 RMD160    : 3q2LoiPG+ZgWu0IdDMw1iKYg6Z4=

End timestamp: 2026-03-23 15:55:53 +0000 (run time: 0m 0s)
[crea@petitmiaoudeviendragrandmiaou ~]$
```

After : 

```bash
crea@petitmiaoudeviendragrandmiaou ~]$ sudo aide --check
Start timestamp: 2026-03-23 15:57:01 +0000 (AIDE 0.18.6)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	22
  Added entries:		0
  Removed entries:		0
  Changed entries:		1

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > ... mc..H    : /etc/ssh/sshd_config

---------------------------------------------------
Detailed information about changes:
---------------------------------------------------

File: /etc/ssh/sshd_config
 Size      : 1527                             | 1534
 Mtime     : 2026-03-23 14:40:09 +0000        | 2026-03-23 15:56:57 +0000
 Ctime     : 2026-03-23 14:40:09 +0000        | 2026-03-23 15:56:57 +0000
 SHA256    : AC/DkXrTSSjAjupnHx3mxrvuZwrQZhBM | 6wsiZxNetSwoYDaj8ZulfpDdzE3SQYa/
             PhAMZIrb2KA=                     | SWSfTJF5tWs=
 SHA512    : 5TTRW8RGlrF6kXI/r/Z+51DTH8esF2QP | GLkArfuD3zbuKI0hae818UInXwcm0KIp
             lmMCCI6bCjH73abOKDHSgOl3U3SSXx4R | JYz3UOwH0oeUS6q4TgJ8swB38YzLgelt
             LeTOBZWrb2uyzZ6MrBcKlg==         | xm7vVafESN4xiN/ybIFghg==

---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------

/var/lib/aide/aide.db.gz
 MD5       : lou9eFmicmtbEeiDHIdfow==
 SHA1      : xca5tLNLrAJLO8DpODl6NGGhTqQ=
 SHA256    : LoC7c8DfIN5GGJ9QgEepIqGNg98qKFTn
             RhQMlpAT9bE=
 SHA512    : JUCi/aawVIwZyFdbnO4yJXfrB/HgLbMD
             iMQfn0kepsrIqv8bXJYUbiTGmX4+liRg
             0g3o6IflgnMww09TbIjdeA==
 RMD160    : 3q2LoiPG+ZgWu0IdDMw1iKYg6Z4=

End timestamp: 2026-03-23 15:57:01 +0000 (run time: 0m 0s)
```

**3. Automated**

🌞 **Créer un service systemd pour lancer un test AIDE**

Dans `/systemd/system/aide-test.service` : 

```bash
[Unit]
Description=Run an AIDE integrity check

[Service]
Type=oneshot
ExecStart=/usr/sbin/aide --check
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

🌞 **Indiquer à systemd qu'on a modifié les services**

```bash
[crea@petitmiaoudeviendragrandmiaou system]$ sudo systemctl daemon-reload
```

🌞 **Tester le service**

```bash
[crea@petitmiaoudeviendragrandmiaou system]$ sudo systemctl start aide-test
[crea@petitmiaoudeviendragrandmiaou system]$ journalctl -xeu aide-test.service
░░ A start job for unit aide-test.service has begun execution.
░░
░░ The job identifier is 9842.
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: WARNING: /var/lib/aide/aide.db.gz: gnutls_hash_init (stribog256) failed for '/var/lib/aide/aide.db.gz'
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: WARNING: /var/lib/aide/aide.db.gz: gnutls_hash_init (stribog512) failed for '/var/lib/aide/aide.db.gz'
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: Start timestamp: 2026-03-23 16:02:49 +0000 (AIDE 0.18.6)
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: AIDE found NO differences between database and filesystem. Looks okay!!
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: Number of entries:        22
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: ---------------------------------------------------
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: The attributes of the (uncompressed) database(s):
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: ---------------------------------------------------
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: /var/lib/aide/aide.db.gz
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:  MD5       : BL2hiJxA8uB+JLc00+wCZQ==
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:  SHA1      : b7UGLYrD9yFevzZ7/37BiayXyv0=
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:  SHA256    : +cBa8x3FPiJQ1r6ZEwSaLscvPvgmWle6
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:              lFnIH8fphoE=
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:  SHA512    : YG6r9ehC5StCH7wqeu7JBykY5DNnscQ8
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:              GWp3vDOuEMmhxynvElwbS3vnp3+SP+hI
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:              KDHgLjVguSISApP3VDN8hA==
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]:  RMD160    : 1YyAs6nQWfPNIQyZH6LxlItJL2w=
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou aide[35624]: End timestamp: 2026-03-23 16:02:49 +0000 (run time: 0m 0s)
Mar 23 16:02:49 petitmiaoudeviendragrandmiaou systemd[1]: Finished aide-test.service - Run an AIDE integrity check.
░░ Subject: A start job for unit aide-test.service has finished successfully
░░ Defined-By: systemd
░░ Support: https://wiki.almalinux.org/Help-and-Support
░░
░░ A start job for unit aide-test.service has finished successfully.
░░
░░ The job identifier is 9842.
```

```bash
[crea@petitmiaoudeviendragrandmiaou system]$ systemctl status aide-test
● aide-test.service - Run an AIDE integrity check
     Loaded: loaded (/etc/systemd/system/aide-test.service; disabled; preset: disabled)
     Active: active (exited) since Mon 2026-03-23 16:02:49 UTC; 44s ago
 Invocation: 6a7d9b6052f14567838a65bc59bd8098
    Process: 35624 ExecStart=/usr/sbin/aide --check (code=exited, status=0/SUCCESS)
   Main PID: 35624 (code=exited, status=0/SUCCESS)
   Mem peak: 1.9M
        CPU: 21ms
```

🌞 **Créer un *timer* systemd**

```bash
[Unit]
Description=Timer AIDE

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

### **4. Bonus : Alerte Discord**

⭐ **Proposer un setup qui permet de recevoir des alertes Discord**

- donc le script et le service systemd mis à jour
- invitez-moi dans votre serv Discord que je vois les alertes :)

Le script : 

```bash
#!/bin/bash

AIDE_WEBHOOK_URL=https://discord.com/api/webhooks/1485909255260209196/fHdiqNckVyZlfxOqSUp6bRUxYqan-o81WeE_VVYAk89ZMcoeD9RNLlw5-YitQ9Z7xinF
# on lance le check
/usr/sbin/aide --check
# on vérifie c'est quoi l'exit code de la commande
EXIT_CODE=$?

# si c'est 4 ça veut dire qu'il y a eu une modif dans un file
if [ $EXIT_CODE -eq 4 ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d '{"content": "**Alerte Sec** : AIDE à détecté modifs sur des fichiers critiques !!!!"}' \
             "$AIDE_WEBHOOK_URL"
fi
```

Il est aussi dans le repo

Service updated : 

```bash
[Unit]
Description=Run an AIDE integrity check

[Service]
Type=oneshot
ExecStart=/opt/discord_script.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target

```

<img width="658" height="402" alt="Screenshot_09h:04_26" src="https://github.com/user-attachments/assets/95dc718c-e00d-4d26-929d-cc79d2df82a6" />


## **V. Deploy**

**1. Create the template**

🌞 **Clean la VM**

```bash
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo cloud-init clean --logs
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo rm -rf /var/lib/cloud/*
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo systemctl enable cloud-init
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo rm -rf /var/log/*
[crea@petitmiaoudeviendragrandmiaou ~]$ cat /dev/null > ~/.bash_history
[crea@petitmiaoudeviendragrandmiaou ~]$ history -c
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo rm -rf /var/lib/waagent/*
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo dnf clean all
33 files removed
[crea@petitmiaoudeviendragrandmiaou ~]$ sudo waagent -deprovision+user -force
WARNING! The waagent service will be stopped.
WARNING! All SSH host key pairs will be deleted.
WARNING! Cached DHCP leases will be deleted.
WARNING! root password will be disabled. You will not be able to login as root.
WARNING! /etc/resolv.conf will be deleted.
WARNING! crea account and entire home directory will be deleted.
2026-03-23T16:12:16.528528Z INFO MainThread Examine /proc/net/route for primary interface
2026-03-23T16:12:16.529579Z INFO MainThread Primary interface is [eth0]
```

🌞 **Faire de la VM un template**

```bash
az>> vm deallocate --resource-group MIAOU-SOLIDE --name petit_miaou_deviendra_grand_miaou
az>> vm generalize --resource-group MIAOU-SOLIDE --name petit_miaou_deviendra_grand_miaou
az>> image create --resource-group MIAOU-SOLIDE --name  HARDENED-MIAOU --source petit_miaou_deviendra_grand_miaou --hyper-v-generation V2
{
  "hyperVGeneration": "V2",
  "id": "/subscriptions/.../resourceGroups/MIAOU-SOLIDE/providers/Microsoft.Compute/images/HARDENED-MIAOU",
  "location": "denmarkeast",
  "name": "HARDENED-MIAOU",
  "provisioningState": "Succeeded",
  "resourceGroup": "MIAOU-SOLIDE",
  "sourceVirtualMachine": {
    "id": "/subscriptions/.../resourceGroups/MIAOU-SOLIDE/providers/Microsoft.Compute/virtualMachines/petit_miaou_deviendra_grand_miaou",
    "resourceGroup": "MIAOU-SOLIDE"
  },
  "storageProfile": {
    "dataDisks": [],
    "osDisk": {
      "caching": "ReadWrite",
      "diskSizeGB": 30,
      "managedDisk": {
        "id": "/subscriptions/.../resourceGroups/MIAOU-SOLIDE/providers/Microsoft.Compute/disks/petit_miaou_deviendra_grand_miaou_disk1_814799a32067491684bf9f413d917bba",
        "resourceGroup": "MIAOU-SOLIDE"
      },
      "osState": "Generalized",
      "osType": "Linux",
      "storageAccountType": "Premium_LRS"
    }
  },
  "tags": {},
  "type": "Microsoft.Compute/images"
}
```

**2. Test**

🌞 **Lancer une VM à partir de cette image**

```bash
az>> az vm create -g MIAOU-SOLIDE -n hardened_miaou_vm --size Standard_B1s --image HARDENED-MIAOU --admin-username crea --ssh-key-values /tmp/ssh/cloud_tp1.pub
```

```bash
❯ ssh hardened
The authenticity of host '9.205.153.77 (9.205.153.77)' can't be established.
ED25519 key fingerprint is SHA256:SWDzsPCFXPW+lNBvVzZLETdI07WJkBieXzYAtbEWH20.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '9.205.153.77' (ED25519) to the list of known hosts.

[crea@hardened_miaou_vm ~]$
```

🌞 **Vérif**

```bash
[crea@hardened_miaou_vm ~]$ sudo cat /etc/systemd/system/aide-test.service
[Unit]
Description=Run an AIDE integrity check

[Service]
Type=oneshot
ExecStart=/opt/discord_script.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```
