#!/bin/bash

set -e  

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}\n"
}

check_requirements() {
    print_header "1. KIỂM TRA YÊU CẦU HỆ THỐNG"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "Script này phải chạy với quyền root!"
        log_info "Sử dụng: sudo ./install-lemp.sh"
        exit 1
    fi
    log_success "Đang chạy với quyền root"
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Không thể xác định hệ điều hành"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$PRETTY_NAME" != *"Ubuntu"* ]] || [[ "$VERSION_ID" != "22.04" ]]; then
        log_warning "Script này được tối ưu cho Ubuntu 22.04"
        log_warning "Phiên bản của bạn: $PRETTY_NAME"
    else
        log_success "Hệ điều hành: $PRETTY_NAME"
    fi
    
    # Check disk space
    DISK_SPACE=$(df /var | awk 'NR==2 {print int($4/1024/1024)}')
    if [ $DISK_SPACE -lt 5 ]; then
        log_error "Cần ít nhất 5GB dung lượng trống. Hiện tại: ${DISK_SPACE}GB"
        exit 1
    fi
    log_success "Dung lượng trống: ${DISK_SPACE}GB (Đủ)"
    
    # Check RAM
    RAM=$(free -h | awk 'NR==2 {print $2}')
    log_success "RAM: $RAM"
}

update_system() {
    print_header "2. CẬP NHẬT HỆ THỐNG"
    
    log_info "Cập nhật package lists..."
    apt update
    log_success "Package lists updated"
    
    log_info "Cập nhật packages..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y
    log_success "Packages upgraded"
}

install_nginx() {
    print_header "3. CÀI ĐẶT NGINX WEB SERVER"
    
    if command -v nginx &> /dev/null; then
        log_warning "Nginx đã cài đặt"
        nginx -v
        return
    fi
    
    log_info "Cài đặt Nginx..."
    apt install -y nginx
    log_success "Nginx installed"
    
    log_info "Bắt đầu Nginx service..."
    systemctl start nginx
    systemctl enable nginx
    log_success "Nginx service started and enabled"
    
    log_info "Checking Nginx status..."
    systemctl status nginx --no-pager | head -5
}


install_database() {
    print_header "4. CÀI ĐẶT DATABASE SERVER"
    
    read -p "Chọn database: MySQL (1) hay MariaDB (2)? [Mặc định: 1] " DB_CHOICE
    DB_CHOICE=${DB_CHOICE:-1}
    
    if [ "$DB_CHOICE" == "2" ]; then
        install_mariadb
    else
        install_mysql
    fi
}

install_mysql() {
    log_info "Cài đặt MySQL Server..."
    
    if command -v mysql &> /dev/null; then
        log_warning "MySQL đã cài đặt"
        mysql --version
        return
    fi
    
    export DEBIAN_FRONTEND=noninteractive
    apt install -y mysql-server mysql-client
    log_success "MySQL installed"
    
    log_info "Bắt đầu MySQL service..."
    systemctl start mysql
    systemctl enable mysql
    log_success "MySQL service started and enabled"
    
    log_warning "⚠️ QUAN TRỌNG: Chạy lệnh này để bảo mật MySQL:"
    log_warning "   sudo mysql_secure_installation"
}

install_mariadb() {
    log_info "Cài đặt MariaDB Server..."
    
    if command -v mariadb &> /dev/null; then
        log_warning "MariaDB đã cài đặt"
        mariadb --version
        return
    fi
    
    export DEBIAN_FRONTEND=noninteractive
    apt install -y mariadb-server mariadb-client
    log_success "MariaDB installed"
    
    log_info "Bắt đầu MariaDB service..."
    systemctl start mariadb
    systemctl enable mariadb
    log_success "MariaDB service started and enabled"
    
    log_warning "⚠️ QUAN TRỌNG: Chạy lệnh này để bảo mật MariaDB:"
    log_warning "   sudo mysql_secure_installation"
}

install_php_fpm() {
    print_header "5. CÀI ĐẶT PHP-FPM VÀ CÁC MODULES"
    
    if command -v php &> /dev/null; then
        log_warning "PHP đã cài đặt"
        php --version
        return
    fi
    
    log_info "Cài đặt PHP-FPM và các extensions..."
    apt install -y \
        php \
        php-fpm \
        php-cli \
        php-common \
        php-mysql \
        php-mbstring \
        php-curl \
        php-gd \
        php-json \
        php-zip \
        php-xml \
        php-soap \
        php-opcache \
        php-imagick
    
    log_success "PHP-FPM installed with extensions"
    
    log_info "PHP version:"
    php --version
    
   log_info "Starting PHP-FPM service..."
    PHP_VAL=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    systemctl start php$PHP_VAL-fpm
    systemctl enable php$PHP_VAL-fpm
}

