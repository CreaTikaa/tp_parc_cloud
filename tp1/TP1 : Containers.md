## **Part I : Docker basics**

## 1. Install

🌞 **Installer Docker votre machine Azure**

```bash
~ maison                                                                  2m 36s 09:15:44
❯ sudo systemctl start docker

~ maison                                                                         09:16:56
❯ sudo systemctl status docker
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-03-19 09:09:16 CET; 7min ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 14919 (dockerd)
      Tasks: 13
     Memory: 27.7M
        CPU: 220ms
     CGroup: /system.slice/docker.service
```

```bash
~ maison                                                                        
❯ sudo usermod -aG docker crea
~ maison                                                                         
❯ groups
crea [...] docker

```

## **3. Lancement de conteneurs**

🌞 **Utiliser la commande `docker run`**

- lancer un conteneur `nginx`
    - conf par défaut étou étou, simple pour le moment
    - par défaut il écoute sur le port 80 et propose une page d'accueil
- le conteneur doit être lancé avec un partage de port
    - le port 9999 de la machine hôte doit rediriger vers le port 80 du conteneur
    
    ```bash
    ~ maison                                                                         09:29:34
    ❯ docker run --name web -d -p 9999:80 nginx
    127a36ca8c2e28bb37343ecdc728b2f24a1f16d48c9fd33bb13f765dee4f4cec
    
    ```
    

🌞 **Rendre le service dispo sur internet**

- il faut peut-être ouvrir un port firewall dans votre VM (suivant votre OS, ptet y'en a un, ptet pas)
- il faut ouvrir un port dans l'interface web de Azure (appelez moi si vous trouvez pas)
- vous devez pouvoir le visiter avec votre navigateur (un `curl` m'ira bien pour le compte-rendu)

```html
~ maison                                                                         09:29:37
❯ curl localhost:9999
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy,
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

🌞 **Custom un peu le lancement du conteneur**

- l'app NGINX doit avoir un fichier de conf personnalisé pour écouter sur le port 7777 (pas le port 80 par défaut)
- l'app NGINX doit servir un fichier `index.html` personnalisé (pas le site par défaut)
- l'application doit être joignable grâce à un partage de ports (vers le port 7777)
- vous limiterez l'utilisation de la RAM du conteneur à 512M
- le conteneur devra avoir un nom : `meow`

```bash
~ maison                                                                                                                                                                                                09:42:54
❯ docker run --name meow -d -v /etc/nginx/conf.d/tp_1.conf:/etc/nginx/conf.d/tp_1.conf -v /var/www/salut:/var/www/salut -p 7777:7777 -m 512m nginx
7a7f3b6d917f72b254da5a01bb8755ecbfb745a0c798bff11dd8fe4f935d7c63

~ maison                                                                                                                                                                                                09:42:57
❯ curl 10.100.2.208:7777
<!DOCTYPE html>
<body>
<h1> salut </h1>
</body>

```

## **Part II : Images**

## Construisez votre propre Dockerfile

🌞 **Construire votre propre image**

- image de base (celle que vous voulez : debian, alpine, ubuntu, etc.)
    - une image du Docker Hub
    - qui ne porte aucune application par défaut
- vous ajouterez
    - mise à jour du système
    - installation de Apache (pour les systèmes debian, le serveur Web apache s'appelle `apache2` et non pas `httpd` comme sur Rocky)
    - page d'accueil Apache HTML personnalisée

```bash
ServerName localhost
# on définit un port sur lequel écouter
Listen 80

# on charge certains modules Apache strictement nécessaires à son bon fonctionnement
LoadModule mpm_event_module "/usr/lib/apache2/modules/mod_mpm_event.so"
LoadModule dir_module "/usr/lib/apache2/modules/mod_dir.so"
LoadModule authz_core_module "/usr/lib/apache2/modules/mod_authz_core.so"

# on indique le nom du fichier HTML à charger par défaut
DirectoryIndex index.html
# on indique le chemin où se trouve notre site
DocumentRoot "/var/www/html/"

# quelques paramètres pour les logs
ErrorLog "/var/log/apache2/error.log"
LogLevel warn
```

```docker
FROM debian:latest

RUN apt update -y
RUN apt install apache2 -y

COPY conf_de_bonhomme.conf /etc/apache2/apache2.conf

CMD ["apachectl", "-D", "FOREGROUND"] 
# ou CMD ["/usr/sbin/apache2", "-D",  "FOREGROUND"]

EXPOSE 80
```

## **Part III : `docker-compose`**

on git clone la python app

```docker
❯ ls
compose.yml  Dockerfile  python-app
```

1. Dockerfile : 

```docker
FROM python:3.12-alpine
WORKDIR /app
COPY python-app/ .
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python3", "app.py"]
```

1. Compose : 

```docker
services:

  python-app:
    build: .
    environment:
      - REDIS_HOST=db
      - REDIS_PORT=6379
    ports:
      - "8888:8888"

  db:
    image: redis:alpine
    restart: unless-stopped
```

1. Check

```docker
❯ curl 127.0.0.1:8888
<h1>Add key</h1>
<form action="/add" method = "POST">

Key:
<input type="text" name="key" >

Value:
<input type="text" name="value" >

<input type="submit" value="Submit">
</form>

<h1>Check key</h1>
<form action="/get" method = "POST">

Key:
<input type="text" name="key" >
<input type="submit" value="Submit">
</form>

Host : 8bdbbaa00f28
```

working 👍

## **Part IV : Docker security**

### 1. Le groupe docker

🌞 **Prouvez que vous pouvez devenir `root`**

```docker
❯ docker run --name mom_im_root alpine cat /etc/shadow
root:*::0:::::
bin:!::0:::::
daemon:!::0:::::
lp:!::0:::::
sync:!::0:::::
shutdown:!::0:::::
halt:!::0:::::
mail:!::0:::::
news:!::0:::::
uucp:!::0:::::
cron:!::0:::::
ftp:!::0:::::
sshd:!::0:::::
games:!::0:::::
ntp:!::0:::::
guest:!::0:::::
nobody:!::0:::::
```

### **2. Scan de vuln**

```docker
❯ docker run --rm aquasec/trivy image ghcr.io/requarks/wiki:2 > trivi_wikijs.txt
❯ docker run --rm aquasec/trivy image postgres:15-alpine > trivi_postgres.txt
❯ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image miaouuu:latest > trivi_miaouuu.txt (sinon il j'aais que des errors vu qu'il trouvait pas l'image dcp)
❯ docker run --rm aquasec/trivy image nginx > trivi_nginx.txt
```

voir trivi_wikijs.txt (TODO : mettre un lien cliquable pour chacun et tous les uplaod)

### 3. Petit benchmark secu

Bonnes pratiques : 

- Healthcheck sur chaque service
- Run des contenneurs avec des users spécifiques et pas root (lol)
- Mettre des SecurityOptions (comme `no-new-privileges:true` ou créer un profile seccomp `--security-opt seccomp=strict-seccomp.json`)
- Mettre des memory, CPU & PIDs restrictions (avec `-m` , `--cpus=<value>`  &`pids_limit =<value>`)
