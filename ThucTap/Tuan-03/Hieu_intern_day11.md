# Báo cáo thực tập ngày 11 - Chuyên sâu về web server
## Load Balancing 
Load Balancing là việc phân phối lưu lượng mạng hoặc lưu lượng truy cập ứng dụng trên nhiều máy chủ khác nhau
Mục tiêu chính là:
Tăng tính sẵn sàng (High Availability): Nếu một máy chủ bị hỏng, bộ cân bằng tải sẽ tự động chuyển hướng khách sang các máy chủ còn lại.  
Tăng khả năng mở rộng (Scalability): Bạn có thể dễ dàng thêm hoặc bớt máy chủ tùy theo lượng truy cập.  
Tối ưu hiệu suất: Tránh tình trạng một server đầy trong khi server khác lại đang không có gì.  
### Các thuật toán load balancing
```
round-robin  → Xoay vòng đều: 1→2→3→1→2→3
              Phù hợp: Servers có cấu hình tương đương

least_conn   → Gửi đến server có ít connections nhất
              Phù hợp: Requests có thời gian xử lý khác nhau

ip_hash      → Cùng IP → Cùng server (Session Sticky)
              Phù hợp: App có session trên từng server

hash $uri    → Hash theo URL → Cùng URL → Cùng server
              Phù hợp: Cache consistency

random       → Ngẫu nhiên
least_time   → Thời gian phản hồi thấp nhất (NGINX Plus)
```
### Cài đặt load balancing,Caching, Tối ưu tốc độ, Tuning 
Mô hình thực hiện:  
client -> máy 1: nginx(80,load balancing), apache(8080) -> máy 2: apache (8081)  
Sử dụng thuật toán RR 50-50  

* Bước 1: Cài đặt nginx cho máy làm load, apache cho 2 máy
  sudo apt install -y nginx apache2  
  sudo apt install -y apache2  
<img width="385" height="91" alt="{7FDC95C5-ED20-4A68-9701-2803B1661124}" src="https://github.com/user-attachments/assets/da4f1014-73e4-4e21-ab5c-d855e847fd96" />

* Bước 2: Cấu hình apache cho máy 1
  sudo nano /etc/apache2/ports.conf: Đổi cổng 80 -> 8080
  sudo nano /etc/apache2/sites-available/000-default.conf
  ```
  <VirtualHost *:8080>
    ServerName 192.168.136.131
    DocumentRoot /var/www/html

    # Tạo trang test để phân biệt với máy 2
    DirectoryIndex index.html

    ErrorLog  ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    # Bật HTTP/2
    Protocols h2c http/1.1

    # Keep-Alive
    KeepAlive On
    KeepAliveTimeout 5
    MaxKeepAliveRequests 100
</VirtualHost>
```
<img width="474" height="366" alt="{01CF8258-AFD0-4925-BBBA-EB3C0588C736}" src="https://github.com/user-attachments/assets/7d283924-6769-474f-a4cd-376e434de08e" />

* Tạo trên apache máy 2 tương tự
<img width="643" height="263" alt="{91490A65-EBAD-44C2-9607-2BD18C0FBC1F}" src="https://github.com/user-attachments/assets/820a2cc6-f170-4535-8aaf-54c74ac9176b" />

* Dùng tường lửa cho phép Máy 1 kết nối vào
  sudo ufw allow from 192.168.136.131 to any port 80
<img width="484" height="140" alt="{83A9223E-E57C-402C-866E-FF593564F17B}" src="https://github.com/user-attachments/assets/bdb033cd-4bb3-434f-916d-bc4334c2d71a" />

