# VirtualHost Templates — SSL Ready (Apache / Nginx / Tomcat)

---

## 1. NGINX 

**File:** `/etc/nginx/conf.d/DOMAIN.conf`

```nginx
# ══════════════════════════════════════════════════════════════
#  NGINX VirtualHost Template — SSL Ready
#  Sửa: DOMAIN | USER | CERT_PATH
# ══════════════════════════════════════════════════════════════

# ── [1] HTTP → HTTPS redirect ────────────────────────────────
server {
    listen      80;
    listen      [::]:80;
    server_name DOMAIN www.DOMAIN;

    # Let's Encrypt renewal vẫn đi qua HTTP
    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# ── [2] HTTPS main block ──────────────────────────────────────
server {
    listen      443 ssl;
    listen      [::]:443 ssl;
    http2       on;                           
    server_name DOMAIN www.DOMAIN;

    # ── SSL ──────────────────────────────────────────────────
    ssl_certificate     CERT_PATH/fullchain.crt;   # public.crt + ca.crt gộp lại
    ssl_certificate_key CERT_PATH/private.key;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    # ── Security Headers ─────────────────────────────────────
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options           "SAMEORIGIN"                          always;
    add_header X-Content-Type-Options    "nosniff"                             always;
    add_header Referrer-Policy           "strict-origin-when-cross-origin"     always;
    add_header Content-Security-Policy   "default-src 'self' https: 'unsafe-inline'" always;
    server_tokens off;

    # ── Web root & logs ──────────────────────────────────────
    root  /home/USER/public_html;
    index index.php index.html index.htm;

    access_log /var/log/nginx/DOMAIN-access.log;
    error_log  /var/log/nginx/DOMAIN-error.log;

    # ── Static files cache ───────────────────────────────────
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg)$ {
        expires     30d;
        add_header  Cache-Control "public, no-transform";
        access_log  off;
    }

    # ── PHP-FPM ──────────────────────────────────────────────
    location ~ \.php$ {
        try_files      $uri =404;
        fastcgi_pass   unix:/var/run/USER-fpm.sock;   # hoặc 127.0.0.1:9000
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_read_timeout 120;
    }

    # ── WordPress permalink (bỏ comment nếu cài WP) ──────────
    # location / {
    #     try_files $uri $uri/ /index.php$is_args$args;
    # }

    # ── Chặn truy cập file nhạy cảm ─────────────────────────
    location ~ /\.(ht|git|env) {
        deny all;
    }
    location ~ /wp-config\.php {
        deny all;
    }

    # ── Trang lỗi ────────────────────────────────────────────
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

**Kiểm tra & áp dụng:**
```bash
nginx -t && systemctl reload nginx
```

---

## 2. APACHE

**File:** `/etc/httpd/conf.d/DOMAIN.conf` (CentOS)
hoặc `/etc/apache2/sites-available/DOMAIN.conf` (Ubuntu)

```apache
# ══════════════════════════════════════════════════════════════
#  APACHE VirtualHost Template — SSL Ready
#  Sửa: DOMAIN | USER | CERT_PATH
# ══════════════════════════════════════════════════════════════

# ── [1] HTTP → HTTPS redirect ────────────────────────────────
<VirtualHost *:80>
    ServerName  DOMAIN
    ServerAlias www.DOMAIN

    # Let's Encrypt renewal
    Alias /.well-known/acme-challenge/ /var/www/letsencrypt/.well-known/acme-challenge/
    <Directory "/var/www/letsencrypt/.well-known/acme-challenge/">
        Options None
        AllowOverride None
        Require all granted
    </Directory>

    RewriteEngine On
    RewriteCond   %{REQUEST_URI} !^/.well-known/acme-challenge/
    RewriteRule   ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>

