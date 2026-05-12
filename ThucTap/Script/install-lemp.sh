#!/bin/bash
# ============================================================
#  LEMP Stack Installer — Ubuntu 22.04
#  Server IP : 192.168.136.131
#  Includes  : Nginx + HTTP/2 · MySQL 8 · PHP 8.1-FPM
#              FastCGI Cache · Detailed JSON Logging
#              Redis · OPcache · Beautiful Status Page
# ============================================================
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  COLOUR HELPERS
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}━━━  $*  ━━━${NC}\n"; }

# ─────────────────────────────────────────────────────────────
#  VARIABLES
# ─────────────────────────────────────────────────────────────
SERVER_IP="192.168.136.131"
WEB_ROOT="/var/www/html"
NGINX_CONF="/etc/nginx/nginx.conf"
SITE_CONF="/etc/nginx/sites-available/lemp"
CACHE_DIR="/var/cache/nginx/fastcgi"
LOG_DIR="/var/log/nginx"
SSL_DIR="/etc/nginx/ssl"
PHP_VER="8.1"
MYSQL_ROOT_PASS="LEMPr00t@$(date +%Y)"
DB_NAME="lemp_db"
DB_USER="lemp_user"
DB_PASS="LEMPuser@$(date +%Y)"

# ─────────────────────────────────────────────────────────────
#  BANNER
# ─────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${BLUE}"
cat << 'BANNER'
  ██╗     ███████╗███╗   ███╗██████╗
  ██║     ██╔════╝████╗ ████║██╔══██╗
  ██║     █████╗  ██╔████╔██║██████╔╝
  ██║     ██╔══╝  ██║╚██╔╝██║██╔═══╝
  ███████╗███████╗██║ ╚═╝ ██║██║
  ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  Stack Installer
  Linux · Nginx · MySQL · PHP  —  Ubuntu 22.04
BANNER
echo -e "${NC}"
echo -e "  ${CYAN}Server IP:${NC} ${SERVER_IP}  |  ${CYAN}PHP:${NC} ${PHP_VER}  |  ${CYAN}HTTP/2:${NC} Enabled"
echo -e "  ${CYAN}Features:${NC}  FastCGI Cache · Redis · OPcache · JSON Logging\n"
echo -e "${YELLOW}  Starting installation in 3 seconds...${NC}\n"
sleep 3

# ─────────────────────────────────────────────────────────────
#  PRE-FLIGHT CHECKS
# ─────────────────────────────────────────────────────────────
section "Pre-flight Checks"
[[ $EUID -ne 0 ]] && error "Run this script as root: sudo bash $0"
[[ "$(lsb_release -rs)" != "22.04" ]] && warn "Designed for Ubuntu 22.04 — proceed with caution"
info "Updating package lists..."
apt-get update -qq
success "System ready"

# ─────────────────────────────────────────────────────────────
#  1. NGINX
# ─────────────────────────────────────────────────────────────
section "Installing Nginx"
apt-get install -y -qq nginx nginx-extras
systemctl enable nginx

# Create SSL self-signed certificate (enables HTTP/2)
info "Generating self-signed SSL certificate..."
mkdir -p "$SSL_DIR"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$SSL_DIR/lemp.key" \
  -out    "$SSL_DIR/lemp.crt" \
  -subj "/C=VN/ST=HCM/L=HoChiMinh/O=LEMP Server/CN=${SERVER_IP}" \
  2>/dev/null
chmod 600 "$SSL_DIR/lemp.key"
success "SSL certificate created (10 years)"

# FastCGI cache directory
info "Creating FastCGI cache directory..."
mkdir -p "$CACHE_DIR"
chown www-data:www-data "$CACHE_DIR"
success "Cache directory: $CACHE_DIR"

# ─────────────────────────────────────────────────────────────
#  NGINX MAIN CONFIG
# ─────────────────────────────────────────────────────────────
info "Writing optimised nginx.conf..."
cat > "$NGINX_CONF" << 'NGINXMAIN'
# ============================================================
#  nginx.conf — LEMP Optimised Configuration
# ============================================================
user www-data;
worker_processes auto;
worker_rlimit_nofile 65535;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # ── Basic ────────────────────────────────────────────────
    sendfile           on;
    tcp_nopush         on;
    tcp_nodelay        on;
    server_tokens      off;       # hide Nginx version
    keepalive_timeout  65;
    keepalive_requests 1000;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # ── Charset ──────────────────────────────────────────────
    charset utf-8;

    # ── File Cache (reduce syscalls) ─────────────────────────
    open_file_cache          max=10000 inactive=30s;
    open_file_cache_valid    60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors   on;

    # ── Gzip ─────────────────────────────────────────────────
    gzip              on;
    gzip_vary         on;
    gzip_proxied      any;
    gzip_comp_level   5;
    gzip_buffers      16 8k;
    gzip_http_version 1.1;
    gzip_min_length   256;
    gzip_types
        text/plain text/css text/xml text/javascript
        application/json application/javascript application/xml
        application/rss+xml application/atom+xml image/svg+xml
        font/ttf font/otf font/woff font/woff2;

    # ── FastCGI Cache Zone ───────────────────────────────────
    # 100m = shared memory for keys; 1g = max disk space for cache
    fastcgi_cache_path /var/cache/nginx/fastcgi
        levels=1:2
        keys_zone=LEMP_CACHE:100m
        max_size=1g
        inactive=60m
        use_temp_path=off;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
    fastcgi_cache_lock on;

    # ── JSON Access Log Format ───────────────────────────────
    # Detailed structured logging — easy to parse with ELK/GoAccess
    log_format json_detailed escape=json
    '{'
        '"timestamp":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"remote_user":"$remote_user",'
        '"request":"$request",'
        '"method":"$request_method",'
        '"uri":"$request_uri",'
        '"args":"$args",'
        '"status":"$status",'
        '"bytes_sent":"$bytes_sent",'
        '"body_bytes":"$body_bytes_sent",'
        '"referer":"$http_referer",'
        '"user_agent":"$http_user_agent",'
        '"http_x_forwarded_for":"$http_x_forwarded_for",'
        '"request_time":"$request_time",'
        '"upstream_response_time":"$upstream_response_time",'
        '"upstream_addr":"$upstream_addr",'
        '"upstream_status":"$upstream_status",'
        '"http_version":"$server_protocol",'
        '"ssl_protocol":"$ssl_protocol",'
        '"ssl_cipher":"$ssl_cipher",'
        '"cache_status":"$upstream_cache_status",'
        '"gzip_ratio":"$gzip_ratio",'
        '"connection":"$connection",'
        '"connection_requests":"$connection_requests",'
        '"pipe":"$pipe",'
        '"scheme":"$scheme",'
        '"host":"$host",'
        '"server_port":"$server_port"'
    '}';

    # Human-readable combined format (for quick tailing)
    log_format detailed
        '$remote_addr [$time_local] '
        '"$request" $status $bytes_sent '
        '"$http_referer" "$http_user_agent" '
        'rt=$request_time urt=$upstream_response_time '
        'cs=$upstream_cache_status gz=$gzip_ratio '
        'proto=$server_protocol ssl=$ssl_protocol';

    access_log /var/log/nginx/access.log    json_detailed;
    error_log  /var/log/nginx/error.log     warn;

    # ── Rate Limiting ────────────────────────────────────────
    limit_req_zone  $binary_remote_addr zone=general:10m rate=60r/m;
    limit_req_zone  $binary_remote_addr zone=api:10m     rate=30r/m;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    # ── Security Headers (global) ────────────────────────────
    add_header X-Frame-Options           "SAMEORIGIN"           always;
    add_header X-Content-Type-Options    "nosniff"              always;
    add_header X-XSS-Protection         "1; mode=block"        always;
    add_header Referrer-Policy          "strict-origin-when-cross-origin" always;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINXMAIN
success "nginx.conf written"

# ─────────────────────────────────────────────────────────────
#  NGINX SITE CONFIG
# ─────────────────────────────────────────────────────────────
info "Writing site configuration with HTTP/2..."
cat > "$SITE_CONF" << SITECONF
# ============================================================
#  LEMP Site — ${SERVER_IP}
#  HTTP/2 · FastCGI Cache · Detailed Logging
# ============================================================

# ── Cache bypass map ────────────────────────────────────────
# Skip cache for: logged-in users, POST, admin area
map \$http_cookie \$skip_cache_cookie {
    default         0;
    "~PHPSESSID"    1;
    "~wordpress_"   1;
    "~wp-settings"  1;
}
map \$request_method \$skip_cache_method {
    default 0;
    POST    1;
}

# ── Redirect HTTP → HTTPS ───────────────────────────────────
server {
    listen 80;
    server_name ${SERVER_IP};
    return 301 https://\$host\$request_uri;
    access_log /var/log/nginx/http_redirect.log json_detailed;
}

# ── Main HTTPS + HTTP/2 server ──────────────────────────────
server {
    listen 443 ssl;
    http2  on;
    server_name ${SERVER_IP};
    root   ${WEB_ROOT};
    index  index.php index.html;

    # ── SSL ─────────────────────────────────────────────────
    ssl_certificate     ${SSL_DIR}/lemp.crt;
    ssl_certificate_key ${SSL_DIR}/lemp.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # HSTS (1 year — only uncomment when domain is real)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # ── Per-site Logging ────────────────────────────────────
    access_log ${LOG_DIR}/access.log     json_detailed;
    access_log ${LOG_DIR}/access_hr.log  detailed;      # human-readable copy
    error_log  ${LOG_DIR}/error.log      warn;

    # ── FastCGI Cache Settings ──────────────────────────────
    fastcgi_cache           LEMP_CACHE;
    fastcgi_cache_valid     200 301 302 60m;
    fastcgi_cache_valid     404          1m;
    fastcgi_cache_bypass    \$skip_cache_cookie \$skip_cache_method;
    fastcgi_no_cache        \$skip_cache_cookie \$skip_cache_method;
    add_header X-Cache-Status \$upstream_cache_status always;  # HIT/MISS/BYPASS

    # ── Security ────────────────────────────────────────────
    server_tokens off;
    add_header X-Powered-By "" always;   # hide PHP version

    # ── Rate Limiting ────────────────────────────────────────
    limit_req  zone=general burst=20 nodelay;
    limit_conn addr 15;

    # ── Main location ────────────────────────────────────────
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # ── PHP-FPM handler ──────────────────────────────────────
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;

        fastcgi_pass   unix:/var/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 60;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE       "error_log=${LOG_DIR}/php_errors.log";
        fastcgi_param SERVER_SOFTWARE "LEMP/${SERVER_IP}";
    }

    # ── Static assets — long cache, no logging ───────────────
    location ~* \.(jpg|jpeg|png|gif|ico|webp|svg|css|js|woff|woff2|ttf|eot)\$ {
        expires     30d;
        access_log  off;
        log_not_found off;
        add_header  Cache-Control "public, immutable";
        add_header  X-Cache-Status "STATIC" always;
    }

    # ── Nginx stub status ────────────────────────────────────
    location = /nginx-status {
        stub_status;
        allow 127.0.0.1;
        allow ${SERVER_IP};
        deny all;
        access_log off;
    }

    # ── PHP-FPM status ───────────────────────────────────────
    location = /fpm-status {
        fastcgi_pass unix:/var/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        allow 127.0.0.1;
        allow ${SERVER_IP};
        deny all;
        access_log off;
    }

    # ── Cache purge endpoint (manual) ───────────────────────
    location = /cache-purge {
        fastcgi_pass unix:/var/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root/cache-purge.php;
        include fastcgi_params;
        allow 127.0.0.1;
        allow ${SERVER_IP};
        deny all;
    }

    # ── Block sensitive files ────────────────────────────────
    location ~ /\.(env|git|htaccess|htpasswd) {
        deny all; return 403;
    }
    location ~ /(vendor|storage|bootstrap/cache) {
        deny all; return 403;
    }
}
SITECONF

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -sf "$SITE_CONF" /etc/nginx/sites-enabled/lemp
success "Site config enabled with HTTP/2"

# ─────────────────────────────────────────────────────────────
#  2. MYSQL
# ─────────────────────────────────────────────────────────────
section "Installing MySQL 8"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mysql-server

# Secure MySQL automatically
info "Securing MySQL installation..."
mysql -u root << MYSQL_SECURE
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
    IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SECURE

# MySQL performance tuning
info "Writing MySQL optimised config..."
cat > /etc/mysql/conf.d/lemp-tuning.cnf << 'MYSQLCNF'
[mysqld]
# ── InnoDB Buffer Pool ──────────────────────────────────────
# 70% of available RAM — most important MySQL setting
innodb_buffer_pool_size        = 512M
innodb_buffer_pool_instances   = 2
innodb_log_file_size           = 128M
innodb_flush_log_at_trx_commit = 1
innodb_flush_method            = O_DIRECT

# ── Connections ─────────────────────────────────────────────
max_connections       = 200
thread_cache_size     = 16
wait_timeout          = 60
interactive_timeout   = 60

# ── Query Cache (disabled in MySQL 8 — use Redis) ──────────
# query_cache_type = 0

# ── Slow Query Log ──────────────────────────────────────────
slow_query_log            = 1
slow_query_log_file       = /var/log/mysql/slow.log
long_query_time           = 1
log_queries_not_using_indexes = 1
min_examined_row_limit    = 100

# ── General Logging (disabled on prod, enable for debug) ────
# general_log      = 1
# general_log_file = /var/log/mysql/general.log

# ── Character Set ───────────────────────────────────────────
character-set-server  = utf8mb4
collation-server      = utf8mb4_unicode_ci
MYSQLCNF

systemctl restart mysql
success "MySQL 8 installed and tuned"

# ─────────────────────────────────────────────────────────────
#  3. PHP-FPM
# ─────────────────────────────────────────────────────────────
section "Installing PHP ${PHP_VER}-FPM"
add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
apt-get update -qq
apt-get install -y -qq \
    php${PHP_VER}-fpm \
    php${PHP_VER}-mysql \
    php${PHP_VER}-redis \
    php${PHP_VER}-curl \
    php${PHP_VER}-mbstring \
    php${PHP_VER}-xml \
    php${PHP_VER}-zip \
    php${PHP_VER}-gd \
    php${PHP_VER}-bcmath \
    php${PHP_VER}-intl \
    php${PHP_VER}-imagick \
    php${PHP_VER}-opcache \
    php${PHP_VER}-sqlite3

# PHP-FPM pool config
info "Configuring PHP-FPM pool..."
cat > /etc/php/${PHP_VER}/fpm/pool.d/www.conf << PHPPOOL
[www]
user  = www-data
group = www-data
listen = /var/run/php/php${PHP_VER}-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode  = 0660

