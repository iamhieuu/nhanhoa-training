```bash
#!/bin/bash
set -e

# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Apache
sudo apt install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2

# Xóa VirtualHost mặc định của Apache
sudo a2dissite 000-default.conf
sudo rm -f /etc/apache2/sites-enabled/000-default.conf

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

# Cài đặt PHP 8.1 và module Apache
sudo apt install -y \
php8.1 \
libapache2-mod-php8.1 \
php8.1-mysql \
php8.1-cli \
php8.1-curl \
php8.1-gd \
php8.1-mbstring \
php8.1-xml \
php8.1-zip

# Bật module Apache
sudo a2enmod php8.1 rewrite

# Khởi động lại Apache
sudo systemctl restart apache2

# Tạo file kiểm tra PHP
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

# Hiển thị thông tin
echo "========================================"
echo "LAMP Stack cài đặt thành công!"
echo "PHP     : $(php -v | head -1)"
echo "Apache  : $(apache2 -v | head -1)"
echo "MariaDB : $(mysql --version)"
echo "========================================"
```