# ── [2] HTTPS main block ──────────────────────────────────────
<VirtualHost *:443>
    ServerName  DOMAIN
    ServerAlias www.DOMAIN
    ServerAdmin webmaster@DOMAIN

    # ── Web root & logs ──────────────────────────────────────
    DocumentRoot /home/USER/public_html
    ErrorLog     /var/log/httpd/DOMAIN-error.log
    CustomLog    /var/log/httpd/DOMAIN-access.log combined

    <Directory /home/USER/public_html>
        Options       -Indexes +FollowSymLinks
        AllowOverride All   
        Require       all granted
    </Directory>

    # ── SSL ──────────────────────────────────────────────────
    SSLEngine             on
    SSLCertificateFile    CERT_PATH/public.crt
    SSLCertificateKeyFile CERT_PATH/private.key
    SSLCACertificateFile  CERT_PATH/ca.crt 

    SSLProtocol           all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite        ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder   off
    SSLSessionTickets     off

    # ── HTTP/2 (cần mod_http2) ───────────────────────────────
    Protocols h2 http/1.1

    # ── Security Headers ─────────────────────────────────────
    <IfModule mod_headers.c>
        Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
        Header always set X-Frame-Options           "SAMEORIGIN"
        Header always set X-Content-Type-Options    "nosniff"
        Header always set Referrer-Policy           "strict-origin-when-cross-origin"
        Header always set Content-Security-Policy   "default-src 'self' https: 'unsafe-inline'"
        Header unset  Server
    </IfModule>
    ServerTokens Prod
    ServerSignature Off

    # ── PHP-FPM qua Unix Socket ──────────────────────────────
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/USER-fpm.sock|fcgi://localhost"
    </FilesMatch>

    # ── Static cache ─────────────────────────────────────────
    <FilesMatch "\.(jpg|jpeg|png|gif|ico|css|js|woff2|svg)$">
        <IfModule mod_expires.c>
            ExpiresActive on
            ExpiresDefault "access plus 30 days"
        </IfModule>
    </FilesMatch>

    # ── Chặn file nhạy cảm ───────────────────────────────────
    <FilesMatch "^(\.htaccess|\.env|wp-config\.php)$">
        Require all denied
    </FilesMatch>
</VirtualHost>
```

**Kiểm tra & áp dụng:**
```bash
# Ubuntu
a2ensite DOMAIN.conf
a2enmod  ssl headers rewrite http2
apachectl configtest && systemctl reload apache2

# CentOS
apachectl configtest && systemctl reload httpd
```

---

## 3. TOMCAT (Nginx làm SSL Termination)

> **Best practice:** Không expose Tomcat trực tiếp ra internet. Để **Nginx xử lý SSL**, Tomcat chỉ nhận request nội bộ qua HTTP.

### 3a. Nginx — Reverse Proxy → Tomcat

**File:** `/etc/nginx/conf.d/DOMAIN.conf`

```nginx
# ══════════════════════════════════════════════════════════════
#  NGINX → TOMCAT Reverse Proxy Template — SSL Ready
#  Sửa: DOMAIN | CERT_PATH | APP_PORT (mặc định 8080)
# ══════════════════════════════════════════════════════════════

# ── [1] HTTP → HTTPS redirect ────────────────────────────────
server {
    listen      80;
    listen      [::]:80;
    server_name DOMAIN www.DOMAIN;
    return 301  https://$host$request_uri;
}

