#!/bin/bash
# LEMP = Linux + Nginx + MySQL (MariaDB) + PHP
# Autor: Jakub Rolecki

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_LEMP.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

apt update
apt install -y software-properties-common

# Repozytoria zewnętrzne z PHP i najnowszymi wydaniami nginx
add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:nginx/stable

# Aktualizacja repozytoriow
apt update

# nginx + najpopularniejsze moduły do PHP
apt install -y nginx php php-fpm php-zip php-xml php-sqlite3 php-pgsql php-mysql php-mcrypt php-mbstring php-intl php-gd php-curl php-cli php-bcmath

# dodanie MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client

# utworzenie konfiguracji wspierającej PHP w nginx
config=$(cat <<EOF
server {
   listen   80 default_server;
   listen   [::]:80 default_server;

   root /var/www/html;

   index index.html index.htm index.php;

   server_name _;

   location / {
      try_files \$uri \$uri/ =404;
   }

   location ~ \.php\$ {
      include snippets/fastcgi-php.conf;
      
      fastcgi_pass unix:/var/run/php/php-fpm.sock;
   }
}
EOF
)

# aktualizacja konfiguracji
echo "$config" >/etc/nginx/sites-available/default

# Dowód na działanie PHP
echo '<?php echo "2 + 2 = ".(2+2); ' >/var/www/html/index.php

# Serwer będzie się przedstawiał jako "Nginx" - bez wersji serwera
sed -e 's/# server_tokens off;/server_tokens off;/' -i /etc/nginx/nginx.conf 

# Dodanie nginxa do autostartu
systemctl enable --now nginx

# Przeładowanie nginxa
systemctl reload nginx

systemctl status nginx
