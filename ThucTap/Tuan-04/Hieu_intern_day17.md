# Báo cáo học tập - Hệ thống HA Web
*Keepalived · HAProxy · Apache · WordPress · MariaDB · Redis · Prometheus · Grafana · Alertmanager*

---

## Tổng quan

#### Sơ đồ kiến trúc hệ thống
<img width="3484" height="3564" alt="image" src="https://github.com/user-attachments/assets/9d265c4b-78d5-43fd-942e-fc10eddd3573" />


#### Bảng IP và dịch vụ

Node	| IP	| Role	| Dịch vụ chính
-- | -- | -- | --
VIP |	192.168.136.100 |	Virtual IP |	VRRP :80 :443 :8404
edge-01 |	192.168.136.131 |	MASTER LB |	HAProxy · Keepalived · Prometheus · Grafana · Alertmanager
edge-02 |	192.168.136.140	 | BACKUP LB |	HAProxy · Keepalived · Prometheus · Grafana · Alertmanager
web-01 |	192.168.136.145 |	Backend 1 |	Apache2 · PHP-FPM · WordPress · node_exporter
web-02  |	192.168.136.134	| Backend 2 + DB |	Apache2 · MariaDB · Redis · node_exporter · redis_exp · mysqld_exp 

#### Yêu cầu hệ thống

Hệ thống được triển khai trên môi trường máy ảo sử dụng hệ điều hành Ubuntu Server 22.04 LTS nhằm xây dựng mô hình Web Cluster kết hợp Load Balancing, High Availability và Monitoring.  

Cấu hình phần cứng tối thiểu  
Thành phần  |	Yêu cầu
---|---
Số lượng máy ảo	 | 05 VM
Hệ điều hành |	Ubuntu Server 22.04 LTS
CPU	Tối thiểu | 1 vCPU / node
RAM	 | ≥ 1 GB RAM / node
RAM cho Web Server phụ (web-02) |	≥ 2 GB RAM
Dung lượng đĩa |	≥ 20 GB / node
Kiểu card mạng |	NAT hoặc Host-only
Dải mạng nội bộ |	192.168.136.0/24
Kết nối Internet |	Bắt buộc để sử dụng apt, wget, tải package và cập nhật hệ thống

Mục tiêu triển khai 
Hệ thống hỗ trợ cân bằng tải giữa nhiều Web Server.  
Hỗ trợ tự động chuyển đổi dự phòng (failover) khi HAProxy Master gặp sự cố.  
Dữ liệu WordPress được đồng bộ giữa các node thông qua Shared Storage/NFS.  
Hệ thống Monitoring giám sát:  
  * CPU  
  * RAM  
  * Disk  
  * Trạng thái HAProxy 
  * Trạng thái Database  
  * Trạng thái Web Server  
Hỗ trợ gửi cảnh báo email khi xảy ra sự cố hệ thống.  

### Thực hành 
#### 1. Đặt hostname + /etc/hosts (tất cả node)
Đặt hostname giúp phân biệt node rõ ràng trong log, Prometheus, và Grafana. Mỗi node chạy lệnh tương ứng  
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