configure_nginx() {
    print_header "6. CẤU HÌNH NGINX CHO PHP"
    
    log_info "Backup Nginx default config..."
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    log_success "Backup created"
    
    log_info "Creating Nginx configuration for PHP..."
    cat > /etc/nginx/sites-available/default << 'EOF'

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    
    root /var/www/html;
    
    index index.php index.html index.htm index.nginx-debian.html;

    location / {
        # Try files in order
        try_files $uri $uri/ =404;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME $fastcgi_script_name;
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param CONTENT_TYPE $content_type;
        fastcgi_param CONTENT_LENGTH $content_length;
        
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}


EOF

    log_success "Nginx configuration created"
}



test_nginx_config() {
    print_header "7. KIỂM TRA NGINX CONFIGURATION"
    
    log_info "Testing Nginx configuration..."
    if nginx -t 2>&1 | grep -q "successful"; then
        log_success "Nginx configuration is valid"
    else
        log_error "Nginx configuration test failed!"
        nginx -t
        exit 1
    fi
    
    log_info "Reloading Nginx..."
    systemctl reload nginx
    log_success "Nginx reloaded"
}

create_test_files() {
    print_header "8. TẠO CÁC FILE TEST"
    
    WEB_ROOT="/var/www/html"
    
    log_info "Tạo index.php test file..."
    cat > ${WEB_ROOT}/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>LEMP Stack Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 800px;
            margin: 0 auto;
        }
        .success {
            color: #28a745;
            font-weight: bold;
        }
        .info {
            background-color: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 10px;
            margin: 10px 0;
        }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 10px 0;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 LEMP Stack Test Page</h1>
        
        <div class="info">
            <strong>Chúc mừng!</strong> Bạn đã cài đặt LEMP stack thành công!
        </div>

        <h2>📋 System Information</h2>
        <table>
            <tr>
                <th>Thông tin</th>
                <th>Giá trị</th>
            </tr>
            <tr>
                <td>Server Hostname</td>
                <td><?php echo gethostname(); ?></td>
            </tr>
            <tr>
                <td>Server OS</td>
                <td><?php echo php_uname(); ?></td>
            </tr>
            <tr>
                <td>Server IP</td>
                <td><?php echo $_SERVER['SERVER_ADDR']; ?></td>
            </tr>
            <tr>
                <td>Server Software</td>
                <td><?php echo $_SERVER['SERVER_SOFTWARE']; ?></td>
            </tr>
            <tr>
                <td>Server Port</td>
                <td><?php echo $_SERVER['SERVER_PORT']; ?></td>
            </tr>
        </table>

        <h2>🐘 PHP Information</h2>
        <table>
            <tr>
                <th>Thông tin</th>
                <th>Giá trị</th>
            </tr>
            <tr>
                <td>PHP Version</td>
                <td><span class="success"><?php echo phpversion(); ?></span></td>
            </tr>
            <tr>
                <td>PHP SAPI</td>
                <td><?php echo php_sapi_name(); ?></td>
            </tr>
            <tr>
                <td>PHP-FPM Status</td>
                <td><span class="success">✓ Running (via PHP-FPM)</span></td>
            </tr>
            <tr>
                <td>Max Upload Size</td>
                <td><?php echo ini_get('upload_max_filesize'); ?></td>
            </tr>
            <tr>
                <td>Max Execution Time</td>
                <td><?php echo ini_get('max_execution_time'); ?> seconds</td>
            </tr>
        </table>

        <h2>📦 Loaded PHP Extensions</h2>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 4px;">
            <?php
                $extensions = get_loaded_extensions();
                sort($extensions);
                $important = array('mysql', 'mysqli', 'pdo', 'pdo_mysql', 'curl', 'gd', 'zip', 'json', 'xml');
                
                echo "Important: ";
                foreach ($important as $ext) {
                    if (in_array($ext, $extensions)) {
                        echo "<span class='success'>✓ $ext</span> ";
                    }
                }
                echo "<br><br>";
                
                echo "All Extensions: <br>";
                echo implode(", ", $extensions);
            ?>
        </div>

        <h2>🗄️ Database Test</h2>
        <?php
            $mysqli = @new mysqli("localhost", "root");
            if ($mysqli->connect_error) {
                echo '<div style="color: red; background: #ffebee; padding: 10px; border-radius: 4px;">';
                echo '❌ MySQL/MariaDB connection failed<br>';
                echo 'Error: ' . htmlspecialchars($mysqli->connect_error);
                echo '</div>';
            } else {
                echo '<div style="color: green; background: #e8f5e9; padding: 10px; border-radius: 4px;">';
                echo '✓ MySQL/MariaDB connection successful<br>';
                echo 'Server version: ' . htmlspecialchars($mysqli->server_info);
                echo '</div>';
                $mysqli->close();
            }
        ?>

        <h2>⚡ LEMP vs LAMP</h2>
        <div class="info">
            <p><strong>LEMP Stack Advantages:</strong></p>
            <ul style="margin: 10px 0;">
                <li>⚡ <strong>Better Performance:</strong> Nginx is faster than Apache</li>
                <li>💾 <strong>Lower Memory Usage:</strong> PHP-FPM is more efficient</li>
                <li>🚀 <strong>Higher Concurrency:</strong> Better for high-traffic sites</li>
                <li>🔧 <strong>Easier Scaling:</strong> Can separate components</li>
                <li>🛡️ <strong>Lighter Weight:</strong> Smaller resource footprint</li>
            </ul>
        </div>

        <h2>🔗 Next Steps</h2>
        <div class="info">
            <p>1. <strong>Test Database:</strong></p>
            <code style="background: #f0f0f0; padding: 10px; display: block;">
            mysql_secure_installation
            </code>
            
            <p>2. <strong>Create Database & User:</strong></p>
            <code style="background: #f0f0f0; padding: 10px; display: block;">
            mysql -u root -p<br>
            CREATE DATABASE mydb;<br>
            CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';<br>
            GRANT ALL ON mydb.* TO 'myuser'@'localhost';<br>
            FLUSH PRIVILEGES;
            </code>
            
            <p>3. <strong>Create PHP Script:</strong></p>
            <code style="background: #f0f0f0; padding: 10px; display: block;">
            nano /var/www/html/index.php
            </code>
            
            <p>4. <strong>Set Permissions:</strong></p>
            <code style="background: #f0f0f0; padding: 10px; display: block;">
            sudo chown -R www-data:www-data /var/www/html<br>
            sudo chmod -R 755 /var/www/html
            </code>
        </div>

        <h2>📚 Useful Information</h2>
        <div class="info">
            <p><strong>Nginx Config:</strong> /etc/nginx/</p>
            <p><strong>PHP-FPM Config:</strong> /etc/php/8.1/fpm/</p>
            <p><strong>MySQL Config:</strong> /etc/mysql/</p>
            <p><strong>Web Root:</strong> /var/www/html/</p>
            <p><strong>Nginx Logs:</strong> /var/log/nginx/</p>
            <p><strong>MySQL Logs:</strong> /var/log/mysql/</p>
            <p><strong>PHP-FPM Logs:</strong> /var/log/php*-fpm.log</p>
        </div>

        <h2>🛠️ Useful Commands</h2>
        <table>
            <tr>
                <th>Command</th>
                <th>Description</th>
            </tr>
            <tr>
                <td>systemctl restart nginx</td>
                <td>Restart Nginx</td>
            </tr>
            <tr>
                <td>systemctl restart php-fpm</td>
                <td>Restart PHP-FPM</td>
            </tr>
            <tr>
                <td>systemctl restart mysql</td>
                <td>Restart MySQL</td>
            </tr>
            <tr>
                <td>nginx -t</td>
                <td>Test Nginx configuration</td>
            </tr>
            <tr>
                <td>mysql -u root -p</td>
                <td>Connect to MySQL</td>
            </tr>
            <tr>
                <td>php -v</td>
                <td>Check PHP version</td>
            </tr>
            <tr>
                <td>ps aux | grep php-fpm</td>
                <td>Check PHP-FPM processes</td>
            </tr>
        </table>

        <hr>
        <p style="color: #999; font-size: 12px;">
            Generated on <?php echo date('Y-m-d H:i:s'); ?> | 
            Nhân Hòa Training
        </p>
    </div>