# ── [2] HTTPS → Tomcat ───────────────────────────────────────
server {
    listen      443 ssl;
    listen      [::]:443 ssl;
    http2       on;
    server_name DOMAIN www.DOMAIN;

    # ── SSL ──────────────────────────────────────────────────
    ssl_certificate     CERT_PATH/fullchain.crt;
    ssl_certificate_key CERT_PATH/private.key;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    # ── Security Headers ─────────────────────────────────────
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options           "SAMEORIGIN"                          always;
    add_header X-Content-Type-Options    "nosniff"                             always;
    server_tokens off;

    # ── Logs ─────────────────────────────────────────────────
    access_log /var/log/nginx/DOMAIN-access.log;
    error_log  /var/log/nginx/DOMAIN-error.log;

    # ── Static files (Nginx serve trực tiếp, không qua Tomcat)
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg|pdf)$ {
        root    /home/USER/public_html/static;   # thư mục static riêng
        expires 30d;
        access_log off;
        try_files $uri @tomcat;                  # fallback về Tomcat nếu không có
    }

    # ── Proxy → Tomcat ───────────────────────────────────────
    location / {
        proxy_pass         http://127.0.0.1:APP_PORT;
        proxy_http_version 1.1;

        # Headers quan trọng — Tomcat cần biết client thật
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;    # ← để Tomcat biết request là HTTPS
        proxy_set_header   Connection        "";

        # Timeout
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    120s;

        # Buffer
        proxy_buffers         16 16k;
        proxy_buffer_size     32k;
    }

    location @tomcat {
        proxy_pass http://127.0.0.1:APP_PORT;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # ── Trang lỗi ────────────────────────────────────────────
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

---

### 3b. Tomcat — `server.xml` (lắng nghe nội bộ)

**File:** `/opt/tomcat/conf/server.xml`

```xml
<!-- ══════════════════════════════════════════════════════════
     TOMCAT server.xml — Chạy sau Nginx reverse proxy
     Sửa: APP_PORT | DOMAIN
═══════════════════════════════════════════════════════════════ -->

<Server port="8005" shutdown="SHUTDOWN">

  <Service name="Catalina">

    <!-- Connector nội bộ — chỉ nghe localhost, KHÔNG expose ra ngoài -->
    <Connector
        port="APP_PORT"
        protocol="HTTP/1.1"
        address="127.0.0.1"
        connectionTimeout="20000"
        redirectPort="443"

        <!-- Quan trọng: nói cho Tomcat biết request đến từ HTTPS proxy -->
        scheme="https"
        secure="true"
        proxyName="DOMAIN"
        proxyPort="443"
    />

    <Engine name="Catalina" defaultHost="localhost">

      <Host name="localhost" appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <!-- Ghi log riêng cho từng host -->
        <Valve className="org.apache.catalina.valves.AccessLogValve"
               directory="logs"
               prefix="DOMAIN_access_log"
               suffix=".log"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
```

**Kiểm tra & restart Tomcat:**
```bash
# Kiểm tra port Tomcat đang listen
ss -tlnp | grep APP_PORT

# Restart
systemctl restart tomcat

# Kiểm tra log Tomcat
tail -f /opt/tomcat/logs/catalina.out
```

---

## 4. Gộp fullchain.crt 

```bash
# Gộp cert + chain thành fullchain (Nginx cần)
cat CERT_PATH/public.crt CERT_PATH/ca.crt > CERT_PATH/fullchain.crt

# Phân quyền đúng
chmod 600 CERT_PATH/private.key
chmod 644 CERT_PATH/fullchain.crt
chmod 644 CERT_PATH/public.crt
chmod 644 CERT_PATH/ca.crt
chown -R root:root CERT_PATH/  
```

---

## 5. Checklist sau khi cài SSL

```bash
# 1. Test cú pháp config
nginx -t                               # Nginx
apachectl configtest                   # Apache

# 2. Reload (không restart — tránh gián đoạn)
systemctl reload nginx
systemctl reload httpd

# 3. Kiểm tra HTTPS
curl -I https://DOMAIN

# 4. Kiểm tra redirect HTTP → HTTPS
curl -I http://DOMAIN

# 5. Kiểm tra cert hết hạn khi nào
echo | openssl s_client -connect DOMAIN:443 2>/dev/null \
  | openssl x509 -noout -dates

# 6. Kiểm tra chain đầy đủ không
openssl s_client -connect DOMAIN:443 -showcerts 2>/dev/null \
  | grep "subject\|issuer"
```

---



## 6. NGINX REVERSE PROXY → APACHE (Nginx làm frontend SSL)

> **Use case thực tế:** Server đang chạy Apache (shared hosting, DA, cPanel), muốn thêm Nginx phía trước để xử lý SSL termination + cache static + tăng hiệu suất. Apache đổi sang port 8080, Nginx đứng port 80/443.

### 6a. Đổi Apache sang port 8080

```bash
# CentOS — /etc/httpd/conf/httpd.conf
# Ubuntu — /etc/apache2/ports.conf
```

```apache
# Sửa Listen 80 → Listen 8080
Listen 8080
```

```apache
# Sửa VirtualHost *:80 → *:8080
<VirtualHost *:8080>
    ServerName DOMAIN
    ...
</VirtualHost>
```

```bash
# Restart Apache
systemctl restart httpd      # CentOS
systemctl restart apache2    # Ubuntu
```

### 6b. Nginx config — SSL termination + proxy → Apache

**File:** `/etc/nginx/conf.d/DOMAIN.conf`

```nginx
# ══════════════════════════════════════════════════════════════
#  NGINX → APACHE Reverse Proxy Template — SSL Ready
#  Sửa: DOMAIN | CERT_PATH
#  Apache chạy port 8080 nội bộ
# ══════════════════════════════════════════════════════════════

# ── [1] HTTP → HTTPS ─────────────────────────────────────────
server {
    listen      80;
    listen      [::]:80;
    server_name DOMAIN www.DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# ── [2] HTTPS → Apache 8080 ──────────────────────────────────
server {
    listen      443 ssl;
    listen      [::]:443 ssl;
    http2       on;
    server_name DOMAIN www.DOMAIN;

    # ── SSL ──────────────────────────────────────────────────
    ssl_certificate     CERT_PATH/fullchain.crt;
    ssl_certificate_key CERT_PATH/private.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    # ── Security Headers ─────────────────────────────────────
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options           "SAMEORIGIN"       always;
    add_header X-Content-Type-Options    "nosniff"          always;
    server_tokens off;

    # ── Logs ─────────────────────────────────────────────────
    access_log /var/log/nginx/DOMAIN-access.log;
    error_log  /var/log/nginx/DOMAIN-error.log;

    # ── Static: Nginx tự serve, KHÔNG chuyển về Apache ───────
    # Tiết kiệm tài nguyên Apache, Nginx serve static nhanh hơn
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg|pdf|txt)$ {
        root    /home/USER/public_html;
        expires 30d;
        access_log off;
        try_files $uri @apache;    # không tìm thấy thì fallback Apache
    }

    # ── Dynamic: forward về Apache ───────────────────────────
    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_http_version 1.1;

        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;    # Apache biết client dùng HTTPS
        proxy_set_header   Connection        "";

        # Fix redirect loop — Apache không tự redirect sang HTTPS nữa
        proxy_redirect     http://DOMAIN/ https://DOMAIN/;

        proxy_connect_timeout 60s;
        proxy_read_timeout    120s;
    }

    location @apache {
        proxy_pass       http://127.0.0.1:8080;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 6c. Apache VirtualHost (port 8080, nhận từ Nginx)

```apache
# ══════════════════════════════════════════════════════════════
#  APACHE VirtualHost — Chạy sau Nginx Reverse Proxy
#  Port 8080, chỉ nghe localhost
#  Sửa: DOMAIN | USER
# ══════════════════════════════════════════════════════════════

<VirtualHost 127.0.0.1:8080>
    ServerName  DOMAIN
    ServerAlias www.DOMAIN

    DocumentRoot /home/USER/public_html
    ErrorLog     /var/log/httpd/DOMAIN-error.log
    CustomLog    /var/log/httpd/DOMAIN-access.log combined

    <Directory /home/USER/public_html>
        Options       -Indexes +FollowSymLinks
        AllowOverride All
        Require       all granted
    </Directory>

    # Quan trọng: Trust header từ Nginx proxy
    # Cần mod_remoteip để Apache log đúng IP client thật
    RemoteIPHeader       X-Forwarded-For
    RemoteIPTrustedProxy 127.0.0.1

    # Không redirect sang HTTPS ở tầng Apache
    # (Nginx đã lo rồi — tránh redirect loop)
</VirtualHost>
```

```bash
# Ubuntu: enable mod_remoteip
a2enmod remoteip
systemctl reload apache2
```

> **Lỗi hay gặp — redirect loop:** Apache có `RewriteRule` force HTTPS trong `.htaccess` → Nginx gửi request HTTP xuống Apache → Apache redirect HTTPS → Nginx lại gửi HTTP → loop vô tận. Fix: thêm điều kiện trong `.htaccess`:
> ```apache
> RewriteCond %{HTTP:X-Forwarded-Proto} !https
> RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
> ```

---

## 7. DIRECTADMIN — Cài SSL

> DA quản lý cert theo từng user/domain. Có 2 luồng: Let's Encrypt (1 click) và SSL trả phí (paste thủ công).

### 7a. Let's Encrypt (miễn phí, tự động)

```
User Level
→ Advanced Features
→ SSL Certificates
→ ● Free & automatic certificate from Let's Encrypt
→ Tích: DOMAIN + www.DOMAIN
→ Save
```

DA tự động:
- Tạo CSR + private key
- Chạy ACME challenge (HTTP-01 qua port 80)
- Nhận cert → ghi vào Apache/Nginx config
- Cron tự renew trước 30 ngày hết hạn

**Điều kiện:** DNS bản ghi A của DOMAIN phải trỏ đúng về IP server trước.

---

### 7b. SSL Trả phí — Paste thủ công

**Bước 1: Tạo CSR**
```
User Level → Advanced Features → SSL Certificates
→ ● Generate a Certificate Request (CSR)
→ Điền: Key Size=2048, Common Name=DOMAIN, Country=VN, ...
→ Save
```
Copy CSR → gửi nhà cung cấp SSL.

**Bước 2: Paste cert nhận về**
```
→ ● Paste a pre-generated certificate and key
```

```
[Certificate] box: paste nội dung public.crt
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----

[Key] box: paste private.key (DA đã lưu sẵn từ lúc tạo CSR)
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
```
→ Save

**Bước 3: Paste CA Bundle**
```
→ Click "Save" xong kéo xuống
→ [CA Root Certificate] box: paste nội dung ca.crt
→ Save
```

**Bước 4: Force HTTPS**
```
User Level → Domain Setup → chọn DOMAIN
→ ✅ Force SSL with https redirect
→ Save
```

**Kiểm tra qua SSH:**
```bash
# Xem cert DA đang dùng cho domain
cat /usr/local/directadmin/data/users/USER/domains/DOMAIN.conf | grep ssl

# Cert lưu ở đây
ls /usr/local/directadmin/data/users/USER/domains/
# DOMAIN.key   DOMAIN.cert   DOMAIN.cacert
```

---

### 7c. DA Admin — Cài SSL cho hostname server

```
Admin Level → Admin Tools → SSL Certificates
→ Paste cert cho hostname server (server.nhanhoa.com)
→ Hoặc dùng Let's Encrypt cho hostname
```

```bash
# Hoặc SSH
/usr/local/directadmin/scripts/letsencrypt.sh request_single \
  server.nhanhoa.com 4096
```

---

## 8. CPANEL — Cài SSL

### 8a. Let's Encrypt / AutoSSL (tự động)

cPanel có **AutoSSL** chạy tự động mỗi ngày — thường không cần làm gì.

Kiểm tra trạng thái:
```
WHM (root) → SSL/TLS → Manage AutoSSL
→ Xem domain nào đang có SSL, domain nào fail
→ Click "Run AutoSSL for All Users" nếu muốn force chạy ngay
```

Nếu 1 user bị fail:
```
WHM → Manage AutoSSL → chọn user → Run AutoSSL
```

**Lý do hay fail AutoSSL:**
- DNS chưa trỏ đúng về IP server
- Domain đang dùng Cloudflare proxy (cam) → tắt proxy (xám) rồi chạy lại
- Port 80 bị chặn firewall

---

### 8b. SSL Trả phí — Upload qua WHM

```
WHM (root)
→ SSL/TLS → Install an SSL Certificate on a Domain
```

```
Domain    : DOMAIN
Certificate (CRT): paste public.crt
Private Key       : paste private.key
Certificate Authority Bundle (CABUNDLE): paste ca.crt
→ Install
```

Hoặc qua cPanel user:
```
cPanel → Security → SSL/TLS
→ Manage SSL Sites
→ Browse Certificates → chọn domain
→ Paste cert + key + bundle
→ Install Certificate
```

---

### 8c. Force HTTPS trong cPanel

```
cPanel → Domains → Domains
→ Toggle "Redirect to HTTPS" = ON
```

Hoặc thêm vào `.htaccess`:
```apache
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

**Kiểm tra cert qua SSH:**
```bash
# Cert cPanel lưu ở
ls /var/cpanel/ssl/installed/
# hoặc
/usr/local/cpanel/bin/ssl_info DOMAIN
```

---

## 9. AAPANEL — Cài SSL

> aaPanel dùng giao diện đồ họa đơn giản, phù hợp VPS cá nhân.

### 9a. Let's Encrypt (miễn phí)

```
aaPanel → Website → chọn DOMAIN → Settings
→ SSL → Let's Encrypt
→ Chọn domain + www.DOMAIN
→ Apply
```

aaPanel tự chạy Certbot → lưu cert vào `/www/server/panel/vhost/cert/DOMAIN/`.

---

### 9b. SSL Trả phí — Paste thủ công

```
aaPanel → Website → chọn DOMAIN → Settings
→ SSL → Other Certificate
```

```
[Certificate (PEM format)]: paste public.crt + ca.crt (gộp lại)
-----BEGIN CERTIFICATE-----
(nội dung public.crt)
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
(nội dung ca.crt)
-----END CERTIFICATE-----

[Private Key (PEM format)]: paste private.key
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----

→ Save
```

**Force HTTPS:**
```
→ Bật toggle "Force HTTPS"
→ Save
```

**Cert lưu ở:**
```bash
ls /www/server/panel/vhost/cert/DOMAIN/
# fullchain.pem  privkey.pem
```

**Nginx config aaPanel sinh ra tại:**
```bash
cat /www/server/panel/vhost/nginx/DOMAIN.conf
```

---

### 9c. aaPanel Nginx config mẫu (sinh tự động, tham khảo)

```nginx
server {
    listen      80;
    server_name DOMAIN www.DOMAIN;
    return 301  https://$host$request_uri;
}
server {
    listen      443 ssl http2;
    server_name DOMAIN www.DOMAIN;

    ssl_certificate     /www/server/panel/vhost/cert/DOMAIN/fullchain.pem;
    ssl_certificate_key /www/server/panel/vhost/cert/DOMAIN/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root  /www/wwwroot/DOMAIN;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass   unix:/tmp/php-cgi-82.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}
```

---

## 10. PLESK — Cài SSL

### 10a. Let's Encrypt

```
Plesk → Websites & Domains → chọn DOMAIN
→ SSL/TLS Certificates
→ Get it free (Let's Encrypt)
→ Điền email
→ ✅ Secure the domain
→ ✅ Secure www.DOMAIN
→ Get it Free
```

---

### 10b. SSL Trả phí — Upload

```
Plesk → Websites & Domains → DOMAIN
→ SSL/TLS Certificates → Add SSL/TLS Certificate
```

```
Certificate name : SSL_DOMAIN_2026
Private key      : paste private.key
Certificate      : paste public.crt
CA certificate   : paste ca.crt
→ Upload Certificate
```

Sau đó apply vào domain:
```
→ Websites & Domains → DOMAIN
→ Hosting Settings
→ SSL/TLS certificate: chọn SSL_DOMAIN_2026
→ ✅ Redirect from http to https
→ OK
```

---

### 10c. Plesk — SSL qua CLI

```bash
# List cert hiện có
plesk bin certificate --list -domain DOMAIN

# Cài cert mới
plesk bin certificate --create SSL_DOMAIN_2026 \
  -domain DOMAIN \
  -key-file  /tmp/private.key \
  -cert-file /tmp/public.crt \
  -cacert-file /tmp/ca.crt

# Apply cho domain
plesk bin domain --update DOMAIN \
  -certificate-name SSL_DOMAIN_2026

# Bật redirect HTTPS
plesk bin domain --update DOMAIN \
  -https-redirect true
```

**Cert Plesk lưu ở:**
```bash
ls /usr/local/psa/var/certificates/
```

---