```
sudo nano /etc/hosts
```
127.0.0.1       localhost
192.168.136.100      vip
192.168.136.131   edge-01
192.168.136.140   edge-02
192.168.136.145    web-01
192.168.136.134    web-02
```

#### 2. SSL Certificate (edge-01 & edge-02)
Mục đích để tối ưu hóa hiệu năng cho các máy chủ Web Backend (web-01, web-02), chúng ta áp dụng mô hình SSL Termination. Toàn bộ nhiệm vụ giải mã mã hóa HTTPS phức tạp sẽ được xử lý tập trung một lần duy nhất tại HAProxy. HAProxy yêu cầu file chứng chỉ phải được gộp chung (chứa cả mã Public Cert và Private Key) vào thành một file định dạng .pem.
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

Copy sang edge-02
```
sudo scp /etc/ssl/haproxy/cert.pem backup2@192.168.136.146:/tmp/
# Trên edge-02:
sudo mkdir -p /etc/ssl/haproxy
sudo mv /tmp/cert.pem  /etc/ssl/haproxy/cert.pem 
sudo chmod 600 /etc/ssl/haproxy/cert.pem 
```
<img width="483" height="354" alt="{F6D8E73C-0258-449C-9D53-96EEA9D49374}" src="https://github.com/user-attachments/assets/7867d37f-e57e-4dc7-8c83-b14ea1fa182d" />

#### 3. Keepalived (edge-01 MASTER + edge-02 BACKUP)

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

   * Trên edge-02
sudo nano /etc/keepalived/keepalived.conf  
Sửa 3 chỗ  
```
router_id edge-02   
state     BACKUP   
priority  100     
```
<img width="392" height="332" alt="{5F0C0E84-5F20-4A78-88FE-D0CFA8DCE462}" src="https://github.com/user-attachments/assets/2dfc8ab0-9c74-4b71-ac51-f51c9e6bfb3a" />

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

Gán quyền và reset, kiểm tra  
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

#### 4. HAProxy (edge-01 & edge-02)
Cấu hình này giúp HAProxy lắng nghe mọi yêu cầu HTTP (port 80) và HTTPS (port 443) đi vào IP ảo, tự động điều hướng traffic (Load Balancing) theo thuật toán Round Robin đến 2 máy chủ Backend (web-01, web-02). Ngoài ra, nó cũng kích hoạt trang Dashboard theo dõi trực quan và mở cổng xuất dữ liệu (Metrics) cho hệ thống Prometheus giám sát.  

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
<img width="417" height="369" alt="{5A42F5D0-D87C-498B-BE3C-4D92C9438894}" src="https://github.com/user-attachments/assets/36129ce3-34eb-4fad-aea2-05e3fd060aba" />
Kể từ các phiên bản HAProxy mới, nhà phát triển đã tích hợp sẵn một endpoint xuất dữ liệu thô chuẩn Prometheus mà không cần phải cài thêm công cụ trung gian (haproxy_exporter). Chúng ta mở riêng một cổng ẩn để máy chủ Prometheus central từ xa có thể kéo các chỉ số (Băng thông, số lượng request/giây, trạng thái các node backend) về lưu trữ. 
```
frontend prometheus_metrics
    bind 0.0.0.0:9101       
    mode http
    http-request use-service promo-services allow if { path /metrics }
    no log
```
#### 5. Apache + PHP (web-01 & web-02)
Cài công cụ quản lý, thêm ppa/php, cài Apache + PHP + extensions
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

# Tạo health check cho HAProxy
echo "OK" | sudo tee /var/www/html/health.html
sudo chown www-data:www-data /var/www/html/health.html

# Kiểm tra
curl http://192.168.136.145/health.html   # → OK
curl http://192.168.136.134/health.html   # → OK
```
<img width="416" height="185" alt="{9EC30250-F59E-4FA3-929F-64E6F297DE4D}" src="https://github.com/user-attachments/assets/3292dc6d-2620-44c1-8b82-5a2da2fe7866" />

#### 6. MariaDB + Redis (web-02)
Cài đặt mariadb trên web 02
```
sudo apt install -y mariadb-server
sudo mysql_secure_installation 
```

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
Cho phép kết nối từ xa
```
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb

# Test từ web-01
sudo apt install -y mariadb-client redis-tools
mysql -u iamhieu -p -h 192.168.136.134 wordpress_db -e "SHOW TABLES;"
```

Cài đặt Redis trên web 02
```
sudo apt install -y redis-server

```
sudo nano /etc/redis/redis.conf
```
bind 0.0.0.0
protected-mode no
requirepass redis_2026
maxmemory 256mb
maxmemory-policy allkeys-lru
```
Test từ web-01
<img width="613" height="56" alt="{D7241FB2-2022-40B2-B7ED-6AC9DFBD1D7C}" src="https://github.com/user-attachments/assets/6c1e891b-bd4a-4dc7-b238-23195a49b9d8" />

7. WordPress (web-01 & web-02)
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

```
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php  
sudo nano /var/www/html/wp-config.php  
```
define( 'DB_NAME',     'wordpress_db' );
define( 'DB_USER',     'wp_user' );
define( 'DB_PASSWORD', 'StrongPass@2024' );
define( 'DB_HOST',     '192.168.136.134' );   // MariaDB trên web-02
define( 'DB_CHARSET',  'utf8mb4' );

// Thêm vào sau dòng DB_HOST để dùng Redis session
define( 'WP_REDIS_HOST',     '192.168.136.134' );
define( 'WP_REDIS_PORT',     6379 );
define( 'WP_REDIS_PASSWORD', 'redis_secret_2024' );
define( 'WP_CACHE',          true );
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

