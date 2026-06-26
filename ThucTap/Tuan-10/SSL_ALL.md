MỤC LỤC

PHẦN 1: Cài SSL trên Web Server thuần (CLI)
  1A. Apache VirtualHost :443
  1B. Nginx server block :443
  1C. Main domain + Subdomain cùng lúc

PHẦN 2: Cài SSL trên Control Panel
  2A. cPanel — AutoSSL + Thủ công
  2B. DirectAdmin — Let's Encrypt + Paste ngoài
  2C. Plesk — Extension + Manual

PHẦN 3: Auto-renewal Let's Encrypt
  3A. Certbot (apt — non-snap)
  3B. ACME.sh (siêu nhẹ)
  3C. Cronjob + Systemd Timer

PHẦN 4: ZeroSSL
  4A. Đăng ký + Lấy cert
  4B. HTTP Validation + DNS Validation
  4C. Tích hợp acme.sh

PHẦN 5: Troubleshooting 4 Case Study thực chiến

------------------

PHẦN 1 — CÀI SSL TRÊN WEB SERVER THUẦN
📁 Chuẩn bị: Đặt cert files đúng chỗ
Trước khi cấu hình Apache hay Nginx, cần đặt 3 file cert đúng vị trí chuẩn:
````
# Tạo thư mục lưu cert theo domain
mkdir -p /etc/ssl/nhanhoa/khachhang1.com

# Copy 3 file cert vào (KH cung cấp hoặc từ CA)
# - khachhang1.com.crt    → Certificate chính
# - khachhang1.com.key    → Private Key (TUYỆT MẬT)
# - khachhang1.com.ca     → CA Bundle (chain)

# Upload qua SCP từ máy local
scp khachhang1.com.crt root@IP_VPS:/etc/ssl/nhanhoa/khachhang1.com/
scp khachhang1.com.key root@IP_VPS:/etc/ssl/nhanhoa/khachhang1.com/
scp khachhang1.com.ca  root@IP_VPS:/etc/ssl/nhanhoa/khachhang1.com/

# Phân quyền bảo mật
chmod 644 /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt
chmod 644 /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.ca
chmod 600 /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.key
# ⚠️ Key PHẢI 600 — chỉ root đọc được

# Xác nhận files đã đúng chỗ
ls -la /etc/ssl/nhanhoa/khachhang1.com/
````
1A — APACHE: Cấu hình VirtualHost :443
Step 1: Bật module SSL
````
# Bật module ssl và headers
a2enmod ssl
a2enmod headers
a2enmod rewrite

# Kiểm tra module đã bật
apache2ctl -M | grep -E "ssl|headers|rewrite"
# Output phải thấy: ssl_module, headers_module, rewrite_module
````
Step 2: Tạo file VirtualHost cho HTTPS
````
# Tạo file config riêng cho SSL
nano /etc/apache2/sites-available/khachhang1.com-ssl.conf
Nội dung file chuẩn sản xuất:
apache# ============================================
# REDIRECT HTTP → HTTPS (Block :80)
# ============================================
<VirtualHost *:80>
    ServerName  khachhang1.com
    ServerAlias www.khachhang1.com

    # Redirect toàn bộ HTTP sang HTTPS
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>

# ============================================
# HTTPS BLOCK (Block :443)
# ============================================
<VirtualHost *:443>
    ServerName  khachhang1.com
    ServerAlias www.khachhang1.com

    # Thư mục web root
    DocumentRoot /var/www/khachhang1.com/public_html

    # ── SSL ENGINE ──────────────────────────
    SSLEngine on

    # File chứng chỉ chính của domain
    SSLCertificateFile    /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt

    # Private Key — PHẢI khớp với CRT
    SSLCertificateKeyFile /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.key

    # CA Bundle (chuỗi chứng chỉ trung gian)
    SSLCertificateChainFile /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.ca

    # ── BẢO MẬT TLS ─────────────────────────
    # Chỉ dùng TLS 1.2 và 1.3 (tắt TLS 1.0, 1.1 đã lỗi thời)
    SSLProtocol         all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite      ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets   off

    # ── SECURITY HEADERS ────────────────────
    Header always set Strict-Transport-Security \
      "max-age=63072000; includeSubDomains; preload"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"

    # ── LOGS ────────────────────────────────
    ErrorLog  ${APACHE_LOG_DIR}/khachhang1.com_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/khachhang1.com_ssl_access.log combined

    # ── PHP-FPM (nếu dùng) ──────────────────
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost"
    </FilesMatch>
</VirtualHost>
````
Step 3: Kích hoạt và kiểm tra
````
# Kích hoạt site SSL mới
a2ensite khachhang1.com-ssl.conf

# Kiểm tra cú pháp Apache (PHẢI chạy trước khi reload)
apache2ctl configtest
# Output phải là: Syntax OK

# Nếu Syntax OK → reload Apache
systemctl reload apache2

# Xác nhận Apache đang chạy
systemctl status apache2

# Test SSL từ command line
openssl s_client -connect khachhang1.com:443 -servername khachhang1.com \
  2>/dev/null | openssl x509 -noout -subject -dates -issuer