* Cấu hình nginx ở máy 1
```
  Xóa cấu trúc mặc định
sudo rm /etc/nginx/sites-enabled/default  
  Tạo cấu hình riêng  
sudo nano /etc/nginx/conf.d/loadbalancer.conf
upstream apache_backends{
    server 192.168.136.131:8080; 
    server 192.168.136.134:80; 

    keepalive 32;
}

server {
    listen 80;
    server_name 192.168.136.131;

    gzip            on;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_proxied    any;
    gzip_vary       on;
    gzip_types      text/plain text/css application/json
                    application/javascript text/xml image/svg+xml;

    location / {
        proxy_pass http://apache_backends;

        proxy_http_version 1.1;
        proxy_set_header Connection        "";

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout  5s;
        proxy_send_timeout    30s;
        proxy_read_timeout    30s;

        # Failover: tự chuyển sang máy còn lại nếu 1 máy lỗi
        proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries   2;
        proxy_next_upstream_timeout 10s;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg|ttf)$ {
        proxy_pass        http://apache_backends;
        proxy_http_version 1.1;
        proxy_set_header  Connection "";
        proxy_set_header  Host $host;

        expires           7d;
        add_header        Cache-Control "public, immutable";
        add_header        X-Cache-Status $upstream_cache_status;
    }

    location /api/ {
        proxy_pass        http://apache_backends;
        proxy_http_version 1.1;
        proxy_set_header  Connection "";
        proxy_set_header  Host $host;

        add_header        Cache-Control "no-store, no-cache";
        proxy_no_cache    1;
        proxy_cache_bypass 1;
    }

    location /health {
        access_log off;
        return 200 "Load Balancer OK\n";
        add_header Content-Type text/plain;
    }

    location /nginx_status {
        stub_status on;
        allow 192.168.136.0/24;  
        deny all;
    }

    server_tokens off;
}
```
* Tuning thông số máy 1, caching
  sudo nano /etc/nginx/nginx.conf
```
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    multi_accept       on;
    use                epoll;
}

http {
    sendfile           on;
    tcp_nopush         on;
    tcp_nodelay        on;
    server_tokens      off;
    types_hash_max_size 2048;

    keepalive_timeout  65;
    keepalive_requests 1000;

    client_body_buffer_size    16k;
    client_header_buffer_size  1k;
    client_max_body_size       50m;
    large_client_header_buffers 4 8k;

    proxy_buffer_size    4k;
    proxy_buffers        8 16k;
    proxy_busy_buffers_size 32k;

    client_body_timeout   12s;
    client_header_timeout 12s;
    send_timeout          10s;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
```

* cache apache (Cả 2 máy)
  <img width="367" height="189" alt="{99E583FB-2193-4C37-8821-6E741B74B564}" src="https://github.com/user-attachments/assets/58d55dae-b4d2-446a-8115-c5bdc6e9cd59" />
  
sudo nano /etc/apache2/mods-available/mpm_event.conf  

 ```
<IfModule mpm_event_module>
    StartServers          2
    MinSpareThreads      25
    MaxSpareThreads      75
    ThreadLimit          64
    ThreadsPerChild      25
    MaxRequestWorkers   150
    MaxConnectionsPerChild 1000
</IfModule>
```

 Tăng giới hạn file OS (cả 2 máy)
sudo nano /etc/security/limits.conf 
 ```
www-data soft nofile 65535
www-data hard nofile 65535

```
 Tối ưu kernel network (cả 2 máy)  
sudo nano /etc/sysctl.conf
```
net.core.somaxconn           = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout     = 10
net.ipv4.tcp_keepalive_time  = 300
```
sudo sysctl -p   

Check   
<img width="589" height="216" alt="{13ED0BA5-379E-4DD2-87B9-41BA63CDD05F}" src="https://github.com/user-attachments/assets/2252c334-252d-4daa-94bc-d8db11bbeae9" />
Tắt máy 2, máy 1 vẫn hoạt động oke
<img width="953" height="367" alt="{D14B94F7-8D56-475F-AE47-CC0C1BD9EF96}" src="https://github.com/user-attachments/assets/3bf155d3-4aed-4ada-92a4-5a9db7ff9aa7" />

---

# Bảo mật Webserver
DDoS là hành động làm tê liệt một server hoặc dịch vụ bằng cách làm tràn ngập lưu lượng truy cập từ nhiều nguồn khác nhau.  
* Cơ chế: Kẻ tấn công sử dụng một mạng lưới các thiết bị bị chiếm quyền điều khiển để đồng loạt gửi request đến IP của máy.
* Mục tiêu: Làm cạn kiệt tài nguyên hệ thống (CPU, RAM) hoặc băng thông mạng, khiến người dùng thật không thể truy cập được.
DDoS Layer 3/4 (Network): Gửi ồ ạt gói tin TCP/UDP/ICMP làm nghẽn băng thông. Ví dụ: SYN Flood
DDoS Layer 7 (Application): Gửi request HTTP hợp lệ nhưng quá nhiều, làm server kiệt sức khi xử lý. Khó phát hiện hơn vì trông giống traffic thật.