#### 8. Prometheus + Alertmanager + Grafana
* Cài prometheus
Prometheus Server sẽ chạy ngầm, đóng vai trò lưu trữ dữ liệu chuỗi thời gian và liên tục tính toán các biểu thức biểu đồ (PromQL). Nếu một biểu thức vượt ngưỡng an toàn (ví dụ CPU > 85%), nó sẽ tự động kích hoạt trạng thái báo động và bắn dữ liệu sang Alertmanager
```
sudo useradd --no-create-home --shell /bin/false prometheus 2>/dev/null
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

cd /tmp
sudo wget https://github.com/prometheus/prometheus/releases/download/v3.11.2/prometheus-3.11.2.linux-amd64.tar.gz
sudo tar xf prometheus-3.11.2.linux-amd64.tar.gz
cd prometheus-3.11.2.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus
```
Tạo service:
sudo nano /etc/systemd/system/prometheus.service
```
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple

ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=15d \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```
<img width="340" height="293" alt="{FC67F455-85B5-4697-A283-72CA4AB29101}" src="https://github.com/user-attachments/assets/9f203b75-0776-44f7-a31a-a050a3c2a63b" />

Tạo config Prometheus:
Cấu hình này giúp Prometheus biết phải đi đâu để kéo các chỉ số từ lớp Edge và lớp Backend về
sudo nano /etc/prometheus/prometheus.yml

```
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'localhost:9093'

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:

  - job_name: 'node_exporter'
    static_configs:
      - targets:
          - '192.168.136.131:9100'
          - '192.168.136.146:9100'
          - '192.168.136.145:9100'
          - '192.168.136.134:9100'

  - job_name: 'haproxy'
    metrics_path: /metrics
    static_configs:
      - targets:
          - '192.168.136.131:8404'
          - '192.168.136.140:8404'

  - job_name: 'redis'
    static_configs:
      - targets:
          - '192.168.136.134:9121'

  - job_name: 'mariadb'
    static_configs:
      - targets:
          - '192.168.136.134:9104'
```
Check config:
````
promtool check config /etc/prometheus/prometheus.yml
````
start service:
````
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
````
Test: 
```
curl http://localhost:9090/-/ready
```
<img width="318" height="41" alt="{EAB3BFA8-FCA5-4110-A6D7-C2280BFC7564}" src="https://github.com/user-attachments/assets/0572f161-6ccd-443f-9bbf-dc3147a89700" />
<img width="959" height="471" alt="{DBB6A716-B07E-4533-AD14-5CFB4A3C811C}" src="https://github.com/user-attachments/assets/91334f79-fb35-488a-b97d-a8472cc370d2" />

Cài Alermanager
Khi Prometheus phát hiện lỗi, nó sẽ đẩy hàng loạt cảnh báo thô sang đây. Alertmanager có nhiệm vụ làm bộ điều phối và lọc nhiễu cảnh báo

```
sudo useradd --no-create-home --shell /bin/false alertmanager 2>/dev/null
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo chown alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

cd /tmp
sudo wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
sudo tar xf alertmanager-0.26.0.linux-amd64.tar.gz
cd alertmanager-0.26.0.linux-amd64
sudo cp alertmanager amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool
```
sudo nano /etc/systemd/system/alertmanager.service
```
[Unit]
Description=Alertmanager
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --web.listen-address=0.0.0.0:9093
Restart=always

[Install]
WantedBy=multi-user.target
```
<img width="955" height="476" alt="{EF3B76E0-6831-4BF4-A3B1-AD67E014DAA9}" src="https://github.com/user-attachments/assets/f5b91824-0409-429b-a41a-b40a5f631ba6" />
Cài Alert_rules
sudo nano /etc/prometheus/alert_rules.yml
```
groups:
  - name: node_alerts
    rules:
      - alert: NodeDown
        expr: up == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: '🔴 NODE DOWN: {{ $labels.instance }}'
          description: 'Node {{ $labels.instance }} mất kết nối hơn 30 giây.'

      - alert: HighCPU
        expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: '⚠️ CPU CAO: {{ $labels.instance }}'
          description: 'CPU vượt 85% liên tục 5 phút. Hiện tại: {{ printf "%.1f" $value }}%'

      - alert: HighMemory
        expr: (1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes) * 100 > 90
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: '⚠️ RAM THẤP: {{ $labels.instance }}'
          description: 'RAM còn trống dưới 10%.'

      - alert: DiskFull
        expr: (1 - node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: '💾 DISK ĐẦY: {{ $labels.instance }}'
          description: 'Disk đã dùng {{ printf "%.1f" $value }}%.'

  - name: haproxy_alerts
    rules:
      - alert: HAProxyBackendDown
        expr: haproxy_backend_up == 0
        for: 10s
        labels:
          severity: critical
        annotations:
          summary: '🔴 HAPROXY BACKEND DOWN: {{ $labels.backend }}'
          description: 'Backend {{ $labels.backend }} trên HAProxy bị DOWN.'
```
Check và reload cấu hình 
```
sudo promtool check rules /etc/prometheus/alert_rules.yml
sudo promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload
```
<img width="959" height="478" alt="{FCC628AA-8D1E-42A9-B690-E296670EA79C}" src="https://github.com/user-attachments/assets/e8fb2684-de89-4fbd-b23c-3f37068fa6a7" />

