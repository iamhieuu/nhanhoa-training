#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

clear

echo "======================================="
echo "   AUTO LEMP INSTALLER UBUNTU 22.04"
echo "======================================="

sleep 2

if [ "$EUID" -ne 0 ]; then
    error "Hãy chạy bằng sudo"
    exit 1
fi

info "Updating system..."
apt update -y
apt upgrade -y

info "Installing packages..."
apt install -y \
nginx \
mysql-server \
php \
php-fpm \
php-cli \
php-mysql \
php-curl \
php-gd \
php-mbstring \
php-xml \
php-zip \
php-soap \
php-imagick \
curl \
wget \
zip \
unzip \
ufw \
dos2unix

success "Packages installed"

PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

info "Detected PHP version: $PHP_VER"

systemctl enable nginx
systemctl start nginx

systemctl enable mysql
systemctl start mysql

systemctl enable php${PHP_VER}-fpm
systemctl start php${PHP_VER}-fpm

success "Services started"

info "Configuring firewall..."

ufw allow OpenSSH
ufw allow 'Nginx Full'

echo "y" | ufw enable

success "Firewall configured"

info "Fixing permissions..."

mkdir -p /var/www/html

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

success "Permissions fixed"

info "Creating nginx config..."

rm -f /etc/nginx/sites-enabled/default

printf '%s\n' \
'server {' \
'    listen 80 default_server;' \
'    listen [::]:80 default_server;' \
'' \
'    root /var/www/html;' \
'    index index.php index.html;' \
'' \
'    server_name _;' \
'' \
'    location / {' \
'        try_files $uri $uri/ /index.php?$query_string;' \
'    }' \
'' \
'    location ~ \.php$ {' \
'        include snippets/fastcgi-php.conf;' \
"        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;" \
'        include fastcgi_params;' \
'    }' \
'' \
'    location ~ /\.ht {' \
'        deny all;' \
'    }' \
'}' \
> /etc/nginx/sites-available/default

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

success "Nginx config created"

info "Creating index.php..."

printf '%s\n' \
'<?php' \
'echo "<h1>LEMP STACK WORKING</h1>";' \
'echo "<hr>";' \
'echo "<h3>Server Info</h3>";' \
'echo "PHP Version: ".phpversion();' \
'echo "<br>";' \
'echo "Server IP: ".$_SERVER["SERVER_ADDR"];' \
'echo "<br>";' \
'echo "Server Software: ".$_SERVER["SERVER_SOFTWARE"];' \
'?>' \
> /var/www/html/index.php

success "index.php created"

info "Creating phpinfo..."

printf '%s\n' \
'<?php' \
'phpinfo();' \
'?>' \
> /var/www/html/phpinfo.php

success "phpinfo created"

info "Testing nginx config..."

nginx -t

success "Nginx config OK"

systemctl restart nginx
systemctl restart php${PHP_VER}-fpm

success "Services restarted"

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "======================================="
echo " INSTALLATION COMPLETED"
echo "======================================="
echo ""
echo "Website:"
echo "http://$IP"
echo ""
echo "PHP Info:"
echo "http://$IP/phpinfo.php"
echo ""
echo "Useful Commands:"
echo "systemctl restart nginx"
echo "systemctl restart php${PHP_VER}-fpm"
echo "systemctl restart mysql"
echo ""
echo "Secure MySQL:"
echo "mysql_secure_installation"
echo ""
