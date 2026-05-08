#!/bin/bash
set -e

DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wppass123"
WEB_ROOT="/var/www/html"

echo "1. Đang tải và giải nén WordPress..."
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

echo "2. Đang dọn dẹp thư mục web và chép code mới..."
sudo rm -rf ${WEB_ROOT}/*
sudo cp -r wordpress/* ${WEB_ROOT}/

echo "3. Đang tạo Database..."
sudo mysql << EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "4. Cấu hình wp-config.php tự động..."
cd ${WEB_ROOT}
sudo cp wp-config-sample.php wp-config.php

sudo sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sudo sed -i "s/username_here/$DB_USER/" wp-config.php
sudo sed -i "s/password_here/$DB_PASS/" wp-config.php

echo "5. Cấp quyền sở hữu thư mục..."
sudo chown -R www-data:www-data ${WEB_ROOT}
sudo chmod -R 755 ${WEB_ROOT}

echo "------------------------------------------"
echo "Xong! Truy cập http://$(hostname -I | awk '{print $1}') để hoàn tất cài đặt."
