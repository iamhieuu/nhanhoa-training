# Báo Cáo Học Tập — Hệ Thống High Availability Web

*Keepalived · HAProxy · Apache · WordPress · MariaDB Galera · Redis Sentinel · Prometheus · Grafana · Alertmanager*

---

| Thông tin | Chi tiết |
|---|---|
| **Họ và tên** | Nguyễn Thanh Hiếu |
| **Ngày thực hiện** | 20/05/2026 — Cập nhật 30/05/2026 |
| **Tuần thực tập** | Tuần 4 — Ngày 17 |
| **Đơn vị thực tập** | Nhân Hòa |
| **Người hướng dẫn** | Vũ Trường An |
| **Chủ đề** | Xây dựng hệ thống HA Web không còn Single Point of Failure: HAProxy · Keepalived · Apache · WordPress · MariaDB Galera Cluster · Redis Sentinel · Prometheus · Grafana · Alertmanager |

---

## Mục Lục

1. [Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
2. [Chuẩn Bị Môi Trường](#2-chuẩn-bị-môi-trường)
3. [SSL Certificate](#3-ssl-certificate)
4. [Keepalived — VRRP Failover](#4-keepalived--vrrp-failover)
5. [HAProxy — Load Balancer](#5-haproxy--load-balancer)
6. [Apache + PHP-FPM](#6-apache--php-fpm)
7. [MariaDB Galera Cluster](#7-mariadb-galera-cluster)
8. [Redis Sentinel](#8-redis-sentinel)
9. [WordPress](#9-wordpress)
10. [Monitoring: Prometheus + Grafana + Alertmanager](#10-monitoring-prometheus--grafana--alertmanager)
11. [Kết Quả Kiểm Tra & Failover Test](#11-kết-quả-kiểm-tra--failover-test)
12. [Lỗi Gặp Phải và Cách Khắc Phục](#12-lỗi-gặp-phải-và-cách-khắc-phục)
13. [Kết Luận và Bài Học Rút Ra](#13-kết-luận-và-bài-học-rút-ra)

---

## 1. Tổng Quan Hệ Thống

### 1.1 Mục Tiêu

Xây dựng hệ thống web có tính sẵn sàng cao (High Availability) nhằm **loại bỏ hoàn toàn Single Point of Failure** ở tất cả các tầng. Hệ thống tự động xử lý mọi sự cố mà không cần can thiệp thủ công.

**Các yêu cầu cụ thể:**

- Cân bằng tải (Load Balancing) giữa nhiều web server thông qua HAProxy
- Tự động failover Load Balancer trong vòng **< 3 giây** (Keepalived VRRP)
- Database HA với **MariaDB Galera Cluster** — bất kỳ node DB nào cũng accept read/write
- Session store HA với **Redis Sentinel** — tự động bầu chọn Master mới khi node DB chết
- Hệ thống giám sát realtime (Prometheus + Grafana) theo dõi toàn bộ stack
- Cảnh báo tự động qua Gmail khi phát hiện sự cố trong vòng **< 90 giây**

### 1.2 Kiến Trúc Hệ Thống

<img width="4180" height="3748" alt="image" src="https://github.com/user-attachments/assets/28cb5dae-edd0-43da-92d4-376179dfb561" />

### 1.3 Bảng Địa Chỉ IP và Dịch Vụ

| Node | IP | Vai trò | Dịch vụ chính |
|---|---|---|---|
| VIP-HTTP | 192.168.136.100 | Virtual IP Web | VRRP · :80 · :443 · :8404 |
| VIP-MySQL | 192.168.136.101 | Virtual IP Database | VRRP · :3306 |
| edge-01 | 192.168.136.131 | LB MASTER | HAProxy · Keepalived · Prometheus · Grafana · Alertmanager · garbd · node\_exporter |
| edge-02 | 192.168.136.146 | LB BACKUP | HAProxy · Keepalived · Prometheus · Grafana · Alertmanager · node\_exporter |
| web-01 | 192.168.136.145 | Backend 1 + DB | Apache2 · PHP-FPM · WordPress · MariaDB · Redis(Slave) · Redis Sentinel · node\_exporter · redis\_exporter · mysqld\_exporter |
| web-02 | 192.168.136.134 | Backend 2 + DB | Apache2 · PHP-FPM · WordPress · MariaDB · Redis(Master) · Redis Sentinel · node\_exporter · redis\_exporter · mysqld\_exporter |

### 1.4 Bảng Phiên Bản Phần Mềm

| Phần mềm | Phiên bản | Ghi chú |
|---|---|---|
| Ubuntu Server | 22.04.5 LTS |  |
| MariaDB | 10.11.x | LTS, hỗ trợ đến 2028 |
| Galera | 26.4.x | Đi kèm MariaDB 10.11 |
| galera-arbitrator-4 | 26.4.x | khớp version với DB node |
| Redis | 7.0.x | Ubuntu 22.04 default repo |
| HAProxy | 2.4.x | Ubuntu 22.04 default repo |
| Keepalived | 2.2.x | Ubuntu 22.04 default repo |
| Prometheus | 2.52.x | Latest stable |
| Grafana | 11.x | Latest stable |
| node\_exporter | 1.7.0 | — |

### 1.5 Yêu Cầu Phần Cứng

| Thành phần | Yêu cầu |
|---|---|
| Số lượng máy ảo | 4 VM |
| Hệ điều hành | Ubuntu Server 22.04 LTS |
| CPU | ≥ 1 vCPU / node |
| RAM (edge-01, edge-02, web-01) | ≥ 1 GB |
| RAM (web-02 — DB Master + Redis Master) | ≥ 2 GB |
| Dung lượng đĩa | ≥ 20 GB / node |
| Card mạng | NAT hoặc Host-only · subnet 192.168.136.0/24 |
| Kết nối Internet | Bắt buộc (apt, wget, tải package) |

---

## 2. Chuẩn Bị Môi Trường

### 2.1 Đặt Hostname cho Từng Node

**Mục đích:** Hostname rõ ràng giúp phân biệt node trong log, Prometheus và Grafana.

```bash
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

### 2.2 Cập Nhật /etc/hosts — Tất Cả 4 Node

```bash
sudo tee -a /etc/hosts << 'EOF'

# HA Stack nodes
192.168.136.100   vip
192.168.136.101   vip-mysql
192.168.136.131   edge-01
192.168.136.146   edge-02
192.168.136.145   web-01
192.168.136.134   web-02
EOF
```

---

## 3. SSL Certificate

### 3.1 Lý Thuyết — SSL Termination

Mô hình **SSL Termination** tập trung việc giải mã HTTPS vào HAProxy. Backend Apache chỉ nhận HTTP thuần — giảm tải CPU đáng kể và quản lý certificate tập trung tại một chỗ.

> **Lưu ý:** HAProxy yêu cầu file `.pem` chứa cả Public Certificate **và** Private Key trong một file duy nhất theo thứ tự: **cert trước, key sau**.

### 3.2 Tạo Self-signed Certificate — Trên edge-01

```bash
sudo mkdir -p /etc/ssl/haproxy

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/ha.key \
  -out    /tmp/ha.crt \
  -subj   "/C=VN/ST=HaNoi/L=HaNoi/O=Lab/CN=192.168.136.100" \
  -addext "subjectAltName=IP:192.168.136.100,IP:192.168.136.131,IP:192.168.136.146"

# HAProxy yêu cầu cert + key gộp trong 1 file .pem
sudo bash -c 'cat /tmp/ha.crt /tmp/ha.key > /etc/ssl/haproxy/cert.pem'
sudo chmod 600 /etc/ssl/haproxy/cert.pem

# Kiểm tra
ls -lh /etc/ssl/haproxy/cert.pem
sudo openssl x509 -in /etc/ssl/haproxy/cert.pem -noout -subject -dates
```
<img width="491" height="404" alt="{185365E2-BD76-4C55-804F-38854AFDE41A}" src="https://github.com/user-attachments/assets/9a753e70-3a59-492a-8f9f-ab8e83e7f19d" />

### 3.3 Copy Certificate sang edge-02

```bash
# Trên edge-01
sudo scp /etc/ssl/haproxy/cert.pem user@192.168.136.146:/tmp/

# Trên edge-02
sudo mkdir -p /etc/ssl/haproxy
sudo mv /tmp/cert.pem /etc/ssl/haproxy/cert.pem
sudo chmod 600 /etc/ssl/haproxy/cert.pem
```
<img width="483" height="354" alt="{F6D8E73C-0258-449C-9D53-96EEA9D49374}" src="https://github.com/user-attachments/assets/7867d37f-e57e-4dc7-8c83-b14ea1fa182d" />

---

## 4. Keepalived — VRRP Failover

### 4.1 Lý Thuyết — VRRP

**VRRP (Virtual Router Redundancy Protocol)** là giao thức Layer 3, hoạt động độc lập với ứng dụng.

- **edge-01 (MASTER, priority 110):** Giữ VIP, broadcast VRRP advertisement mỗi 1 giây
- **edge-02 (BACKUP, priority 100):** Lắng nghe. Sau 3 giây không nhận được → tự nâng lên MASTER, gửi Gratuitous ARP
- **Thời gian failover:** < 3 giây

Hệ thống quản lý **2 VIP** qua 2 VRRP instance:
- `VI_1` → VIP-HTTP `192.168.136.100` (web traffic)
- `VI_2` → VIP-MySQL `192.168.136.101` (database traffic)

### 4.2 Cài Đặt và Cấu Hình sysctl — edge-01 và edge-02

```bash
sudo apt install -y keepalived

sudo tee /etc/sysctl.d/99-haproxy.conf << 'EOF'
net.ipv4.ip_forward          = 1
net.ipv4.ip_nonlocal_bind    = 1
net.core.somaxconn            = 65535
net.ipv4.tcp_max_syn_backlog  = 65535
EOF

sudo sysctl --system

# Xác nhận
sysctl net.ipv4.ip_nonlocal_bind
# Kết quả mong đợi: net.ipv4.ip_nonlocal_bind = 1
```
<img width="235" height="80" alt="{DBD86E95-9A00-4957-9D67-1FDC30F9E473}" src="https://github.com/user-attachments/assets/680e8a8f-c438-45b8-b4ce-e134cca04229" />

> **Quan trọng:** Nếu `ip_nonlocal_bind = 0`, Keepalived chạy nhưng VIP không xuất hiện — đây là lỗi hay gặp nhất.

### 4.3 Cấu Hình Keepalived — edge-01 (MASTER)

```bash
sudo nano /etc/keepalived/keepalived.conf
```

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

# VI_1: VIP Web (192.168.136.100)
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

# VI_2: VIP MySQL (192.168.136.101)
vrrp_instance VI_2 {
    state             MASTER
    interface         ens33
    virtual_router_id 52
    priority          110
    advert_int        1
    authentication {
        auth_type PASS
        auth_pass HAStack2024
    }
    virtual_ipaddress {
        192.168.136.101/24 dev ens33 label ens33:vip2
    }
}
```
<img width="354" height="372" alt="{D80CEE46-F4A4-4545-B881-03B957851011}" src="https://github.com/user-attachments/assets/a0e6d6e5-e3f7-49f8-b105-c81b219736ec" />

### 4.4 Cấu Hình Keepalived — edge-02 (BACKUP)

```bash
sudo nano /etc/keepalived/keepalived.conf
# Sao chép từ edge-01 và sửa 3 chỗ:
```

```
# Sửa trong global_defs:
router_id edge-02

# Sửa trong cả VI_1 và VI_2:
state    BACKUP
priority 100
```
<img width="392" height="332" alt="{5F0C0E84-5F20-4A78-88FE-D0CFA8DCE462}" src="https://github.com/user-attachments/assets/2dfc8ab0-9c74-4b71-ac51-f51c9e6bfb3a" />

### 4.5 Notify Script — edge-01 và edge-02
Tạo file thông báo cho log dễ đọc  


```bash
sudo tee /etc/keepalived/notify.sh << 'SCRIPT'
#!/bin/bash
STATE=$1; HOST=$(hostname); TS=$(date '+%Y-%m-%d %H:%M:%S')
LOG=/var/log/keepalived-notify.log
case $STATE in
    MASTER) echo "[$TS] $HOST → MASTER | VIP đã GÁN vào máy này" >> $LOG ;;
    BACKUP) echo "[$TS] $HOST → BACKUP | VIP đã rời đi" >> $LOG ;;
    FAULT)  echo "[$TS] $HOST → FAULT  | Đang restart HAProxy..." >> $LOG
            sudo systemctl restart haproxy ;;
esac
SCRIPT

sudo chmod +x /etc/keepalived/notify.sh
sudo systemctl enable --now keepalived

# Kiểm tra VIP trên edge-01
ip addr show ens33 | grep "136.10"
# Kết quả mong đợi:
#   inet 192.168.136.100/24  ← VIP Web
#   inet 192.168.136.101/24  ← VIP MySQL
```

<img width="478" height="144" alt="{F0A6A0CA-8509-40AC-8498-463C27010E6A}" src="https://github.com/user-attachments/assets/ac4187b8-a7e0-438a-a688-16b102d6a00b" />
<img width="1402" height="501" alt="image" src="https://github.com/user-attachments/assets/4f2fa6ba-7135-4a00-be33-51967afd50ae" />

Máy edge-02 Backup chưa có VIP     
<img width="529" height="182" alt="{C8EF45EA-3B2C-40DF-AFF4-85D92DAD20E9}" src="https://github.com/user-attachments/assets/75619082-e59d-4116-ae20-5442c54c24d8" />

---

## 5. HAProxy — Load Balancer

### 5.1 Lý Thuyết — HAProxy Làm 3 Việc Chính

1. **SSL Termination:** Nhận HTTPS, giải mã TLS tại LB, forward HTTP thuần xuống backend
2. **Load Balancing (Round Robin):** Phân phối request đến web-01 và web-02 luân phiên
3. **Health Check tự động:** Cứ 2 giây kiểm tra `/health.html`. 3 lần fail → loại backend; 2 lần success → đưa vào lại

Từ HAProxy 2.0+, có sẵn Prometheus metrics endpoint tích hợp — không cần cài exporter riêng.

### 5.2 Cài Đặt và Cấu Hình — edge-01 và edge-02

```bash
sudo apt install -y haproxy
sudo nano /etc/haproxy/haproxy.cfg
```

```
global
    log         /dev/log local0
    log         /dev/log local1 notice
    chroot      /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user        haproxy
    group       haproxy
    daemon
    maxconn     50000

defaults
    log         global
    mode        http
    option      httplog
    option      dontlognull
    option      forwardfor
    option      http-server-close
    timeout connect  5s
    timeout client   30s
    timeout server   30s

# ─── Stats + Prometheus endpoint ─────────────────────
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /haproxy-stats
    stats refresh 10s
    stats auth admin:admin123
    stats show-legends
    stats show-node
    # Prometheus scrape tại /metrics — BẮT BUỘC để Prometheus scrape được
    http-request use-service prometheus-exporter if { path /metrics }

# ─── HTTP → HTTPS redirect ────────────────────────────
frontend fe_http
    bind *:80
    mode http
    http-request redirect scheme https code 301

# ─── HTTPS SSL Termination ────────────────────────────
frontend fe_https
    bind *:443 ssl crt /etc/ssl/haproxy/cert.pem ssl-min-ver TLSv1.2
    mode http
    option forwardfor
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Real-IP %[src]
    http-response set-header Strict-Transport-Security "max-age=63072000"
    default_backend web_servers

# ─── Web Backend — 2 Apache nodes ─────────────────────
backend web_servers
    balance     roundrobin
    option      httpchk
    http-check  send meth GET uri /health.html ver HTTP/1.1 \
                hdr Host 192.168.136.100 hdr Connection close
    http-check  expect string OK
    cookie      SERVERID insert indirect nocache
    server web01 192.168.136.145:80 check inter 2s rise 2 fall 3 cookie w1
    server web02 192.168.136.134:80 check inter 2s rise 2 fall 3 cookie w2

# ─── MySQL / Galera Backend — VIP 192.168.136.101:3306 ─
frontend fe_mysql
    bind 192.168.136.101:3306
    mode tcp
    option tcplog
    default_backend mysql_galera

backend mysql_galera
    mode        tcp
    option      tcpka
    option      mysql-check user haproxy_check
    balance     leastconn
    timeout connect 3s
    timeout server  30s
    server web-01-db 192.168.136.145:3306 check inter 2s rise 2 fall 3
    server web-02-db 192.168.136.134:3306 check inter 2s rise 2 fall 3
```

```bash
# Validate config
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
# Kết quả mong đợi: Configuration file is valid

sudo systemctl enable --now haproxy

# Kiểm tra backends
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock \
  | awk -F',' 'NR>1 && $2!="FRONTEND" && $2!="BACKEND" {printf "  %-20s %-20s %s\n", $1, $2, $18}'
# web_servers   web01   UP
# web_servers   web02   UP
# mysql_galera  web-01-db  UP
# mysql_galera  web-02-db  UP
```

> **Stats UI:** `http://192.168.136.131:8404/haproxy-stats` — user `admin` / `admin123`

---

## 6. Apache + PHP-FPM

### 6.1 Cài Đặt — web-01 và web-02

> **Lưu ý bắt buộc:** Ubuntu 22.04 không có PHP 8.1 trong repo mặc định. Phải thêm PPA của Ondřej Surý trước, nếu không `apt` sẽ báo lỗi: `php8.1-fpm has no installation candidate`.

```bash
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

**Lý do dùng PHP-FPM thay vì mod_php:** PHP-FPM tách riêng pool process PHP, giao tiếp qua Unix socket. Static file (CSS, JS, ảnh) không cần qua PHP — ít tốn RAM hơn, throughput cao hơn, crash isolation tốt hơn.

### 6.2 Cấu Hình VirtualHost WordPress — web-01 và web-02

```bash
sudo tee /etc/apache2/sites-available/wordpress.conf << 'EOF'
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
EOF

# Bật site WordPress, TẮT site mặc định (quan trọng!)
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
```
<img width="453" height="258" alt="{62E485D9-075D-4007-B1B0-951ACC092A27}" src="https://github.com/user-attachments/assets/614e51f9-5c64-4b1d-9f4c-636f4074a4a4" />

### 6.3 Tạo Health Check Endpoint cho HAProxy

```bash
# Tạo file health check
echo "OK" | sudo tee /var/www/html/health.html
sudo chown www-data:www-data /var/www/html/health.html

# Kiểm tra từ cả hai node
curl http://192.168.136.145/health.html   # → OK
curl http://192.168.136.134/health.html   # → OK
```
<img width="416" height="185" alt="{9EC30250-F59E-4FA3-929F-64E6F297DE4D}" src="https://github.com/user-attachments/assets/3292dc6d-2620-44c1-8b82-5a2da2fe7866" />

---

## 7. MariaDB Galera Cluster

### 7.1 Lý Thuyết — Tại Sao Cần Galera?

Phiên bản báo cáo trước chỉ cài MariaDB đơn lẻ trên web-02 — đây là **Single Point of Failure cuối cùng** trong hệ thống: nếu web-02 chết, database mất, WordPress không thể hoạt động.

**Galera Cluster giải quyết triệt để:**
- Active-active: cả web-01 và web-02 đều accept read/write
- Khi một node DB chết — node còn lại tiếp tục phục vụ không gián đoạn
- HAProxy phân phối kết nối DB qua VIP-MySQL `192.168.136.101`
- **garbd** (Galera Arbitrator) chạy trên edge-01 đóng vai trò node thứ 3 để đảm bảo quorum mà không cần thêm máy chủ DB

### 7.2 Cài Đặt MariaDB 10.11 — web-01 và web-02

```bash
# Thêm MariaDB 10.11 LTS repo (bắt buộc — Ubuntu 22.04 chỉ có 10.6)
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
  | sudo bash -s -- --mariadb-server-version=mariadb-10.11

sudo apt update
sudo apt install -y mariadb-server mariadb-backup galera-4
sudo mysql_secure_installation 

# Kiểm tra phiên bản
mariadb --version
# mariadb  Ver 15.1 Distrib 10.11.x-MariaDB
```

### 7.3 Cấu Hình Galera — web-01 và web-02

```bash
sudo systemctl stop mariadb
sudo tee /etc/mysql/mariadb.conf.d/60-galera.cnf << 'EOF'
[mysqld]
binlog_format            = ROW
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2
bind-address             = 0.0.0.0

# Galera settings
wsrep_on               = ON
wsrep_provider         = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name     = "wp_galera_cluster"
wsrep_cluster_address  = "gcomm://192.168.136.145,192.168.136.134"
wsrep_sst_method       = mariabackup
wsrep_sst_auth         = sst_user:SST@Nhanhoa2026!
wsrep_slave_threads    = 2
EOF
```

> **Quan trọng:** Sau đó thêm vào file cấu hình trên **từng node** theo IP tương ứng:

```bash
# Trên web-01:
echo 'wsrep_node_address = "192.168.136.145"
wsrep_node_name    = "web-01"' \
  | sudo tee -a /etc/mysql/mariadb.conf.d/60-galera.cnf

# Trên web-02:
echo 'wsrep_node_address = "192.168.136.134"
wsrep_node_name    = "web-02"' \
  | sudo tee -a /etc/mysql/mariadb.conf.d/60-galera.cnf
```

```bash
# Mở firewall Galera trên cả 2 web node
sudo ufw allow from 192.168.136.0/24 to any port 3306   # MySQL
sudo ufw allow from 192.168.136.0/24 to any port 4567   # Galera gcomm
sudo ufw allow from 192.168.136.0/24 to any port 4568   # Galera IST
sudo ufw allow from 192.168.136.0/24 to any port 4444   # SST
sudo ufw reload
```

### 7.4 Bootstrap Cluster

```bash
# ===== BƯỚC 1: Bootstrap trên web-02 trước (node có data WordPress) =====
sudo galera_new_cluster

# Tạo SST user và HAProxy health check user
sudo mysql -u root << 'SQL'
CREATE USER 'sst_user'@'localhost' IDENTIFIED BY 'SST@Nhanhoa2026!';
GRANT PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sst_user'@'localhost';

-- User để HAProxy health check (không cần password)
CREATE USER 'haproxy_check'@'192.168.136.%' IDENTIFIED BY '';
FLUSH PRIVILEGES;
SQL

# Kiểm tra sau bootstrap
sudo mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# wsrep_cluster_size: 1  (chỉ web-02, chờ web-01 join)
```

```bash
# ===== BƯỚC 2: web-01 join cluster =====
sudo systemctl start mariadb

# Theo dõi quá trình SST (clone data từ web-02 → web-01)
sudo tail -f /var/log/mysql/error.log | grep -i "wsrep\|sst\|synced"

# Kiểm tra sau khi join
sudo mysql -u root -e "
  SHOW STATUS LIKE 'wsrep_cluster_size';
  SHOW STATUS LIKE 'wsrep_cluster_status';
  SHOW STATUS LIKE 'wsrep_local_state_comment';
  SHOW STATUS LIKE 'wsrep_ready';"
# wsrep_cluster_size        : 2
# wsrep_cluster_status      : Primary
# wsrep_local_state_comment : Synced
# wsrep_ready               : ON
```

### 7.5 Tạo Database và User WordPress

```bash
# Chạy trên bất kỳ node (Galera tự sync)
sudo mysql -u root << 'SQL'
CREATE DATABASE IF NOT EXISTS wordpress_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'iamhieu'@'192.168.136.145' IDENTIFIED BY 'Iamhieu@2026';
CREATE USER 'iamhieu'@'192.168.136.134' IDENTIFIED BY 'Iamhieu@2026';
CREATE USER 'iamhieu'@'192.168.136.101' IDENTIFIED BY 'Iamhieu@2026';

GRANT ALL PRIVILEGES ON wordpress_db.* TO 'iamhieu'@'192.168.136.145';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'iamhieu'@'192.168.136.134';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'iamhieu'@'192.168.136.101';
FLUSH PRIVILEGES;
SQL

# Tạo user cho mysqld_exporter
sudo mysql -u root << 'SQL'
CREATE USER IF NOT EXISTS 'exporter'@'127.0.0.1' IDENTIFIED BY 'Exporter@2026!';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
```

### 7.6 Cài garbd (Galera Arbitrator) — edge-01

**Mục đích:** garbd là node thứ 3 trong cluster không lưu data, chỉ tham gia bầu chọn quorum. Đảm bảo khi 1 trong 2 DB node chết, cluster vẫn đạt quorum `2/3` và tiếp tục hoạt động.

```bash
#  Thêm MariaDB repo trên edge-01
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
  | sudo bash -s -- --mariadb-server-version=mariadb-10.11

sudo apt update

# Kiểm tra version package phải khớp với Galera trên web-01/web-02
apt-cache show galera-arbitrator-4 | grep Version
sudo apt install galera-arbitrator-4 -y
garbd --version
# INFO: 26.4.x (galera-arbitrator-4) 
```

```bash
# Cấu hình đúng file /etc/default/garb
sudo tee /etc/default/garb << 'EOF'
# Địa chỉ các DB node trong cluster 
GALERA_NODES="192.168.136.145:4567,192.168.136.134:4567"
GALERA_GROUP="wp_galera_cluster"
LOG_FILE="/var/log/garb.log"
EOF

#  Mở firewall 
sudo ufw allow from 192.168.136.145 to any port 4567
sudo ufw allow from 192.168.136.134 to any port 4567
sudo ufw reload

# Start service 
sudo systemctl enable garb
sudo systemctl start garb
sudo systemctl status garb
```

```bash
# Xác nhận cluster size = 3
sudo mysql -h 192.168.136.145 -u root \
  -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# wsrep_cluster_size: 3  (web-01 + web-02 + garbd) ✅
```

---

## 8. Redis Sentinel

### 8.1 Lý Thuyết — Tại Sao Cần Redis Sentinel?

Redis đơn lẻ trên web-02 là SPOF — nếu web-02 chết, toàn bộ session mất, tất cả user bị logout.

**Redis Sentinel cung cấp:**
- **Monitoring:** 3 Sentinel liên tục kiểm tra trạng thái Redis Master
- **Auto Failover:** Khi Master chết, Sentinel bầu chọn Replica mới làm Master trong **5-10 giây**
- **Quorum:** Cần `2/3` Sentinel đồng ý Master chết → mới thực hiện failover (tránh split-brain)

**Kiến trúc**
- Redis Master: web-02 
- Redis Replica: web-01 
- Redis Sentinel: chạy trên web-01, web-02, edge-01 (3 node = quorum)

### 8.2 Cài Đặt Redis trên web-01 

```bash
sudo apt install redis-server -y
redis-server --version
# Redis server v=7.0.x 

sudo tee /etc/redis/redis.conf << 'EOF'
bind 0.0.0.0
protected-mode no
port 6379
daemonize yes
logfile /var/log/redis/redis-server.log

# Khai báo là Replica của web-02
replicaof 192.168.136.134 6379
replica-read-only yes

# Bảo mật
requirepass Redis_2026
masterauth  Redis_2026
EOF
```

### 8.3 Redis trên web-02 (Master)

```bash
sudo tee /etc/redis/redis.conf << 'EOF'
bind 0.0.0.0
protected-mode no
port 6379
daemonize yes
logfile /var/log/redis/redis-server.log

requirepass Redis_2026
masterauth  Redis_2026
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

# Restart Redis trên cả 2 node
sudo systemctl restart redis-server

# Mở firewall
sudo ufw allow from 192.168.136.0/24 to any port 6379   
sudo ufw allow from 192.168.136.0/24 to any port 26379  
sudo ufw reload

# Verify replication từ web-02
redis-cli -a 'Redis_2026' info replication \
  | grep -E "role|connected_slaves"
# role:master
# connected_slaves:1  
```

### 8.4 Cấu Hình Sentinel — web-01, web-02, edge-01

```bash
sudo tee /etc/redis/sentinel.conf << 'EOF'
port 26379
daemonize yes
logfile /var/log/redis/sentinel.log
pidfile /var/run/redis/redis-sentinel.pid

# Monitor Master — quorum 2: cần 2/3 Sentinel đồng ý → failover
sentinel monitor wp_redis 192.168.136.134 6379 2
sentinel auth-pass wp_redis Redis_2026

# Master không phản hồi 5 giây → subjective down
sentinel down-after-milliseconds wp_redis 5000
sentinel failover-timeout        wp_redis 30000
sentinel parallel-syncs          wp_redis 1

bind 0.0.0.0
protected-mode no
EOF

sudo systemctl enable redis-sentinel
sudo systemctl start redis-sentinel

# Verify Sentinel
redis-cli -p 26379 sentinel masters
# name: wp_redis | ip: 192.168.136.134 | port: 6379 | status: ok ✅

# Kiểm tra đủ 3 Sentinel
redis-cli -p 26379 sentinel sentinels wp_redis
# Phải thấy 2 sentinel khác (tổng 3 including local)
```

---

## 9. WordPress

### 9.1 Tải và Cài Đặt — web-01 và web-02

```bash
cd /var/www/html
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

# Đảm bảo health check còn tồn tại
echo "OK" | sudo tee /var/www/html/health.html
sudo chown www-data:www-data /var/www/html/health.html
```

### 9.2 Cấu Hình wp-config.php — web-01 và web-02

```bash
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo nano /var/www/html/wp-config.php
```

```php
<?php
if ( isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
     $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}
if ( isset($_SERVER['HTTP_X_REAL_IP']) ) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_REAL_IP'];
}

// ================================================================
// DATABASE — Kết nối qua VIP-MySQL (HAProxy → Galera Cluster)
// ================================================================
define( 'DB_NAME',     'wordpress_db' );
define( 'DB_USER',     'iamhieu' );
define( 'DB_PASSWORD', 'Iamhieu@2026' );
define( 'DB_HOST',     '192.168.136.101' );  // VIP-MySQL → HAProxy → Galera
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  'utf8mb4_unicode_ci' );

// ================================================================
// REDIS SENTINEL — Object Cache + Session Store
// ================================================================
define( 'WP_REDIS_CLIENT',   'predis' );
define( 'WP_REDIS_SENTINEL', 'wp_redis' );
define( 'WP_REDIS_SERVERS', [
    'tcp://192.168.136.145:26379',  // Sentinel trên web-01
    'tcp://192.168.136.134:26379',  // Sentinel trên web-02
    'tcp://192.168.136.131:26379',  // Sentinel trên edge-01
]);
define( 'WP_REDIS_PASSWORD',      'Redis_2026' );
define( 'WP_REDIS_TIMEOUT',       1 );
define( 'WP_REDIS_READ_TIMEOUT',  1 );
define( 'WP_CACHE',               true );

// ================================================================
// Site URLs — HTTPS qua VIP
// ================================================================
define( 'FORCE_SSL_ADMIN', true );
define( 'WP_HOME',         'https://192.168.136.100' );
define( 'WP_SITEURL',      'https://192.168.136.100' );

// ================================================================
// Performance
// ================================================================
define( 'DISABLE_WP_CRON', true );
define( 'FS_METHOD',       'direct' );
define( 'WP_DEBUG',        false );
define( 'WP_DEBUG_LOG',    false );

// Lấy Salt Keys từ: https://api.wordpress.org/secret-key/1.1/salt/
define( 'AUTH_KEY',         'paste-your-unique-phrase-here' );
define( 'SECURE_AUTH_KEY',  'paste-your-unique-phrase-here' );
define( 'LOGGED_IN_KEY',    'paste-your-unique-phrase-here' );
define( 'NONCE_KEY',        'paste-your-unique-phrase-here' );
define( 'AUTH_SALT',        'paste-your-unique-phrase-here' );
define( 'SECURE_AUTH_SALT', 'paste-your-unique-phrase-here' );
define( 'LOGGED_IN_SALT',   'paste-your-unique-phrase-here' );
define( 'NONCE_SALT',       'paste-your-unique-phrase-here' );

$table_prefix = 'wp_';

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
```
<img width="420" height="160" alt="{31C4A194-B011-4340-9D6E-90A72575FB80}" src="https://github.com/user-attachments/assets/fb9a3c23-32f7-42e5-954e-5c7c6389be72" />

### 9.3 Kiểm Tra WordPress

```bash
# Xác nhận site đang active
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
sudo apache2ctl -S | grep wordpress

# Test PHP hoạt động
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
curl http://192.168.136.145/info.php | grep -i "PHP Version"
sudo rm /var/www/html/info.php  

# Truy cập trình duyệt: https://192.168.136.100

```
<img width="951" height="478" alt="{F117E332-5949-4683-AA91-5264AAD1F01F}" src="https://github.com/user-attachments/assets/a742ceaf-be3f-40d5-8eac-9b9690b367e6" />

---

## 10. Monitoring: Prometheus + Grafana + Alertmanager

### 10.1 Cài Đặt node\_exporter — Tất Cả 4 Node

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

### 10.2 Cài Đặt redis\_exporter và mysqld\_exporter — web-01 và web-02

```bash
# ===== redis_exporter =====
cd /tmp
sudo wget -q https://github.com/oliver006/redis_exporter/releases/download/v1.62.0/redis_exporter-v1.62.0.linux-amd64.tar.gz
sudo tar xzf redis_exporter-v1.62.0.linux-amd64.tar.gz
sudo cp redis_exporter-v1.62.0.linux-amd64/redis_exporter /usr/local/bin/

sudo tee /etc/systemd/system/redis_exporter.service << 'EOF'
[Unit]
Description=Redis Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/redis_exporter \
  --redis.addr=redis://127.0.0.1:6379 \
  --redis.password=Redis@Nhanhoa2026!
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ===== mysqld_exporter =====
sudo bash -c 'printf "[client]\nuser=exporter\npassword=Exporter@2026!\nhost=127.0.0.1\n" > /etc/.mysqld_exporter.cnf'
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

### 10.3 Cài Đặt Prometheus — edge-01 và edge-02

```bash
PROM_VER="2.52.0"
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
          - '192.168.136.131:8404'   # edge-01
          - '192.168.136.146:8404'   # edge-02

  - job_name: 'redis'
    static_configs:
      - targets:
          - '192.168.136.145:9121'   # web-01 redis_exporter
          - '192.168.136.134:9121'   # web-02 redis_exporter

  - job_name: 'mysql'
    static_configs:
      - targets:
          - '192.168.136.145:9104'   # web-01 mysqld_exporter
          - '192.168.136.134:9104'   # web-02 mysqld_exporter
```


### 10.4 Alert Rules — `/etc/prometheus/alert_rules.yml`

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

  - name: galera_alerts
    rules:
      - alert: GaleraClusterSizeDecreased
        expr: mysql_global_status_wsrep_cluster_size < 3
        for: 30s
        labels:
          severity: warning
        annotations:
          summary: 'GALERA: Cluster chi con {{ $value }} node'
          description: 'Mot node DB co the da thoat khoi cluster.'

inhibit_rules:
  - source_match:
      alertname: NodeDown
    target_match_re:
      alertname: 'HighCPU|HighMemory|DiskFull'
    equal: ['instance']
```
<img width="1915" height="706" alt="image" src="https://github.com/user-attachments/assets/083ca71e-7567-4909-9c42-46996ee519c7" />

### 10.5 Cài Đặt Alertmanager — edge-01 và edge-02

```bash
ALERTM_VER="0.27.0"
cd /tmp
sudo wget -q https://github.com/prometheus/alertmanager/releases/download/v${ALERTM_VER}/alertmanager-${ALERTM_VER}.linux-amd64.tar.gz
sudo tar xzf alertmanager-${ALERTM_VER}.linux-amd64.tar.gz
sudo cp alertmanager-${ALERTM_VER}.linux-amd64/{alertmanager,amtool} /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
```

**Cấu hình `/etc/alertmanager/alertmanager.yml`:**

```yaml
global:
  smtp_smarthost:     'smtp.gmail.com:587'
  smtp_from:          'your.email@gmail.com'
  smtp_auth_username: 'your.email@gmail.com'
  smtp_auth_password: 'app-password-16-chars'  # Gmail App Password
  smtp_require_tls:   true
  resolve_timeout:    1m

route:
  group_by:        ['alertname', 'severity', 'instance']
  group_wait:      10s
  group_interval:  1m
  repeat_interval: 2h
  receiver: 'gmail'
  routes:
    - match:
        severity: critical
      receiver: 'gmail_critical'
      group_wait:      5s
      repeat_interval: 30m

receivers:
  - name: 'gmail'
    email_configs:
      - to: 'your.email@gmail.com'
        send_resolved: true
        headers:
          Subject: >-
            {{ if eq .Status "firing" }}WARNING FIRING{{ else }}RESOLVED{{ end }}
            [{{ .GroupLabels.alertname }}]

  - name: 'gmail_critical'
    email_configs:
      - to: 'your.email@gmail.com'
        send_resolved: true
        headers:
          Subject: >-
            {{ if eq .Status "firing" }}CRITICAL FIRING{{ else }}CRITICAL RESOLVED{{ end }}
            [{{ .GroupLabels.alertname }}]

inhibit_rules:
  - source_match:
      alertname: NodeDown
    target_match_re:
      alertname: 'HighCPU|HighMemory|DiskFull'
    equal: ['instance']
```

### 10.6 Cài Đặt Grafana — edge-01 và edge-02

```bash
wget -q -O - https://packages.grafana.com/gpg.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```

**Dashboard Import (Grafana → Dashboards → Import → nhập ID):**

| Dashboard ID | Tên | Nội dung giám sát |
|---|---|---|
| `1860` | Node Exporter Full | CPU · RAM · Disk · Network mọi node |
| `367` | HAProxy 2 Full | Request rate · Backend UP/DOWN · Sessions |
| `763` | Redis Dashboard | Memory · Hit rate · Commands/s |
| `7362` | MySQL Overview | Queries · Connections · InnoDB · Galera |

<img width="960" height="436" alt="image" src="https://github.com/user-attachments/assets/c9f5f6f6-9d31-4e6e-b79d-d74209529f84" />

---

## 11. Kết Quả Kiểm Tra & Failover Test

### 11.1 Script Kiểm Tra Toàn Hệ Thống

```bash
#!/bin/bash
# Chạy trên edge-01
echo "===== HA SYSTEM CHECK — $(date) ====="

echo ""
echo "[1] VIP Status"
ip addr show ens33 | grep "136.10" | awk '{print "  " $2}'

echo ""
echo "[2] HAProxy Backends"
echo "show stat" | socat stdio /run/haproxy/admin.sock 2>/dev/null \
  | awk -F',' 'NR>1 && $2!="FRONTEND" && $2!="BACKEND" \
    {printf "  %-20s %-20s %s\n", $1, $2, $18}'

echo ""
echo "[3] Galera Cluster Size"
mysql -h 192.168.136.101 -u root -e \
  "SELECT VARIABLE_VALUE as cluster_size \
   FROM information_schema.GLOBAL_STATUS \
   WHERE VARIABLE_NAME='wsrep_cluster_size';" 2>/dev/null

echo ""
echo "[4] garbd Status"
systemctl is-active garb \
  && echo "  garb: RUNNING ✅" \
  || echo "  garb: DOWN ❌"

echo ""
echo "[5] Redis Sentinel"
redis-cli -p 26379 sentinel get-master-addr-by-name wp_redis 2>/dev/null \
  | paste - - | awk '{print "  Redis Master: "$1":"$2}'

echo ""
echo "[6] Services Health"
for svc in haproxy keepalived prometheus grafana-server alertmanager node_exporter; do
  STATUS=$(systemctl is-active $svc 2>/dev/null || echo "not-found")
  printf "  %-25s %s\n" "$svc" "$STATUS"
done
```

### 11.2 Test Keepalived Failover (VIP chuyển trong < 3 giây)

```bash
# Bước 1: Xác nhận VIP trên edge-01
ip addr show | grep "136.10"
# inet 192.168.136.100/24 scope global ens33:vip
# inet 192.168.136.101/24 scope global ens33:vip2

# Bước 2: Giả lập sự cố — tắt Keepalived trên edge-01
sudo systemctl stop keepalived

# Bước 3: Sau 3 giây — kiểm tra edge-02 đã tiếp quản VIP chưa
sleep 3
# (Chạy trên edge-02)
ip addr show | grep "136.10"
# Kết quả: VIP đã chuyển sang edge-02

# Bước 4: Website và DB vẫn online
curl -sk https://192.168.136.100/health.html    # → OK
mysql -h 192.168.136.101 -u root -e "SELECT 1;" # → 1

# Bước 5: Khôi phục
sudo systemctl start keepalived    # Trên edge-01
```

### 11.3 Test HAProxy Backend Failover

```bash
# Tắt Apache trên web-01
sudo systemctl stop apache2   # Trên web-01

# Sau 6 giây (fall 3 × inter 2s):
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock \
  | cut -d',' -f1,2,18 | grep web_servers
# web_servers,web01,DOWN   ← bị loại
# web_servers,web02,UP     ← vẫn phục vụ

# Website vẫn online
curl -sk https://192.168.136.100/health.html   # → OK

# Khôi phục
sudo systemctl start apache2   # Trên web-01
# Sau 4 giây (rise 2 × inter 2s) → web01 tự UP lại
```

### 11.4 Test Galera Failover (SPOF đã xử lý)

```bash
# Giả lập web-02 chết hoàn toàn
# Trên web-02:
sudo systemctl stop mariadb redis-server redis-sentinel apache2

# ===== Quan sát từ edge-01 =====

# Galera: web-01 + garbd = 2/3 nodes → đủ quorum
mysql -h 192.168.136.101 -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# wsrep_cluster_size: 2 ✅ (cluster vẫn Primary)

# Redis Sentinel failover (~5-10 giây)
redis-cli -p 26379 sentinel get-master-addr-by-name wp_redis
# 192.168.136.145 6379 ← web-01 là Master mới ✅

# Website vẫn online
curl -sk https://192.168.136.100/ -o /dev/null -w "HTTP %{http_code}\n"
# HTTP 200 ✅

# ===== Khôi phục web-02 =====
sudo systemctl start mariadb redis-server redis-sentinel apache2   # Trên web-02
# Galera tự IST/SST sync data từ web-01
# Redis web-02 tự trở thành Replica
# wsrep_cluster_size trở lại 3
```

### 11.5 Test Alert Gmail

```bash
# Tắt node_exporter trên web-01 để trigger NodeDown alert
sudo systemctl stop node_exporter    # Trên web-01

# Theo dõi trên Prometheus: http://192.168.136.131:9090/alerts
# T+30s: NodeDown → PENDING
# T+60s: NodeDown → FIRING → Alertmanager nhận, gửi Gmail
# T+65s: Gmail nhận email 🚨 CRITICAL

# Bật lại → Gmail nhận email ✅ RESOLVED (~90 giây)
sudo systemctl start node_exporter
```

---

## 12. Lỗi Gặp Phải và Cách Khắc Phục

| STT | Lỗi | Nguyên nhân | Cách khắc phục |
|---|---|---|---|
| 1 | `php8.1-fpm has no installation candidate` | Ubuntu 22.04 không có PHP 8.1 trong repo mặc định | Thêm PPA `ppa:ondrej/php` trước khi cài |
| 2 | `HAProxy: unable to stat SSL certificate` | Quên tạo file `cert.pem` hoặc sai thứ tự cert/key | Ghép đúng: `cat ha.crt ha.key > cert.pem` |
| 3 | Vào IP vẫn thấy trang Apache mặc định | `000-default.conf` vẫn bật hoặc `index.html` còn tồn tại | `sudo a2dissite 000-default.conf && sudo rm -f /var/www/html/index.html` |
| 4 | VIP không xuất hiện sau khi cài Keepalived | `ip_nonlocal_bind = 0` — kernel từ chối bind VIP | `echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf && sysctl -p` |
| 5 | Prometheus scrape HAProxy bị `503` | HAProxy không có `/metrics` endpoint theo mặc định | Thêm `http-request use-service prometheus-exporter if { path /metrics }` vào `listen stats` |
| 6 | `NodeDown` alert fire cho `job="haproxy"` | Rule `up == 0` bắt tất cả jobs kể cả HAProxy exporter | Sửa thành `up{job="node_exporter"} == 0` |
| 7 | Không nhận email RESOLVED | `resolve_timeout: 5m` quá dài, thiếu `instance` trong `group_by` | Đặt `resolve_timeout: 1m`, thêm `instance` vào `group_by` |
| 8 | `DiskFull` không fire dù disk đầy | `fstype!="tmpfs"` bỏ sót `overlay`, `squashfs`, `devtmpfs` | Dùng regex: `fstype!~"tmpfs\|overlay\|squashfs\|devtmpfs"` |
| 9 | `Unit garbd.service not found` | Tên service sai — package tạo service tên `garb` | Dùng `systemctl start garb` (không có `d`) |
| 10 | `garb.service: Status=1/FAILURE` | Config file sai đường dẫn — `/etc/garbd.cnf` không tồn tại | Dùng đúng file `/etc/default/garb` |
| 11 | `Package galera-arbitrator-4 not found` | Chưa thêm MariaDB repo trên edge-01 | Chạy `mariadb_repo_setup` trước khi `apt install` |
| 12 | Galera cluster xuống `non-Primary` | Cả 2 DB node restart cùng lúc, không có quorum | Chạy `galera_new_cluster` trên node có data mới nhất |
| 13 | Redis Sentinel không failover | Chưa đủ 3 Sentinel — quorum 2/3 không đạt | Đảm bảo Sentinel chạy trên web-01, web-02 VÀ edge-01 |

---

## 13. Kết Luận và Bài Học Rút Ra

### 13.1 Kết Quả Đạt Được

| Tiêu chí | Kết quả |
|---|---|
| Thời gian failover Keepalived (VIP) | **< 3 giây** |
| Thời gian HAProxy loại backend lỗi | **6 giây** (fall 3 × inter 2s) |
| Thời gian Redis Sentinel failover | **5-10 giây** |
| Galera quorum khi 1 DB node chết | ✅ Đảm bảo (web + garbd = 2/3) |
| Uptime website khi 1 backend down | **100%** (HAProxy tự route) |
| Uptime DB khi 1 DB node down | **100%** (Galera + HAProxy mysql) |
| Uptime Session khi Redis Master down | **100%** (Redis Sentinel failover) |
| Cảnh báo sự cố đến Gmail | **< 90 giây** sau khi phát sinh |
| Dashboard Grafana hoạt động | ✅ 4 dashboard (node/HAProxy/Redis/MySQL) |
| Single Point of Failure còn lại | Không còn |

### 13.2 So Sánh Trước và Sau

| Thành phần | Phiên bản đầu | Phiên bản hoàn chỉnh |
|---|---|---|
| Load Balancer | 2 node LB + VRRP | ✅ Giống — đã ổn |
| Web Backend | 2 node Apache | ✅ Giống — đã ổn |
| Database | MariaDB đơn lẻ trên web-02 | ✅ **Galera Cluster + garbd** |
| Session Store | Redis đơn lẻ trên web-02 | ✅ **Redis Master-Replica + Sentinel** |
| DB Connection | Direct IP web-02 | ✅ **Qua VIP-MySQL (HAProxy)** |
| WordPress config | Hard-code IP web-02 | ✅ **Redis Sentinel + VIP-MySQL** |
| SPOF còn lại | Database = web-02 | ✅ **Không còn SPOF** |

### 13.3 Bài Học Rút Ra

**Về kỹ thuật:**

- `ip_nonlocal_bind = 1` là điều kiện tiên quyết để Keepalived bind VIP — không có dòng này, Keepalived chạy nhưng VIP không xuất hiện
- HAProxy cần file `.pem` = cert + key gộp lại đúng thứ tự (cert trước, key sau)
- WordPress sau reverse proxy HTTPS bắt buộc phải xử lý header `X-Forwarded-Proto` — thiếu gây redirect loop
- `fstype!~"regex"` quan trọng hơn `fstype!="string"` khi viết PromQL — dùng sai thì DiskFull không bao giờ fire
- garbd: tên package là `galera-arbitrator-4`, tên service là `garb`, config file là `/etc/default/garb` — ba cái tên khác nhau dễ gây nhầm lẫn
- Galera cluster cần quorum `(N/2)+1` — 2 node DB + 1 garbd cho phép chịu đựng 1 node fail bất kỳ
- Redis Sentinel cần số lẻ Sentinels (3, 5...) để bầu chọn quorum không bị tie

**Về quy trình:**

- Setup và test từng lớp độc lập: LB layer → Web layer → DB layer → Cache layer → Monitoring layer
- Document lại từng lỗi gặp phải ngay khi sửa xong — 1 tuần sau sẽ không còn nhớ
- Chủ động test fail case (tắt từng service) thay vì chỉ test happy path
- HA không chỉ là "2 cái máy" — mà là từng tầng đều phải có backup độc lập

**Định hướng mở rộng:**

- **Scale backend:** Thêm web-03 chỉ cần 1 dòng trong `haproxy.cfg`, reload không cần restart
- **Galera 3-node:** Bỏ garbd, thêm web-03 làm DB node thứ 3 — mạnh hơn và không cần arbitrator
- **Redis Cluster:** Thay Redis Sentinel bằng Redis Cluster cho horizontal scaling session
- **Automation:** Viết Ansible playbook để deploy toàn bộ stack từ đầu trong < 15 phút
- **CI/CD:** Tích hợp GitHub Actions để auto-deploy WordPress update mà không downtime

---

*Báo cáo hoàn chỉnh · Cập nhật lần cuối 30/05/2026*
*Nguyễn Thanh Hiếu · Intern IT — Tuần 4 · Nhân Hòa*
