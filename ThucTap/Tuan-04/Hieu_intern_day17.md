# Báo cáo học tập - Hệ thống HA Web
*Keepalived · HAProxy · Apache · WordPress · MariaDB · Redis · Prometheus · Grafana · Alertmanager*

---

| Thông tin | Chi tiết |
|---|---|
| **Họ và tên** | Nguyễn Thanh Hiếu |
| **Ngày thực hiện** | 20/05/2026 |
| **Tuần thực tập** | Tuần 4 — Ngày 17 |
| **Đơn vị thực tập** | Nhân Hòa |
| **Người hướng dẫn** | *Trường An* |
| **Chủ đề** | Xây dựng hệ thống HA Web: HAProxy · Keepalived · Apache · WordPress · MariaDB · Redis · Prometheus · Grafana · Alertmanager |

## Mục lục
 
1. [Tổng quan hệ thống](#1-tổng-quan)
2. [Chuẩn bị môi trường](#2-chuẩn-bị-môi-trường)
3. [SSL Certificate](#3-ssl-certificate)
4. [Keepalived — VRRP Failover](#4-keepalived--vrrp-failover)
5. [HAProxy — Load Balancer](#5-haproxy--load-balancer)
6. [Apache + PHP-FPM](#6-apache--php-fpm)
7. [MariaDB + Redis](#7-mariadb--redis)
8. [WordPress](#8-wordpress)
9. [Monitoring: Prometheus + Grafana + Alertmanager](#9-monitoring-prometheus--grafana--alertmanager)
10. [Kết quả kiểm tra](#10-kết-quả-kiểm-tra)
11. [Lỗi gặp phải và cách khắc phục](#11-lỗi-gặp-phải-và-cách-khắc-phục)
12. [Kết luận và bài học rút ra](#12-kết-luận-và-bài-học-rút-ra)
---
## 1. Tổng quan hệ thống
 
### 1.1 Mục tiêu
 
Xây dựng hệ thống web có tính sẵn sàng cao (High Availability) nhằm loại bỏ điểm chết duy nhất (Single Point of Failure) ở mọi tầng. Hệ thống tự động chuyển đổi dự phòng khi có sự cố, cân bằng tải giữa nhiều backend, và gửi cảnh báo tự động đến người vận hành.  
- Cân bằng tải (Load Balancing) giữa nhiều Web Server thông qua HAProxy  
- Tự động failover khi Load Balancer Master gặp sự cố (Keepalived VRRP < 3 giây)  
- Session người dùng được lưu tập trung trên Redis — không bị mất khi HAProxy route sang node khác   
- Hệ thống giám sát (Prometheus + Grafana) theo dõi CPU, RAM, Disk, trạng thái HAProxy, MariaDB, Redis    
- Cảnh báo tự động qua Gmail khi phát hiện sự cố  
#### Sơ đồ kiến trúc hệ thống
<img width="3676" height="3564" alt="image" src="https://github.com/user-attachments/assets/9702b116-3d97-4983-b35c-f8e2b07f43ba" />

#### Bảng IP và dịch vụ

Node	| IP	| Role	| Dịch vụ chính
-- | -- | -- | --
VIP |	192.168.136.100 |	Virtual IP |	VRRP :80 :443 :8404
edge-01 |	192.168.136.131 |	MASTER LB |	HAProxy · Keepalived · Prometheus · Grafana · Alertmanager · node\_exporter
edge-02 |	192.168.136.146	 | BACKUP LB |	HAProxy · Keepalived · Prometheus · Grafana · Alertmanager · node\_exporter
web-01 |	192.168.136.145 |	Backend 1 |	Apache2 · PHP-FPM · WordPress · node_exporter
web-02  |	192.168.136.134	| Backend 2 + DB |	Apache2 · MariaDB · Redis · node_exporter · redis_exp · mysqld_exp 

#### Yêu cầu hệ thống

Hệ thống được triển khai trên môi trường máy ảo sử dụng hệ điều hành Ubuntu Server 22.04 LTS nhằm xây dựng mô hình Web Cluster kết hợp Load Balancing, High Availability và Monitoring.  

Cấu hình phần cứng tối thiểu  

Thành phần  |	Yêu cầu
---|---
Số lượng máy ảo	 | 04 VM
Hệ điều hành |	Ubuntu Server 22.04 LTS
CPU	Tối thiểu | 1 vCPU / node
RAM	 | ≥ 1 GB RAM / node
RAM cho Web Server phụ (web-02) |	≥ 2 GB RAM
Dung lượng đĩa |	≥ 20 GB / node
Kiểu card mạng |	NAT hoặc Host-only
Dải mạng nội bộ |	192.168.136.0/24
Kết nối Internet |	Bắt buộc để sử dụng apt, wget, tải package và cập nhật hệ thống


## 2. Chuẩn bị môi trường
 
### 2.1 Đặt hostname cho từng node
 
**Mục đích:** Hostname rõ ràng giúp phân biệt node trong log, Prometheus và Grafana thay vì chỉ hiển thị địa chỉ IP.
 
Chạy lệnh tương ứng trên **từng node**:
```
# edge-01
sudo hostnamectl set-hostname edge-01
sudo sed -i "s/^127.0.1.1.*/127.0.1.1 edge-01/" /etc/hosts

# edge-02
sudo hostnamectl set-hostname edge-02
sudo sed -i "s/^127.0.1.1.*/127.0.1.1 edge-02/" /etc/hosts

# web-01
sudo hostnamectl set-hostname web-01
sudo sed -i "s/^127.0.1.1.*/127.0.1.1 web-01/" /etc/hosts

# web-02
sudo hostnamectl set-hostname web-02
sudo sed -i "s/^127.0.1.1.*/127.0.1.1 web-02/" /etc/hosts

### 2.2 Cập nhật /etc/hosts trên tất cả node
Thêm vào cuối file `/etc/hosts` trên **cả 4 node**:  
```
sudo nano /etc/hosts
```
127.0.0.1       localhost
192.168.136.100      vip
192.168.136.131   edge-01
192.168.136.146   edge-02
192.168.136.145    web-01
192.168.136.134    web-02
```

## 3. SSL Certificate
 
### 3.1 Lý thuyết — SSL Termination
 
Thay vì để mỗi Web Backend tự xử lý HTTPS (tốn CPU), mô hình **SSL Termination** tập trung toàn bộ việc giải mã HTTPS vào HAProxy. Backend Apache chỉ nhận HTTP thuần — giảm tải đáng kể và dễ quản lý certificate.
 
> **Lưu ý quan trọng:** HAProxy yêu cầu file certificate phải là định dạng `.pem` chứa cả Public Certificate và Private Key trong cùng một file theo thứ tự: **cert trước, key sau**.

### 3.2 Tạo Self-signed Certificate — Chỉ trên edge-01

```
sudo mkdir -p /etc/ssl/haproxy

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/ha.key \
  -out /tmp/ha.crt \
  -subj "/C=VN/ST=HaNoi/L=HaNoi/O=Lab/CN=192.168.136.100"

# HAProxy yêu cầu cert + key gộp trong 1 file
sudo bash -c 'cat /tmp/ha.crt /tmp/ha.key > /etc/ssl/haproxy/cert.pem'
sudo chmod 600 /etc/ssl/haproxy/cert.pem

# Kiểm tra
ls -lh /etc/ssl/haproxy/cert.pem
sudo openssl x509 -in /etc/ssl/haproxy/cert.pem -text -noout
```
<img width="491" height="404" alt="{185365E2-BD76-4C55-804F-38854AFDE41A}" src="https://github.com/user-attachments/assets/9a753e70-3a59-492a-8f9f-ab8e83e7f19d" />

### 3.3 Copy certificate sang edge-02

Copy sang edge-02
```
sudo scp /etc/ssl/haproxy/cert.pem backup2@192.168.136.146:/tmp/
# Trên edge-02:
sudo mkdir -p /etc/ssl/haproxy
sudo mv /tmp/cert.pem  /etc/ssl/haproxy/cert.pem 
sudo chmod 600 /etc/ssl/haproxy/cert.pem 
```
<img width="483" height="354" alt="{F6D8E73C-0258-449C-9D53-96EEA9D49374}" src="https://github.com/user-attachments/assets/7867d37f-e57e-4dc7-8c83-b14ea1fa182d" />

## 4. Keepalived — VRRP Failover
### 4.1 Lý thuyết — VRRP hoạt động như thế nào
**VRRP (Virtual Router Redundancy Protocol)** là giao thức mạng Layer 3, hoạt động độc lập với ứng dụng. Cơ chế:
 
- **edge-01 (MASTER, priority 110):** Giữ VIP `192.168.136.100`, broadcast gói VRRP advertisement mỗi 1 giây
- **edge-02 (BACKUP, priority 100):** Lắng nghe. Nếu không nhận được advertisement trong 3 giây → kết luận MASTER đã chết → tự nâng lên MASTER, gửi Gratuitous ARP để thông báo VIP chuyển sang
- **Thời gian failover:** < 3 giây

### 4.2 Cài đặt và cấu hình sysctl — edge-01 và edge-02

* Cài đặt keepalived
```
sudo apt install -y keepalived
sudo nano /etc/sysctl.d/99-haproxy.conf
# Bắt buộc: cho phép bind VIP vào interface
net.ipv4.ip_forward = 1
net.ipv4.ip_nonlocal_bind = 1
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
sudo sysctl -p

# Xác nhận
sysctl net.ipv4.ip_nonlocal_bind
# Phải thấy: net.ipv4.ip_nonlocal_bind = 1
```
<img width="235" height="80" alt="{DBD86E95-9A00-4957-9D67-1FDC30F9E473}" src="https://github.com/user-attachments/assets/680e8a8f-c438-45b8-b4ce-e134cca04229" />

### 4.3 Cấu hình Keepalived — edge-01 (MASTER)

* Cấu hình keepalived
Máy edge-01 nhận trọng trách làm MASTER sở hữu độ ưu tiên (Priority) cao hơn, máy edge-02 đóng vai trò BACKUP. Hai máy liên tục bắt tay nhau qua cổng mạng ens33 với chu kỳ 1 giây.

  * Trên edge-01
sudo nano /etc/keepalived/keepalived.conf
```
global_defs {
    router_id edge-01
    script_user root
    enable_script_security
}
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight  -20
    rise    2
    fall    2
}
vrrp_instance VI_1 {
    state             MASTER
    interface         ens33       
    virtual_router_id 51
    priority          110
    advert_int        1
    preempt_delay     10
    authentication {
        auth_type PASS
        auth_pass HAStack2024
    }
    virtual_ipaddress {
        192.168.136.100/24 dev ens33 label ens33:vip
    }
    track_script { chk_haproxy }
    notify_master "/etc/keepalived/notify.sh MASTER"
    notify_backup "/etc/keepalived/notify.sh BACKUP"
    notify_fault  "/etc/keepalived/notify.sh FAULT"
}
```
<img width="354" height="372" alt="{D80CEE46-F4A4-4545-B881-03B957851011}" src="https://github.com/user-attachments/assets/a0e6d6e5-e3f7-49f8-b105-c81b219736ec" />

### 4.4 Cấu hình Keepalived — edge-02 (BACKUP)
   * Trên edge-02
sudo nano /etc/keepalived/keepalived.conf  
Sửa 3 chỗ  
```
router_id edge-02   
state     BACKUP   
priority  100     
```
<img width="392" height="332" alt="{5F0C0E84-5F20-4A78-88FE-D0CFA8DCE462}" src="https://github.com/user-attachments/assets/2dfc8ab0-9c74-4b71-ac51-f51c9e6bfb3a" />

### 4.5 Notify script — edge-01 và edge-02
Tạo file thông báo cho log dễ đọc
sudo nano /etc/keepalived/notify.sh
```
#!/bin/bash
STATE=$1; HOST=$(hostname); TS=$(date '+%Y-%m-%d %H:%M:%S')
LOG=/var/log/keepalived-notify.log
case $STATE in
  MASTER) echo "[$TS] $HOST → MASTER | VIP 192.168.136.100 GÁN vào máy này" >> $LOG ;;
  BACKUP) echo "[$TS] $HOST → BACKUP | VIP rời đi" >> $LOG ;;
  FAULT)  echo "[$TS] $HOST  FAULT | Restart HAProxy..." >> $LOG
          sudo systemctl restart haproxy ;;
esac
```

<img width="478" height="144" alt="{F0A6A0CA-8509-40AC-8498-463C27010E6A}" src="https://github.com/user-attachments/assets/ac4187b8-a7e0-438a-a688-16b102d6a00b" />

**Kiểm tra:**
```
sudo chmod +x /etc/keepalived/notify.sh
sudo systemctl enable --now keepalived

# Kiểm tra VIP trên edge-01
ip addr show | grep 192.168.136.100

# Theo dõi log
sudo tail -f /var/log/keepalived-notify.log
```
Máy edge-01 Master đã nhận được và giữ VIP  

<img width="591" height="116" alt="{E407B8A0-DCA5-4176-A581-A96E41DAFF23}" src="https://github.com/user-attachments/assets/acd555be-0703-4a2d-829d-aa5f713b8878" />  

Máy edge-02 Backup chưa có VIP  

<img width="529" height="182" alt="{C8EF45EA-3B2C-40DF-AFF4-85D92DAD20E9}" src="https://github.com/user-attachments/assets/75619082-e59d-4116-ae20-5442c54c24d8" />

## 5. HAProxy — Load Balancer
### 5.1 Lý thuyết — HAProxy làm 3 việc
 
1. **SSL Termination:** Nhận HTTPS từ client, giải mã TLS, forward HTTP thuần đến backend
2. **Load Balancing (Round Robin):** Phân phối request đến web-01 và web-02 luân phiên
3. **Health Check:** Cứ 2 giây kiểm tra `/health.html` của từng backend. 3 lần fail liên tiếp (6 giây) → tự loại node ra khỏi pool

### 5.2 Cài đặt và cấu hình — edge-01 và edge-02

sudo apt install -y haproxy  
sudo nano /etc/haproxy/haproxy.cfg
```
global
    log /dev/log local0
    maxconn 50000
    user haproxy
    group haproxy

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client  30s
    timeout server  30s

# Stats page + Prometheus metrics
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin123
    # Prometheus scrape tại /metrics — BẮT BUỘC
    http-request use-service prometheus-exporter if { path /metrics }

# HTTP → HTTPS redirect
frontend http_in
    bind *:80
    redirect scheme https code 301

# HTTPS frontend
frontend https_in
    bind *:443 ssl crt /etc/ssl/haproxy/cert.pem
    option forwardfor
    default_backend web_servers

# Backend — 2 Apache nodes
backend web_servers
    balance roundrobin
    option httpchk GET /health.html
    http-check expect string OK
    server web01 192.168.136.145:80 check inter 2s rise 2 fall 3
    server web02 192.168.136.134:80 check inter 2s rise 2 fall 3
```
**Kiểm tra và khởi động:**
 
```
# Validate cấu hình — phải thấy "Configuration file is valid"
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
 
sudo systemctl enable --now haproxy
sudo systemctl status haproxy
 
# Kiểm tra backend status
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock \
  | cut -d',' -f1,2,18 | grep web_servers
# Kết quả mong đợi:
# web_servers,web01,UP
# web_servers,web02,UP
```
 
> **Truy cập Stats:** `http://192.168.136.131:8404/haproxy-stats` — user `admin` / `Admin@2026!`
 
<img width="417" height="369" alt="{5A42F5D0-D87C-498B-BE3C-4D92C9438894}" src="https://github.com/user-attachments/assets/36129ce3-34eb-4fad-aea2-05e3fd060aba" />

Kể từ các phiên bản HAProxy mới, nhà phát triển đã tích hợp sẵn một endpoint xuất dữ liệu thô chuẩn Prometheus mà không cần phải cài thêm công cụ trung gian (haproxy_exporter). Chúng ta mở riêng một cổng ẩn để máy chủ Prometheus central từ xa có thể kéo các chỉ số (Băng thông, số lượng request/giây, trạng thái các node backend) về lưu trữ.  

```
frontend prometheus_metrics
    bind 0.0.0.0:9101       
    mode http
    http-request use-service promo-services allow if { path /metrics }
    no log
```
## 6. Apache + PHP-FPM
Cài công cụ quản lý, thêm ppa/php, cài Apache + PHP + extensions  
> **Lưu ý bắt buộc:** Ubuntu 22.04 không có PHP 8.1 trong repo mặc định. Phải thêm PPA trước, nếu không `apt` sẽ báo lỗi: `php8.1-fpm has no installation candidate`.
 
```
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

sudo apt install -y apache2 php8.1 php8.1-fpm php8.1-mysql \
  php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml \
  php8.1-zip php8.1-redis php8.1-intl php8.1-bcmath

sudo a2enmod rewrite proxy_fcgi setenvif headers
sudo a2enconf php8.1-fpm
sudo systemctl restart apache2 php8.1-fpm
```
<img width="550" height="218" alt="{F08F56D5-3406-4F47-BEBC-CD56479C786B}" src="https://github.com/user-attachments/assets/3dce133f-dfb1-4e07-890c-af0af5fbc194" />
### 6.2 Cấu hình VirtualHost WordPress — web-01 và web-02

sudo nano /etc/apache2/sites-available/wordpress.conf
```
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.1-fpm.sock|fcgi://localhost"
    </FilesMatch>

    <Directory /var/www/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    RequestHeader set X-Forwarded-Proto "http"
    ErrorLog  ${APACHE_LOG_DIR}/wp_error.log
    CustomLog ${APACHE_LOG_DIR}/wp_access.log combined
</VirtualHost>
```
<img width="453" height="258" alt="{62E485D9-075D-4007-B1B0-951ACC092A27}" src="https://github.com/user-attachments/assets/614e51f9-5c64-4b1d-9f4c-636f4074a4a4" />

```
# Bật site WordPress, TẮT site mặc định 
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
```
### 6.3 Tạo health check endpoint cho HAProxy
```
# Tạo health check cho HAProxy
echo "OK" | sudo tee /var/www/html/health.html
sudo chown www-data:www-data /var/www/html/health.html

# Kiểm tra
curl http://192.168.136.145/health.html   # → OK
curl http://192.168.136.134/health.html   # → OK
```
<img width="416" height="185" alt="{9EC30250-F59E-4FA3-929F-64E6F297DE4D}" src="https://github.com/user-attachments/assets/3292dc6d-2620-44c1-8b82-5a2da2fe7866" />

## 7. MariaDB + Redis
 
### 7.1 MariaDB — Cài đặt trên web-02
 
**Lý do đặt trên web-02:** Tập trung database tại một node. Cả hai web backend đều kết nối remote vào đây.
 
Cài đặt mariadb trên web 02
```
sudo apt install -y mariadb-server
sudo mysql_secure_installation 
```
**Tạo database và user:**
```
sudo  mysql -u root -p

CREATE DATABASE wordpress_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'iamhieu'@'192.168.136.145' IDENTIFIED BY 'Iamhieu@2026';
CREATE USER 'iamhieu'@'192.168.136.134' IDENTIFIED BY 'Iamhieu@2026';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'iamhieu'@'192.168.136.145';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'iamhieu'@'192.168.136.134';
FLUSH PRIVILEGES;
EXIT;
```
**Cho phép kết nối từ xa:**
```
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
```
**Kiểm tra kết nối từ web-01:**
```
# Test từ web-01
sudo apt install -y mariadb-client redis-tools
mysql -u iamhieu -p -h 192.168.136.134 wordpress_db -e "SHOW TABLES;"
```

### 7.2 Redis — Cài đặt trên web-02
**Lý do cần Redis:** Mặc định WordPress lưu session trong RAM/file của từng server. Khi HAProxy route sang node khác, session bị mất → user bị đăng xuất. Redis lưu session tập trung, cả 2 node đều đọc được.

```
sudo apt install -y redis-server
```

**Cấu hình `/etc/redis/redis.conf`:** 

sudo nano /etc/redis/redis.conf 
```
bind 0.0.0.0
protected-mode no
requirepass redis_2026
maxmemory 256mb
maxmemory-policy allkeys-lru
```

**Kiểm tra từ web-01:**

<img width="613" height="56" alt="{D7241FB2-2022-40B2-B7ED-6AC9DFBD1D7C}" src="https://github.com/user-attachments/assets/6c1e891b-bd4a-4dc7-b238-23195a49b9d8" />

---

## 8. WordPress
 
### 8.1 Tải và cài đặt — web-01 và web-02
 
```
cd /var/www/html
# Xóa file mặc định của Apache
sudo rm -f index.html

# Tải WordPress
sudo wget https://wordpress.org/latest.tar.gz
sudo tar xf latest.tar.gz
sudo cp -r wordpress/* .
sudo rm -rf wordpress latest.tar.gz

# Phân quyền
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Đảm bảo health check vẫn còn
echo "OK" | sudo tee /var/www/html/health.html
sudo chown www-data:www-data /var/www/html/health.html
```
### 8.2 Cấu hình wp-config.php — web-01 và web-02

```
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php  
sudo nano /var/www/html/wp-config.php  

<?php

if ( isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
     $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}
// Lấy IP thật của client (qua HAProxy)
if ( isset($_SERVER['HTTP_X_REAL_IP']) ) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_REAL_IP'];
}

// ================================================================
// DATABASE — MariaDB trên web-02 (192.168.136.134)
// ================================================================
define( 'DB_NAME',     'wordpress_db' );
define( 'DB_USER',     'iamhieu' );           // ← user đã tạo trong MariaDB
define( 'DB_PASSWORD', 'Iamhieu@2026' );      // ← password đã đặt
define( 'DB_HOST',     '192.168.136.134' );   // ← MariaDB trên web-02
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  'utf8mb4_unicode_ci' );


define('FORCE_SSL_ADMIN', true);
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

define( 'WP_HOME',    'https://192.168.136.100' );
define( 'WP_SITEURL', 'https://192.168.136.100' );

define( 'WP_REDIS_HOST',         '192.168.136.134' );
define( 'WP_REDIS_PORT',         6379 );
define( 'WP_REDIS_PASSWORD',     'redis_2026' );  
define( 'WP_REDIS_TIMEOUT',      1 );
define( 'WP_REDIS_READ_TIMEOUT', 1 );
define( 'WP_CACHE',              true );

define( 'DISABLE_WP_CRON', true );

define( 'FS_METHOD', 'direct' );

define( 'UPLOADS', 'wp-content/uploads' );

// Lấy từ: https://api.wordpress.org/secret-key/1.1/salt/
// DÁN OUTPUT CỦA curl https://api.wordpress.org/secret-key/1.1/salt/ VÀO ĐÂY
define( 'AUTH_KEY',         'paste-your-unique-phrase-here' );
define( 'SECURE_AUTH_KEY',  'paste-your-unique-phrase-here' );
define( 'LOGGED_IN_KEY',    'paste-your-unique-phrase-here' );
define( 'NONCE_KEY',        'paste-your-unique-phrase-here' );
define( 'AUTH_SALT',        'paste-your-unique-phrase-here' );
define( 'SECURE_AUTH_SALT', 'paste-your-unique-phrase-here' );
define( 'LOGGED_IN_SALT',   'paste-your-unique-phrase-here' );
define( 'NONCE_SALT',       'paste-your-unique-phrase-here' );

$table_prefix = 'wp_';

define( 'WP_DEBUG',         false );
define( 'WP_DEBUG_LOG',     false );
define( 'WP_DEBUG_DISPLAY', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
```
<img width="420" height="160" alt="{31C4A194-B011-4340-9D6E-90A72575FB80}" src="https://github.com/user-attachments/assets/fb9a3c23-32f7-42e5-954e-5c7c6389be72" />

kiểm tra Apache đúng site chưa
```
# Đảm bảo 000-default đã tắt
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

# Kiểm tra site đang active
sudo apache2ctl -S | grep wordpress

# Test PHP hoạt động
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
curl http://192.168.136.145/info.php | grep -i "PHP Version"
sudo rm /var/www/html/info.php   # xóa sau khi test

# Truy cập trình duyệt: https://192.168.136.100
```
<img width="951" height="478" alt="{F117E332-5949-4683-AA91-5264AAD1F01F}" src="https://github.com/user-attachments/assets/a742ceaf-be3f-40d5-8eac-9b9690b367e6" />

## 9. Monitoring: Prometheus + Grafana + Alertmanager
 
### 9.1 Cài đặt node\_exporter — tất cả 4 node
 
```bash
NODE_VER="1.7.0"
cd /tmp
sudo wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VER}/node_exporter-${NODE_VER}.linux-amd64.tar.gz
sudo tar xzf node_exporter-${NODE_VER}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_VER}.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter 2>/dev/null || true
 
sudo tee /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target
 
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
 
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```
 
### 9.2 Cài đặt redis\_exporter và mysqld\_exporter — web-02
 
```bash
# redis_exporter
cd /tmp
sudo wget -q https://github.com/oliver006/redis_exporter/releases/download/v1.58.0/redis_exporter-v1.58.0.linux-amd64.tar.gz
sudo tar xzf redis_exporter-v1.58.0.linux-amd64.tar.gz
sudo cp redis_exporter-v1.58.0.linux-amd64/redis_exporter /usr/local/bin/
 
sudo tee /etc/systemd/system/redis_exporter.service << 'EOF'
[Unit]
Description=Redis Exporter
After=network.target
 
[Service]
ExecStart=/usr/local/bin/redis_exporter \
  --redis.addr=redis://127.0.0.1:6379 \
  --redis.password=redis_2026 \
  --web.listen-address=:9121
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
 
# mysqld_exporter
sudo mysql -u root -p -e "
CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY 'exp_pass2026';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;"
 
sudo bash -c 'printf "[client]\nuser=exporter\npassword=exp_pass2026\n" > /etc/.mysqld_exporter.cnf'
sudo chmod 600 /etc/.mysqld_exporter.cnf
 
cd /tmp
sudo wget -q https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo tar xzf mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo cp mysqld_exporter-0.15.1.linux-amd64/mysqld_exporter /usr/local/bin/
 
sudo tee /etc/systemd/system/mysqld_exporter.service << 'EOF'
[Unit]
Description=MySQL Exporter
After=network.target
 
[Service]
ExecStart=/usr/local/bin/mysqld_exporter \
  --config.my-cnf=/etc/.mysqld_exporter.cnf \
  --web.listen-address=:9104
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
 
sudo systemctl daemon-reload
sudo systemctl enable --now redis_exporter mysqld_exporter
```
 <img width="591" height="469" alt="{755DA620-B696-46DF-A1F0-3B692D036CA4}" src="https://github.com/user-attachments/assets/ac92a224-6ee6-4bf6-a770-f4d89959c2b9" />

<img width="855" height="467" alt="{9BCD94F0-D720-4F4A-9472-4D5FB08B5BF7}" src="https://github.com/user-attachments/assets/934b086a-2cd3-42a4-a7ab-9ae763aff305" />

### 9.3 Cài đặt Prometheus — edge-01 và edge-02
 
```bash
PROM_VER="2.48.1"
cd /tmp
sudo wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
sudo tar xzf prometheus-${PROM_VER}.linux-amd64.tar.gz
sudo cp prometheus-${PROM_VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo useradd -rs /bin/false prometheus 2>/dev/null || true
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```
 
**Cấu hình `/etc/prometheus/prometheus.yml`:**
 
```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s
 
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']
 
rule_files:
  - "/etc/prometheus/alert_rules.yml"
 
scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets:
          - '192.168.136.131:9100'   # edge-01
          - '192.168.136.146:9100'   # edge-02
          - '192.168.136.145:9100'   # web-01
          - '192.168.136.134:9100'   # web-02
 
  - job_name: 'haproxy'
    metrics_path: /metrics
    static_configs:
      - targets:
          - '192.168.136.131:8404'
          - '192.168.136.146:8404'
 
  - job_name: 'redis'
    static_configs:
      - targets: ['192.168.136.134:9121']
 
  - job_name: 'mariadb'
    static_configs:
      - targets: ['192.168.136.134:9104']
```
 <img width="948" height="474" alt="{40A04B32-9729-469C-88EB-7B78F03B7AAF}" src="https://github.com/user-attachments/assets/58ef5e0a-920d-4f90-a3a9-8d46de25a1d9" />

### 9.4 Alert Rules — `/etc/prometheus/alert_rules.yml`
 
```yaml
groups:
  - name: node_alerts
    rules:
      - alert: NodeDown
        expr: up{job="node_exporter"} == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: 'NODE DOWN: {{ $labels.instance }}'
          description: 'Node {{ $labels.instance }} mat ket noi hon 30 giay.'
 
      - alert: HighCPU
        expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: 'CPU CAO: {{ $labels.instance }}'
          description: 'CPU vuot 85%. Hien tai: {{ $value | printf "%.1f" }}%'
 
      - alert: HighMemory
        expr: (1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes) * 100 > 90
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: 'RAM THAP: {{ $labels.instance }}'
          description: 'RAM con trong duoi 10%.'
 
      - alert: DiskFull
        expr: |
          (1 - node_filesystem_avail_bytes{
            job="node_exporter",
            fstype!~"tmpfs|overlay|squashfs|devtmpfs",
            mountpoint!~"/boot/efi|/run/.*"
          } / node_filesystem_size_bytes{
            job="node_exporter",
            fstype!~"tmpfs|overlay|squashfs|devtmpfs",
            mountpoint!~"/boot/efi|/run/.*"
          }) * 100 > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: 'DISK DAY: {{ $labels.instance }}'
          description: 'Disk {{ $labels.mountpoint }} su dung {{ $value | printf "%.1f" }}%.'
 
  - name: haproxy_alerts
    rules:
      - alert: HAProxyBackendDown
        expr: haproxy_backend_up{job="haproxy"} == 0
        for: 10s
        labels:
          severity: critical
        annotations:
          summary: 'HAPROXY BACKEND DOWN: {{ $labels.backend }}'
          description: 'Backend {{ $labels.backend }} bi DOWN tren HAProxy.'
 
inhibit_rules:
  - source_match:
      alertname: NodeDown
    target_match_re:
      alertname: 'HighCPU|HighMemory|DiskFull'
    equal: ['instance']
```
 <img width="959" height="429" alt="{8C1AF128-7C6B-4D98-82B7-C6296C50CFE5}" src="https://github.com/user-attachments/assets/6370c1c9-42fd-4d8a-881e-2f70e3e39df5" />
<img width="940" height="438" alt="{E9389CAA-93AC-44C4-8497-785D87A31204}" src="https://github.com/user-attachments/assets/d0db0f97-2532-4fd2-949b-0a6d66c2c5b9" />

### 9.5 Cài đặt Grafana — edge-01 và edge-02
 
```bash
wget -q -O - https://packages.grafana.com/gpg.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```
 
**Dashboard Import:**
 
| Dashboard ID | Tên | Nội dung |
|---|---|---|
| `1860` | Node Exporter Full | CPU · RAM · Disk · Network |
| `367` | HAProxy 2 Full | Request rate · Backend status |
| `763` | Redis Dashboard | Memory · Hit rate · Commands/s |
| `7362` | MySQL Overview | Queries · Connections · InnoDB |

<img width="960" height="436" alt="image" src="https://github.com/user-attachments/assets/c9f5f6f6-9d31-4e6e-b79d-d74209529f84" />

---
 
## 10. Kết quả kiểm tra
 
### 10.1 Kiểm tra toàn bộ dịch vụ
 
```bash
# Chạy trên edge-01
for svc in haproxy keepalived prometheus grafana-server alertmanager node_exporter; do
  STATUS=$(systemctl is-active $svc 2>/dev/null || echo "not-found")
  printf "%-20s %s\n" "$svc" "$STATUS"
done
```
 
### 10.2 Test Load Balancing — roundrobin
 
```bash
# Gửi 6 request liên tiếp — phải thấy xen kẽ web-01 / web-02
for i in {1..6}; do
  curl -sk https://192.168.136.100/health.html -o /dev/null \
    -w "Request $i → HTTP %{http_code}\n"
done
```
 
### 10.3 Test Keepalived Failover
 
```bash
# Bước 1: Xác nhận VIP trên edge-01
ip addr show | grep 192.168.136.100
 
# Bước 2: Giả lập sự cố — tắt Keepalived trên edge-01
sudo systemctl stop keepalived
 
# Bước 3: Chờ 3 giây, kiểm tra edge-02 đã tiếp quản VIP chưa
sleep 3
# (Chạy trên edge-02)
ip addr show | grep 192.168.136.100
# Kết quả mong đợi: inet 192.168.136.100/24 scope global ens33:vip
 
# Bước 4: Website vẫn online
curl -sk https://192.168.136.100/health.html
# Kết quả mong đợi: OK
 
# Bước 5: Khôi phục
sudo systemctl start keepalived    # Trên edge-01
```
 
### 10.4 Test Alert Gmail
 
```bash
# Tắt node_exporter trên web-01 để trigger NodeDown alert
sudo systemctl stop node_exporter    # Trên web-01
 
# Theo dõi trên Prometheus (edge-01)
# T+30s: NodeDown → PENDING
# T+60s: NodeDown → FIRING → Alertmanager gửi email
# → Kiểm tra hộp thư Gmail
 
# Bật lại → nhận email RESOLVED (~90 giây sau)
sudo systemctl start node_exporter
```
 
---
 
## 11. Lỗi gặp phải và cách khắc phục
 
| STT | Lỗi | Nguyên nhân | Cách khắc phục |
|-----|-----|-------------|----------------|
| 1 | `php8.1-fpm has no installation candidate` | Ubuntu 22.04 không có PHP 8.1 trong repo mặc định | Thêm PPA `ppa:ondrej/php` trước khi cài |
| 2 | `HAProxy: unable to stat SSL certificate` | Quên tạo file `cert.pem` trước khi khởi động HAProxy | Tạo cert và ghép `cat ha.crt ha.key > cert.pem` |
| 3 | Vào IP vẫn thấy trang Apache mặc định | `000-default.conf` vẫn bật / file `index.html` còn tồn tại | `sudo a2dissite 000-default.conf && sudo rm -f /var/www/html/index.html` |
| 4 | VIP không xuất hiện sau khi cài Keepalived | `ip_nonlocal_bind = 0` — Keepalived không bind được VIP | `echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf && sysctl -p` |
| 5 | Prometheus scrape HAProxy bị `503` | HAProxy không có `/metrics` endpoint theo mặc định | Thêm `http-request use-service prometheus-exporter if { path /metrics }` vào `listen stats` |
| 6 | `NodeDown` alert bắn cho `job="haproxy"` (không phải node thật) | Rule `up == 0` bắt tất cả jobs | Sửa thành `up{job="node_exporter"} == 0` |
| 7 | Không nhận email RESOLVED | `resolve_timeout: 5m` quá dài, thiếu `instance` trong `group_by` | Đặt `resolve_timeout: 1m`, thêm `instance` vào `group_by` |
| 8 | `DiskFull` không fire dù disk đầy | `fstype!="tmpfs"` bỏ sót `overlay`, `squashfs`, `devtmpfs` | Dùng regex: `fstype!~"tmpfs\|overlay\|squashfs\|devtmpfs"` |
 
---
 
## 12. Kết luận và bài học rút ra
 
### 12.1 Kết quả đạt được
 
| Tiêu chí | Kết quả |
|---|---|
| Thời gian failover Keepalived | < 3 giây |
| Uptime website khi 1 backend down | 100% (HAProxy tự route) |
| Cảnh báo sự cố đến Gmail | < 90 giây sau khi phát sinh |
| Dashboard Grafana hoạt động | ✅ 4 dashboard (node/HAProxy/Redis/MySQL) |
| Load balancing roundrobin | ✅ Phân phối đều 50/50 |
 
### 12.2 Bài học rút ra
 
**Về kỹ thuật:**
 
- `ip_nonlocal_bind = 1` là điều kiện tiên quyết để Keepalived bind VIP — không có dòng này, Keepalived chạy nhưng VIP không xuất hiện
- HAProxy cần file `.pem` = cert + key gộp lại theo đúng thứ tự (cert trước, key sau)
- WordPress sau reverse proxy HTTPS bắt buộc phải xử lý header `X-Forwarded-Proto`, thiếu sẽ gây redirect loop
- `fstype!~"regex"` quan trọng hơn `fstype!="string"` khi viết PromQL cho DiskFull
**Về quy trình:**
 
- Nên setup và test từng lớp độc lập trước khi ghép: LB layer → Web layer → DB layer → Monitoring layer
- Document lại từng lỗi gặp phải ngay khi sửa xong — 1 tuần sau sẽ không còn nhớ
- Chủ động test fail case (tắt từng service) thay vì chỉ test khi mọi thứ đang chạy
**Định hướng mở rộng:**
 
- **Scale backend:** Thêm web-03 chỉ cần 1 dòng trong `haproxy.cfg`, HAProxy reload không cần restart
- **Database HA:** MariaDB Galera Cluster (3 node đồng bộ realtime) để loại bỏ điểm chết duy nhất tại DB
- **Redis HA:** Redis Sentinel hoặc Redis Cluster cho session store
---
 
*Báo cáo hoàn thành ngày 20/05/2026 · Nguyễn Thanh Hiếu