# Output mong đợi:
# subject=CN=khachhang1.com
# notBefore=...
# notAfter=...   ← Kiểm tra ngày hết hạn
# issuer=...     ← Tên CA đã cấp
````
⚠️ Troubleshooting Apache SSL
````
# Lỗi 1: "SSLCertificateFile: file not found"
ls -la /etc/ssl/nhanhoa/khachhang1.com/
# → Kiểm tra đường dẫn và tên file có khớp không

# Lỗi 2: "private key does not match certificate"
# → CRT và KEY không cùng bộ — KH gửi sai file
# Kiểm tra: fingerprint của CRT và KEY phải khớp
openssl x509 -noout -modulus -in khachhang1.com.crt | md5sum
openssl rsa  -noout -modulus -in khachhang1.com.key | md5sum
# Hai dòng md5sum PHẢI giống nhau

# Lỗi 3: "AH00526: Syntax error" không rõ dòng nào
apache2ctl configtest 2>&1 | grep -i "error"

# Lỗi 4: Port 443 không lắng nghe
ss -tlnp | grep 443
# Không thấy → Apache chưa start hoặc bị block firewall
ufw allow 443/tcp
systemctl restart apache2
````
1B — NGINX: Cấu hình server block :443
Step 1: Kiểm tra Nginx và tạo config
````
# Kiểm tra version Nginx
nginx -v

# Kiểm tra module ssl có sẵn không (Ubuntu 22.04 có mặc định)
nginx -V 2>&1 | grep -o with-http_ssl_module
# Output: with-http_ssl_module ← OK

# Tạo file config
nano /etc/nginx/sites-available/khachhang1.com
````
Step 2: Nội dung config Nginx chuẩn sản xuất
````
# ============================================
# REDIRECT HTTP → HTTPS
# ============================================
server {
    listen 80;
    listen [::]:80;
    server_name khachhang1.com www.khachhang1.com;

    # Redirect 301 toàn bộ sang HTTPS
    return 301 https://$host$request_uri;
}

# ============================================
# HTTPS BLOCK
# ============================================
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;                          # Bật HTTP/2 tăng tốc

    server_name khachhang1.com www.khachhang1.com;
    root /var/www/khachhang1.com/public_html;
    index index.php index.html;

    # ── SSL CERTIFICATES ────────────────────
    ssl_certificate     /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt;
    ssl_certificate_key /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.key;

    # CA Bundle — Nginx dùng fullchain (gộp CRT + CA)
    # Nếu có file .ca riêng, gộp lại:
    # cat khachhang1.com.crt khachhang1.com.ca > khachhang1.com.fullchain.crt
    # Rồi trỏ ssl_certificate vào fullchain

    # ── TLS SECURITY ────────────────────────
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    # Session cache tăng tốc TLS handshake
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # OCSP Stapling — tăng tốc xác thực cert
    ssl_stapling        on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.ca;
    resolver 8.8.8.8 8.8.4.4 valid=300s;

    # ── SECURITY HEADERS ────────────────────
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options           "SAMEORIGIN" always;
    add_header X-Content-Type-Options    "nosniff" always;
    add_header Referrer-Policy           "no-referrer-when-downgrade" always;

    # ── LOGS ────────────────────────────────
    access_log /var/log/nginx/khachhang1.com_ssl.access.log;
    error_log  /var/log/nginx/khachhang1.com_ssl.error.log;

    # ── PHP-FPM ─────────────────────────────
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # WordPress rewrite
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Chặn truy cập file ẩn
    location ~ /\. {
        deny all;
    }
}
````
Step 3: Tạo fullchain cho Nginx (quan trọng)
````
# Nginx cần file fullchain = CRT + CA Bundle gộp lại
cat /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt \
    /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.ca \
  > /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.fullchain.crt

# Cập nhật ssl_certificate trong config trỏ vào fullchain
sed -i 's/khachhang1.com.crt/khachhang1.com.fullchain.crt/' \
  /etc/nginx/sites-available/khachhang1.com
````
Step 4: Kích hoạt và kiểm tra
````
# Tạo symlink kích hoạt site
ln -s /etc/nginx/sites-available/khachhang1.com \
      /etc/nginx/sites-enabled/

# ── QUAN TRỌNG: Kiểm tra cú pháp TRƯỚC KHI reload
nginx -t
# Output phải là:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# Reload Nginx (không cắt kết nối đang có)
systemctl reload nginx

# Kiểm tra port 443 đang lắng nghe
ss -tlnp | grep ':443'

# Test SSL chi tiết
curl -vI https://khachhang1.com 2>&1 | grep -E "SSL|TLS|HTTP|subject|expire"
````
⚠️ Troubleshooting Nginx SSL
````
# Lỗi 1: "nginx: [emerg] cannot load certificate"
# Kiểm tra file cert có đúng format PEM không
head -1 /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt
# Phải thấy: -----BEGIN CERTIFICATE-----

# Lỗi 2: "SSL_CTX_use_PrivateKey_file failed"
# Key không khớp cert → kiểm tra modulus
openssl x509 -noout -modulus -in *.crt | md5sum
openssl rsa  -noout -modulus -in *.key | md5sum

# Lỗi 3: "conflicting server name" — 2 site cùng domain
grep -r "server_name khachhang1.com" /etc/nginx/sites-enabled/

