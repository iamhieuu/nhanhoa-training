```bash
#!/bin/bash
set -e

# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Cài đặt MariaDB
sudo apt install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Xóa user anonymous và database test
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Thêm repository PHP
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php

# Cập nhật package
sudo apt update

# Cài đặt PHP 8.1 và các extension
sudo apt install -y \
php8.1-fpm \
php8.1-mysql \
php8.1-cli \
php8.1-curl \
php8.1-gd \
php8.1-mbstring \
php8.1-xml \
php8.1-zip

# Khởi động PHP-FPM
sudo systemctl enable php8.1-fpm
sudo systemctl start php8.1-fpm

# Cấu hình Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINX'
server {
    listen 80 default_server;
    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX

# Kiểm tra và reload Nginx
sudo nginx -t
sudo systemctl reload nginx

# Tạo file phpinfo
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

# Hiển thị thông tin
echo "========================================"
echo "LEMP Stack cài đặt thành công!"
echo "PHP   : $(php -v | head -1)"
echo "Nginx : $(nginx -v 2>&1)"
echo "MariaDB: $(mysql --version)"
echo "========================================"
```
