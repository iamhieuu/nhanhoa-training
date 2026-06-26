# 📚 Sổ Tay Kỹ Thuật Viên — Nhân Hòa
> **Phiên bản:** 1.0 — Ubuntu/Debian | Cập nhật: 2026  
> **Mục tiêu:** Tài liệu tham chiếu nhanh dùng trong công việc hàng ngày  
> **Phạm vi:** Domain & DNS · SSL/TLS · Email Server · VPS/Server Linux

---

## 📋 MỤC LỤC

- [**PHẦN 1 — DOMAIN & DNS**](#phần-1--domain--dns)
  - [1.1 Tổng quan DNS](#11-tổng-quan-dns)
  - [1.2 Các loại bản ghi DNS](#12-các-loại-bản-ghi-dns)
  - [1.3 Cấu hình Zone File trên BIND9](#13-cấu-hình-zone-file-trên-bind9)
  - [1.4 Trỏ domain về server — Tình huống thực tế](#14-trỏ-domain-về-server--tình-huống-thực-tế)
  - [1.5 DNSSEC](#15-dnssec)
  - [1.6 Lệnh kiểm tra DNS bắt buộc phải thuộc](#16-lệnh-kiểm-tra-dns-bắt-buộc-phải-thuộc)
  - [1.7 Lỗi DNS thường gặp & cách fix](#17-lỗi-dns-thường-gặp--cách-fix)

- [**PHẦN 2 — SSL/TLS**](#phần-2--ssltls)
  - [2.1 Cài Let's Encrypt trên Nginx & Apache](#21-cài-lets-encrypt-trên-nginx--apache)
  - [2.2 Wildcard SSL](#22-wildcard-ssl)
  - [2.3 Cài Cert Trả Phí Thủ Công (Comodo/Sectigo)](#23-cài-cert-trả-phí-thủ-công-commodosectigo)
  - [2.4 Hardening SSL — Đạt điểm A/A+ SSL Labs](#24-hardening-ssl--đạt-điểm-aa-ssl-labs)
  - [2.5 Auto-Renew & Giám sát Cert Expiry](#25-auto-renew--giám-sát-cert-expiry)
  - [2.6 Xử lý khẩn cấp — Cert hết hạn](#26-xử-lý-khẩn-cấp--cert-hết-hạn)
  - [2.7 Lỗi SSL thường gặp & cách fix](#27-lỗi-ssl-thường-gặp--cách-fix)

- [**PHẦN 3 — VPS & SERVER LINUX**](#phần-3--vps--server-linux)
  - [3.1 SSH & Quản lý User](#31-ssh--quản-lý-user)
  - [3.2 LEMP Stack — Cài đặt & cấu hình](#32-lemp-stack--cài-đặt--cấu-hình)
  - [3.3 Nginx Tuning — Tối ưu hiệu suất](#33-nginx-tuning--tối-ưu-hiệu-suất)
  - [3.4 MySQL/MariaDB Optimization](#34-mysqlmariadb-optimization)
  - [3.5 Giám sát tài nguyên & xử lý quá tải](#35-giám-sát-tài-nguyên--xử-lý-quá-tải)
  - [3.6 Firewall & Bảo mật Server](#36-firewall--bảo-mật-server)
  - [3.7 Backup & Khôi phục](#37-backup--khôi-phục)

- [**PHẦN 4 — EMAIL SERVER**](#phần-4--email-server)
  - [4.1 SPF, DKIM, DMARC — Xác thực email](#41-spf-dkim-dmarc--xác-thực-email)
  - [4.2 Cấu hình mail hosting cho khách](#42-cấu-hình-mail-hosting-cho-khách)
  - [4.3 Troubleshoot mail — Không nhận/gửi được mail](#43-troubleshoot-mail--không-nhậngửi-được-mail)
  - [4.4 Xử lý Blacklist & Spam](#44-xử-lý-blacklist--spam)

- [**PHẦN 5 — QUY TRÌNH XỬ LÝ TICKET**](#phần-5--quy-trình-xử-lý-ticket)
  - [5.1 Quy trình nhận & xử lý ticket](#51-quy-trình-nhận--xử-lý-ticket)
  - [5.2 Ticket thường gặp & script xử lý nhanh](#52-ticket-thường-gặp--script-xử-lý-nhanh)

- [**PHẦN 6 — CHEAT SHEET TỔNG HỢP**](#phần-6--cheat-sheet-tổng-hợp)

---

---

# PHẦN 1 — DOMAIN & DNS

## 1.1 Tổng quan DNS

```
Người dùng gõ nhanhoa.com
        ↓
Trình duyệt hỏi DNS Resolver (8.8.8.8 / 1.1.1.1)
        ↓
Resolver hỏi Root → TLD (.com) → Authoritative Nameserver
        ↓
Nhận IP (ví dụ: 103.101.162.x)
        ↓
Kết nối đến server
```

**Các khái niệm quan trọng:**
- **TTL (Time To Live):** Thời gian DNS cache giữ bản ghi. TTL cao → thay đổi lâu có hiệu lực. Trước khi đổi IP → hạ TTL xuống 300 (5 phút).
- **Propagation:** Thời gian thay đổi DNS lan ra toàn cầu. Thông thường 5–30 phút, tối đa 48 giờ.
- **Authoritative NS:** Nameserver quản lý zone của domain. Tại Nhân Hòa thường là `ns1.nhanhoa.vn`, `ns2.nhanhoa.vn`.

---

## 1.2 Các loại bản ghi DNS

| Bản ghi | Công dụng | Ví dụ |
|---------|-----------|-------|
| **A** | Trỏ domain → IPv4 | `nhanhoa.com → 103.101.162.1` |
| **AAAA** | Trỏ domain → IPv6 | `nhanhoa.com → 2001:db8::1` |
| **CNAME** | Alias — trỏ domain → domain khác | `www → nhanhoa.com` |
| **MX** | Mail server của domain | `nhanhoa.com → mail.nhanhoa.com (priority 10)` |
| **TXT** | Lưu text — dùng cho SPF, DKIM, xác minh | `v=spf1 ip4:103.x.x.x ~all` |
| **NS** | Nameserver quản lý domain | `ns1.nhanhoa.vn` |
| **SOA** | Thông tin zone chính | Serial, Refresh, Retry, Expire |
| **PTR** | Reverse DNS — IP → domain | Dùng cho mail server, tránh spam |
| **SRV** | Dịch vụ đặc biệt (VoIP, game) | Ít gặp |

> ⚠️ **Quy tắc vàng:** KHÔNG được dùng CNAME cho root domain `@`. Phải dùng A record.

---

## 1.3 Cấu hình Zone File trên BIND9

### Cài đặt BIND9

```bash
sudo apt update && sudo apt install -y bind9 bind9utils dnsutils
sudo systemctl enable --now bind9
sudo systemctl status bind9
```

### Khai báo zone

```bash
sudo nano /etc/bind/named.conf.local
```

```
zone "nhanhoalab.local" {
    type master;
    file "/etc/bind/zones/db.nhanhoalab.local";
};
```

### Tạo zone file

```bash
sudo mkdir -p /etc/bind/zones
sudo nano /etc/bind/zones/db.nhanhoalab.local
```

```
$TTL    604800
@   IN  SOA     ns1.nhanhoalab.local. admin.nhanhoalab.local. (
                2026062601  ; Serial  ← TĂNG SỐ NÀY MỖI KHI SỬA FILE
                604800      ; Refresh
                86400       ; Retry
                2419200     ; Expire
                604800 )    ; Negative Cache TTL

; Name servers
@       IN  NS      ns1.nhanhoalab.local.

; A records
ns1     IN  A       192.168.136.145
@       IN  A       192.168.136.145
www     IN  A       192.168.136.145
mail    IN  A       192.168.136.145

; Mail exchanger
@       IN  MX  10  mail.nhanhoalab.local.

; CNAME
ftp     IN  CNAME   www.nhanhoalab.local.

; SPF
@       IN  TXT     "v=spf1 ip4:192.168.136.145 ~all"
```

### Kiểm tra & reload

```bash
# Kiểm tra cú pháp
sudo named-checkconf
sudo named-checkzone nhanhoalab.local /etc/bind/zones/db.nhanhoalab.local

# Reload (nhẹ hơn restart, không drop connection)
sudo systemctl reload bind9
```

> ⚠️ **Bắt buộc:** Mỗi lần sửa zone file phải tăng số **Serial** lên. Format gợi ý: `YYYYMMDDxx` (vd: `2026062601`).

---

## 1.4 Trỏ domain về server — Tình huống thực tế

### Tình huống 1: Khách mua hosting + domain tại Nhân Hòa
Nameserver đã trỏ về Nhân Hòa → chỉ cần sửa A record trong DNS Manager.

```
@       IN  A   103.x.x.x      ← IP server hosting
www     IN  A   103.x.x.x
```

### Tình huống 2: Khách có domain ở nơi khác (GoDaddy, PA, Mắt Bão...)
Hai lựa chọn:
- **Đổi Nameserver** về Nhân Hòa → sau đó quản lý DNS tại Nhân Hòa
- **Giữ NS cũ, thêm record trực tiếp** tại nơi đăng ký

### Tình huống 3: Khách trỏ về VPS/Dedicated riêng

```
@       IN  A   [IP VPS của khách]
www     IN  A   [IP VPS của khách]
```

### Tình huống 4: Khách dùng Google Workspace

```
; MX records cho Google Workspace
@   IN  MX  1   ASPMX.L.GOOGLE.COM.
@   IN  MX  5   ALT1.ASPMX.L.GOOGLE.COM.
@   IN  MX  5   ALT2.ASPMX.L.GOOGLE.COM.
@   IN  MX  10  ALT3.ASPMX.L.GOOGLE.COM.
@   IN  MX  10  ALT4.ASPMX.L.GOOGLE.COM.

; SPF cho Google
@   IN  TXT  "v=spf1 include:_spf.google.com ~all"
```

### Tình huống 5: Khách dùng subdomain trỏ riêng

```
blog    IN  A       5.6.7.8
shop    IN  A       5.6.7.8
api     IN  CNAME   api.provider.com.    ← CNAME cho subdomain thì được
```

### Quy trình fix khi domain chưa vào được sau khi trỏ

```bash
# 1. Kiểm tra A record
dig abc.com A +short

# 2. Kiểm tra trên nhiều DNS server
dig @8.8.8.8 abc.com A +short      # Google
dig @1.1.1.1 abc.com A +short      # Cloudflare

# 3. Xem TTL còn bao nhiêu
dig abc.com A | grep -i ttl

# 4. Hướng dẫn khách flush DNS
# Windows: ipconfig /flushdns
# macOS:   sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
# Linux:   sudo systemd-resolve --flush-caches

# 5. Bảo khách đổi DNS tạm sang 8.8.8.8 nếu ISP cache lâu
```

---

## 1.5 DNSSEC

DNSSEC ký số vào bản ghi DNS → ngăn chặn DNS spoofing/cache poisoning.

```bash
# Bật DNSSEC trên BIND9
sudo nano /etc/bind/named.conf.options
```

```
options {
    dnssec-enable yes;
    dnssec-validation auto;
    dnssec-lookaside auto;
};
```

```bash
# Tạo Zone Signing Key (ZSK)
cd /etc/bind/zones/
sudo dnssec-keygen -a RSASHA256 -b 1024 -n ZONE nhanhoalab.local

# Tạo Key Signing Key (KSK)
sudo dnssec-keygen -a RSASHA256 -b 2048 -f KSK -n ZONE nhanhoalab.local

# Ký zone
sudo dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) \
    -N INCREMENT -o nhanhoalab.local -t \
    /etc/bind/zones/db.nhanhoalab.local

# Cập nhật named.conf.local để dùng zone đã ký
sudo systemctl reload bind9

# Kiểm tra DNSSEC
dig nhanhoalab.local DNSKEY
dig nhanhoalab.local +dnssec
```

---

## 1.6 Lệnh kiểm tra DNS bắt buộc phải thuộc

```bash
# Kiểm tra A record
dig abc.com A
nslookup abc.com

# Kiểm tra MX (mail server)
dig abc.com MX

# Kiểm tra TXT (SPF/DKIM)
dig abc.com TXT

# Kiểm tra NS (nameserver)
dig abc.com NS

# Kiểm tra bằng DNS server cụ thể
dig @8.8.8.8 abc.com A        # Google DNS
dig @1.1.1.1 abc.com A        # Cloudflare DNS

# Xem toàn bộ bản ghi
dig abc.com ANY +noall +answer

# Kiểm tra propagation nhanh
dig @8.8.8.8 abc.com A +short
dig @1.1.1.1 abc.com A +short
dig @9.9.9.9  abc.com A +short

# Reverse DNS (IP → domain) — quan trọng cho mail server
dig -x 103.101.162.x

# Xem TTL hiện tại
dig abc.com A | grep -i "ttl\|answer"
```

**Công cụ online:**

| Công cụ | URL | Dùng để |
|---------|-----|---------|
| whatsmydns | whatsmydns.net | Xem propagation toàn cầu |
| dnschecker | dnschecker.org | Check nhiều DNS server cùng lúc |
| mxtoolbox | mxtoolbox.com | Check MX, blacklist, SPF, DKIM |
| intodns | intodns.com | Audit toàn bộ DNS config |

---

## 1.7 Lỗi DNS thường gặp & cách fix

| Triệu chứng | Nguyên nhân | Cách fix |
|-------------|-------------|----------|
| Khách nói "trỏ rồi mà không vào được" | DNS chưa propagate / TTL cũ cao | Hỏi TTL cũ, hướng dẫn flush cache / đổi DNS sang 8.8.8.8 |
| Website vào được nhưng mail không hoạt động | Sai/thiếu MX record | `dig domain MX` → kiểm tra và sửa |
| Subdomain không resolve | Thiếu A/CNAME record cho subdomain | Thêm record, reload BIND |
| CNAME cho root domain | Sai kỹ thuật (CNAME conflict) | Đổi thành A record |
| `named-checkzone` báo lỗi | Quên tăng Serial hoặc cú pháp sai | Tăng Serial, kiểm tra từng dòng |
| SERVFAIL | Zone file sai cú pháp | Chạy `named-checkzone` xem dòng lỗi cụ thể |
| Port 53 bị block | UFW chặn | `sudo ufw allow 53` |

---
---

# PHẦN 2 — SSL/TLS

## 2.1 Cài Let's Encrypt trên Nginx & Apache

### Điều kiện bắt buộc trước khi cài

```bash
# 1. Domain đã trỏ A record về IP server chưa?
dig abc.com A +short
# → Phải ra đúng IP server

# 2. Port 80 đang mở?
ufw status | grep 80
ss -tlnp | grep :80

# 3. Web server đang chạy và có config cho domain?
nginx -t        # hoặc apache2ctl configtest
```

### Cài Certbot

```bash
apt update
apt install certbot -y
apt install python3-certbot-nginx -y    # Plugin Nginx
apt install python3-certbot-apache -y   # Plugin Apache
```

### Cài SSL cho Nginx

```bash
# Single domain
certbot --nginx -d abc.com -d www.abc.com

# Nhiều domain cùng lúc
certbot --nginx -d site1.com -d www.site1.com -d site2.com

# Chỉ lấy cert, tự config Nginx (dùng khi muốn kiểm soát cấu hình)
certbot certonly --nginx -d abc.com -d www.abc.com
```

Certbot tự động sửa Nginx config thành:

```nginx
server {
    listen 443 ssl;
    server_name abc.com www.abc.com;

    ssl_certificate     /etc/letsencrypt/live/abc.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/abc.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name abc.com www.abc.com;
    return 301 https://$host$request_uri;
}
```

### Cài SSL cho Apache

```bash
# Bật module cần thiết
a2enmod ssl
a2enmod rewrite
systemctl restart apache2

# Cài SSL
certbot --apache -d xyz.com -d www.xyz.com
```

```bash
# Kích hoạt site SSL
a2ensite xyz.com-le-ssl.conf
systemctl reload apache2
```

### Kiểm tra sau khi cài

```bash
curl -I https://abc.com
# Phải thấy: HTTP/2 200

openssl s_client -connect abc.com:443 -servername abc.com < /dev/null 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates
```

---

## 2.2 Wildcard SSL

Dùng khi khách có nhiều subdomain: `shop.abc.com`, `blog.abc.com`, `api.abc.com`...

```bash
# Wildcard BẮT BUỘC xác minh qua DNS
certbot certonly --manual --preferred-challenges dns \
    -d abc.com -d "*.abc.com"
```

**Quy trình:**

```
Bước 1: Certbot hiện yêu cầu tạo TXT record:
        _acme-challenge.abc.com → xYz123AbCdEf...

Bước 2: Vào DNS Manager Nhân Hòa → thêm TXT record:
        Host: _acme-challenge
        Value: xYz123AbCdEf...
        TTL: 300

Bước 3: Kiểm tra TXT đã cập nhật chưa (terminal MỚI):
        dig _acme-challenge.abc.com TXT +short

Bước 4: Quay lại Certbot nhấn Enter
```

> ⚠️ Wildcard dùng `--manual` **KHÔNG tự renew** được. Phải renew thủ công mỗi 90 ngày, hoặc dùng DNS API plugin (Cloudflare, Route53...).

---

## 2.3 Cài Cert Trả Phí Thủ Công (Comodo/Sectigo)

### Bước 1: Tạo CSR + Private Key trên server

```bash
openssl req -new -newkey rsa:2048 -nodes \
    -keyout /etc/ssl/private/abc.com.key \
    -out /etc/ssl/certs/abc.com.csr
```

**Điền thông tin:**
```
Country Name:           VN
State or Province:      Ho Chi Minh
Locality:               Ho Chi Minh
Organization Name:      Cong Ty ABC
Common Name:            abc.com     ← QUAN TRỌNG: đúng domain!
Email Address:          admin@abc.com
Challenge password:     [BỎ TRỐNG - nhấn Enter]
```

```bash
# Xem CSR để copy gửi nhà cung cấp
cat /etc/ssl/certs/abc.com.csr

# Kiểm tra CSR đúng chưa
openssl req -in /etc/ssl/certs/abc.com.csr -noout -text | grep "Subject:"
```

### Bước 2–3: Gửi CSR + Xác minh domain

```
→ Copy toàn bộ nội dung file CSR
→ Paste vào hệ thống đăng ký SSL Nhân Hòa
→ Xác minh domain bằng:
   - Email: admin@abc.com hoặc webmaster@abc.com
   - HTTP: đặt file xác minh vào thư mục website
   - DNS: thêm CNAME/TXT record
```

### Bước 4: Nhận cert files từ nhà cung cấp

```
abc.com.crt      ← Certificate chính
CAbundle.crt     ← Certificate chain (Intermediate CA)
```

**3 file quan trọng:**

| File | Vị trí | Vai trò |
|------|--------|---------|
| `abc.com.key` | Tạo ở Bước 1 | Private Key — **TUYỆT MẬT** |
| `abc.com.crt` | Nhà cung cấp gửi | Certificate chính |
| `CAbundle.crt` | Nhà cung cấp gửi | Chuỗi tin cậy CA chain |

### Bước 5A: Cài cert thủ công trên Nginx

```bash
# Ghép cert + CA bundle thành 1 file (Nginx yêu cầu)
# THỨ TỰ PHẢI ĐÚNG: cert domain TRƯỚC, CA bundle SAU
cat /etc/ssl/certs/abc.com.crt /etc/ssl/certs/CAbundle.crt > /etc/ssl/certs/abc.com.chained.crt
```

```nginx
# /etc/nginx/sites-available/abc.com
server {
    listen 443 ssl http2;
    server_name abc.com www.abc.com;

    ssl_certificate     /etc/ssl/certs/abc.com.chained.crt;
    ssl_certificate_key /etc/ssl/private/abc.com.key;
}

server {
    listen 80;
    server_name abc.com www.abc.com;
    return 301 https://$host$request_uri;
}
```

```bash
nginx -t && systemctl reload nginx
```

### Bước 5B: Cài cert thủ công trên Apache

```apache
# /etc/apache2/sites-available/abc.com-ssl.conf
<VirtualHost *:443>
    ServerName abc.com
    ServerAlias www.abc.com
    DocumentRoot /var/www/abc.com

    SSLEngine on
    SSLCertificateFile      /etc/ssl/certs/abc.com.crt       # cert chính (RIÊNG)
    SSLCertificateKeyFile   /etc/ssl/private/abc.com.key
    SSLCertificateChainFile /etc/ssl/certs/CAbundle.crt      # CA bundle (RIÊNG)
</VirtualHost>
```

> **Khác biệt quan trọng Nginx vs Apache:**
> - **Nginx:** Ghép thành **1 file** → `ssl_certificate`
> - **Apache:** Để **riêng** → `SSLCertificateFile` + `SSLCertificateChainFile`

```bash
a2ensite abc.com-ssl.conf
systemctl reload apache2
```

### Kiểm tra Private Key khớp Cert

```bash
# 2 giá trị MD5 PHẢI GIỐNG NHAU
openssl x509 -noout -modulus -in /etc/ssl/certs/abc.com.crt | md5sum
openssl rsa  -noout -modulus -in /etc/ssl/private/abc.com.key | md5sum
```

---

## 2.4 Hardening SSL — Đạt điểm A/A+ SSL Labs

### Bảng giao thức SSL/TLS

| Giao thức | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| SSL 2.0 | ☠️ Đã chết | Bỏ từ 2011 |
| SSL 3.0 | ☠️ Đã chết | Lỗ hổng POODLE |
| TLS 1.0 | ⚠️ Không an toàn | PCI DSS cấm từ 2018 |
| TLS 1.1 | ⚠️ Không an toàn | Trình duyệt lớn bỏ từ 2020 |
| **TLS 1.2** | ✅ An toàn | Tiêu chuẩn hiện tại |
| **TLS 1.3** | ✅ Rất an toàn | Nhanh nhất, mới nhất |

### Hardening trên Nginx

```bash
# Tạo file config dùng chung
mkdir -p /etc/nginx/ssl
nano /etc/nginx/snippets/ssl-hardening.conf
```

```nginx
# /etc/nginx/snippets/ssl-hardening.conf
# SSL HARDENING — Nhân Hòa KTV Template — Target: A+

# 1. Chỉ TLS 1.2 và 1.3
ssl_protocols TLSv1.2 TLSv1.3;

# 2. Cipher Suite an toàn
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';

# 3. DH Parameters
ssl_dhparam /etc/nginx/ssl/dhparam.pem;

# 4. SSL Session
ssl_session_cache shared:SSL:20m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# 5. OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# 6. Security Headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

```bash
# Tạo DH Parameters (mất 1–5 phút)
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# Áp dụng vào từng domain
nano /etc/nginx/sites-available/abc.com
```

```nginx
server {
    listen 443 ssl http2;
    server_name abc.com www.abc.com;

    ssl_certificate     /etc/letsencrypt/live/abc.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/abc.com/privkey.pem;

    # Gọi file hardening dùng chung
    include /etc/nginx/snippets/ssl-hardening.conf;
}
```

```bash
nginx -t && systemctl reload nginx
```

### Hardening trên Apache

```bash
a2enmod ssl headers
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
nano /etc/apache2/mods-available/ssl.conf
```

```apache
SSLProtocol             -all +TLSv1.2 +TLSv1.3
SSLHonorCipherOrder     on
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
SSLOpenSSLConfCmd       DHParameters "/etc/ssl/certs/dhparam.pem"
SSLUseStapling          on
SSLStaplingCache        shmcb:/var/run/ocsp(128000)
SSLCompression          off
```

```apache
# Trong mỗi VirtualHost 443:
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
```

### Kiểm tra Hardening

```bash
# Test TLS 1.0/1.1 phải FAIL
openssl s_client -connect abc.com:443 -tls1   < /dev/null 2>&1 | grep -i "handshake\|error"
openssl s_client -connect abc.com:443 -tls1_1 < /dev/null 2>&1 | grep -i "handshake\|error"

# Test TLS 1.2/1.3 phải PASS
openssl s_client -connect abc.com:443 -tls1_2 < /dev/null 2>&1 | grep "Protocol"
openssl s_client -connect abc.com:443 -tls1_3 < /dev/null 2>&1 | grep "Protocol"

# Kiểm tra HSTS header
curl -sI https://abc.com | grep -i strict

# Kiểm tra online (chính xác nhất)
# → https://www.ssllabs.com/ssltest/analyze.html?d=abc.com
```

---

## 2.5 Auto-Renew & Giám sát Cert Expiry

### Kiểm tra timer Let's Encrypt

```bash
# Certbot tự cài timer — kiểm tra đang chạy chưa
systemctl list-timers | grep certbot

# Nếu chưa có → bật lên
systemctl enable certbot.timer && systemctl start certbot.timer

# Test renew (dry-run — KHÔNG renew thật)
certbot renew --dry-run
```

### Hook: Tự reload web server sau khi renew

```bash
nano /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh
```

```bash
#!/bin/bash
systemctl reload nginx
echo "[$(date)] Nginx reloaded after cert renewal" >> /var/log/letsencrypt/renew.log
```

```bash
chmod +x /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh
```

### Script kiểm tra cert expiry — 1 domain

```bash
nano /usr/local/bin/check-ssl.sh
```

```bash
#!/bin/bash
# Cách dùng: check-ssl.sh abc.com

DOMAIN=$1
PORT=${2:-443}
WARN_DAYS=30

if [ -z "$DOMAIN" ]; then
    echo "Cách dùng: $0 <domain> [port]"
    exit 1
fi

EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

if [ -z "$EXPIRY_DATE" ]; then
    echo "❌ KHÔNG THỂ KẾT NỐI: $DOMAIN:$PORT"
    exit 2
fi

EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
ISSUER=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null \
    | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Domain:   $DOMAIN"
echo "📅 Hết hạn: $EXPIRY_DATE"
echo "⏳ Còn lại: $DAYS_LEFT ngày"
echo "🏢 Issuer:  $ISSUER"

if   [ $DAYS_LEFT -le 0 ];         then echo "🚨 TRẠNG THÁI: ĐÃ HẾT HẠN!"
elif [ $DAYS_LEFT -le $WARN_DAYS ]; then echo "⚠️  TRẠNG THÁI: SẮP HẾT HẠN — RENEW GẤP!"
else                                     echo "✅ TRẠNG THÁI: OK"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

```bash
chmod +x /usr/local/bin/check-ssl.sh

# Cách dùng:
check-ssl.sh abc.com
check-ssl.sh xyz.com 443
```

### Script giám sát nhiều domain + gửi cảnh báo

```bash
nano /usr/local/bin/check-ssl-all.sh
```

```bash
#!/bin/bash
# Giám sát SSL nhiều domain — chạy qua cron hàng ngày

WARN_DAYS=30
LOG_FILE="/var/log/ssl-check.log"
ALERT_EMAIL="ktv@nhanhoa.com"

DOMAINS=(
    "abc.com"
    "xyz.com"
    "shop.nhanhoa.com"
    # Thêm domain khách hàng vào đây
)

echo "========== SSL Check: $(date) ==========" >> "$LOG_FILE"
ALERT_MSG=""

for DOMAIN in "${DOMAINS[@]}"; do
    EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$EXPIRY_DATE" ]; then
        MSG="❌ $DOMAIN — KHÔNG KẾT NỐI ĐƯỢC"
        ALERT_MSG+="$MSG\n"
    else
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - $(date +%s)) / 86400 ))

        if   [ $DAYS_LEFT -le 0 ];         then MSG="🚨 $DOMAIN — ĐÃ HẾT HẠN!"
        elif [ $DAYS_LEFT -le $WARN_DAYS ]; then MSG="⚠️  $DOMAIN — còn $DAYS_LEFT ngày"; ALERT_MSG+="$MSG\n"
        else                                    MSG="✅ $DOMAIN — còn $DAYS_LEFT ngày"
        fi
    fi

    echo "$MSG" >> "$LOG_FILE"
done

if [ -n "$ALERT_MSG" ]; then
    echo -e "Cảnh báo SSL:\n\n$ALERT_MSG" | mail -s "🚨 SSL Alert — Cert sắp hết hạn!" "$ALERT_EMAIL"
fi
```

```bash
chmod +x /usr/local/bin/check-ssl-all.sh

# Thêm vào cron — kiểm tra lúc 8h sáng hàng ngày
crontab -e
# Thêm dòng:
0 8 * * * /usr/local/bin/check-ssl-all.sh
0 3 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

---

## 2.6 Xử lý khẩn cấp — Cert hết hạn

```
Khách (gấp): "Website em báo 'Your connection is not private'!"
```

```bash
# BƯỚC 1: Xác nhận cert hết hạn
echo | openssl s_client -servername abc.com -connect abc.com:443 2>/dev/null \
    | openssl x509 -noout -dates

# BƯỚC 2: Xác định loại cert
echo | openssl s_client -servername abc.com -connect abc.com:443 2>/dev/null \
    | openssl x509 -noout -issuer
# → "Let's Encrypt" → miễn phí → fix ngay
# → "Sectigo/Comodo" → trả phí → cần liên hệ NCC
```

**Nếu Let's Encrypt:**

```bash
# Renew ngay
certbot renew --force-renewal
systemctl reload nginx    # hoặc apache2

# Kiểm tra lại
curl -I https://abc.com
```

**Nếu cert trả phí — giải pháp tạm:**

```bash
# Cài Let's Encrypt tạm trong khi chờ renew cert trả phí
certbot --nginx -d abc.com -d www.abc.com
```

---

## 2.7 Lỗi SSL thường gặp & cách fix

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `Challenge failed` — Domain not pointing | Domain chưa trỏ đúng IP | `dig abc.com A` → sửa A record |
| `Too many certificates` | Vượt quá 50 cert/tuần | Chờ 1 tuần hoặc dùng `--staging` |
| `Port 80 in use` | Apache chiếm port 80 | `systemctl stop apache2` |
| `key values mismatch` | Key không khớp cert | `openssl x509 -modulus cert \| md5sum` vs `openssl rsa -modulus key \| md5sum` |
| Chain không đầy đủ | Thiếu CA bundle hoặc sai thứ tự | Kiểm tra file `.chained.crt` có nhiều `BEGIN CERTIFICATE` |
| Vẫn hiện cert cũ | Chưa reload web server | `systemctl reload nginx` |
| `ERR_SSL_PROTOCOL_ERROR` | Port 443 chưa mở | `ufw allow 443/tcp` |
| Mixed Content (ổ khóa gạch đỏ) | Resource load bằng `http://` | Thêm `add_header Content-Security-Policy "upgrade-insecure-requests"` |
| Cert từ email bị lỗi format | Windows `\r\n` vs Linux `\n` | `dos2unix /etc/ssl/certs/abc.com.crt` |

---
---

# PHẦN 3 — VPS & SERVER LINUX

## 3.1 SSH & Quản lý User

### SSH cơ bản

```bash
# Đăng nhập VPS
ssh root@103.x.x.x
ssh -p 2222 root@103.x.x.x          # Port tùy chỉnh
ssh -i ~/.ssh/id_rsa root@103.x.x.x  # Đăng nhập bằng key

# Tạo SSH key pair (trên máy local)
ssh-keygen -t rsa -b 4096 -C "ktv@nhanhoa.com"

# Copy public key lên server
ssh-copy-id -p 2222 root@103.x.x.x
```

### Quản lý User

```bash
# Tạo user mới
adduser devteam

# Cho phép dùng sudo
usermod -aG sudo devteam

# Đổi password
passwd devteam

# Xem user thuộc nhóm nào
groups devteam

# Xóa user + thư mục home
userdel -r devteam
```

### Bảo mật SSH (BẮT BUỘC sau khi setup VPS)

```bash
nano /etc/ssh/sshd_config
```

```
Port 2222                   # Đổi port mặc định
PermitRootLogin no          # Tắt login root trực tiếp
PasswordAuthentication no   # Chỉ dùng SSH key
MaxAuthTries 3              # Giới hạn lần thử
```

```bash
systemctl restart sshd
# ⚠️ LUÔN test SSH ở terminal MỚI trước khi đóng terminal cũ!
ufw allow 2222/tcp
```

---

## 3.2 LEMP Stack — Cài đặt & cấu hình

### Cài đặt LEMP

```bash
# Cập nhật hệ thống
apt update && apt upgrade -y

# Cài Nginx
apt install nginx -y
systemctl enable nginx && systemctl start nginx

# Cài MariaDB
apt install mariadb-server -y
systemctl enable mariadb
mysql_secure_installation    # Đặt password root, xóa anonymous users, test DB

# Cài PHP
apt install php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip -y
php -v
```

### Cấu hình Nginx cho domain

```bash
mkdir -p /var/www/abc.com
chown -R www-data:www-data /var/www/abc.com
nano /etc/nginx/sites-available/abc.com
```

```nginx
server {
    listen 80;
    server_name abc.com www.abc.com;
    root /var/www/abc.com;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/abc.com /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### Tạo database WordPress

```bash
mysql -u root -p
```

```sql
CREATE DATABASE abc_db;
CREATE USER 'abc_user'@'localhost' IDENTIFIED BY 'MatKhauManh@123';
GRANT ALL PRIVILEGES ON abc_db.* TO 'abc_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

## 3.3 Nginx Tuning — Tối ưu hiệu suất

### Config chính nginx.conf

```bash
nano /etc/nginx/nginx.conf
```

```nginx
worker_processes auto;
worker_rlimit_nofile 4096;      # Server nhỏ: 4096 | Server vừa: 16384

events {
    worker_connections 1024;    # Server nhỏ: 1024 | Server vừa: 4096
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 30;
    keepalive_requests 100;

    # Buffer
    client_body_buffer_size 16k;
    client_header_buffer_size 1k;
    client_max_body_size 50m;

    # Timeout
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_types text/plain text/css text/javascript application/javascript application/json image/svg+xml;

    include /etc/nginx/mime.types;
    include /etc/nginx/sites-enabled/*;
}
```

### Cache file tĩnh (thêm vào từng server block)

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|webp|svg)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    access_log off;
}

location ~* \.(css|js)$ {
    expires 7d;
    add_header Cache-Control "public";
    access_log off;
}
```

### FastCGI Cache (WordPress nhanh gấp 10 lần)

```nginx
# Thêm trong block http (nginx.conf):
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=MYAPP:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

# Trong server block:
set $no_cache 0;
if ($request_method = POST)                                          { set $no_cache 1; }
if ($request_uri ~* "/wp-admin/|/wp-login.php|/cart/|/checkout/")  { set $no_cache 1; }
if ($http_cookie ~* "wordpress_logged_in|comment_author")           { set $no_cache 1; }

location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    fastcgi_cache MYAPP;
    fastcgi_cache_valid 200 60m;
    fastcgi_cache_bypass $no_cache;
    fastcgi_no_cache $no_cache;
    add_header X-FastCGI-Cache $upstream_cache_status;
}
```

```bash
mkdir -p /var/cache/nginx && chown www-data:www-data /var/cache/nginx
nginx -t && systemctl reload nginx

# Kiểm tra cache
curl -I https://abc.com | grep X-FastCGI-Cache
# HIT = đang dùng cache ✅ | MISS = lần đầu | BYPASS = bỏ qua (admin/login)
```

---

## 3.4 MySQL/MariaDB Optimization

```bash
nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

```ini
[mysqld]
default-storage-engine = InnoDB

# InnoDB Buffer Pool — QUAN TRỌNG NHẤT
# Server 2GB RAM → 512M | Server 4GB RAM → 2G | Server 8GB RAM → 4G
innodb_buffer_pool_size = 512M
innodb_buffer_pool_instances = 1     # >= 1G → đổi thành 2

innodb_log_file_size = 64M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2   # 1=an toàn nhất, 2=nhanh hơn
innodb_flush_method = O_DIRECT

# Connections
max_connections = 50                  # Server nhỏ: 50 | Server vừa: 150
wait_timeout = 300
interactive_timeout = 300

# Temp table
tmp_table_size = 32M
max_heap_table_size = 32M

# Query cache (MariaDB)
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 1M

# Buffer
sort_buffer_size = 2M
join_buffer_size = 2M

# Slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

skip-name-resolve
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### Kiểm tra hiệu năng MySQL

```sql
-- Xem connections hiện tại
SHOW GLOBAL STATUS LIKE 'Threads_connected';
SHOW GLOBAL STATUS LIKE 'Max_used_connections';

-- Kiểm tra Buffer Pool hit rate (mục tiêu: > 99%)
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';

-- Xem slow queries
SHOW GLOBAL STATUS LIKE 'Slow_queries';

-- Xem process đang chạy
SHOW PROCESSLIST;

-- Kill query bị treo
KILL process_id;
```

```bash
# Xem slow query log
mysqldumpslow -t 10 /var/log/mysql/slow.log

# Phân tích tự động bằng MySQLTuner
wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl
perl mysqltuner.pl --user root --pass YourPassword
```

### Tối ưu database WordPress

```sql
-- Xóa revision cũ
DELETE FROM wp_posts WHERE post_type = 'revision';

-- Xóa transients hết hạn
DELETE FROM wp_options WHERE option_name LIKE '%_transient_%';

-- Optimize tables
OPTIMIZE TABLE wp_posts, wp_options, wp_postmeta;
```

---

## 3.5 Giám sát tài nguyên & xử lý quá tải

### Lệnh giám sát bắt buộc phải thuộc

```bash
# CPU & RAM tổng quan
top                         # Realtime — nhấn P sắp xếp CPU, M sắp xếp RAM
htop                        # Đẹp hơn (apt install htop)

# RAM chi tiết
free -h
# Nếu available < 10% tổng RAM → nguy hiểm

# Tải hệ thống
uptime
# load average: 0.5, 0.8, 1.2
# 3 số = tải 1 phút / 5 phút / 15 phút
# Nếu > số CPU core (xem: nproc) → server đang quá tải

# Ổ cứng
df -h                       # Dung lượng các phân vùng
du -sh /var/log/*           # Thư mục nào chiếm nhiều dung lượng

# Process tốn tài nguyên nhất
ps aux --sort=-%mem | head -10
ps aux --sort=-%cpu | head -10

# Connections
ss -s
netstat -an | grep :80 | wc -l
```

### Quy trình troubleshoot server chậm / không vào được

```bash
# Bước 1: Kiểm tra tải
uptime
# Load average > số core? → Quá tải

# Bước 2: Tìm process gây ra
top  # Nhấn P sắp xếp CPU, M sắp xếp RAM

# Bước 3: Kiểm tra disk đầy
df -h
# /dev/vda1 đạt 100%? → Disk đầy → website có thể chết

# Bước 4: Xử lý disk đầy
truncate -s 0 /var/log/syslog
journalctl --vacuum-size=100M
apt autoremove -y && apt clean

# Bước 5: Kiểm tra kết nối đồng thời
ss -s
netstat -an | grep :80 | wc -l
```

---

## 3.6 Firewall & Bảo mật Server

### UFW — Cấu hình cơ bản

```bash
# ⚠️ Cho phép SSH TRƯỚC khi bật UFW — nếu không sẽ bị khóa!
ufw allow 2222/tcp      # SSH (port đã đổi)
ufw allow 80/tcp        # HTTP
ufw allow 443/tcp       # HTTPS
ufw allow 25/tcp        # SMTP (nếu có mail server)
ufw allow 587/tcp       # SMTP submission
ufw allow 993/tcp       # IMAPS

# Bật UFW
ufw enable

# Cho MySQL chỉ từ IP cụ thể (không expose ra internet)
ufw allow from 10.0.0.5 to any port 3306

# Xem rules
ufw status numbered

# Xóa rule
ufw delete 3
```

### Fail2ban — Tự động chặn brute-force

```bash
apt install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled  = true
port     = 2222
maxretry = 3        # Sai 3 lần → ban
bantime  = 3600     # Ban 1 giờ
findtime = 600      # Trong vòng 10 phút

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
```

```bash
systemctl enable fail2ban && systemctl start fail2ban

# Xem ai đang bị ban
fail2ban-client status sshd

# Mở ban cho 1 IP (khách bị khóa nhầm)
fail2ban-client set sshd unbanip 1.2.3.4
```

---

## 3.7 Backup & Khôi phục

### Backup thủ công

```bash
# Backup web
tar -czf /backup/web_$(date +%Y%m%d).tar.gz /var/www/

# Backup database
mysqldump -u root -p abc_db > /backup/abc_db_$(date +%Y%m%d).sql

# Backup toàn bộ
tar -czf /backup/full_$(date +%Y%m%d).tar.gz /var/www/ /etc/nginx/ /etc/letsencrypt/
```

### Tự động backup qua Cron

```bash
crontab -e
```

```bash
# Backup lúc 2h sáng hàng ngày
0 2 * * * tar -czf /backup/web_$(date +\%Y\%m\%d).tar.gz /var/www/
0 2 * * * mysqldump -u root -pMatKhau abc_db > /backup/db_$(date +\%Y\%m\%d).sql

# Xóa backup cũ hơn 7 ngày
0 3 * * * find /backup/ -type f -mtime +7 -delete
```

### Khôi phục

```bash
# Khôi phục web
cd /var/www/
tar -xzf /backup/web_20260626.tar.gz

# Khôi phục database
mysql -u root -p abc_db < /backup/abc_db_20260626.sql

# Kiểm tra sau khôi phục
ls -la /var/www/abc.com/
mysql -u root -p -e "USE abc_db; SHOW TABLES;"
```

---
---

# PHẦN 4 — EMAIL SERVER

## 4.1 SPF, DKIM, DMARC — Xác thực email

### SPF (Sender Policy Framework)
Chỉ định server nào được phép gửi mail thay mặt domain.

```
; Chỉ server với IP 103.x.x.x được gửi mail
@   IN  TXT  "v=spf1 ip4:103.x.x.x ~all"

; Server + Google Workspace
@   IN  TXT  "v=spf1 ip4:103.x.x.x include:_spf.google.com ~all"

; Giải thích các qualifier:
; +all  = Cho phép tất cả (KHÔNG dùng)
; ~all  = Softfail — nhận nhưng mark spam (khuyến nghị)
; -all  = Hardfail — từ chối thẳng
```

```bash
# Kiểm tra SPF
dig abc.com TXT | grep spf
```

### DKIM (DomainKeys Identified Mail)
Ký số email bằng private key, domain publish public key qua DNS.

```bash
# Cài opendkim (nếu dùng Postfix)
apt install opendkim opendkim-tools -y

# Tạo key pair
mkdir -p /etc/opendkim/keys/abc.com
opendkim-genkey -b 2048 -d abc.com -D /etc/opendkim/keys/abc.com -s mail -v

# Public key để thêm vào DNS
cat /etc/opendkim/keys/abc.com/mail.txt
```

**Thêm DKIM TXT record vào DNS:**
```
Host:  mail._domainkey
Value: v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3...  ← nội dung từ mail.txt
```

```bash
# Kiểm tra DKIM
dig mail._domainkey.abc.com TXT
```

### DMARC
Policy xử lý email không vượt qua SPF/DKIM.

```
; DMARC record
Host:  _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc@abc.com; pct=100

; Giải thích policy:
; p=none       = Chỉ báo cáo, không làm gì
; p=quarantine = Đưa vào spam
; p=reject     = Từ chối
```

```bash
# Kiểm tra DMARC
dig _dmarc.abc.com TXT
```

### Kiểm tra đầy đủ SPF/DKIM/DMARC

```bash
# Dùng mxtoolbox
# → https://mxtoolbox.com/spf.aspx
# → https://mxtoolbox.com/dkim.aspx
# → https://mxtoolbox.com/dmarc.aspx

# Hoặc gửi mail đến địa chỉ test tự động
# → check-auth@verifier.port25.com
# Server sẽ trả về kết quả SPF/DKIM/DMARC qua email
```

---

## 4.2 Cấu hình mail hosting cho khách

### Checklist khi setup mail hosting

```bash
# 1. MX record đã trỏ đúng chưa?
dig abc.com MX

# 2. A record của mail server
dig mail.abc.com A

# 3. Reverse DNS (PTR) — QUAN TRỌNG cho tránh spam
dig -x [IP mail server]
# Phải trỏ về mail.abc.com (liên hệ data center để set PTR)

# 4. Port mail mở
ufw allow 25/tcp    # SMTP
ufw allow 587/tcp   # SMTP submission (TLS)
ufw allow 993/tcp   # IMAPS
ufw allow 995/tcp   # POP3S
ufw allow 465/tcp   # SMTPS (nếu dùng)
```

### Cấu hình MX cho mail hosting Nhân Hòa

```
@       IN  MX  10  mail.nhanhoa.com.
mail    IN  A       [IP mail server Nhân Hòa]
@       IN  TXT     "v=spf1 include:nhanhoa.com ~all"
```

---

## 4.3 Troubleshoot mail — Không nhận/gửi được mail

### Quy trình kiểm tra

```bash
# Bước 1: Kiểm tra MX record
dig abc.com MX
# → MX phải trỏ đúng mail server

# Bước 2: Kiểm tra kết nối đến mail server
telnet mail.abc.com 25
# Phải thấy: 220 mail.abc.com ESMTP

# Bước 3: Xem mail queue
mailq               # Xem queue đang chờ gửi

# Bước 4: Xem log mail (Postfix)
tail -100 /var/log/mail.log | grep abc.com

# Bước 5: Xem log Zimbra (nếu dùng Zimbra)
tail -f /opt/zimbra/log/mailbox.log
tail -f /opt/zimbra/log/zimbra.log

# Bước 6: Test gửi mail từ command line
echo "Test email body" | mail -s "Test Subject" recipient@gmail.com
# Sau đó xem log:
tail -f /var/log/mail.log
```

### Lỗi mail thường gặp

| Triệu chứng | Nguyên nhân | Cách fix |
|------------|-------------|---------|
| Mail bị vào spam | Thiếu SPF/DKIM/DMARC, thiếu PTR | Thêm đủ record, liên hệ DC set PTR |
| Không gửi được ra ngoài | ISP block port 25 | Dùng port 587, relay qua SMTP provider |
| Không nhận được mail | Sai MX record, disk đầy | Kiểm tra MX, kiểm tra `df -h` |
| `550 User unknown` | Tài khoản mail không tồn tại | Tạo account, kiểm tra alias |
| Bounce với `TLS required` | Server đích yêu cầu TLS | Kiểm tra cert mail server còn hạn không |

---

## 4.4 Xử lý Blacklist & Spam

### Kiểm tra IP có bị blacklist không

```bash
# Online tool
# → https://mxtoolbox.com/blacklists.aspx → nhập IP mail server

# Kiểm tra qua command line (một số blacklist phổ biến)
host [IP].zen.spamhaus.org
host [IP].bl.spamcop.net
# Nếu trả về 127.0.0.x → IP đang bị blacklist
```

### Quy trình xử lý khi bị blacklist

```
Bước 1: Xác định bị blacklist ở đâu (mxtoolbox.com)
Bước 2: Tìm nguyên nhân (server có bị hack? có spam không?)
         → Kiểm tra mail log: grep "status=sent" /var/log/mail.log | wc -l
         → Kiểm tra số lượng mail gửi bất thường
Bước 3: Khắc phục nguồn gốc (đổi mật khẩu, vá lỗi, dọn malware)
Bước 4: Yêu cầu delist trên website của từng blacklist
         → Spamhaus: www.spamhaus.org/lookup/
         → SpamCop: www.spamcop.net
Bước 5: Theo dõi lại sau 24-48h
```

---
---

# PHẦN 5 — QUY TRÌNH XỬ LÝ TICKET

## 5.1 Quy trình nhận & xử lý ticket

```
Nhận ticket
     ↓
Xác nhận thông tin: domain, IP, loại dịch vụ, mô tả lỗi
     ↓
Reproduce lỗi (tự kiểm tra lại từ đầu, không tin 100% vào mô tả của khách)
     ↓
Tìm nguyên nhân gốc rễ (root cause) — không chỉ fix triệu chứng
     ↓
Fix + test lại
     ↓
Thông báo khách + hướng dẫn kiểm tra
     ↓
Ghi chú vào ticket: đã làm gì, fix bằng cách nào
```

**Quy tắc quan trọng:**
- **Backup trước khi sửa** — luôn luôn, không ngoại lệ
- **Không sửa live production** mà không test trước
- **Thông báo khách** khi cần downtime (dù chỉ 1 phút)
- **Ghi log** những gì đã làm để đồng nghiệp biết

---

## 5.2 Ticket thường gặp & script xử lý nhanh

### Ticket: Website không vào được

```bash
# 1. Kiểm tra DNS
dig domain.com A +short

# 2. Kiểm tra web server chạy không
systemctl status nginx
systemctl status apache2

# 3. Kiểm tra port
ss -tlnp | grep ":80\|:443"

# 4. Kiểm tra log lỗi
tail -50 /var/log/nginx/error.log
tail -50 /var/log/apache2/error.log

# 5. Kiểm tra disk đầy
df -h

# 6. Kiểm tra firewall
ufw status
```

### Ticket: SSL hết hạn

```bash
# Xem cert hết hạn khi nào
echo | openssl s_client -connect domain.com:443 2>/dev/null | openssl x509 -noout -dates

# Renew Let's Encrypt
certbot renew --force-renewal && systemctl reload nginx

# Kiểm tra lại
curl -I https://domain.com
```

### Ticket: Mail bị spam / không gửi được

```bash
# Kiểm tra SPF/DKIM/DMARC
dig domain.com TXT
dig mail._domainkey.domain.com TXT
dig _dmarc.domain.com TXT

# Kiểm tra blacklist
# → mxtoolbox.com/blacklists.aspx

# Xem mail log
tail -100 /var/log/mail.log | grep domain.com
```

### Ticket: Server chậm / quá tải

```bash
# Kiểm tra tải
uptime && nproc

# Tìm process gây quá tải
ps aux --sort=-%cpu | head -10

# Kiểm tra disk
df -h && du -sh /var/log/* | sort -h | tail -10

# Kiểm tra connections
ss -s
netstat -an | grep :80 | wc -l
```

### Ticket: Không đăng nhập SSH được

```bash
# Kiểm tra fail2ban (từ server khác hoặc console)
fail2ban-client status sshd

# Mở ban IP
fail2ban-client set sshd unbanip [IP khách]

# Kiểm tra UFW
ufw status | grep 22
```

---
---

# PHẦN 6 — CHEAT SHEET TỔNG HỢP

## DNS

| Việc cần làm | Lệnh / Công cụ |
|---|---|
| Check A record | `dig abc.com A +short` |
| Check MX | `dig abc.com MX` |
| Check TXT (SPF/DKIM) | `dig abc.com TXT` |
| Check từ DNS cụ thể | `dig @8.8.8.8 abc.com A +short` |
| Check propagation | whatsmydns.net |
| Check toàn bộ DNS | intodns.com |
| Reload BIND9 | `systemctl reload bind9` |
| Kiểm tra zone file | `named-checkzone domain /path/to/zone` |
| Flush cache BIND | `rndc flush` |

## SSL

| Việc cần làm | Lệnh |
|---|---|
| Cài SSL Nginx | `certbot --nginx -d domain.com` |
| Cài SSL Apache | `certbot --apache -d domain.com` |
| Xem cert hiện tại | `certbot certificates` |
| Test auto-renew | `certbot renew --dry-run` |
| Force renew | `certbot renew --force-renewal` |
| Xem hạn cert | `check-ssl.sh domain.com` |
| Xem hạn từ file | `openssl x509 -in cert.pem -noout -dates` |
| Kiểm tra cert chain | `openssl s_client -connect domain.com:443 < /dev/null 2>/dev/null` |
| Kiểm tra key khớp cert | `openssl x509 -noout -modulus -in cert.crt \| md5sum` |
| Test TLS protocol | `openssl s_client -connect domain.com:443 -tls1_2 < /dev/null 2>&1` |
| Kiểm tra grade SSL | ssllabs.com/ssltest |

## Nginx

| Việc cần làm | Lệnh |
|---|---|
| Test config | `nginx -t` |
| Reload (không downtime) | `systemctl reload nginx` |
| Xem log lỗi | `tail -f /var/log/nginx/error.log` |
| Xem log access | `tail -f /var/log/nginx/access.log` |
| Xóa FastCGI cache | `rm -rf /var/cache/nginx/*` |
| Kiểm tra cache header | `curl -I https://domain.com \| grep X-FastCGI` |
| Xem connections | `ss -s` |
| Backup config | `cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d)` |

## MySQL / MariaDB

| Việc cần làm | Lệnh |
|---|---|
| Connections hiện tại | `SHOW GLOBAL STATUS LIKE 'Threads_connected';` |
| Max connections đã dùng | `SHOW GLOBAL STATUS LIKE 'Max_used_connections';` |
| Xem slow queries | `mysqldumpslow -t 10 /var/log/mysql/slow.log` |
| Phân tích query | `EXPLAIN SELECT ...;` |
| Xem process đang chạy | `SHOW PROCESSLIST;` |
| Kill query bị treo | `KILL process_id;` |
| Optimize bảng | `mysqlcheck -u root -p --optimize db_name` |
| Phân tích tự động | `perl mysqltuner.pl --user root --pass xxx` |

## Server / Hệ thống

| Việc cần làm | Lệnh |
|---|---|
| Tải hệ thống | `uptime` |
| RAM | `free -h` |
| Disk | `df -h` |
| Process tốn CPU | `ps aux --sort=-%cpu \| head -10` |
| Process tốn RAM | `ps aux --sort=-%mem \| head -10` |
| Connections web | `netstat -an \| grep :80 \| wc -l` |
| Mở ban IP | `fail2ban-client set sshd unbanip 1.2.3.4` |
| Xem ai bị ban | `fail2ban-client status sshd` |
| Kiểm tra blacklist mail | mxtoolbox.com/blacklists.aspx |

## Checklist Trước Khi Sửa Config

```bash
# 1. Backup config
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d)
cp /etc/mysql/mariadb.conf.d/50-server.cnf {...}.bak.$(date +%Y%m%d)

# 2. Test cú pháp
nginx -t

# 3. Reload / Restart
systemctl reload nginx
systemctl restart mariadb

# 4. Kiểm tra service
systemctl status nginx
curl -I https://domain.com

# 5. Xem log ngay sau restart (30 giây đầu quan trọng nhất)
tail -f /var/log/nginx/error.log
```

---

> **📌 Ghi nhớ:** Luôn backup trước khi sửa. Test trên staging trước khi đụng production. Ghi log những gì đã làm.
> 
> **📞 Liên hệ nội bộ:** Nếu gặp tình huống chưa từng xử lý → hỏi senior (Anh Lâm, Anh Duy, Anh Vũ Trường An) trước khi tự xử.
