#!/bin/bash

# =========================================================

# ULTIMATE LEMP LEARNING ENVIRONMENT

# Ubuntu 22.04+

# Linux + Nginx + MariaDB + PHP-FPM + JMeter + Dev Tools

# =========================================================

set -e

# ================= COLORS =================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ================= LOG FUNCTIONS =================

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
echo -e "\n${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}$1${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}\n"
}

# ================= CHECK ROOT =================

check_requirements() {

```
print_header "1. SYSTEM CHECK"

if [[ $EUID -ne 0 ]]; then
    log_error "Please run as root"
    echo "Use: sudo ./ultimate-lemp.sh"
    exit 1
fi

log_success "Running as root"

source /etc/os-release

log_success "OS: $PRETTY_NAME"

RAM=$(free -h | awk 'NR==2 {print $2}')
CPU=$(nproc)

log_success "RAM: $RAM"
log_success "CPU Cores: $CPU"

DISK=$(df -h / | awk 'NR==2 {print $4}')
log_success "Free Disk: $DISK"
```

}

# ================= UPDATE =================

update_system() {

```
print_header "2. UPDATE SYSTEM"

apt update -y
apt upgrade -y

log_success "System updated"
```

}

# ================= INSTALL BASIC TOOLS =================

install_basic_tools() {

```
print_header "3. INSTALL BASIC TOOLS"

apt install -y \
    curl \
    wget \
    unzip \
    zip \
    git \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    gnupg \
    apache2-utils \
    fail2ban \
    ufw \
    tree \
    vim \
    nano

log_success "Basic tools installed"
```

}

# ================= INSTALL NGINX =================

install_nginx() {

```
print_header "4. INSTALL NGINX"

apt install -y nginx

systemctl enable nginx
systemctl start nginx

log_success "Nginx installed"

nginx -v
```

}

# ================= INSTALL MARIADB =================

install_database() {

```
print_header "5. INSTALL MARIADB"

apt install -y mariadb-server mariadb-client

systemctl enable mariadb
systemctl start mariadb

log_success "MariaDB installed"

mysql --version
```

}

# ================= INSTALL PHP =================

install_php() {

```
print_header "6. INSTALL PHP"

add-apt-repository ppa:ondrej/php -y

apt update -y

apt install -y \
    php8.3 \
    php8.3-fpm \
    php8.3-cli \
    php8.3-common \
    php8.3-mysql \
    php8.3-curl \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-soap \
    php8.3-intl \
    php8.3-opcache \
    php8.3-imagick

systemctl enable php8.3-fpm
systemctl start php8.3-fpm

log_success "PHP installed"

php -v
```

}

# ================= OPTIMIZE PHP =================

optimize_php() {

```
print_header "7. OPTIMIZE PHP"

PHPINI="/etc/php/8.3/fpm/php.ini"

sed -i 's/memory_limit = .*/memory_limit = 256M/' $PHPINI
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' $PHPINI
sed -i 's/post_max_size = .*/post_max_size = 64M/' $PHPINI
sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHPINI

systemctl restart php8.3-fpm

log_success "PHP optimized"
```

}

# ================= CONFIGURE NGINX =================

configure_nginx() {

```
print_header "8. CONFIGURE NGINX"

cat > /etc/nginx/sites-available/default << 'EOF'
```

server {

```
listen 80 default_server;
listen [::]:80 default_server;

server_name _;

root /var/www/html;

index index.php index.html index.htm;

location / {
    try_files $uri $uri/ =404;
}

location ~ \.php$ {

    include snippets/fastcgi-php.conf;

    fastcgi_pass unix:/run/php/php8.3-fpm.sock;

    include fastcgi_params;

    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}

location ~ /\.ht {
    deny all;
}

gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

access_log /var/log/nginx/access.log;
error_log /var/log/nginx/error.log;
```

}
EOF

```
nginx -t

systemctl restart nginx

log_success "Nginx configured"
```

}

# ================= FIX PERMISSIONS =================

fix_permissions() {

```
print_header "9. FIX PERMISSIONS"

chown -R www-data:www-data /var/www/html

find /var/www/html -type d -exec chmod 755 {} \;

find /var/www/html -type f -exec chmod 644 {} \;

log_success "Permissions fixed"
```

}

# ================= CREATE TEST PAGE =================

create_test_page() {

```
print_header "10. CREATE TEST PAGE"
```

cat > /var/www/html/index.php << 'EOF'

<?php
echo "<h1>ULTIMATE LEMP SERVER</h1>";

echo "<h2>Server Information</h2>";

echo "<p><b>Hostname:</b> ".gethostname()."</p>";
echo "<p><b>PHP Version:</b> ".phpversion()."</p>";
echo "<p><b>Server Software:</b> ".$_SERVER['SERVER_SOFTWARE']."</p>";

echo "<h2>Loaded Extensions</h2>";

echo "<pre>";
print_r(get_loaded_extensions());
echo "</pre>";

$conn = @new mysqli("localhost","root","");

if($conn->connect_error){
    echo "<h3>Database Connection Failed</h3>";
}else{
    echo "<h3>Database Connected Successfully</h3>";
}
?>

EOF

```
log_success "Test page created"
```

}

