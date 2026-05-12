#!/bin/bash

# 1. Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# 2. Cài đặt Nginx
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# 3. Cài đặt MariaDB (Thay cho MySQL cho nhẹ và ổn định hơn)
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

# 4. Cài đặt PHP 8.1 và các module cần thiết
sudo apt install php8.1-fpm php8.1-mysql php8.1-common php8.1-cli php8.1-gd php8.1-curl -y

# 5. Cấu hình Nginx Default Site (Ghi đè cấu hình chuẩn)
sudo tee /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# 6. Tạo file info.php để kiểm tra
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

# 7. Cấp quyền cho thư mục web
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 8. Restart dịch vụ
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm

echo "------------------------------------------------"
echo " Cai dat LEMP hoan tat!"
echo " Truy cap http://$(curl -s ifconfig.me)/info.php de kiem tra."
echo "------------------------------------------------"