</body>
</html>
EOF

    chown www-data:www-data ${WEB_ROOT}/index.php
    chmod 644 ${WEB_ROOT}/index.php
    log_success "index.php created"
    
    log_info "Tạo phpinfo() test file..."
    cat > ${WEB_ROOT}/phpinfo.php << 'EOF'
<?php
phpinfo();
?>
EOF
    chown www-data:www-data ${WEB_ROOT}/phpinfo.php
    chmod 644 ${WEB_ROOT}/phpinfo.php
    log_success "phpinfo.php created"
}

verify_installation() {
    print_header "9. KIỂM TRA CÀI ĐẶT"
    
    echo -e "${CYAN}📋 Nginx Status:${NC}"
    systemctl status nginx --no-pager | head -3
    echo ""
    
    echo -e "${CYAN}📋 PHP-FPM Status:${NC}"
    systemctl status php-fpm --no-pager | head -3
    echo ""
    
    echo -e "${CYAN}📋 MySQL/MariaDB Status:${NC}"
    systemctl status mysql --no-pager | head -3
    echo ""
    
    echo -e "${CYAN}📋 Versions:${NC}"
    echo -n "Nginx: "
    nginx -v 2>&1
    echo -n "PHP: "
    php --version | head -1
    echo -n "MySQL/MariaDB: "
    mysql --version
    echo ""
}