# Lỗi 4: OCSP stapling lỗi (không ảnh hưởng HTTPS, chỉ chậm hơn)
# Comment tạm: ssl_stapling on; → ssl_stapling off;

````
1C — MAIN DOMAIN + SUBDOMAIN cùng lúc
Cách 1: Wildcard cert (1 cert dùng cho tất cả subdomain)
````
# Nếu KH có wildcard cert: *.khachhang1.com
# Tạo thư mục wildcard
mkdir -p /etc/ssl/nhanhoa/wildcard.khachhang1.com

# Upload cert wildcard vào đây
# Cert này cover: khachhang1.com, www., blog., shop., api., ...

````
Nginx config dùng chung 1 cert cho nhiều subdomain:   
nano /etc/nginx/sites-available/khachhang1.com-all   
````
# Cert wildcard dùng chung cho tất cả subdomain
# ── MAIN DOMAIN ─────────────────────────────────
server {
    listen 443 ssl;
    server_name khachhang1.com www.khachhang1.com;

    ssl_certificate     /etc/ssl/nhanhoa/wildcard.khachhang1.com/fullchain.crt;
    ssl_certificate_key /etc/ssl/nhanhoa/wildcard.khachhang1.com/wildcard.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/khachhang1.com/public_html;
    # ... các config khác
}

# ── SUBDOMAIN: blog ──────────────────────────────
server {
    listen 443 ssl;
    server_name blog.khachhang1.com;

    # Dùng CÙNG wildcard cert — không cần cert riêng
    ssl_certificate     /etc/ssl/nhanhoa/wildcard.khachhang1.com/fullchain.crt;
    ssl_certificate_key /etc/ssl/nhanhoa/wildcard.khachhang1.com/wildcard.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/khachhang1.com/blog;
    # ... các config khác
}

# ── SUBDOMAIN: shop ──────────────────────────────
server {
    listen 443 ssl;
    server_name shop.khachhang1.com;

    ssl_certificate     /etc/ssl/nhanhoa/wildcard.khachhang1.com/fullchain.crt;
    ssl_certificate_key /etc/ssl/nhanhoa/wildcard.khachhang1.com/wildcard.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/khachhang1.com/shop;
}
````
Cách 2: SAN cert (Subject Alternative Names — cert nhiều domain)
````
# SAN cert cover nhiều domain/subdomain khác nhau trong 1 cert
# Kiểm tra cert có SAN không
openssl x509 -noout -text \
  -in /etc/ssl/nhanhoa/khachhang1.com/khachhang1.com.crt \
  | grep -A5 "Subject Alternative Name"
# Output: DNS:khachhang1.com, DNS:www.khachhang1.com, DNS:blog.khachhang1.com

# Cách dùng: tương tự wildcard, trỏ ssl_certificate vào file SAN cert
# Mỗi server{} block dùng cùng 1 cert file
````
Cách 3: Cert riêng cho từng subdomain
````
# Cách tổ chức thư mục khuyến nghị cho nhiều subdomain:
/etc/ssl/nhanhoa/
├── khachhang1.com/
│   ├── fullchain.crt
│   └── private.key
├── blog.khachhang1.com/
│   ├── fullchain.crt
│   └── private.key
└── shop.khachhang1.com/
    ├── fullchain.crt
    └── private.key