# ── Process Management ──────────────────────────────────────
pm                   = dynamic
pm.max_children      = 50
pm.start_servers     = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 15
pm.max_requests      = 500
pm.status_path       = /fpm-status

# ── Logging ─────────────────────────────────────────────────
access.log    = /var/log/php${PHP_VER}-fpm.access.log
access.format = '%%R - %%u %%t "%%m %%r%%Q%%q" %%s %%f %%{mili}dms %%{kilo}Mkb %%C%%'
slowlog       = /var/log/php${PHP_VER}-fpm.slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 60s

# ── PHP Settings ────────────────────────────────────────────
php_flag[display_errors]       = off
php_admin_value[error_log]     = /var/log/nginx/php_errors.log
php_admin_flag[log_errors]     = on
php_admin_value[memory_limit]  = 256M
PHPPOOL

# PHP.ini optimisation
info "Configuring php.ini..."
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 256M/'             "$PHP_INI"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 64M/' "$PHP_INI"
sed -i 's/^post_max_size = .*/post_max_size = 64M/'            "$PHP_INI"
sed -i 's/^max_execution_time = .*/max_execution_time = 60/'   "$PHP_INI"
sed -i 's/^;date.timezone.*/date.timezone = Asia\/Ho_Chi_Minh/' "$PHP_INI"
sed -i 's/^expose_php = .*/expose_php = Off/'                  "$PHP_INI"

# OPcache
info "Configuring OPcache..."
cat > /etc/php/${PHP_VER}/fpm/conf.d/10-opcache.ini << 'OPCACHE'
; ── OPcache — PHP bytecode cache ────────────────────────────
zend_extension=opcache

opcache.enable                 = 1
opcache.enable_cli             = 1
opcache.memory_consumption     = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files  = 20000
opcache.max_wasted_percentage  = 10

; Production: 0 = never check for file changes (faster)
; Development: 2 = check every 2 seconds
opcache.revalidate_freq        = 0
opcache.validate_timestamps    = 0

opcache.fast_shutdown          = 1
opcache.huge_code_pages        = 1
opcache.preload_user           = www-data

; JIT — PHP 8 native compilation
opcache.jit                    = tracing
opcache.jit_buffer_size        = 64M
OPCACHE

systemctl enable php${PHP_VER}-fpm
systemctl restart php${PHP_VER}-fpm
success "PHP ${PHP_VER}-FPM installed with OPcache + JIT"

# ─────────────────────────────────────────────────────────────
#  4. REDIS
# ─────────────────────────────────────────────────────────────
section "Installing Redis"
apt-get install -y -qq redis-server

cat > /etc/redis/redis.conf.d/lemp.conf << 'REDISCONF' 2>/dev/null || true
# Appended by LEMP installer
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
REDISCONF

# Append settings to main redis.conf
echo "maxmemory 256mb"          >> /etc/redis/redis.conf
echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server
redis-cli ping | grep -q "PONG" && success "Redis running" || warn "Redis may need manual check"

# ─────────────────────────────────────────────────────────────
#  5. LOG ROTATION
# ─────────────────────────────────────────────────────────────
section "Configuring Log Rotation"
cat > /etc/logrotate.d/lemp << 'LOGROTATE'
# LEMP Stack — Log Rotation
/var/log/nginx/*.log
/var/log/php8.1-fpm*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 $(cat /var/run/nginx.pid) 2>/dev/null || true
        fi
        kill -USR2 $(cat /var/run/php/php8.1-fpm.pid) 2>/dev/null || true
    endscript
}

/var/log/mysql/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 mysql adm
    postrotate
        test -x /usr/bin/mysqladmin && \
        /usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf flush-logs || true
    endscript
}
LOGROTATE
success "Log rotation configured (30 days Nginx, 14 days MySQL)"

# ─────────────────────────────────────────────────────────────
#  6. CACHE PURGE SCRIPT
# ─────────────────────────────────────────────────────────────
cat > "${WEB_ROOT}/cache-purge.php" << 'PURGE'
<?php
// Simple FastCGI cache purge — only accessible from server IP
$cache_dir = '/var/cache/nginx/fastcgi';
$count = 0;
$iter  = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($cache_dir, FilesystemIterator::SKIP_DOTS),
    RecursiveIteratorIterator::CHILD_FIRST
);
foreach ($iter as $file) {
    if ($file->isFile()) { unlink($file); $count++; }
}
header('Content-Type: application/json');
echo json_encode(['status' => 'purged', 'files_removed' => $count, 'timestamp' => date('c')]);
PURGE

# ─────────────────────────────────────────────────────────────
#  7. BEAUTIFUL STATUS PAGE
# ─────────────────────────────────────────────────────────────
section "Building Status Page"
info "Creating beautiful LEMP status dashboard..."

cat > "${WEB_ROOT}/index.php" << 'STATUSPAGE'
<?php
// ── Gather server data ──────────────────────────────────────
$start = microtime(true);

$serverIP   = $_SERVER['SERVER_ADDR']    ?? '192.168.136.131';
$phpVersion = PHP_VERSION;
$phpSAPI    = PHP_SAPI;
$protocol   = $_SERVER['SERVER_PROTOCOL'] ?? 'HTTP/1.1';
$isHTTP2    = ($protocol === 'HTTP/2.0' || ($protocol === 'HTTP/2'));
$sslProto   = $_SERVER['SSL_PROTOCOL']   ?? ($_SERVER['HTTPS'] ?? '' ? 'TLS' : '—');
$sslCipher  = $_SERVER['SSL_CIPHER']     ?? '—';
$isSSL      = !empty($_SERVER['HTTPS']);
$cacheHdr   = getallheaders()['X-Cache-Status'] ?? $_SERVER['HTTP_X_CACHE_STATUS'] ?? null;

// OPcache
$opcache = function_exists('opcache_get_status') ? opcache_get_status(false) : false;
$opcacheEnabled = $opcache && ($opcache['opcache_enabled'] ?? false);
$opcacheHit  = $opcache['opcache_statistics']['hits'] ?? 0;
$opcacheMiss = $opcache['opcache_statistics']['misses'] ?? 0;
$opcacheRatio = ($opcacheHit + $opcacheMiss > 0)
    ? round($opcacheHit / ($opcacheHit + $opcacheMiss) * 100, 1) : 0;
$opcacheMem  = $opcache['memory_usage']['used_memory'] ?? 0;
$opcacheMemF = $opcache['memory_usage']['free_memory'] ?? 0;
$opcacheMemPct = ($opcacheMem + $opcacheMemF > 0)
    ? round($opcacheMem / ($opcacheMem + $opcacheMemF) * 100, 1) : 0;
$jitEnabled  = !empty($opcache['jit']['enabled']);

// Redis
$redisOK = false;
$redisInfo = [];
if (class_exists('Redis')) {
    try {
        $r = new Redis();
        $r->connect('127.0.0.1', 6379, 1);
        $redisOK   = ($r->ping() === '+PONG' || $r->ping() === true);
        $rawInfo   = $r->info();
        $redisInfo = [
            'version'     => $rawInfo['redis_version']     ?? '—',
            'memory'      => $rawInfo['used_memory_human']  ?? '—',
            'keys'        => array_sum(array_map(fn($d) => $d['keys'] ?? 0,
                                array_filter($rawInfo, fn($v, $k) => str_starts_with($k, 'db'), ARRAY_FILTER_USE_BOTH))),
            'hits'        => $rawInfo['keyspace_hits']       ?? 0,
            'misses'      => $rawInfo['keyspace_misses']     ?? 0,
            'uptime'      => $rawInfo['uptime_in_days']      ?? 0,
            'connections' => $rawInfo['connected_clients']   ?? 0,
        ];
    } catch (Exception $e) { $redisOK = false; }
}

// MySQL
$dbOK = false; $dbVersion = '—'; $dbThreads = '—';
try {
    $pdo = new PDO('mysql:host=127.0.0.1;dbname=lemp_db', 'lemp_user', 'LEMPuser@' . date('Y'));
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $dbVersion = $pdo->query('SELECT VERSION()')->fetchColumn();
    $dbThreads = $pdo->query("SHOW STATUS LIKE 'Threads_connected'")->fetchColumn(1);
    $dbOK = true;
} catch (Exception $e) { /* silent */ }