Cài đặt báo về gmail  
Thiết lập cấu hình tích hợp hệ thống thư điện tử SMTP của Google. Khi Alertmanager nhận được cảnh báo thuộc nhóm critical, nó sẽ ngay lập tức đăng nhập vào hệ thống mail và bắn thông báo khẩn cấp cho người quản trị
sudo nano /etc/alertmanager/alertmanager.yml

```
global:
  smtp_smarthost:     'smtp.gmail.com:587'
  smtp_from:          'monitoring-system@gmail.com'
  smtp_auth_username: 'tai-khoan-cua-ban@gmail.com'
  smtp_auth_password: 'zmvigdkenyuuuyon'
  smtp_require_tls:   true
  smtp_hello:         'localhost'
  resolve_timeout:    5m

route:
  group_by:        ['alertname', 'severity']
  group_wait:      10s
  group_interval:  5m
  repeat_interval: 2h
  receiver: 'gmail'
  routes:
    - match:
        severity: critical
      receiver: 'gmail_critical'
      group_wait: 5s
      repeat_interval: 30m

receivers:
  - name: 'gmail'
    email_configs:
      - to:            'admin-quan-tri@gmail.com'
        send_resolved: true
        send_resolved: true
        headers:
          Subject: >-
            {{ if eq .Status "firing" }}⚠️ FIRING{{ else }}✅ RESOLVED{{ end }}
            [{{ .GroupLabels.alertname }}] {{ .CommonLabels.instance }}
        html: |
          <h3>{{ if eq .Status "firing" }}🔴 CẢNH BÁO{{ else }}✅ ĐÃ GIẢI QUYẾT{{ end }}</h3>
          {{ range .Alerts }}
          <b>Alert:</b> {{ .Annotations.summary }}<br>
          <b>Chi tiết:</b> {{ .Annotations.description }}<br>
          <b>Node:</b> {{ .Labels.instance }}<br>
          <b>Mức độ:</b> {{ .Labels.severity }}<br>
          <b>Thời gian:</b> {{ .StartsAt.Format "2006-01-02 15:04:05" }}<br><hr>
          {{ end }}
          <a href="http://192.168.136.131:3000">📊 Grafana Dashboard</a> &nbsp;|&nbsp;
          <a href="http://192.168.136.131:9090/alerts">📡 Prometheus Alerts</a>

  - name: 'gmail_critical'
    email_configs:
      - to:            'admin-quan-tri@gmail.com'
        send_resolved: true
        headers:
          Subject: >-
            🚨 CRITICAL [{{ .GroupLabels.alertname }}] {{ .CommonLabels.instance }}
        html: |
          <h2 style="color:red">🚨 SỰ CỐ NGHIÊM TRỌNG</h2>
          {{ range .Alerts }}
          <p><b>{{ .Annotations.summary }}</b><br>
          {{ .Annotations.description }}<br>
          Node: <code>{{ .Labels.instance }}</code><br>
          Lúc: {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
          {{ end }}
          <a href="http://192.168.136.131:3000">Grafana</a> |
          <a href="http://192.168.136.131:9090/alerts">Prometheus</a>

inhibit_rules:
  - source_match:
      alertname: NodeDown
    target_match_re:
      alertname: 'HighCPU|HighMemory|DiskFull'
    equal: ['instance']
```
Cài Grafana
```
cd /tmp
sudo wget https://dl.grafana.com/oss/release/grafana_13.0.1_amd64.deb
sudo dpkg -i grafana_13.0.1_amd64.deb
sudo apt-get install -f -y
sudo systemctl enable --now grafana-server
# Grafana: http://192.168.136.131:3000  (admin / admin)
```