# ================= INSTALL COMPOSER =================

install_composer() {

```
print_header "11. INSTALL COMPOSER"

curl -sS https://getcomposer.org/installer | php

mv composer.phar /usr/local/bin/composer

composer --version

log_success "Composer installed"
```

}

# ================= INSTALL NODEJS =================

install_nodejs() {

```
print_header "12. INSTALL NODEJS"

apt install -y nodejs npm

node -v
npm -v

log_success "NodeJS installed"
```

}

# ================= INSTALL JMETER =================

install_jmeter() {

```
print_header "13. INSTALL JMETER"

apt install -y default-jre

cd /opt

wget -q https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz

tar -xzf apache-jmeter-5.6.3.tgz

ln -sf /opt/apache-jmeter-5.6.3/bin/jmeter /usr/local/bin/jmeter

log_success "JMeter installed"

jmeter --version
```

}

# ================= INSTALL MONITORING =================

install_monitoring() {

```
print_header "14. INSTALL MONITORING TOOLS"

apt install -y \
    vnstat \
    iotop \
    sysstat

systemctl enable vnstat
systemctl start vnstat

log_success "Monitoring tools installed"
```

}

# ================= FIREWALL =================

setup_firewall() {

```
print_header "15. CONFIGURE FIREWALL"

ufw allow OpenSSH
ufw allow 'Nginx Full'

echo "y" | ufw enable

log_success "Firewall enabled"
```

}

# ================= HEALTH CHECK =================

health_check() {

```
print_header "16. HEALTH CHECK"

IP=$(hostname -I | awk '{print $1}')

STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://$IP)

if [ "$STATUS" == "200" ]; then
    log_success "Website OK (HTTP 200)"
else
    log_error "Website Error: HTTP $STATUS"
fi
```

}

# ================= BENCHMARK =================

run_benchmark() {

```
print_header "17. PERFORMANCE TEST"

IP=$(hostname -I | awk '{print $1}')

ab -n 1000 -c 50 http://$IP/
```

}

# ================= CREATE JMETER TEST =================

create_jmeter_test() {

```
print_header "18. CREATE JMETER TEST FILE"
```

cat > /root/test.jmx << 'EOF'

<?xml version="1.0" encoding="UTF-8"?>

<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.6.3">
<hashTree>
<TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="LEMP TEST" enabled="true">
<stringProp name="TestPlan.comments"></stringProp>
<boolProp name="TestPlan.functional_mode">false</boolProp>
<boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
<boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
</TestPlan>

<hashTree>

<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Users" enabled="true">

<stringProp name="ThreadGroup.on_sample_error">continue</stringProp>

<elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller" enabled="true">
<boolProp name="LoopController.continue_forever">false</boolProp>
<stringProp name="LoopController.loops">10</stringProp>
</elementProp>

<stringProp name="ThreadGroup.num_threads">50</stringProp> <stringProp name="ThreadGroup.ramp_time">10</stringProp>

<boolProp name="ThreadGroup.scheduler">false</boolProp>

</ThreadGroup>

<hashTree>

<ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Defaults" enabled="true">

<stringProp name="HTTPSampler.domain">127.0.0.1</stringProp> <stringProp name="HTTPSampler.port">80</stringProp> <stringProp name="HTTPSampler.protocol">http</stringProp>

</ConfigTestElement>

<hashTree/>

<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Home Page" enabled="true">

<stringProp name="HTTPSampler.path">/</stringProp> <stringProp name="HTTPSampler.method">GET</stringProp>

</HTTPSamplerProxy>

<hashTree/>

</hashTree>

</hashTree>

</jmeterTestPlan>
EOF

```
log_success "JMeter test created: /root/test.jmx"
```

}

# ================= SHOW INFO =================

show_info() {

```
print_header "SERVER INFORMATION"

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "======================================="
echo " SERVER READY "
echo "======================================="
echo ""
echo "Website:"
echo "http://$IP"
echo ""
echo "PHP Info:"
echo "http://$IP/phpinfo.php"
echo ""
echo "JMeter Test:"
echo "jmeter -n -t /root/test.jmx -l result.jtl -e -o report/"
echo ""
echo "Benchmark:"
echo "ab -n 1000 -c 50 http://$IP/"
echo ""
echo "Monitoring:"
echo "htop"
echo "vnstat"
echo ""
echo "======================================="
```

}

# ================= MAIN =================

main() {

```
clear

echo -e "${CYAN}"
echo "===================================================="
echo "      ULTIMATE LEMP LEARNING ENVIRONMENT"
echo "===================================================="
echo -e "${NC}"

check_requirements
update_system
install_basic_tools
install_nginx
install_database
install_php
optimize_php
configure_nginx
fix_permissions
create_test_page
install_composer
install_nodejs
install_jmeter
install_monitoring
setup_firewall
create_jmeter_test
health_check
show_info

log_success "INSTALLATION COMPLETED"
```

}

main