Brute Force là kiểu tấn công mang tính "thử sai". Kẻ tấn công sẽ thử tất cả các tổ hợp mật khẩu có thể có cho đến khi tìm ra mật khẩu đúng.  
*Cơ chế: Sử dụng các công cụ tự động để gõ hàng ngàn mật khẩu mỗi giây vào các form đăng nhập (như SSH, Trang quản trị Admin, Login website).
* Mục tiêu: Chiếm quyền điều khiển tài khoản (thường là quyền root hoặc admin).

## Chống DDoS , Brute Force
Các cách chống tấn công chống DDoS: Rate Limiting trong Nginx,iptables / ufw ,Cloudflare
Các cách chống tấn công chống Brute Force: Fail2Ban, Đổi Port mặc định, Sử dụng SSH Key

**Rate limiting nginx**
sudo nano /etc/nginx/nginx.conf
```
# zone=one:10m: đặt tên "one", dùng 10MB RAM (~160.000 IP)
# rate=30r/m: giới hạn 30 request/phút mỗi IP
limit_req_zone $binary_remote_addr zone=one:10m rate=30r/m;

# Giới hạn số kết nối đồng thời mỗi IP
limit_conn_zone $binary_remote_addr zone=addr:10m;
```
<img width="628" height="305" alt="{FDB0EC38-F879-4294-896F-9283C972DB1E}" src="https://github.com/user-attachments/assets/bcdc4419-4374-4bb4-9449-0edbda5602bf" />

```
location / {
    # Áp dụng zone "one", cho phép vọt lên 10 req tức thời (burst)
    # nodelay: không queue mà xử lý ngay (giảm độ trễ cho user thật)
    limit_req        zone=one burst=10 nodelay;
    # Tối đa 10 kết nối đồng thời từ 1 IP
    limit_conn       addr 10;
    # Trả về lỗi 429 thay vì 503 khi bị giới hạn
    limit_req_status 429;
}

# Trang login cần bảo vệ chặt hơn
location /login {
    limit_req zone=one burst=3 nodelay;
}

```
sudo nano /etc/nginx/sites-available/default
<img width="638" height="346" alt="{375278F9-962F-42EC-8235-5ACBE44A42C2}" src="https://github.com/user-attachments/assets/891b3e8c-8d19-429f-98e8-1ed41a23b5e0" />

---
**UFW**
```
sudo ufw default deny incoming
sudo ufw deny from 10.0.0.5
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 192.168.136.0/24 to any port 22         
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# max 6 kết nối/30 giây
sudo ufw limit ssh          
sudo ufw enable
sudo ufw status verbose
```
<img width="532" height="232" alt="{BE670787-4B9A-408D-B468-CF2009A066BE}" src="https://github.com/user-attachments/assets/fcdcd442-6eb2-4cbe-877d-e1e7b014a652" />

**iptables**
```
iptables -F && iptables -X
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Cho phép loopback và kết nối đã thiết lập
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

```
* Chống SYN Flood
```
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 4 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
```
LƯU RULE  
sudo apt install iptables-persistent -y  
iptables-save > /etc/iptables/rules.v4  
## Chống Brute Force
**Fail2Ban** theo dõi log, phát hiện pattern này và tự động chặn IP đó trong X giờ. Không cần can thiệp thủ công.  
* Cài đặt và bật Fail2Ban
sudo apt update && sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

<img width="864" height="241" alt="{BA56F15F-DB9B-43A6-8033-9AE2D558023D}" src="https://github.com/user-attachments/assets/ddabc014-e96e-47eb-a190-4ef26c0d2865" />

Tạo file cấu hình local (KHÔNG sửa jail.conf)  
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local  
sudo nano /etc/fail2ban/jail.local  
```
[DEFAULT]
# bantime: bao lâu thì bị ban (giây). 3600 = 1 giờ
bantime  = 3600
# findtime: khoảng thời gian theo dõi (giây). 600 = 10 phút
findtime = 600
# maxretry: số lần thất bại tối đa trong findtime trước khi bị ban
maxretry = 5
# ignoreip: IP không bao giờ bị ban (IP của bạn, local network)
ignoreip = 127.0.0.1/8 192.168.136.0/24
```
<img width="640" height="111" alt="{D6E794D6-A2F9-4695-9DB4-553BF367E542}" src="https://github.com/user-attachments/assets/9a5f7d11-ec3f-48cc-bf08-485475fed32b" />