* Thêm Datasource
  * Connections → Data Sources → Add → Prometheus
* Prometheus URL
 * http://localhost:9090 → Save & Test 
* Import dashboard
 * Dashboards → Import → nhập ID → Load → Import

<img width="960" height="469" alt="{5EAF2C90-981C-4713-A720-F9A998FCA463}" src="https://github.com/user-attachments/assets/247b8fdf-1807-4b8a-be63-5f9860475e98" />

node_exporter (tất cả 4 node)
Nhằm mục đích nắm bắt được tình trạng sức khỏe phần cứng (Tỷ lệ tải CPU, dung lượng RAM còn trống, tốc độ đọc ghi ổ đĩa, băng thông card mạng ens33) của chính các máy chủ Edge để đẩy về Grafana vẽ biểu đồ.  
```
sudo useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null
cd /tmp
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz
sudo tar xf node_exporter-1.11.1.linux-amd64.tar.gz
sudo cp node_exporter-1.11.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```
sudo nano /etc/systemd/system/node_exporter.service 
```
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100
Restart=always
[Install]
WantedBy=multi-user.target
```
Reload và check
```
sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter
curl -s http://192.168.136.145:9100/metrics | head
```
 <img width="832" height="484" alt="{2D10D2EC-B156-4DF7-8106-126F3D603990}" src="https://github.com/user-attachments/assets/0ec171a1-68d5-4f9a-924f-7b4a585ab6f5" />

redis_exporter + mysqld_exporter (web-02)
 * redis_exporter
Do hệ thống HA Web chạy WordPress cần dùng Redis làm Object Cache để giảm tải cho Database. Chúng ta cài đặt công cụ này để thu thập tỷ lệ trúng cache (keyspace_hits vs keyspace_misses), lượng RAM tiêu thụ của Redis xem có bị phình to quá mức gây crash hệ thống không.  
````
cd /tmp
sudo wget https://github.com/oliver006/redis_exporter/releases/download/v1.83.0/redis_exporter-v1.83.0.linux-amd64.tar.gz
sudo tar xf redis_exporter-v1.83.0.linux-amd64.tar.gz
sudo cp redis_exporter-v1.83.0.linux-amd64/redis_exporter /usr/local/bin/
````
sudo nano /etc/systemd/system/redis_exporter.service
````
[Unit]
Description=Redis Exporter
After=network.target
[Service]
ExecStart=/usr/local/bin/redis_exporter --redis.addr=redis://127.0.0.1:6379 --redis.password=redis_2026 --web.listen-address=:9121
Restart=always
[Install]
WantedBy=multi-user.target
````
Check
```
curl -s http://localhost:9121/metrics | grep redis_up
```
<img width="561" height="475" alt="{B260BB1D-FC3A-4987-B76D-710E515BB347}" src="https://github.com/user-attachments/assets/19c8b498-5eea-40e3-8788-6c942bc6f7eb" />

 * mysqld_exporter
````
sudo wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.19.0/mysqld_exporter-0.19.0.linux-amd64.tar.gz
sudo tar xf mysqld_exporter-0.19.0.linux-amd64.tar.gz
sudo cp mysqld_exporter-0.19.0.linux-amd64/mysqld_exporter /usr/local/bin/
````
````
sudo mysql -u root -p -e "
CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY 'exp_pass';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;"

sudo bash -c 'printf "[client]
user=exporter
password=exp_pass
" > /etc/.mysqld_exporter.cnf'
sudo chmod 600 /etc/.mysqld_exporter.cnf
````

sudo nano /etc/systemd/system/mysqld_exporter.service 
````
[Unit]
Description=MySQL Exporter
After=network.target
[Service]
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/.mysqld_exporter.cnf --web.listen-address=:9104
Restart=always
[Install]
WantedBy=multi-user.target
````
sudo systemctl daemon-reload  
sudo systemctl enable --now redis_exporter mysqld_exporter       
Check
```
curl -s http://localhost:9104/metrics | grep mysql_up
```
<img width="759" height="466" alt="{3E93B90E-BE93-41F1-86FB-D1438BF2E71B}" src="https://github.com/user-attachments/assets/4655e8f9-992e-468a-957a-1e19cdcc5fc6" />