// System
$loadAvg  = sys_getloadavg();
$memInfo  = [];
foreach (file('/proc/meminfo') as $line) {
    [$k, $v] = explode(':', $line, 2);
    $memInfo[trim($k)] = (int) trim($v);
}
$memTotal = round(($memInfo['MemTotal'] ?? 0) / 1024);
$memFree  = round(($memInfo['MemAvailable'] ?? 0) / 1024);
$memUsed  = $memTotal - $memFree;
$memPct   = $memTotal > 0 ? round($memUsed / $memTotal * 100) : 0;

$diskTotal = round(disk_total_space('/') / 1073741824, 1);
$diskFree  = round(disk_free_space('/') / 1073741824, 1);
$diskUsed  = round($diskTotal - $diskFree, 1);
$diskPct   = $diskTotal > 0 ? round($diskUsed / $diskTotal * 100) : 0;

$uptime = trim(shell_exec("awk '{d=int($1/86400); h=int(($1%86400)/3600); m=int(($1%3600)/60); printf \"%dd %dh %dm\", d,h,m}' /proc/uptime 2>/dev/null") ?? '—');

$elapsed = round((microtime(true) - $start) * 1000, 2);
$reqTime = date('Y-m-d H:i:s T');

// ── Cache status badge ──────────────────────────────────────
$cacheStatus = $_SERVER['HTTP_X_CACHE_STATUS'] ?? 'BYPASS';
$cacheBadge  = match(strtoupper($cacheStatus)) {
    'HIT'    => ['HIT',    '#00d97e', '✦'],
    'MISS'   => ['MISS',   '#f6c90e', '◎'],
    'BYPASS' => ['BYPASS', '#9ba0ac', '○'],
    'STALE'  => ['STALE',  '#ff7c5c', '◑'],
    'EXPIRED'=> ['EXPIRED','#ff7c5c', '◐'],
    default  => [$cacheStatus, '#9ba0ac', '○'],
};
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>LEMP Server — <?= $serverIP ?></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Syne:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
/* ── Reset & Base ──────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg:       #0a0c10;
  --bg2:      #0f1218;
  --bg3:      #141820;
  --border:   #1e2430;
  --border2:  #252d3a;
  --text:     #d4dae8;
  --muted:    #5a6478;
  --accent:   #4f8fff;
  --accent2:  #00d97e;
  --accent3:  #f6c90e;
  --red:      #ff5c6c;
  --mono:     'Space Mono', monospace;
  --sans:     'Syne', sans-serif;
  --r:        10px;
  --r2:       6px;
}

html { scroll-behavior: smooth; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: var(--sans);
  font-size: 14px;
  line-height: 1.6;
  min-height: 100vh;
  overflow-x: hidden;
}

/* ── Background grid ──────────────────────────────────────── */
body::before {
  content: '';
  position: fixed; inset: 0; z-index: 0;
  background-image:
    linear-gradient(rgba(79,143,255,.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(79,143,255,.03) 1px, transparent 1px);
  background-size: 40px 40px;
  pointer-events: none;
}

/* ── Layout ───────────────────────────────────────────────── */
.wrap { position: relative; z-index: 1; max-width: 1100px; margin: 0 auto; padding: 0 20px 60px; }

/* ── Header ───────────────────────────────────────────────── */
header {
  padding: 48px 0 40px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}
.logo-block { display: flex; align-items: center; gap: 16px; }
.logo-icon {
  width: 48px; height: 48px;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 22px;
  box-shadow: 0 0 24px rgba(79,143,255,.3);
  flex-shrink: 0;
}
.logo-text h1 {
  font-family: var(--sans);
  font-size: 24px; font-weight: 800;
  letter-spacing: -0.5px;
  background: linear-gradient(90deg, #fff 0%, #9fb8ff 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  line-height: 1.1;
}
.logo-text .sub {
  font-family: var(--mono);
  font-size: 11px; color: var(--muted);
  letter-spacing: .04em;
}
.header-meta {
  text-align: right;
  font-family: var(--mono);
  font-size: 11px; color: var(--muted);
  line-height: 1.8;
}
.header-meta strong { color: var(--text); }

/* ── Pill badges ──────────────────────────────────────────── */
.pill {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 3px 10px;
  border-radius: 20px;
  font-family: var(--mono); font-size: 11px; font-weight: 700;
  letter-spacing: .05em;
}
.pill-green { background: rgba(0,217,126,.12); color: var(--accent2); border: 1px solid rgba(0,217,126,.2); }
.pill-blue  { background: rgba(79,143,255,.12); color: var(--accent);  border: 1px solid rgba(79,143,255,.2); }
.pill-amber { background: rgba(246,201,14,.12); color: var(--accent3); border: 1px solid rgba(246,201,14,.2); }
.pill-red   { background: rgba(255,92,108,.12); color: var(--red);     border: 1px solid rgba(255,92,108,.2); }
.pill-muted { background: rgba(90,100,120,.15); color: var(--muted);   border: 1px solid var(--border2); }

/* ── Status row ───────────────────────────────────────────── */
.status-row {
  display: flex; flex-wrap: wrap; gap: 10px;
  margin-bottom: 36px;
  padding: 18px 20px;
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: var(--r);
}
.status-item { display: flex; align-items: center; gap: 8px; }
.dot {
  width: 8px; height: 8px; border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 0 6px currentColor;
}
.dot-green { background: var(--accent2); color: var(--accent2); }
.dot-blue  { background: var(--accent);  color: var(--accent);  }
.dot-red   { background: var(--red);     color: var(--red);     }
.dot-amber { background: var(--accent3); color: var(--accent3); }
.status-label { font-size: 12px; color: var(--muted); }
.status-val   { font-family: var(--mono); font-size: 12px; color: var(--text); }
.sep { width: 1px; height: 20px; background: var(--border2); flex-shrink: 0; }

/* ── Grid ─────────────────────────────────────────────────── */
.grid   { display: grid; gap: 14px; }
.g2     { grid-template-columns: repeat(2, 1fr); }
.g3     { grid-template-columns: repeat(3, 1fr); }
.g4     { grid-template-columns: repeat(4, 1fr); }
.span2  { grid-column: span 2; }

/* ── Card ─────────────────────────────────────────────────── */
.card {
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 20px 22px;
  position: relative;
  overflow: hidden;
  transition: border-color .2s, box-shadow .2s;
}
.card:hover {
  border-color: var(--border2);
  box-shadow: 0 4px 24px rgba(0,0,0,.3);
}
.card::before {
  content: '';
  position: absolute; top: 0; left: 0; right: 0;
  height: 2px;
  background: var(--card-accent, var(--border));
}
.card-blue   { --card-accent: linear-gradient(90deg, var(--accent), transparent); }
.card-green  { --card-accent: linear-gradient(90deg, var(--accent2), transparent); }
.card-amber  { --card-accent: linear-gradient(90deg, var(--accent3), transparent); }
.card-red    { --card-accent: linear-gradient(90deg, var(--red), transparent); }
.card-purple { --card-accent: linear-gradient(90deg, #a78bfa, transparent); }

.card-label {
  font-size: 10px; font-weight: 700; letter-spacing: .12em;
  text-transform: uppercase; color: var(--muted);
  margin-bottom: 12px;
  display: flex; align-items: center; gap: 8px;
}
.card-icon { font-size: 14px; }

.big-num {
  font-family: var(--mono);
  font-size: 28px; font-weight: 700;
  color: #fff; line-height: 1.1;
  margin-bottom: 4px;
  letter-spacing: -.02em;
}
.big-unit { font-size: 14px; color: var(--muted); font-weight: 400; }
.card-sub { font-size: 11px; color: var(--muted); margin-top: 6px; }

/* ── Row list ─────────────────────────────────────────────── */
.row-list { display: flex; flex-direction: column; gap: 0; }
.row-item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 9px 0;
  border-bottom: 1px solid var(--border);
  gap: 8px;
}
.row-item:last-child { border-bottom: none; padding-bottom: 0; }
.row-key {
  font-size: 12px; color: var(--muted);
  display: flex; align-items: center; gap: 6px;
  flex-shrink: 0;
}
.row-val {
  font-family: var(--mono); font-size: 12px; color: var(--text);
  text-align: right; word-break: break-all;
}

/* ── Progress bar ─────────────────────────────────────────── */
.prog-wrap { margin-top: 14px; }
.prog-meta {
  display: flex; justify-content: space-between;
  font-family: var(--mono); font-size: 11px; color: var(--muted);
  margin-bottom: 6px;
}
.prog-track {
  height: 5px; background: var(--border2);
  border-radius: 3px; overflow: hidden;
}
.prog-bar {
  height: 100%; border-radius: 3px;
  transition: width .6s ease;
}
.prog-green { background: linear-gradient(90deg, var(--accent2), #00ff9d); }
.prog-blue  { background: linear-gradient(90deg, var(--accent),  #82b4ff); }
.prog-amber { background: linear-gradient(90deg, var(--accent3), #ffe76b); }
.prog-red   { background: linear-gradient(90deg, var(--red), #ff8fa3); }

/* ── Section header ───────────────────────────────────────── */
.sec-head {
  font-size: 11px; font-weight: 700; letter-spacing: .12em;
  text-transform: uppercase; color: var(--muted);
  margin: 32px 0 14px;
  display: flex; align-items: center; gap: 10px;
}
.sec-head::after {
  content: ''; flex: 1; height: 1px; background: var(--border);
}

/* ── Extensions grid ──────────────────────────────────────── */
.ext-grid {
  display: flex; flex-wrap: wrap; gap: 7px;
}
.ext-badge {
  font-family: var(--mono); font-size: 11px;
  padding: 4px 10px;
  border-radius: 5px;
  background: var(--bg3);
  border: 1px solid var(--border2);
  color: var(--text);
}
.ext-badge.on  { color: var(--accent2); border-color: rgba(0,217,126,.2); background: rgba(0,217,126,.06); }
.ext-badge.off { color: var(--red);     border-color: rgba(255,92,108,.2); background: rgba(255,92,108,.06); }

/* ── Log viewer ───────────────────────────────────────────── */
.log-block {
  background: #070a0e;
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 16px;
  font-family: var(--mono); font-size: 11px;
  color: #8892a4;
  max-height: 260px;
  overflow-y: auto;
  line-height: 1.8;
}
.log-block::-webkit-scrollbar { width: 4px; }
.log-block::-webkit-scrollbar-track { background: transparent; }
.log-block::-webkit-scrollbar-thumb { background: var(--border2); border-radius: 2px; }
.log-line { display: block; }
.log-ip   { color: #4f8fff; }
.log-ok   { color: var(--accent2); }
.log-err  { color: var(--red); }
.log-warn { color: var(--accent3); }
.log-time { color: var(--muted); }
.log-path { color: #d4dae8; }

/* ── Cache info ───────────────────────────────────────────── */
.cache-row {
  display: grid; grid-template-columns: 1fr 1fr 1fr;
  gap: 10px; margin-top: 12px;
}
.cache-cell {
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-radius: var(--r2);
  padding: 10px 12px;
  text-align: center;
}
.cache-cell .num { font-family: var(--mono); font-size: 18px; font-weight: 700; color: #fff; }
.cache-cell .lbl { font-size: 10px; color: var(--muted); text-transform: uppercase; letter-spacing: .08em; margin-top: 2px; }

/* ── Footer ───────────────────────────────────────────────── */
footer {
  margin-top: 50px; padding-top: 20px;
  border-top: 1px solid var(--border);
  display: flex; justify-content: space-between; align-items: center;
  flex-wrap: wrap; gap: 10px;
}
footer .fl { font-family: var(--mono); font-size: 11px; color: var(--muted); }
footer .fr { font-family: var(--mono); font-size: 11px; color: var(--muted); }

/* ── Animations ───────────────────────────────────────────── */
@keyframes pulse { 0%,100% { opacity: 1 } 50% { opacity: .5 } }
.pulse { animation: pulse 2s infinite; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
.fade-up { animation: fadeUp .45s ease forwards; }
.d1 { animation-delay: .05s; opacity: 0; }
.d2 { animation-delay: .10s; opacity: 0; }
.d3 { animation-delay: .15s; opacity: 0; }
.d4 { animation-delay: .20s; opacity: 0; }
.d5 { animation-delay: .25s; opacity: 0; }
.d6 { animation-delay: .30s; opacity: 0; }
.d7 { animation-delay: .35s; opacity: 0; }
.d8 { animation-delay: .40s; opacity: 0; }

/* ── Responsive ───────────────────────────────────────────── */
@media (max-width: 720px) {
  .g2, .g3, .g4 { grid-template-columns: 1fr; }
  .span2 { grid-column: span 1; }
  .cache-row { grid-template-columns: 1fr 1fr; }
  header { flex-direction: column; align-items: flex-start; }
  .header-meta { text-align: left; }
}
</style>
</head>
<body>
<div class="wrap">

<!-- ── HEADER ─────────────────────────────────────────────── -->
<header class="fade-up d1">
  <div class="logo-block">
    <div class="logo-icon">⚡</div>
    <div class="logo-text">
      <h1>LEMP Stack</h1>
      <div class="sub">Linux · Nginx · MySQL · PHP — <?= $serverIP ?></div>
    </div>
  </div>
  <div class="header-meta">
    <div><strong><?= date('D, d M Y H:i:s') ?></strong></div>
    <div>Uptime: <strong><?= $uptime ?></strong></div>
    <div>Response: <strong><?= $elapsed ?>ms</strong></div>
  </div>
</header>

<!-- ── STATUS ROW ─────────────────────────────────────────── -->
<div class="status-row fade-up d2">
  <?php
  $services = [
    ['Nginx',    true,  $isHTTP2 ? 'HTTP/2' : 'HTTP/1.1'],
    ['PHP-FPM',  true,  $phpVersion],
    ['MySQL',    $dbOK, $dbOK ? $dbVersion : 'offline'],
    ['Redis',    $redisOK, $redisOK ? 'connected' : 'offline'],
    ['OPcache',  $opcacheEnabled, $opcacheEnabled ? 'enabled' : 'disabled'],
    ['JIT',      $jitEnabled, $jitEnabled ? 'tracing' : 'off'],
    ['SSL/TLS',  $isSSL, $sslProto ?: 'TLS'],
    ['Cache',    true,  $cacheBadge[0]],
  ];
  foreach ($services as $i => $s):
    $ok = $s[1];
  ?>
  <?php if ($i > 0): ?><div class="sep"></div><?php endif; ?>
  <div class="status-item">
    <div class="dot <?= $ok ? 'dot-green' : 'dot-red' ?> <?= $ok ? 'pulse' : '' ?>"></div>
    <span class="status-label"><?= $s[0] ?></span>
    <span class="status-val"><?= $s[2] ?></span>
  </div>
  <?php endforeach; ?>
</div>

<!-- ── TOP METRICS ────────────────────────────────────────── -->
<p class="sec-head">System Resources</p>
<div class="grid g4 fade-up d3">

  <div class="card card-blue">
    <div class="card-label"><span class="card-icon">▣</span> Memory</div>
    <div class="big-num"><?= $memUsed ?> <span class="big-unit">MB</span></div>
    <div class="card-sub">of <?= $memTotal ?> MB total · <?= $memFree ?> MB free</div>
    <div class="prog-wrap">
      <div class="prog-meta"><span><?= $memPct ?>% used</span><span><?= $memTotal ?>MB</span></div>
      <div class="prog-track">
        <div class="prog-bar <?= $memPct > 80 ? 'prog-red' : ($memPct > 60 ? 'prog-amber' : 'prog-blue') ?>"
             style="width:<?= $memPct ?>%"></div>
      </div>
    </div>
  </div>

  <div class="card card-green">
    <div class="card-label"><span class="card-icon">◈</span> Disk</div>
    <div class="big-num"><?= $diskUsed ?> <span class="big-unit">GB</span></div>
    <div class="card-sub">of <?= $diskTotal ?> GB total · <?= $diskFree ?> GB free</div>
    <div class="prog-wrap">
      <div class="prog-meta"><span><?= $diskPct ?>% used</span><span><?= $diskTotal ?>GB</span></div>
      <div class="prog-track">
        <div class="prog-bar <?= $diskPct > 85 ? 'prog-red' : ($diskPct > 70 ? 'prog-amber' : 'prog-green') ?>"
             style="width:<?= $diskPct ?>%"></div>
      </div>
    </div>
  </div>

  <div class="card card-amber">
    <div class="card-label"><span class="card-icon">⊞</span> Load Average</div>
    <div class="big-num"><?= round($loadAvg[0],2) ?></div>
    <div class="card-sub">5m: <?= round($loadAvg[1],2) ?> · 15m: <?= round($loadAvg[2],2) ?></div>
    <div class="prog-wrap">
      <?php $cores = (int)(shell_exec('nproc') ?: 1); $loadPct = min(100, round($loadAvg[0]/$cores*100)); ?>
      <div class="prog-meta"><span><?= $cores ?> CPU cores</span><span><?= $loadPct ?>%</span></div>
      <div class="prog-track">
        <div class="prog-bar <?= $loadPct > 90 ? 'prog-red' : ($loadPct > 70 ? 'prog-amber' : 'prog-amber') ?>"
             style="width:<?= $loadPct ?>%"></div>
      </div>
    </div>
  </div>

  <div class="card card-purple">
    <div class="card-label"><span class="card-icon">◎</span> FastCGI Cache</div>
    <div class="big-num" style="color:<?= $cacheBadge[1] ?>"><?= $cacheBadge[2] ?> <?= $cacheBadge[0] ?></div>
    <div class="card-sub">This request was <?= strtolower($cacheBadge[0]) ?> by Nginx cache</div>
    <div style="margin-top:10px">
      <span class="pill pill-<?= match($cacheBadge[0]) { 'HIT' => 'green', 'MISS' => 'amber', default => 'muted' } ?>">
        X-Cache-Status: <?= $cacheBadge[0] ?>
      </span>
    </div>
  </div>

</div>

<!-- ── HTTP / SSL / NGINX ─────────────────────────────────── -->
<p class="sec-head">Network &amp; Protocol</p>
<div class="grid g2 fade-up d4">

  <div class="card card-blue">
    <div class="card-label"><span class="card-icon">⟁</span> Connection</div>
    <div class="row-list">
      <div class="row-item">
        <span class="row-key">Protocol</span>
        <span class="row-val"><?= $protocol ?> <?= $isHTTP2 ? '<span class="pill pill-green">HTTP/2</span>' : '' ?></span>
      </div>
      <div class="row-item">
        <span class="row-key">SSL Protocol</span>
        <span class="row-val"><?= $sslProto ?: '—' ?></span>
      </div>
      <div class="row-item">
        <span class="row-key">SSL Cipher</span>
        <span class="row-val"><?= $sslCipher ?: '—' ?></span>
      </div>
      <div class="row-item">
        <span class="row-key">Client IP</span>
        <span class="row-val"><?= htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? '—') ?></span>
      </div>
      <div class="row-item">
        <span class="row-key">Server IP</span>
        <span class="row-val"><?= $serverIP ?></span>
      </div>
      <div class="row-item">
        <span class="row-key">User Agent</span>
        <span class="row-val" style="max-width:200px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-size:10px">
          <?= htmlspecialchars(substr($_SERVER['HTTP_USER_AGENT'] ?? '—', 0, 60)) ?>
        </span>
      </div>
    </div>
  </div>

  <div class="card card-green">
    <div class="card-label"><span class="card-icon">⬡</span> Caching Config</div>
    <div class="row-list">
      <div class="row-item">
        <span class="row-key">FastCGI Cache</span>
        <span class="row-val"><span class="pill pill-green">LEMP_CACHE zone</span></span>
      </div>
      <div class="row-item">
        <span class="row-key">Cache Path</span>
        <span class="row-val" style="font-size:10px">/var/cache/nginx/fastcgi</span>
      </div>
      <div class="row-item">
        <span class="row-key">Cache TTL</span>
        <span class="row-val">200/301/302 → 60min · 404 → 1min</span>
      </div>
      <div class="row-item">
        <span class="row-key">Stale Serve</span>
        <span class="row-val"><span class="pill pill-blue">error · timeout · updating</span></span>
      </div>
      <div class="row-item">
        <span class="row-key">Static Assets</span>
        <span class="row-val">expires 30d · immutable</span>
      </div>
      <div class="row-item">
        <span class="row-key">Gzip</span>
        <span class="row-val">level 5 · 256b min-length</span>
      </div>
    </div>
  </div>

</div>

<!-- ── PHP / OPCACHE ──────────────────────────────────────── -->
<p class="sec-head">PHP &amp; OPcache</p>
<div class="grid g3 fade-up d5">

  <div class="card card-blue">
    <div class="card-label"><span class="card-icon">⬢</span> PHP Runtime</div>
    <div class="row-list">
      <div class="row-item"><span class="row-key">Version</span><span class="row-val"><?= $phpVersion ?></span></div>
      <div class="row-item"><span class="row-key">SAPI</span><span class="row-val"><?= $phpSAPI ?></span></div>
      <div class="row-item"><span class="row-key">Memory Limit</span><span class="row-val"><?= ini_get('memory_limit') ?></span></div>
      <div class="row-item"><span class="row-key">Max Exec</span><span class="row-val"><?= ini_get('max_execution_time') ?>s</span></div>
      <div class="row-item"><span class="row-key">Upload Max</span><span class="row-val"><?= ini_get('upload_max_filesize') ?></span></div>
      <div class="row-item"><span class="row-key">Timezone</span><span class="row-val"><?= ini_get('date.timezone') ?></span></div>
    </div>
  </div>

  <div class="card card-green">
    <div class="card-label"><span class="card-icon">⊛</span> OPcache <?= $jitEnabled ? '<span class="pill pill-blue" style="margin-left:4px">JIT</span>' : '' ?></div>
    <?php if ($opcacheEnabled): ?>
    <div class="row-list">
      <div class="row-item"><span class="row-key">Status</span><span class="row-val"><span class="pill pill-green">Enabled</span></span></div>
      <div class="row-item"><span class="row-key">Hit Ratio</span><span class="row-val"><?= $opcacheRatio ?>%</span></div>
      <div class="row-item"><span class="row-key">Hits / Misses</span><span class="row-val"><?= number_format($opcacheHit) ?> / <?= number_format($opcacheMiss) ?></span></div>
      <div class="row-item"><span class="row-key">Cached Scripts</span><span class="row-val"><?= number_format($opcache['opcache_statistics']['num_cached_scripts'] ?? 0) ?></span></div>
      <div class="row-item"><span class="row-key">JIT Mode</span><span class="row-val"><?= $jitEnabled ? 'tracing' : 'disabled' ?></span></div>
    </div>
    <div class="prog-wrap">
      <div class="prog-meta"><span>Memory <?= $opcacheMemPct ?>%</span><span><?= round(($opcacheMem+$opcacheMemF)/1024/1024) ?>MB total</span></div>
      <div class="prog-track">
        <div class="prog-bar prog-green" style="width:<?= $opcacheMemPct ?>%"></div>
      </div>
    </div>
    <?php else: ?>
    <div style="padding:20px 0; text-align:center; color:var(--muted); font-size:12px">OPcache not enabled</div>
    <?php endif; ?>
  </div>

  <div class="card card-amber">
    <div class="card-label"><span class="card-icon">◆</span> Redis Cache</div>
    <?php if ($redisOK): ?>
    <div class="row-list">
      <div class="row-item"><span class="row-key">Status</span><span class="row-val"><span class="pill pill-green">Connected</span></span></div>
      <div class="row-item"><span class="row-key">Version</span><span class="row-val"><?= $redisInfo['version'] ?></span></div>
      <div class="row-item"><span class="row-key">Memory Used</span><span class="row-val"><?= $redisInfo['memory'] ?></span></div>
      <div class="row-item"><span class="row-key">Keys</span><span class="row-val"><?= $redisInfo['keys'] ?></span></div>
      <div class="row-item"><span class="row-key">Hits / Misses</span><span class="row-val"><?= number_format($redisInfo['hits']) ?> / <?= number_format($redisInfo['misses']) ?></span></div>
      <div class="row-item"><span class="row-key">Clients</span><span class="row-val"><?= $redisInfo['connections'] ?> connected · <?= $redisInfo['uptime'] ?>d uptime</span></div>
    </div>
    <?php else: ?>
    <div style="padding:20px 0; text-align:center; color:var(--red); font-size:12px">Redis not available</div>
    <?php endif; ?>
  </div>

</div>

<!-- ── DATABASE ───────────────────────────────────────────── -->
<p class="sec-head">Database — MySQL</p>
<div class="grid g2 fade-up d6">

  <div class="card card-blue">
    <div class="card-label"><span class="card-icon">◉</span> MySQL Status</div>
    <?php if ($dbOK): ?>
    <div class="row-list">
      <div class="row-item"><span class="row-key">Status</span><span class="row-val"><span class="pill pill-green">Online</span></span></div>
      <div class="row-item"><span class="row-key">Version</span><span class="row-val"><?= $dbVersion ?></span></div>
      <div class="row-item"><span class="row-key">Active Threads</span><span class="row-val"><?= $dbThreads ?></span></div>
      <div class="row-item"><span class="row-key">Database</span><span class="row-val">lemp_db</span></div>
      <div class="row-item"><span class="row-key">Charset</span><span class="row-val">utf8mb4 / unicode_ci</span></div>
      <div class="row-item"><span class="row-key">User</span><span class="row-val">lemp_user@localhost</span></div>
    </div>
    <?php else: ?>
    <div style="padding:16px 0;color:var(--red);font-size:12px">
      ✕ Cannot connect — check credentials in this page header
    </div>
    <?php endif; ?>
  </div>

  <div class="card card-green">
    <div class="card-label"><span class="card-icon">≡</span> Logging Setup</div>
    <div class="row-list">
      <div class="row-item"><span class="row-key">Access Log</span><span class="row-val" style="font-size:10px">/var/log/nginx/access.log (JSON)</span></div>
      <div class="row-item"><span class="row-key">Access (HR)</span><span class="row-val" style="font-size:10px">/var/log/nginx/access_hr.log</span></div>
      <div class="row-item"><span class="row-key">Error Log</span><span class="row-val" style="font-size:10px">/var/log/nginx/error.log</span></div>
      <div class="row-item"><span class="row-key">PHP Errors</span><span class="row-val" style="font-size:10px">/var/log/nginx/php_errors.log</span></div>
      <div class="row-item"><span class="row-key">MySQL Slow</span><span class="row-val" style="font-size:10px">/var/log/mysql/slow.log (≥1s)</span></div>
      <div class="row-item"><span class="row-key">FPM Access</span><span class="row-val" style="font-size:10px">/var/log/php8.1-fpm.access.log</span></div>
    </div>
  </div>

</div>

<!-- ── PHP EXTENSIONS ─────────────────────────────────────── -->
<p class="sec-head">PHP Extensions</p>
<div class="card fade-up d7">
<?php
$want = ['mysql','pdo','pdo_mysql','mbstring','xml','zip','gd','curl',
         'bcmath','intl','imagick','opcache','redis','json','tokenizer',
         'fileinfo','openssl','ctype','pcre','session','spl','iconv'];
echo '<div class="ext-grid">';
foreach ($want as $ext):
    $loaded = extension_loaded($ext);
    echo "<span class='ext-badge " . ($loaded ? 'on' : 'off') . "'>"
       . ($loaded ? '✓' : '✗') . " {$ext}</span>";
endforeach;
echo '</div>';
?>
</div>

<!-- ── RECENT LOG ENTRIES ─────────────────────────────────── -->
<p class="sec-head">Recent Access Log</p>
<div class="fade-up d8">
<?php
$logFile = '/var/log/nginx/access_hr.log';
$lines   = [];
if (file_exists($logFile) && is_readable($logFile)) {
    $lines = array_reverse(array_slice(file($logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES), -20));
}
?>
<div class="log-block">
<?php if (empty($lines)): ?>
  <span style="color:var(--muted)">No log entries yet — make a few requests first.</span>
<?php else: ?>
<?php foreach (array_slice($lines,0,15) as $line):
    preg_match('/^(\S+) \[([^\]]+)\] "([^"]+)" (\d+) (\d+).*rt=([\d.]+) .*cs=(\S+)/', $line, $m);
    $ip = $m[1] ?? '—'; $ts = $m[2] ?? ''; $req = $m[3] ?? $line;
    $st = $m[4] ?? ''; $rt = $m[6] ?? ''; $cs = $m[7] ?? '—';
    $stClass = match(true) { str_starts_with($st,'2') => 'log-ok', str_starts_with($st,'4') || str_starts_with($st,'5') => 'log-err', default => 'log-warn' };
?>
<span class="log-line">
  <span class="log-time">[<?= $ts ?>]</span>
  <span class="log-ip"> <?= htmlspecialchars($ip) ?></span>
  <span class="<?= $stClass ?>"> <?= $st ?></span>
  <span class="log-path"> <?= htmlspecialchars(substr($req,0,60)) ?></span>
  <span style="color:var(--accent3)"> <?= $rt ?>s</span>
  <span style="color:var(--muted)"> cache=<?= $cs ?></span>
</span>
<?php endforeach; ?>
<?php endif; ?>
</div>
</div>

<!-- ── QUICK COMMANDS ─────────────────────────────────────── -->
<p class="sec-head">Quick Reference</p>
<div class="grid g2">
<div class="card">
  <div class="card-label">📋 Useful Commands</div>
  <div style="font-family:var(--mono);font-size:11px;line-height:2;color:#8892a4">
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">sudo tail -f /var/log/nginx/access.log | python3 -m json.tool</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">sudo tail -f /var/log/nginx/access_hr.log</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">sudo nginx -t && sudo systemctl reload nginx</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">sudo systemctl restart php<?= $phpVersion ?>-fpm</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">sudo find /var/cache/nginx -type f -delete</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">redis-cli info stats</span></div>
    <div><span style="color:var(--accent)">$</span> <span style="color:var(--text)">mysqldumpslow -s t -t 5 /var/log/mysql/slow.log</span></div>
  </div>
</div>
<div class="card">
  <div class="card-label">🔗 Internal Endpoints</div>
  <div style="font-family:var(--mono);font-size:11px;line-height:2;color:#8892a4">
    <div><a href="/nginx-status" style="color:var(--accent);text-decoration:none">→ /nginx-status</a> <span style="color:var(--muted)">Nginx stub status</span></div>
    <div><a href="/fpm-status"   style="color:var(--accent);text-decoration:none">→ /fpm-status</a>   <span style="color:var(--muted)">PHP-FPM pool status</span></div>
    <div><a href="/cache-purge"  style="color:var(--accent);text-decoration:none">→ /cache-purge</a>  <span style="color:var(--muted)">Clear FastCGI cache</span></div>
    <div><a href="/phpinfo.php"  style="color:var(--accent);text-decoration:none">→ /phpinfo.php</a>  <span style="color:var(--muted)">Full PHP info (remove in prod)</span></div>
    <div style="margin-top:8px;color:var(--muted)">All endpoints restricted to <?= $serverIP ?></div>
  </div>
</div>
</div>

<!-- ── FOOTER ─────────────────────────────────────────────── -->
<footer>
  <div class="fl">LEMP Stack · Ubuntu 22.04 · <?= $serverIP ?></div>
  <div class="fr">Generated in <strong><?= $elapsed ?>ms</strong> · <?= $reqTime ?></div>
</footer>

</div><!-- .wrap -->
</body>
</html>
STATUSPAGE

# phpinfo (remove in production!)
cat > "${WEB_ROOT}/phpinfo.php" << 'PHPINFO'
<?php
// Remove this file in production!
if ($_SERVER['REMOTE_ADDR'] !== '192.168.136.131' && $_SERVER['REMOTE_ADDR'] !== '127.0.0.1') {
    http_response_code(403); die('Access denied');
}
phpinfo();
PHPINFO

# Set permissions
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
success "Status page created at ${WEB_ROOT}/index.php"

# ─────────────────────────────────────────────────────────────
#  FINAL NGINX TEST & START
# ─────────────────────────────────────────────────────────────
section "Starting Services"
nginx -t 2>&1 | grep -E "ok|error" | while read -r line; do
    [[ "$line" == *"ok"* ]] && success "$line" || error "$line"
done

systemctl restart nginx
systemctl restart php${PHP_VER}-fpm
systemctl restart mysql
systemctl restart redis-server

success "All services started"

# ─────────────────────────────────────────────────────────────
#  VERIFY
# ─────────────────────────────────────────────────────────────
section "Verification"
sleep 2
for svc in nginx php${PHP_VER}-fpm mysql redis-server; do
    if systemctl is-active --quiet "$svc"; then
        success "$svc is running"
    else
        warn "$svc may not be running — check: systemctl status $svc"
    fi
done

HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${SERVER_IP}/" 2>/dev/null || echo "000")
[[ "$HTTP_CODE" == "200" ]] && success "HTTPS status page: HTTP $HTTP_CODE" \
                             || warn    "HTTPS check returned: HTTP $HTTP_CODE (may need browser visit)"

# ─────────────────────────────────────────────────────────────
#  SUMMARY
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║          LEMP Stack Installation Complete! ✓             ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Status Page${NC}   →  https://${SERVER_IP}/"
echo -e "  ${CYAN}Nginx Status${NC}  →  https://${SERVER_IP}/nginx-status"
echo -e "  ${CYAN}FPM Status${NC}   →  https://${SERVER_IP}/fpm-status"
echo -e "  ${CYAN}PHP Info${NC}      →  https://${SERVER_IP}/phpinfo.php"
echo -e "  ${CYAN}Cache Purge${NC}  →  https://${SERVER_IP}/cache-purge"
echo ""
echo -e "  ${CYAN}MySQL Root${NC}    :  ${MYSQL_ROOT_PASS}"
echo -e "  ${CYAN}DB Name${NC}       :  ${DB_NAME}"
echo -e "  ${CYAN}DB User${NC}       :  ${DB_USER} / ${DB_PASS}"
echo ""
echo -e "  ${YELLOW}Credentials saved to:${NC} /root/.lemp_credentials"
echo ""
echo -e "  ${CYAN}Useful Log Commands:${NC}"
echo -e "  ${BOLD}sudo tail -f /var/log/nginx/access_hr.log${NC}"
echo -e "  ${BOLD}sudo tail -f /var/log/nginx/access.log | python3 -m json.tool${NC}"
echo ""
echo -e "  ${YELLOW}Note: Accept the self-signed certificate in your browser${NC}"
echo -e "  ${YELLOW}Remove /var/www/html/phpinfo.php before going to production!${NC}"
echo ""

# Save credentials
cat > /root/.lemp_credentials << CREDS
# LEMP Stack Credentials — $(date)
# Keep this file secure!

MySQL Root Password : ${MYSQL_ROOT_PASS}
Database Name       : ${DB_NAME}
Database User       : ${DB_USER}
Database Password   : ${DB_PASS}

Status Page : https://${SERVER_IP}/
CREDS
chmod 600 /root/.lemp_credentials

success "Credentials saved to /root/.lemp_credentials"
echo -e "\n${BOLD}${BLUE}Happy hosting! ⚡${NC}\n"