```
[sshd]
# Bảo vệ SSH — kích hoạt jail này
enabled = true

[nginx-limit-req]
# Bảo vệ Nginx khỏi request quá nhiều
enabled  = true
logpath  = /var/log/nginx/error.log
maxretry = 10
```
<img width="376" height="153" alt="{03146D8C-5E5B-47AA-9730-2D3BA6862BA1}" src="https://github.com/user-attachments/assets/9376625e-7ca6-4f74-a3f7-544f442594d7" />
**iptables**
```
# SSH brute force protection
iptables -A INPUT -p tcp --dport 22 -m recent --name SSH --set
iptables -A INPUT -p tcp --dport 22 -m recent --name SSH \
  --rcheck --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```


 ## Hardening server
 sudo systemctl list-units --type=service --state=running: xem dịch vụ đang chạy
 <img width="795" height="361" alt="{0506C1CE-50CF-4ADC-98E4-79A2E3CBB5F8}" src="https://github.com/user-attachments/assets/1de94f7f-99ce-42b0-8812-c8da0f05fa69" />
sudo systemctl disable --now xxx avahi-daemon bluetooth: Tắt các dịch vụ không cần
Bật tự động cập nhật bảo mật  
sudo apt install unattended-upgrades -y  
sudo dpkg-reconfigure --priority=low unattended-upgrades  
<img width="474" height="115" alt="{76370678-419D-402E-B8FC-08116DF71371}" src="https://github.com/user-attachments/assets/18d51037-a88d-4461-a20d-42901e0008d9" />
sudo apt install lynis -y && sudo lynis audit system: check lỗ hổng 
<img width="803" height="398" alt="{9CB003FE-F735-401B-80C1-4DE94E3D14D3}" src="https://github.com/user-attachments/assets/fe8eb29e-b952-427f-9338-c968d84d8d63" />

## Xử lí lỗ hổng 
**SQL injection** 
file php 
```
<?php

try {
    $pdo = new PDO(
        'mysql:host=localhost;dbname=myapp;charset=utf8mb4',
        'dbuser',
        'dbpassword',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $e) {
    die('Database lỗi');
}

$id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);

if ($id === false || $id <= 0) {
    die('ID không hợp lệ');
}

$stmt = $pdo->prepare(
    "SELECT id,name,email FROM users WHERE id = ?"
);

$stmt->execute([$id]);

$user = $stmt->fetch();

if (!$user) {
    die('Không tìm thấy user');
}

echo "<h1>User Info</h1>";
echo "ID: " . $user['id'] . "<br>";
echo "Name: " . htmlspecialchars($user['name']) . "<br>";
echo "Email: " . htmlspecialchars($user['email']);

?>
```
Test bình thường  
<img width="468" height="177" alt="{8D993644-9A2E-4D54-BEF9-7205CDB6F415}" src="https://github.com/user-attachments/assets/22cb3436-2352-42ec-904a-00f62fb47a25" />

Hack thử http://192.168.136.131/page.php?id=1 OR 1=1  
<img width="463" height="148" alt="{16926AC1-F5F4-49D1-AA7C-260FA6E192A8}" src="https://github.com/user-attachments/assets/8650500b-a4f0-4c55-a564-2dadfa79be31" />
```
sudo apt install libapache2-mod-security2 -y
sudo cp /etc/modsecurity/modsecurity.conf-recommended \
        /etc/modsecurity/modsecurity.conf

# Bật chế độ ngăn chặn 
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' \
    /etc/modsecurity/modsecurity.conf

# Tải bộ rule OWASP CRS (Core Rule Set) — chuẩn công nghiệp
sudo apt install modsecurity-crs -y
sudo ln -s /usr/share/modsecurity-crs \
           /etc/apache2/modsecurity-crs

# Kích hoạt trong Apache VirtualHost
sudo nano /etc/apache2/sites-available/000-default.conf
apache<VirtualHost *:8080>
    SecRuleEngine On

    IncludeOptional /etc/apache2/modsecurity-crs/crs-setup.conf
    IncludeOptional /etc/apache2/modsecurity-crs/rules/*.conf

    # Ghi log khi phát hiện tấn công
    SecAuditLog /var/log/apache2/modsec_audit.log
    SecAuditLogParts ABIJDEFHZ
</VirtualHost>
sudo systemctl restart apache2
```
<img width="340" height="126" alt="{9838B494-B947-48CC-B01A-593688A805E2}" src="https://github.com/user-attachments/assets/6ed2a378-834e-4822-9483-746c15bc5382" />

**XSS**
XSS khác SQLi ở chỗ: hacker không tấn công server mà tấn công trình duyệt của người dùng khác thông qua server của bạn  