display_access_info() {
    print_header "10. THÔNG TIN TRUY CẬP"
    
    # Get IP address
    IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}✓ Installation Completed Successfully!${NC}\n"
    
    echo -e "${CYAN}📍 Access URLs:${NC}"
    echo -e "  - Test Page: ${GREEN}http://$IP/${NC}"
    echo -e "  - Test Page (localhost): ${GREEN}http://localhost/${NC}"
    echo -e "  - PHP Info: ${GREEN}http://$IP/phpinfo.php${NC}"
    echo ""
    
    echo -e "${CYAN}🔧 Configuration:${NC}"
    echo -e "  - Nginx Root: /var/www/html/"
    echo -e "  - Nginx Config: /etc/nginx/"
    echo -e "  - PHP-FPM Config: /etc/php/8.1/fpm/"
    echo -e "  - MySQL Data: /var/lib/mysql/"
    echo ""
    
    echo -e "${CYAN}🛠️ Useful Commands:${NC}"
    echo -e "  - Restart Nginx: ${YELLOW}sudo systemctl restart nginx${NC}"
    echo -e "  - Restart PHP-FPM: ${YELLOW}sudo systemctl restart php-fpm${NC}"
    echo -e "  - Restart MySQL: ${YELLOW}sudo systemctl restart mysql${NC}"
    echo -e "  - Test Nginx: ${YELLOW}nginx -t${NC}"
    echo -e "  - MySQL Console: ${YELLOW}mysql -u root -p${NC}"
    echo ""
    
    echo -e "${CYAN}⚠️ Next Steps:${NC}"
    echo -e "  1. Run: ${YELLOW}sudo mysql_secure_installation${NC}"
    echo -e "  2. Create database and users"
    echo -e "  3. Deploy your applications to /var/www/html/"
    echo -e "  4. Set proper permissions with chmod/chown"
    echo -e "  5. Optimize Nginx/PHP-FPM for your workload"
    echo ""
}

show_summary() {
    print_header "📊 CÀI ĐẶT TỔNG KẾT"
    
    echo -e "${CYAN}Components Installed:${NC}"
    echo -e "  ${GREEN}✓${NC} Nginx Web Server"
    echo -e "  ${GREEN}✓${NC} MySQL/MariaDB Database"
    echo -e "  ${GREEN}✓${NC} PHP 8.1-FPM"
    echo -e "  ${GREEN}✓${NC} Required PHP modules"
    echo ""
    
    echo -e "${CYAN}Services:${NC}"
    
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✓${NC} Nginx is running"
    else
        echo -e "  ${RED}✗${NC} Nginx is not running"
    fi
    
    if systemctl is-active --quiet php-fpm; then
        echo -e "  ${GREEN}✓${NC} PHP-FPM is running"
    else
        echo -e "  ${RED}✗${NC} PHP-FPM is not running"
    fi
    
    if systemctl is-active --quiet mysql; then
        echo -e "  ${GREEN}✓${NC} MySQL is running"
    else
        echo -e "  ${RED}✗${NC} MySQL is not running"
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️ REMEMBER:${NC}"
    echo "  - Run 'sudo mysql_secure_installation' to secure MySQL"
    echo "  - Create database and users as needed"
    echo "  - Always use 'www-data' user for web files"
    echo "  - Configure PHP-FPM pool settings as needed"
    echo "  - Keep Nginx, PHP, and MySQL updated"
    echo ""
}


main() {
    clear
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         LEMP STACK INSTALLATION FOR UBUNTU 22.04       ║${NC}"
    echo -e "${CYAN}║      Linux + Nginx + MySQL/MariaDB + PHP-FPM          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Bấm ENTER để bắt đầu cài đặt... (Ctrl+C để hủy)"
    
    check_requirements
    update_system
    install_nginx
    install_database
    install_php_fpm
    configure_nginx
    test_nginx_config
    create_test_files
    verify_installation
    display_access_info
    show_summary
}

# Run main function
main