# Mỗi server{} block trong Nginx trỏ ssl_certificate
# vào thư mục tương ứng của subdomain đó
````
PHẦN 2 — CÀI SSL TRÊN CONTROL PANEL
2A — cPANEL
AutoSSL (Let's Encrypt tự động)
````
# ── DÀNH CHO KTV (Root WHM) ───────────────────────
WHM → SSL/TLS → Manage AutoSSL
→ Provider: Let's Encrypt (hoặc Sectigo)
→ Click "Install" nếu chưa có provider

# Chạy AutoSSL cho 1 user cụ thể:
WHM → SSL/TLS → Manage AutoSSL
→ Tab "Manage Users"
→ Tìm username KH → Click "Run AutoSSL"

# Hoặc chạy toàn bộ:
→ "Run AutoSSL for All Users"
→ Chờ 2-5 phút
bash# Chạy AutoSSL qua CLI (nhanh hơn GUI)
/usr/local/cpanel/bin/autossl_check --user=username_KH

# Force renew dù cert chưa hết hạn
/usr/local/cpanel/bin/autossl_check --user=username_KH --force

# Xem log AutoSSL
tail -f /var/cpanel/logs/autossl_check.log

# Xem chi tiết lỗi
tail -100 /var/cpanel/logs/autossl_check.log | grep -i "error\|fail\|warn"
Cài SSL trả phí thủ công trên cPanel
# ── DÀNH CHO KH (cPanel User) ─────────────────────
cPanel → Security → SSL/TLS
→ "Certificates (CRT)" → "Generate, view, upload, or delete SSL certificates"
→ Click "Upload a New Certificate"
→ Paste nội dung file .crt vào ô
→ Click "Save Certificate"

# Sau đó:
→ "Install and Manage SSL for your site (HTTPS)"
→ "Manage SSL Sites"
→ Chọn domain
→ Điền Certificate (CRT), Private Key (KEY), CA Bundle
→ "Install Certificate"
````
````
# Cài SSL thủ công qua WHM CLI cho KTV
# Bước 1: Upload cert lên server
# Bước 2: Cài cert qua whmapi
whmapi1 installssl \
  domain=khachhang1.com \
  cert="$(cat /tmp/khachhang1.crt)" \
  key="$(cat /tmp/khachhang1.key)" \
  cabundle="$(cat /tmp/khachhang1.ca)"
⚠️ Troubleshooting cPanel SSL
bash# Lỗi 1: AutoSSL báo "DCV Error" — domain chưa trỏ đúng
# Kiểm tra domain trỏ về IP server không
dig +short khachhang1.com
# Phải trả về IP của server cPanel

# Lỗi 2: "Rate limit exceeded" — Let's Encrypt block
# Kiểm tra tại: https://crt.sh/?q=khachhang1.com
# Nếu đã cấp >5 cert/tuần → đợi hoặc dùng ZeroSSL

# Lỗi 3: SSL cài xong nhưng vẫn HTTP
/usr/local/cpanel/scripts/rebuildhttpdconf
systemctl reload httpd  # hoặc apache2

2B — DIRECTADMIN
Let's Encrypt trong DirectAdmin
# ── DÀNH CHO USER ─────────────────────────────────
Đăng nhập DA User (port 2222)
→ Account Manager → SSL Certificates
→ Chọn domain từ dropdown
→ Tab "Let's Encrypt"
→ Tick chọn: domain.com và www.domain.com
→ Click "Save"
→ Chờ 30-60 giây → Thấy "Certificate saved successfully"
bash# Cài Let's Encrypt qua DA CLI
# (Dùng khi GUI bị lỗi hoặc cần batch nhiều domain)
/usr/local/directadmin/scripts/letsencrypt.sh \
  request khachhang1.com 4096

# Xem log LE của DA
tail -50 /var/log/directadmin/errortaskq.log | grep -i "ssl\|cert"
Paste SSL cert từ bên ngoài vào DA
User Panel → Account Manager → SSL Certificates
→ Chọn domain
→ Tab "Paste a pre-generated certificate and key"

Ô "Certificate": Paste nội dung file .crt
Ô "Private Key": Paste nội dung file .key
→ Click "Save"

# Sau đó thêm CA Bundle:
→ Tab "CA Root Certificate"
→ Paste nội dung file .ca hoặc .ca-bundle
→ Click "Save"
bash# Xác nhận cert đã cài đúng trong DA
ls -la /usr/local/directadmin/data/users/USERNAME/domains/khachhang1.com.cert
ls -la /usr/local/directadmin/data/users/USERNAME/domains/khachhang1.com.key

# Kiểm tra Apache/Nginx config DA tạo ra
cat /etc/httpd/conf/extra/directadmin-vhosts.conf | \
  grep -A20 "khachhang1.com"
⚠️ Troubleshooting DirectAdmin SSL
bash# Lỗi 1: "Error: Couldn't get challenge"
# → Domain chưa trỏ về IP server DA
dig +short khachhang1.com

# Lỗi 2: Sau khi cài cert, web vẫn HTTP
# → Bật SSL trong DA config
echo "ssl=1" >> \
  /usr/local/directadmin/data/users/USERNAME/domains/khachhang1.com.conf
# Restart DA
systemctl restart directadmin

# Lỗi 3: "Key does not match certificate"
openssl x509 -noout -modulus -in *.cert | md5sum
openssl rsa  -noout -modulus -in *.key  | md5sum

2C — PLESK
Let's Encrypt qua Extension
# ── CÀI EXTENSION LET'S ENCRYPT ───────────────────
Plesk Admin → Extensions → Extensions Catalog
→ Search: "Let's Encrypt"
→ Install (miễn phí)

# Sau khi cài:
Plesk → Websites & Domains → khachhang1.com
→ SSL/TLS Certificates
→ "Let's Encrypt"
→ Điền email
→ Tick: "Include www.khachhang1.com"
→ Tick: "Secure webmail"  ← Tùy chọn
→ "Get it free"
→ Chờ 1-2 phút
Cài SSL trả phí trong Plesk
Plesk → Websites & Domains → khachhang1.com
→ SSL/TLS Certificates → Add SSL/TLS Certificate

Điền:
Certificate name:  Sectigo_2026
→ Upload files:
   - Certificate (.crt)
   - Private key (.key)
   - CA certificate (.ca-bundle)
→ Upload Certificate

# Sau đó gán cert cho domain:
→ Websites & Domains → Hosting Settings
→ Security → SSL/TLS certificate
→ Chọn "Sectigo_2026" từ dropdown
→ OK
bash# Cài SSL Plesk qua CLI
plesk bin certificate \
  --create khachhang1.com \
  -domain khachhang1.com \
  -cert /tmp/khachhang1.crt \
  -key  /tmp/khachhang1.key \
  -cacert /tmp/khachhang1.ca

# Gán cert vào domain
plesk bin domain \
  --update khachhang1.com \
  -certificate-name khachhang1.com

PHẦN 3 — AUTO-RENEWAL LET'S ENCRYPT
3A — CERTBOT (Cài qua apt — không dùng snap)
Cài đặt
bash# Ubuntu 22.04 — cài qua apt (KHÔNG dùng snap)
apt update
apt install -y certbot

# Cài thêm plugin theo web server
apt install -y python3-certbot-apache   # Cho Apache
apt install -y python3-certbot-nginx    # Cho Nginx

# Kiểm tra version
certbot --version
# Output: certbot 1.x.x hoặc 2.x.x
4 Phương thức xác thực
bash# ── PHƯƠNG THỨC 1: --apache (Tự động cấu hình Apache) ──
# Certbot TỰ ĐỘNG sửa VirtualHost, thêm SSL directives
certbot --apache -d khachhang1.com -d www.khachhang1.com \
  --email admin@nhanhoa.com \
  --agree-tos \
  --no-eff-email
# ✅ Dễ nhất | ⚠️ Có thể conflict nếu config Apache phức tạp

# ── PHƯƠNG THỨC 2: --nginx (Tự động cấu hình Nginx) ──
certbot --nginx -d khachhang1.com -d www.khachhang1.com \
  --email admin@nhanhoa.com \
  --agree-tos \
  --no-eff-email
# ✅ Dễ | ⚠️ Tương tự apache plugin

# ── PHƯƠNG THỨC 3: --webroot (An toàn nhất cho production) ──
# Certbot tạo file vào thư mục web, không động vào config
certbot certonly \
  --webroot \
  -w /var/www/khachhang1.com/public_html \
  -d khachhang1.com \
  -d www.khachhang1.com \
  --email admin@nhanhoa.com \
  --agree-tos \
  --no-eff-email
# ✅ Không sửa config | Cần trỏ cert thủ công vào Apache/Nginx

# ── PHƯƠNG THỨC 4: --standalone (Không cần web server chạy) ──
# Certbot tự tạo web server tạm trên port 80
systemctl stop nginx   # Tắt web server trước
certbot certonly \
  --standalone \
  -d khachhang1.com \
  -d www.khachhang1.com \
  --email admin@nhanhoa.com \
  --agree-tos
systemctl start nginx  # Bật lại
# ✅ Dùng khi web server đang lỗi | ⚠️ Downtime ngắn
Cert files sau khi cấp
bash# Certbot lưu cert tại:
ls -la /etc/letsencrypt/live/khachhang1.com/
# cert.pem       → Certificate chính (= .crt)
# chain.pem      → CA Bundle (= .ca)
# fullchain.pem  → cert + chain gộp lại (dùng cho Nginx)
# privkey.pem    → Private Key (= .key)

# Trỏ Apache/Nginx vào cert của Certbot:
# Apache:
SSLCertificateFile    /etc/letsencrypt/live/khachhang1.com/cert.pem
SSLCertificateKeyFile /etc/letsencrypt/live/khachhang1.com/privkey.pem
SSLCertificateChainFile /etc/letsencrypt/live/khachhang1.com/chain.pem

# Nginx:
ssl_certificate     /etc/letsencrypt/live/khachhang1.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/khachhang1.com/privkey.pem;
Test renew và Cron
bash# Test renew (không thực sự renew — chỉ kiểm tra)
certbot renew --dry-run

# Renew thủ công tất cả cert sắp hết hạn
certbot renew

# Renew 1 domain cụ thể
certbot renew --cert-name khachhang1.com

# Reload web server sau khi renew
certbot renew --post-hook "systemctl reload nginx"
# Hoặc Apache:
certbot renew --post-hook "systemctl reload apache2"

# ── THIẾT LẬP CRON TỰ ĐỘNG ──────────────────────────
crontab -e
# Thêm dòng này (chạy 2 lần/ngày — best practice):
0 3,15 * * * certbot renew --quiet \
  --post-hook "systemctl reload nginx" >> \
  /var/log/certbot-renew.log 2>&1

# Kiểm tra cron đã thêm
crontab -l | grep certbot

# Xem log renew
tail -50 /var/log/certbot-renew.log
tail -50 /var/log/letsencrypt/letsencrypt.log

3B — ACME.SH (Siêu nhẹ, không cần root)
bash# ── CÀI ĐẶT ACME.SH ────────────────────────────────
curl https://get.acme.sh | sh -s email=admin@nhanhoa.com

# Reload shell để dùng được lệnh acme.sh
source ~/.bashrc
# Hoặc:
export PATH="$HOME/.acme.sh:$PATH"

# Kiểm tra
acme.sh --version

# ── CẤP CERT VỚI WEBROOT MODE ──────────────────────
acme.sh --issue \
  -d khachhang1.com \
  -d www.khachhang1.com \
  --webroot /var/www/khachhang1.com/public_html

# ── CẤP CERT VỚI NGINX MODE ────────────────────────
acme.sh --issue \
  -d khachhang1.com \
  --nginx

# ── CẤP CERT VỚI STANDALONE ────────────────────────
acme.sh --issue \
  -d khachhang1.com \
  --standalone \
  --httpport 80

# ── INSTALL CERT VÀO THƯ MỤC SẢN XUẤT ─────────────
# Tạo thư mục lưu cert production
mkdir -p /etc/ssl/nhanhoa/khachhang1.com

acme.sh --install-cert \
  -d khachhang1.com \
  --cert-file      /etc/ssl/nhanhoa/khachhang1.com/cert.crt \
  --key-file       /etc/ssl/nhanhoa/khachhang1.com/cert.key \
  --fullchain-file /etc/ssl/nhanhoa/khachhang1.com/fullchain.crt \
  --reloadcmd      "systemctl reload nginx"
# acme.sh tự tạo cron renew và chạy --reloadcmd sau khi renew

# ── KIỂM TRA CRON TỰ ĐỘNG CỦA ACME.SH ─────────────
crontab -l | grep acme
# Output: 30 0 * * * "/root/.acme.sh"/acme.sh --cron ...

# Xem tất cả cert đang quản lý
acme.sh --list

# Force renew
acme.sh --renew -d khachhang1.com --force

3C — SYSTEMD TIMER (Thay thế Cron chuyên nghiệp hơn)
bash# Tạo service file
cat > /etc/systemd/system/certbot-renew.service << 'EOF'
[Unit]
Description=Certbot Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet \
  --post-hook "systemctl reload nginx"
EOF

# Tạo timer file — chạy 2 lần/ngày
cat > /etc/systemd/system/certbot-renew.timer << 'EOF'
[Unit]
Description=Run Certbot renewal twice daily
After=network.target

[Timer]
OnCalendar=*-*-* 03,15:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Kích hoạt timer
systemctl daemon-reload
systemctl enable certbot-renew.timer
systemctl start  certbot-renew.timer

# Kiểm tra timer
systemctl list-timers | grep certbot
# Output:
# Sat 2026-06-27 03:00:00 → certbot-renew.timer

# Test chạy thủ công
systemctl start certbot-renew.service
journalctl -u certbot-renew.service -n 20

PHẦN 4 — ZEROSSL
4A — Đăng ký và lấy cert
bash# ZeroSSL là CA miễn phí thứ 2 sau Let's Encrypt
# Ưu điểm: Rate limit cao hơn LE, dashboard web đẹp
# Trang: https://app.zerossl.com

# ── ĐĂNG KÝ TÀI KHOẢN ──────────────────────────────
# Vào https://app.zerossl.com → Sign Up (miễn phí)
# Gói Free: 3 cert DV 90 ngày đồng thời

# ── LẤY EAB CREDENTIALS ────────────────────────────
# ZeroSSL dùng External Account Binding (EAB)
# Dashboard → Developer → EAB Credentials → Generate
# Lưu lại: EAB_KID và EAB_HMAC_KEY
4B — Xác thực domain
HTTP File Validation
bash# ZeroSSL tạo file cần đặt tại:
# http://khachhang1.com/.well-known/acme-challenge/TOKEN

# Tạo thư mục
mkdir -p /var/www/khachhang1.com/public_html/.well-known/acme-challenge/

# Đặt file xác thực (ZeroSSL cung cấp nội dung)
echo "TOKEN_VALUE.THUMBPRINT_VALUE" > \
  /var/www/khachhang1.com/public_html/.well-known/acme-challenge/TOKEN_FILE

# Kiểm tra truy cập được không
curl http://khachhang1.com/.well-known/acme-challenge/TOKEN_FILE
# Phải thấy nội dung token

# Sau khi ZeroSSL xác thực → Tải về:
# certificate.crt  + private.key + ca_bundle.crt
DNS CNAME Validation
bash# ZeroSSL cung cấp CNAME record dạng:
# _CF8A2E1B4D.khachhang1.com CNAME xxxxx.zerossl.com

# Thêm vào DNS Zone của domain:
# Tên: _CF8A2E1B4D
# Loại: CNAME
# Giá trị: xxxxx.zerossl.com

# Kiểm tra CNAME đã propagate chưa
dig CNAME _CF8A2E1B4D.khachhang1.com
# Phải thấy: xxxxx.zerossl.com

# Sau khi xác thực → click "Verify Domain" trên dashboard
4C — Tích hợp ZeroSSL vào acme.sh
bash# ── ĐĂNG KÝ ZEROSSL LÀM DEFAULT CA ────────────────
acme.sh --register-account \
  -m admin@nhanhoa.com \
  --server zerossl \
  --eab-kid   "EAB_KID_TỪ_DASHBOARD" \
  --eab-hmac-key "EAB_HMAC_KEY_TỪ_DASHBOARD"

# ── CẤP CERT TỪ ZEROSSL ────────────────────────────
acme.sh --issue \
  -d khachhang1.com \
  -d www.khachhang1.com \
  --webroot /var/www/khachhang1.com/public_html \
  --server zerossl

# ── CHUYỂN ĐỔI NHANH GIỮA LE VÀ ZEROSSL ───────────
# Dùng Let's Encrypt:
acme.sh --set-default-ca --server letsencrypt

# Dùng ZeroSSL:
acme.sh --set-default-ca --server zerossl

# ── TÍCH HỢP CERTBOT VỚI ZEROSSL ───────────────────
certbot certonly \
  --server https://acme.zerossl.com/v2/DV90 \
  --eab-kid   "EAB_KID_TỪ_DASHBOARD" \
  --eab-hmac-key "EAB_HMAC_KEY_TỪ_DASHBOARD" \
  --email admin@nhanhoa.com \
  --agree-tos \
  --webroot \
  -w /var/www/khachhang1.com/public_html \
  -d khachhang1.com \
  -d www.khachhang1.com

PHẦN 5 — TROUBLESHOOTING 4 CASE STUDY THỰC CHIẾN

🔴 CASE 1: Xung đột cổng 80/443 — Apache vs Nginx
Triệu chứng:
Job for apache2.service failed
(98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
Chẩn đoán và xử lý:
bash# BƯỚC 1: Tìm process đang chiếm port
ss -tlnp | grep -E ':80|:443'
# Hoặc
lsof -i :80
lsof -i :443

# Output ví dụ:
# nginx  1234  root  6u  IPv4  tcp *:80  → Nginx đang chiếm port 80!

# BƯỚC 2: Xác định service nào đang chạy
systemctl is-active apache2 nginx
# active  active  → Cả 2 đang chạy — đây là vấn đề

# BƯỚC 3A: Nếu muốn chỉ dùng Apache
systemctl stop nginx
systemctl disable nginx
systemctl start apache2
# Kiểm tra
ss -tlnp | grep ':80'

# BƯỚC 3B: Nếu muốn dùng Nginx làm reverse proxy trước Apache
# Nginx lắng nghe 80/443 → Forward về Apache port 8080
# Sửa Apache listen port:
sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' \
  /etc/apache2/sites-enabled/khachhang1.com.conf
systemctl restart apache2

# Nginx config reverse proxy:
nano /etc/nginx/sites-available/khachhang1.com
nginxserver {
    listen 80;
    server_name khachhang1.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name khachhang1.com;

    ssl_certificate     /etc/letsencrypt/live/khachhang1.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/khachhang1.com/privkey.pem;

    # Forward tất cả về Apache đang chạy port 8080
    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
    }
}
bash# Restart cả 2
systemctl restart apache2 nginx

# Xác nhận không còn conflict
ss -tlnp | grep -E ':80|:443|:8080'
# Phải thấy: nginx:80, nginx:443, apache2:8080

🔴 CASE 2: Certbot lỗi NXDOMAIN — Domain chưa trỏ DNS
Triệu chứng:
FAILED challenges:
  dns problem: NXDOMAIN looking up A for www.khachhang1.com
  - check that a DNS record exists for this domain
Chẩn đoán và xử lý:
bash# BƯỚC 1: Kiểm tra DNS đang resolve ra sao
dig +short A khachhang1.com
dig +short A www.khachhang1.com
# Nếu output trống → domain chưa có A record hoặc chưa propagate

# BƯỚC 2: Xem domain đang trỏ về đâu
dig +short A khachhang1.com @8.8.8.8    # Hỏi Google DNS
dig +short A khachhang1.com @1.1.1.1    # Hỏi Cloudflare DNS
# Nếu trả về IP khác IP server → KH trỏ sai

# BƯỚC 3: Kiểm tra DNS propagation toàn cầu
# Truy cập: https://dnschecker.org/#A/khachhang1.com
# Hoặc dùng CLI:
for dns in 8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9; do
  echo -n "DNS $dns: "
  dig +short A khachhang1.com @$dns
done

# BƯỚC 4: Nếu domain chưa trỏ đúng
# → Hướng dẫn KH vào DNS Manager thêm/sửa A record:
# Loại: A
# Host: @ (hoặc để trống)
# Giá trị: IP_VPS
# TTL: 300 (5 phút để test nhanh)

# Và cho www:
# Loại: CNAME (hoặc A)
# Host: www
# Giá trị: khachhang1.com (hoặc IP trực tiếp)

# BƯỚC 5: Sau khi KH sửa DNS, đợi propagate rồi chạy lại
# Kiểm tra đã propagate chưa:
watch -n5 'dig +short A khachhang1.com'
# Ctrl+C khi thấy IP đúng

# BƯỚC 6: Chạy lại Certbot
certbot certonly --webroot \
  -w /var/www/khachhang1.com/public_html \
  -d khachhang1.com -d www.khachhang1.com \
  --email admin@nhanhoa.com --agree-tos

# BƯỚC 7: Nếu cần cấp cert NGAY KHI chưa có A record
# Dùng DNS challenge (không cần port 80):
certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d khachhang1.com \
  -d www.khachhang1.com
# Certbot sẽ yêu cầu thêm TXT record vào DNS
# Thêm xong → nhấn Enter → Certbot tự xác thực

🔴 CASE 3: apt/dpkg bị lock — Không cài được Certbot
Triệu chứng:
E: Could not get lock /var/lib/dpkg/lock-frontend
E: Unable to acquire the dpkg frontend lock
dpkg: error: dpkg status database is locked by another process
Chẩn đoán và xử lý:
bash# BƯỚC 1: Tìm process đang giữ lock
lsof /var/lib/dpkg/lock-frontend
lsof /var/lib/apt/lists/lock
lsof /var/cache/apt/archives/lock

# Output ví dụ:
# apt  12345  root  4uW  REG  lock  → PID 12345 đang giữ lock

# BƯỚC 2A: Nếu là tiến trình hợp lệ đang chạy
# Kiểm tra PID đó là gì
ps aux | grep 12345
# Nếu là apt/unattended-upgrade đang chạy thật → ĐỢI nó xong
# Theo dõi: watch -n2 'ps aux | grep apt'

# BƯỚC 2B: Nếu là tiến trình zombie (đã chết nhưng lock còn)
# Kill process
kill -9 12345

# Xóa lock files
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock

# BƯỚC 3: Fix dpkg bị broken (do MariaDB/MySQL cài lỗi)
dpkg --configure -a
# Lệnh này sẽ tiếp tục cài các package bị dở dang

# Nếu dpkg --configure -a báo lỗi MariaDB:
apt install -f -y
# Hoặc
DEBIAN_FRONTEND=noninteractive dpkg --configure -a

# BƯỚC 4: Fix lỗi MariaDB cụ thể (hay gặp tại Nhân Hòa)
# Lỗi: "mariadb.service failed to start"
mkdir -p /etc/mysql
touch /etc/mysql/mariadb.cnf
dpkg --configure -a
apt install -f -y

# BƯỚC 5: Reset apt hoàn toàn nếu vẫn lỗi
apt clean
apt update
apt install -f -y

# BƯỚC 6: Cài Certbot
apt install -y certbot python3-certbot-nginx

🔴 CASE 4: Mixed Content — HTTPS bật nhưng vẫn "Not Secure"
Triệu chứng:

Chrome báo: ⚠️ "Not Secure" dù đã cài SSL
DevTools Console: Mixed Content: The page was loaded over HTTPS, but requested an insecure resource 'http://...'

Chẩn đoán và xử lý:
bash# BƯỚC 1: Xác định resource nào đang dùng HTTP
# Mở Chrome DevTools (F12) → Console → Lọc "Mixed Content"
# Hoặc scan từ server:
grep -r "http://" /var/www/khachhang1.com/public_html/ \
  --include="*.php" \
  --include="*.html" \
  --include="*.js" \
  -l | head -20
# List các file có chứa http://
Fix cho WordPress (phổ biến nhất tại Nhân Hòa)
bash# BƯỚC 2A: Fix qua WP-CLI (nhanh nhất)
# Cài WP-CLI nếu chưa có
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Replace toàn bộ http → https trong database
cd /var/www/khachhang1.com/public_html
wp search-replace 'http://khachhang1.com' 'https://khachhang1.com' \
  --all-tables \
  --allow-root
# Output: Success: Made X replacements

# BƯỚC 2B: Fix qua MySQL trực tiếp
mysql -u root -p << 'EOF'
USE khachhang1_db;

-- Fix siteurl và home
UPDATE wp_options
SET option_value = REPLACE(option_value,
  'http://khachhang1.com',
  'https://khachhang1.com')
WHERE option_name IN ('siteurl', 'home');

-- Fix nội dung posts
UPDATE wp_posts
SET post_content = REPLACE(post_content,
  'http://khachhang1.com',
  'https://khachhang1.com');

-- Fix post meta (featured images, etc.)
UPDATE wp_postmeta
SET meta_value = REPLACE(meta_value,
  'http://khachhang1.com',
  'https://khachhang1.com');
EOF
Fix ở tầng Nginx/Apache — Force HTTPS cho toàn bộ resource
bash# BƯỚC 3A: Fix qua Nginx — Thêm header upgrade
nano /etc/nginx/sites-available/khachhang1.com
nginxserver {
    listen 443 ssl;
    # ... config khác ...

    # Upgrade tất cả insecure request lên HTTPS
    add_header Content-Security-Policy \
      "upgrade-insecure-requests" always;
}
bash# BƯỚC 3B: Fix qua Apache — Thêm vào .htaccess
cat >> /var/www/khachhang1.com/public_html/.htaccess << 'EOF'

# Fix Mixed Content — Upgrade insecure requests
<IfModule mod_headers.c>
    Header always set Content-Security-Policy "upgrade-insecure-requests"
</IfModule>

# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
EOF

# Reload Apache
systemctl reload apache2
bash# BƯỚC 4: Xóa cache WordPress
# Nếu dùng W3 Total Cache, WP Super Cache, LiteSpeed Cache:
wp cache flush --allow-root

# BƯỚC 5: Xác nhận đã fix
curl -s https://khachhang1.com | \
  grep -o 'http://[^"]*' | \
  grep -v "https://" | \
  head -10
# Nếu output trống → Không còn mixed content

# Test SSL grade
# https://www.ssllabs.com/ssltest/analyze.html?d=khachhang1.com
# Mục tiêu: Grade A hoặc A+

📋 BẢNG TỔNG HỢP QUICK REFERENCE
Tình huốngLệnh kiểm tra nhanhCert còn hạn bao lâuopenssl s_client -connect domain:443 2>/dev/null | openssl x509 -noout -enddateKey có khớp CRT khôngopenssl x509 -modulus -in *.crt | md5sum vs openssl rsa -modulus -in *.key | md5sumPort 443 có mở khôngss -tlnp | grep ':443'Nginx config có lỗi khôngnginx -tApache config có lỗi khôngapache2ctl configtestCert chain có đúng khôngopenssl verify -CAfile chain.pem cert.pemDNS trỏ đúng chưadig +short A domain.com @8.8.8.8apt locklsof /var/lib/dpkg/lock-frontendMixed contentgrep -r "http://" /var/www/ --include="*.php" -lRenew Certbotcertbot renew --dry-run
