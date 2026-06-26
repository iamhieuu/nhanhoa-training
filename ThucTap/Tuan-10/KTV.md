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
  - [2.3 Cài Cert Trả Phí Thủ Công (Comodo/Sectigo)](#23-cài-cert-trả-phí-thủ-công-comodosectigo)
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
- [**PHẦN 7 — CONTROL PANEL (cPanel / DirectAdmin / aaPanel)**](#phần-7--control-panel)
  - [7.1 cPanel — Những thứ KTV đụng hàng ngày](#71-cpanel--những-thứ-ktv-đụng-hàng-ngày)
  - [7.2 DirectAdmin — Workflow thực tế](#72-directadmin--workflow-thực-tế)
  - [7.3 aaPanel — Setup & quản lý](#73-aapanel--setup--quản-lý)
  - [7.4 Cài SSL qua Control Panel](#74-cài-ssl-qua-control-panel)

- [**PHẦN 8 — WORDPRESS THỰC CHIẾN**](#phần-8--wordpress-thực-chiến)
  - [8.1 Troubleshoot WordPress chuyên sâu](#81-troubleshoot-wordpress-chuyên-sâu)
  - [8.2 WordPress bị hack — Quy trình xử lý](#82-wordpress-bị-hack--quy-trình-xử-lý)
  - [8.3 WordPress hiệu năng — Checklist đầy đủ](#83-wordpress-hiệu-năng--checklist-đầy-đủ)
  - [8.4 Di chuyển WordPress giữa server](#84-di-chuyển-wordpress-giữa-server)

- [**PHẦN 9 — BẢO MẬT NÂNG CAO**](#phần-9--bảo-mật-nâng-cao)
  - [9.1 Phân quyền file — Linux permission thực tế](#91-phân-quyền-file--linux-permission-thực-tế)
  - [9.2 PHP Hardening](#92-php-hardening)
  - [9.3 Malware scan & dọn dẹp](#93-malware-scan--dọn-dẹp)
  - [9.4 Nginx — Chặn tấn công phổ biến](#94-nginx--chặn-tấn-công-phổ-biến)
  - [9.5 ModSecurity WAF](#95-modsecurity-waf)

- [**PHẦN 10 — LOG ANALYSIS THỰC TẾ**](#phần-10--log-analysis-thực-tế)
  - [10.1 Đọc Nginx/Apache access log](#101-đọc-nginxapache-access-log)
  - [10.2 Phân tích log tìm vấn đề](#102-phân-tích-log-tìm-vấn-đề)
  - [10.3 Log rotation & quản lý log](#103-log-rotation--quản-lý-log)

- [**PHẦN 11 — REVERSE PROXY & NÂNG CẤP HẠ TẦNG**](#phần-11--reverse-proxy--nâng-cấp-hạ-tầng)
  - [11.1 Nginx Reverse Proxy](#111-nginx-reverse-proxy)
  - [11.2 Cài đặt nhiều PHP version song song](#112-cài-đặt-nhiều-php-version-song-song)
  - [11.3 Redis cache cho WordPress](#113-redis-cache-cho-wordpress)

- [**PHẦN 12 — SCRIPT TỰ ĐỘNG HÓA THỰC TẾ**](#phần-12--script-tự-động-hóa-thực-tế)
  - [12.1 Script setup VPS mới từ đầu](#121-script-setup-vps-mới-từ-đầu)
  - [12.2 Script backup thông minh](#122-script-backup-thông-minh)
  - [12.3 Script health check server hàng ngày](#123-script-health-check-server-hàng-ngày)

- [**PHẦN 13 — EDGE CASES & TÌNH HUỐNG KHÓ**](#phần-13--edge-cases--tình-huống-khó)
  - [13.1 Server bị DDoS — Xử lý khẩn cấp](#131-server-bị-ddos--xử-lý-khẩn-cấp)
  - [13.2 Database bị corrupt](#132-database-bị-corrupt)
  - [13.3 Server hết RAM — Không SSH được](#133-server-hết-ram--không-ssh-được)
  - [13.4 Disk đầy 100% — Website chết](#134-disk-đầy-100--website-chết)
  - [13.5 Cert Let's Encrypt lỗi không rõ nguyên nhân](#135-cert-lets-encrypt-lỗi-không-rõ-nguyên-nhân)


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

### Bước 2-3: Gửi CSR + Xác minh domain

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

-----
# PHẦN 7 — CONTROL PANEL

## 7.1 cPanel — Những thứ KTV đụng hàng ngày

### Truy cập cPanel

```
# Khách truy cập
https://domain.com:2083          # HTTPS
http://domain.com:2082           # HTTP (ít dùng)
https://[IP server]:2083         # Khi domain chưa trỏ

# WHM (Web Host Manager) — dành cho reseller/admin
https://[IP server]:2087
```

### Các tác vụ hay gặp trong cPanel

#### Tạo database & user MySQL

```
cPanel → Databases → MySQL Databases
→ "Create New Database": ten_db
→ "MySQL Users" → "Add New User": ten_user / password
→ "Add User To Database" → chọn ALL PRIVILEGES
```

> ⚠️ **Lưu ý thực tế:** cPanel tự thêm prefix username vào tên DB và user.  
> Ví dụ: username cPanel là `abc123`, tạo DB `mydb` → thực tế tên là `abc123_mydb`  
> Khi điền vào `wp-config.php` phải dùng tên đầy đủ có prefix!

#### Upload & quản lý file

```
cPanel → Files → File Manager
→ Chọn thư mục public_html
→ Upload file zip → Extract ở đây

# Hoặc dùng FTP:
cPanel → Files → FTP Accounts → tạo account FTP
→ Dùng FileZilla: host=domain.com, port=21, SSL explicit
```

#### Quản lý email

```
cPanel → Email → Email Accounts
→ "Create" → nhập địa chỉ + password

# Xem quota email
cPanel → Email → Email Disk Usage

# Cấu hình Autoresponder
cPanel → Email → Autoresponders
```

#### Xem log lỗi

```
cPanel → Metrics → Errors
→ Hiện 300 dòng log lỗi gần nhất

# Hoặc qua terminal:
cat /home/[username]/logs/[domain].com-ssl_log | tail -100
cat /home/[username]/logs/[domain].com-error_log | tail -100
```

#### Tạo subdomain

```
cPanel → Domains → Subdomains
→ Subdomain: blog
→ Domain: abc.com
→ Document Root: tự điền hoặc để mặc định (/public_html/blog)
```

#### Cài WordPress qua Softaculous

```
cPanel → Softaculous Apps Installer → WordPress
→ Điền thông tin → Install
→ Sau khi cài: xóa file /wp-admin/install.php nếu còn
```

## 7.2 DirectAdmin — Workflow thực tế

### Truy cập DirectAdmin

```
https://[IP server]:2222        # Admin panel
https://domain.com:2222         # User panel
```

### Cấu trúc thư mục DirectAdmin

```
/home/[username]/
    domains/
        abc.com/
            public_html/        ← Web root
            logs/
                error.log
                access.log
            private_html/
    imap/                       ← Mail storage
    mail/
        abc.com/
            user@abc.com/
```

### Tác vụ thường gặp

```bash
# Tạo domain mới (qua CLI nếu có quyền admin)
echo "action=create&type=domain&domain=abc.com&username=user1&bandwidth=unlimited&quota=unlimited&ssl=yes&php=yes&cgi=yes" \
    | /usr/local/directadmin/directadmin taskq

# Restart dịch vụ qua DA service manager
/usr/local/directadmin/custombuild/build rewrite_confs
service nginx restart

# Xem log lỗi DirectAdmin
tail -f /var/log/directadmin/errortaskq.log
tail -f /var/log/directadmin/system.log
```

### Cấu hình PHP version cho từng domain

```
DirectAdmin → Domain Setup → chọn domain → PHP version selector
→ Chọn PHP 8.1 / 8.2 / 8.3 cho từng domain riêng
```

---

## 7.3 aaPanel — Setup & quản lý

### Cài aaPanel trên Ubuntu 22.04

```bash
# Cài aaPanel
wget -O install.sh https://www.aapanel.com/script/install_6.0_en.sh
bash install.sh aapanel

# Sau khi cài → ghi lại:
# aaPanel URL:  http://[IP]:7800/[random_path]
# username: aapanel
# password: [random]
```

### Truy cập & thiết lập ban đầu

```
Truy cập URL được cung cấp sau khi cài
→ Chọn LEMP stack (Nginx + MySQL + PHP)
→ Chọn phiên bản: Nginx 1.24, MySQL 8.0, PHP 8.1
→ Đợi cài xong (~5-10 phút)
```

### Tác vụ thường gặp trong aaPanel

```
# Tạo website mới
aaPanel → Website → Add Site
→ Điền domain, chọn PHP version, tạo DB cùng lúc

# Cài SSL (Let's Encrypt)
aaPanel → Website → [domain] → SSL
→ Let's Encrypt → nhập email → Apply

# Xem log
aaPanel → Website → [domain] → Error Log / Access Log

# Quản lý database
aaPanel → Database → chọn DB → phpMyAdmin

# Quản lý file
aaPanel → Files → File Manager
```

### Backup qua aaPanel

```
aaPanel → Cron → Add Task
→ Type: Backup website
→ Select: chọn domain cần backup
→ Backup to: Local / FTP / S3
→ Cron: 0 2 * * * (2h sáng hàng ngày)
→ Keep: 7 (giữ 7 bản)
```

---

## 7.4 Cài SSL qua Control Panel

### Cài SSL trong cPanel (AutoSSL)

```
WHM → SSL/TLS → Manage AutoSSL
→ Enable → chọn Let's Encrypt provider
→ Run AutoSSL for all users

# Hoặc cho 1 domain cụ thể:
cPanel → Security → SSL/TLS → Manage SSL sites
→ Run AutoSSL
```

### Cài SSL cert trả phí trong cPanel

```
cPanel → Security → SSL/TLS → Install and Manage SSL
→ Browse Certificates → chọn domain
→ Dán:
   Certificate (CRT): nội dung file .crt
   Private Key (KEY): nội dung file .key
   CA Bundle (CABUNDLE): nội dung file CAbundle
→ Install Certificate
```

### Cài SSL trong DirectAdmin

```
DirectAdmin → [username] → SSL Certificates
→ Paste a pre-generated certificate and key
→ Dán certificate + key → Save

# Cài CA bundle riêng
→ Click "Click Here to paste a CA Root Certificate"
→ Dán nội dung CAbundle → Save
```

### Cài SSL trong aaPanel

```
aaPanel → Website → [domain] → SSL
→ Other Certificate
→ Dán Certificate (PEM) + Private Key (KEY)
→ Save
```

### Kiểm tra SSL sau khi cài qua Panel

```bash
# Luôn verify sau khi cài — panel đôi khi apply không đúng
openssl s_client -connect domain.com:443 -servername domain.com < /dev/null 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates

# Kiểm tra cert chain
curl -svo /dev/null https://domain.com 2>&1 | grep -i "SSL\|TLS\|certificate"
```

---
---

# PHẦN 8 — WORDPRESS THỰC CHIẾN

> 70-80% ticket hosting tại Nhân Hòa liên quan đến WordPress. Phần này dạy xử lý từ cơ bản đến phức tạp.

## 8.1 Troubleshoot WordPress chuyên sâu

### Bộ công cụ debug WordPress

```php
// Bật debug — thêm vào wp-config.php (CHỈ dùng khi debug, tắt ngay sau đó)
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);     // Log ra /wp-content/debug.log
define('WP_DEBUG_DISPLAY', false); // Không hiện lỗi trên trang (tránh lộ thông tin)
define('SCRIPT_DEBUG', true);     // Dùng file JS/CSS chưa minify
```

```bash
# Xem debug log realtime
tail -f /var/www/abc.com/wp-content/debug.log

# Tắt debug sau khi xong (quan trọng!)
# Sửa lại: define('WP_DEBUG', false);
```

### Lỗi WordPress hay gặp

#### Error 500 — White Screen of Death (WSOD)

```bash
# Bước 1: Xem log lỗi Nginx/Apache
tail -50 /var/log/nginx/error.log
# hoặc:
tail -50 /home/[user]/logs/abc.com-error_log     # Trong cPanel

# Bước 2: Xem PHP error log
tail -50 /var/log/php8.1-fpm.log

# Bước 3: Tắt plugin một cách thủ công (qua terminal, không vào được WP Admin)
# Đổi tên thư mục plugins → WP tắt tất cả plugin
mv /var/www/abc.com/wp-content/plugins /var/www/abc.com/wp-content/plugins_bak

# Vào được rồi → bật từng plugin lại để tìm plugin lỗi
mv /var/www/abc.com/wp-content/plugins_bak /var/www/abc.com/wp-content/plugins

# Bước 4: Đổi theme sang Twenty Twenty-Three để test
# Nếu hết lỗi → theme cũ bị lỗi
mv /var/www/abc.com/wp-content/themes/ten-theme-cu /tmp/theme_bak
```

#### Database connection error

```bash
# Kiểm tra thông tin DB trong wp-config.php
grep -E "DB_NAME|DB_USER|DB_PASSWORD|DB_HOST" /var/www/abc.com/wp-config.php

# Test kết nối database
mysql -u [DB_USER] -p[DB_PASSWORD] [DB_NAME]
# Nếu lỗi → sai thông tin hoặc MySQL chưa chạy

# Kiểm tra MySQL đang chạy
systemctl status mariadb

# Kiểm tra user có quyền truy cập DB không
mysql -u root -p
SHOW GRANTS FOR 'abc_user'@'localhost';
```

#### WordPress không gửi được email

```bash
# WordPress dùng PHP mail() mặc định — hay bị spam filter
# Fix: Dùng plugin WP Mail SMTP

# Cài plugin qua WP-CLI
wp plugin install wp-mail-smtp --activate --path=/var/www/abc.com

# Hoặc cài thủ công nếu không có WP-CLI:
# Vào WP Admin → Plugins → Add New → tìm "WP Mail SMTP"
# Cấu hình dùng Gmail SMTP hoặc Mailgun
```

#### "Sorry, you are not allowed to access this page"

```bash
# Thường do user role bị lỗi hoặc plugin security chặn
# Fix qua database:
mysql -u root -p abc_db

-- Xem user hiện tại
SELECT user_login, user_email FROM wp_users;

-- Cấp lại quyền admin
UPDATE wp_usermeta SET meta_value = 'a:1:{s:13:"administrator";b:1;}' 
WHERE user_id = 1 AND meta_key = 'wp_capabilities';

-- Reset password admin qua SQL (thay bằng password mới)
UPDATE wp_users SET user_pass = MD5('matkhaumoi123') WHERE ID = 1;
```

#### Permalink bị lỗi — 404 trên tất cả bài viết

```bash
# Nguyên nhân thường do .htaccess bị xóa hoặc mod_rewrite chưa bật
# Fix Nginx: kiểm tra có try_files không
grep "try_files" /etc/nginx/sites-available/abc.com
# Phải có: try_files $uri $uri/ /index.php?$args;

# Fix Apache: bật mod_rewrite
a2enmod rewrite
systemctl restart apache2

# Tạo lại .htaccess cho WordPress (Apache)
cat > /var/www/abc.com/.htaccess << 'EOF'
# BEGIN WordPress

RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]

# END WordPress
EOF

chown www-data:www-data /var/www/abc.com/.htaccess
```

### WP-CLI — Công cụ quản lý WordPress qua terminal

```bash
# Cài WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Cách dùng (phải chạy trong thư mục web hoặc chỉ định --path)
cd /var/www/abc.com

# Xem thông tin WordPress
wp core version
wp core verify-checksums       # Kiểm tra file WP có bị sửa không

# Update WordPress + plugin + theme
wp core update
wp plugin update --all
wp theme update --all

# Xóa plugin/theme không dùng (giảm attack surface)
wp plugin delete hello akismet
wp theme delete twentytwenty twentytwentyone

# Tạo user admin mới (khi bị mất quyền truy cập)
wp user create newadmin newadmin@abc.com --role=administrator --user_pass=MatKhauMoi@123

# Export/Import database
wp db export /backup/abc_db_$(date +%Y%m%d).sql
wp db import /backup/abc_db_20260626.sql

# Search và replace URL (dùng khi migrate)
wp search-replace 'http://abc.com' 'https://abc.com' --all-tables

# Flush cache
wp cache flush
wp rewrite flush

# Kiểm tra plugin nào gây chậm
wp profile stage --all
```

---

## 8.2 WordPress bị hack — Quy trình xử lý

```
Dấu hiệu bị hack:
- Website redirect sang trang lạ
- Google hiện cảnh báo "This site may be hacked"
- Thấy file PHP lạ trong thư mục uploads
- Admin bị đổi mật khẩu / thêm user lạ
- Server load bất thường
```

### Bước 1: Xác nhận và cô lập

```bash
# Kiểm tra file PHP nằm trong thư mục uploads (không nên có)
find /var/www/abc.com/wp-content/uploads -name "*.php" -type f
find /var/www/abc.com/wp-content/uploads -name "*.js"  -type f | head -20

# Tìm file mới được sửa trong 7 ngày qua
find /var/www/abc.com -type f -newer /var/www/abc.com/wp-config.php -name "*.php" | head -30

# Tìm file có hàm nguy hiểm (webshell signature)
grep -r "eval(base64_decode" /var/www/abc.com --include="*.php" -l
grep -r "system\|exec\|shell_exec\|passthru" /var/www/abc.com/wp-content/uploads --include="*.php" -l
grep -r "preg_replace.*\/e" /var/www/abc.com --include="*.php" -l

# Xem file nào đang được truy cập nhiều (từ access log)
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20
```

### Bước 2: Xử lý

```bash
# 1. Tạm thời đưa web về maintenance mode
# Tạo file maintenance.html và redirect tất cả về đó
cat > /etc/nginx/sites-available/maintenance.conf << 'EOF'
server {
    listen 80;
    server_name abc.com www.abc.com;
    root /var/www/maintenance;
    index maintenance.html;
    location / { try_files $uri /maintenance.html; }
}
EOF

# 2. Backup toàn bộ trước khi dọn
tar -czf /backup/hacked_site_$(date +%Y%m%d%H%M).tar.gz /var/www/abc.com/
mysqldump -u root -p abc_db > /backup/hacked_db_$(date +%Y%m%d%H%M).sql

# 3. Xóa file PHP trong uploads (không nên có)
find /var/www/abc.com/wp-content/uploads -name "*.php" -delete
find /var/www/abc.com/wp-content/uploads -name "*.php7" -delete

# 4. Download WordPress sạch và so sánh
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
# So sánh file core WP
diff -r /tmp/wordpress/ /var/www/abc.com/ --exclude="wp-config.php" --exclude="wp-content" | grep "^>" | head -30

# 5. Thay thế toàn bộ WP core bằng bản sạch
cp -r /tmp/wordpress/wp-admin /var/www/abc.com/
cp -r /tmp/wordpress/wp-includes /var/www/abc.com/
cp /tmp/wordpress/wp-*.php /var/www/abc.com/
cp /tmp/wordpress/index.php /var/www/abc.com/

# 6. Đổi mật khẩu tất cả mọi thứ
wp user update 1 --user_pass="MatKhauMoi_$(date +%s)" --path=/var/www/abc.com
# Đổi mật khẩu database
# Đổi secret keys trong wp-config.php (lấy key mới từ: https://api.wordpress.org/secret-key/1.1/salt/)

# 7. Kiểm tra và xóa user lạ trong WP
wp user list --path=/var/www/abc.com
wp user delete [ID user lạ] --path=/var/www/abc.com

# 8. Fix permissions
find /var/www/abc.com -type d -exec chmod 755 {} \;
find /var/www/abc.com -type f -exec chmod 644 {} \;
chmod 600 /var/www/abc.com/wp-config.php
```

### Bước 3: Phòng chống tái nhiễm

```nginx
# Chặn PHP execution trong thư mục uploads (Nginx)
location ~* /wp-content/uploads/.*\.php$ {
    deny all;
    return 403;
}

# Chặn truy cập wp-config.php
location = /wp-config.php {
    deny all;
}

# Chặn xmlrpc.php (vector tấn công phổ biến)
location = /xmlrpc.php {
    deny all;
    return 403;
}
```

---

## 8.3 WordPress hiệu năng — Checklist đầy đủ

```bash
# === CHECKLIST HIỆU NĂNG WORDPRESS ===

# 1. Đo baseline trước khi tối ưu
curl -o /dev/null -s -w "Time: %{time_total}s | Size: %{size_download}bytes\n" https://abc.com

# 2. Kiểm tra PageSpeed
# → https://pagespeed.web.dev/ → nhập domain

# 3. Kiểm tra hosting resources
wp eval 'echo "PHP: " . phpversion() . "\nMemory limit: " . ini_get("memory_limit") . "\nMax upload: " . ini_get("upload_max_filesize");' --path=/var/www/abc.com

# 4. Xem plugin nào chạy chậm nhất
wp profile hook --all --spotlight --path=/var/www/abc.com 2>/dev/null | head -30
```

### Tối ưu hình ảnh

```bash
# Cài webp-convert (tối ưu ảnh tốt nhất)
apt install webp -y

# Convert ảnh PNG/JPG sang WebP
find /var/www/abc.com/wp-content/uploads -name "*.jpg" -exec \
    cwebp -q 80 {} -o {}.webp \;

# Hoặc dùng plugin: Imagify, ShortPixel, Smush
# Plugin tốt nhất cho Nhân Hòa hosting: ShortPixel (có free tier)
```

### Cấu hình PHP-FPM cho WordPress

```bash
nano /etc/php/8.1/fpm/pool.d/abc.com.conf
```

```ini
[abc.com]
user = www-data
group = www-data
listen = /run/php/php8.1-fpm-abc.sock       ; Socket riêng cho từng site
listen.owner = www-data
listen.group = www-data

; Số worker process
pm = dynamic
pm.max_children = 20        ; Server 2GB RAM: 20 | 4GB: 40
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
pm.max_requests = 500       ; Restart worker sau 500 request (tránh memory leak)

; PHP settings cho site này
php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 50M
php_admin_value[post_max_size] = 50M
php_admin_value[max_execution_time] = 300

; Log
php_admin_value[error_log] = /var/log/php/abc.com.error.log
php_admin_flag[log_errors] = on
```

```bash
systemctl restart php8.1-fpm
nginx -t && systemctl reload nginx
```

---

## 8.4 Di chuyển WordPress giữa server

```
Tình huống: Khách muốn chuyển từ shared hosting sang VPS mới
```

### Dùng WP-CLI (cách tốt nhất)

```bash
# === Trên server CŨ ===
cd /old/path/to/wordpress

# Export database
wp db export /tmp/abc_db_migrate.sql

# Tạo archive toàn bộ site
tar -czf /tmp/abc_migrate.tar.gz /old/path/to/wordpress/

# Transfer sang server mới
scp /tmp/abc_migrate.tar.gz root@[IP_MỚI]:/tmp/
scp /tmp/abc_db_migrate.sql  root@[IP_MỚI]:/tmp/

# === Trên server MỚI ===
# Tạo thư mục, giải nén
mkdir -p /var/www/abc.com
cd /var/www/
tar -xzf /tmp/abc_migrate.tar.gz --strip-components=N  # N = số thư mục cần bỏ

# Tạo database
mysql -u root -p -e "CREATE DATABASE abc_db; CREATE USER 'abc_user'@'localhost' IDENTIFIED BY 'MatKhauMoi'; GRANT ALL ON abc_db.* TO 'abc_user'@'localhost';"

# Import database
mysql -u abc_user -pMatKhauMoi abc_db < /tmp/abc_db_migrate.sql

# Sửa wp-config.php với thông tin DB mới
nano /var/www/abc.com/wp-config.php
# Sửa: DB_NAME, DB_USER, DB_PASSWORD, DB_HOST

# Search-replace URL cũ sang URL mới
wp search-replace 'https://old-server-ip' 'https://abc.com' --all-tables --path=/var/www/abc.com

# Fix permissions
chown -R www-data:www-data /var/www/abc.com
find /var/www/abc.com -type d -exec chmod 755 {} \;
find /var/www/abc.com -type f -exec chmod 644 {} \;
chmod 600 /var/www/abc.com/wp-config.php

# Flush cache + rewrite
wp cache flush --path=/var/www/abc.com
wp rewrite flush --path=/var/www/abc.com

# Test bằng hosts file trước khi trỏ DNS thật
echo "[IP_MỚI] abc.com www.abc.com" >> /etc/hosts
curl -I https://abc.com
```

---
---

# PHẦN 9 — BẢO MẬT NÂNG CAO

## 9.1 Phân quyền file — Linux permission thực tế

```bash
# === PERMISSION CHUẨN CHO WEB SERVER ===

# Thư mục: 755 (owner đọc/ghi/execute, others chỉ đọc/execute)
# File: 644 (owner đọc/ghi, others chỉ đọc)
# File PHP đặc biệt (wp-config): 600 (chỉ owner đọc/ghi)
# Upload thư mục: 755 (web server cần ghi)

# Fix nhanh permission cho toàn bộ web
find /var/www/abc.com -type d -exec chmod 755 {} \;
find /var/www/abc.com -type f -exec chmod 644 {} \;

# File config nhạy cảm
chmod 600 /var/www/abc.com/wp-config.php
chmod 600 /var/www/abc.com/.env          # Laravel/framework

# Owner phải là web server user
chown -R www-data:www-data /var/www/abc.com

# Thư mục uploads cần ghi được bởi web server
chmod 755 /var/www/abc.com/wp-content/uploads

# === KIỂM TRA PERMISSION ===
# Tìm file có permission quá rộng
find /var/www/abc.com -type f -perm 777 -ls
find /var/www/abc.com -type f -perm 666 -ls

# Tìm file không thuộc về www-data (có thể bị upload bởi hacker)
find /var/www/abc.com -not -user www-data -type f | head -20
```

---

## 9.2 PHP Hardening

```bash
# Tìm file php.ini đang dùng
php --ini | grep "Loaded Configuration"
# Hoặc:
php -r "echo php_ini_loaded_file();"
```

```ini
; /etc/php/8.1/fpm/php.ini — Các giá trị cần kiểm tra và sửa

; === Ẩn thông tin PHP (tránh lộ version) ===
expose_php = Off

; === Giới hạn function nguy hiểm ===
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source,phpinfo

; === Giới hạn file access ===
open_basedir = /var/www/abc.com:/tmp    ; Chỉ cho PHP access 2 thư mục này

; === Upload ===
file_uploads = On
upload_max_filesize = 50M
post_max_size = 50M
max_file_uploads = 20

; === Execution time ===
max_execution_time = 120
max_input_time = 120
memory_limit = 256M

; === Session bảo mật ===
session.use_strict_mode = 1
session.cookie_httponly = 1
session.cookie_secure = 1      ; Chỉ bật nếu đã có SSL
session.use_only_cookies = 1

; === Tắt thông báo lỗi trên browser (production) ===
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log
```

```bash
# Restart PHP-FPM sau khi sửa
systemctl restart php8.1-fpm

# Kiểm tra config
php -r "echo ini_get('disable_functions');"
php -r "echo ini_get('expose_php');"
```

---

## 9.3 Malware scan & dọn dẹp

### ClamAV — Antivirus miễn phí

```bash
# Cài ClamAV
apt install clamav clamav-daemon -y

# Update virus database
freshclam

# Scan thư mục web
clamscan -r /var/www/abc.com --infected --log=/var/log/clamav-scan.log

# Scan và tự động xóa file nhiễm (cẩn thận!)
clamscan -r /var/www/abc.com --infected --remove --log=/var/log/clamav-scan.log

# Xem kết quả
tail -50 /var/log/clamav-scan.log
grep "FOUND" /var/log/clamav-scan.log
```

### Maldet (Linux Malware Detect)

```bash
# Cài Maldet
cd /tmp
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar xzf maldetect-current.tar.gz
cd maldetect-*
./install.sh

# Scan
maldet -a /var/www/abc.com

# Xem report
maldet --report list
maldet --report [SCANID]
```

### Chkrootkit — Kiểm tra rootkit

```bash
apt install chkrootkit -y
chkrootkit | grep -v "not infected\|not found\|nothing found"
# Nếu có dòng "INFECTED" → server có thể đã bị compromise
```

---

## 9.4 Nginx — Chặn tấn công phổ biến

```nginx
# /etc/nginx/snippets/security.conf
# Gọi vào từng server block: include /etc/nginx/snippets/security.conf;

# === Chặn User-Agent nguy hiểm ===
if ($http_user_agent ~* (Nikto|sqlmap|nmap|masscan|zgrab|python-requests|Go-http-client|libwww-perl)) {
    return 403;
}

# === Chặn method lạ ===
if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$) {
    return 405;
}

# === Chặn SQL injection trong URL ===
if ($query_string ~* "(union|select|insert|drop|delete|update|create|alter).*(\(|%28)") {
    return 403;
}

# === Chặn path traversal ===
if ($request_uri ~* "\.\./") {
    return 403;
}

# === Chặn truy cập file nhạy cảm ===
location ~* \.(git|env|log|sql|bak|backup|swp|old|orig)$ {
    deny all;
    return 403;
}

# === Chặn file ẩn ===
location ~ /\. {
    deny all;
    return 403;
}

# === Rate limiting cho login WordPress ===
location ~* /wp-login\.php {
    limit_req zone=one burst=3 nodelay;
    # zone "one" phải được khai báo trong http block:
    # limit_req_zone $binary_remote_addr zone=one:10m rate=5r/m;
}

# === Chặn hotlink ảnh ===
location ~* \.(jpg|jpeg|png|gif|webp)$ {
    valid_referers none blocked server_names *.abc.com;
    if ($invalid_referer) {
        return 403;
    }
    expires 30d;
}
```

```nginx
# Thêm vào http block trong nginx.conf
limit_req_zone $binary_remote_addr zone=one:10m rate=5r/m;         # Login: 5 lần/phút
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/m;        # API: 30 lần/phút
limit_conn_zone $binary_remote_addr zone=addr:10m;                  # Connections
```

---

## 9.5 ModSecurity WAF

```bash
# Cài ModSecurity cho Nginx
apt install libnginx-mod-security -y

# Hoặc compile từ nguồn (khuyến nghị cho production):
apt install -y libmodsecurity3 libmodsecurity-dev
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx /tmp/modsecurity-nginx

# Cài OWASP Core Rule Set
cd /etc/nginx
git clone https://github.com/coreruleset/coreruleset owasp-crs
cp owasp-crs/crs-setup.conf.example owasp-crs/crs-setup.conf
```

```nginx
# /etc/nginx/modsecurity/modsecurity.conf
SecRuleEngine On           # On/DetectionOnly/Off
SecAuditLog /var/log/nginx/modsecurity_audit.log
SecAuditLogParts ABIJDEFHZ
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml

# Bật OWASP rules
Include /etc/nginx/owasp-crs/crs-setup.conf
Include /etc/nginx/owasp-crs/rules/*.conf
```

```nginx
# Trong server block:
modsecurity on;
modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;
```

```bash
nginx -t && systemctl reload nginx

# Monitor ModSecurity logs
tail -f /var/log/nginx/modsecurity_audit.log | grep "id\|uri\|message"
```

---
---

# PHẦN 10 — LOG ANALYSIS THỰC TẾ

> Đọc log là kỹ năng phân biệt KTV thực tập và KTV thực chiến. Biết đọc log = tự debug được 90% vấn đề.

## 10.1 Đọc Nginx/Apache access log

### Format log mặc định Nginx

```
103.10.20.30 - - [26/Jun/2026:10:30:45 +0700] "GET /wp-login.php HTTP/1.1" 200 5432 "https://google.com" "Mozilla/5.0..."
│             │   │                              │   │                       │   │    │                    │
IP            │   Time                          Method URL                 Status Size Referer             User-Agent
            Ident
```

### Phân tích access log thực tế

```bash
# Top 10 IP truy cập nhiều nhất (tìm attacker hoặc bot)
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Top 10 URL được request nhiều nhất
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Lọc request có status 404 (link hỏng) và 500 (lỗi server)
grep '" 404 ' /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -10
grep '" 500 ' /var/log/nginx/access.log | tail -20

# Đếm request theo giờ (tìm giờ cao điểm)
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f2 | sort | uniq -c

# Tìm IP đang brute-force wp-login.php
grep "wp-login.php" /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Lọc request trong khoảng thời gian cụ thể
awk '$4 >= "[26/Jun/2026:09:00:00" && $4 <= "[26/Jun/2026:10:00:00"' /var/log/nginx/access.log

# Tính tổng bandwidth từng IP (xem ai tốn bandwidth nhất)
awk '{arr[$1]+=$10} END {for (i in arr) print arr[i], i}' /var/log/nginx/access.log | sort -rn | head -10

# IP nào đang tạo nhiều request nhất trong 5 phút gần đây
tail -5000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

### Đọc error log Nginx

```bash
# Format error log:
# 2026/06/26 10:30:45 [error] 12345#12345: *123 [lỗi] client: 103.10.20.30, server: abc.com, request: "GET /..." host: "abc.com"

# Lọc lỗi nghiêm trọng
grep "\[error\]\|\[crit\]\|\[alert\]\|\[emerg\]" /var/log/nginx/error.log | tail -20

# Lỗi upstream (PHP-FPM lỗi)
grep "upstream" /var/log/nginx/error.log | tail -20

# Lỗi permission
grep "Permission denied" /var/log/nginx/error.log | tail -10

# Connect refused (service bị tắt)
grep "Connection refused" /var/log/nginx/error.log | tail -10
```

---

## 10.2 Phân tích log tìm vấn đề

### Tình huống: Website chậm bất thường vào buổi trưa

```bash
# Bước 1: Tìm giờ nào có nhiều request nhất
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f2 | sort | uniq -c | sort -rn

# Bước 2: Tìm URL nào bị request nhiều nhất vào giờ đó
awk '$4 >= "[26/Jun/2026:12:00:00" && $4 <= "[26/Jun/2026:13:00:00"' \
    /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head -20

# Bước 3: Xem request time (nếu Nginx có log $request_time)
# Thêm $request_time vào log format trong nginx.conf:
# log_format main '$remote_addr ... $request_time $upstream_response_time';

# Tìm request chậm nhất (> 5 giây)
awk '$NF > 5' /var/log/nginx/access.log | awk '{print $NF, $7}' | sort -rn | head -10
```

### Tình huống: Server bị DDoS / traffic bất thường

```bash
# Đếm connections đang active theo IP
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -20

# Xem SYN connections (dấu hiệu SYN flood)
netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print state[key], "\t", key}'

# Tổng số connections đến port 80/443
ss -s

# IP nào kết nối nhiều nhất đến port 443
ss -tn | awk '$4 ~ /:443$/ {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
```

### Tình huống: Sau khi deploy code — website lỗi

```bash
# Xem lỗi PHP real-time
tail -f /var/log/php8.1-fpm.log

# Xem Nginx error real-time
tail -f /var/log/nginx/error.log

# Combine cả 2 log xem cùng lúc
tail -f /var/log/nginx/error.log /var/log/php8.1-fpm.log

# Tìm lỗi theo thời gian deploy (giả sử deploy lúc 14:00)
sed -n '/2026\/06\/26 14:00/,/2026\/06\/26 14:10/p' /var/log/nginx/error.log
```

---

## 10.3 Log rotation & quản lý log

```bash
# Log Nginx mặc định không rotation → đầy disk
# Cấu hình logrotate

nano /etc/logrotate.d/nginx
```

```
/var/log/nginx/*.log {
    daily              ; Rotate hàng ngày
    missingok          ; Không lỗi nếu log không tồn tại
    rotate 14          ; Giữ 14 bản log cũ
    compress           ; Nén bản cũ bằng gzip
    delaycompress      ; Nén từ bản thứ 2 trở đi (bản mới nhất chưa nén)
    notifempty         ; Không rotate nếu log rỗng
    create 0640 www-data adm    ; Tạo file log mới với permission này
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

```bash
# Test logrotate
logrotate --debug /etc/logrotate.d/nginx

# Force rotate ngay (khi disk đầy do log)
logrotate --force /etc/logrotate.d/nginx

# Xem disk space do log chiếm
du -sh /var/log/nginx/
du -sh /var/log/php/
du -sh /var/log/mysql/

# Xóa nhanh log cũ > 30 ngày
find /var/log/nginx/ -name "*.gz" -mtime +30 -delete
```

---
---

# PHẦN 11 — REVERSE PROXY & NÂNG CẤP HẠ TẦNG

## 11.1 Nginx Reverse Proxy

Dùng khi cần:
- Đứng trước Node.js, Python (Django/Flask), Java app
- Đứng trước server nội bộ không có public IP
- Load balancing đơn giản

```nginx
# /etc/nginx/sites-available/app.abc.com
server {
    listen 443 ssl http2;
    server_name app.abc.com;

    # SSL config
    ssl_certificate     /etc/letsencrypt/live/app.abc.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.abc.com/privkey.pem;
    include /etc/nginx/snippets/ssl-hardening.conf;

    # === Reverse Proxy đến Node.js chạy port 3000 ===
    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;

        # Headers quan trọng
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_set_header   Upgrade           $http_upgrade;    # Cho WebSocket
        proxy_set_header   Connection        "upgrade";        # Cho WebSocket

        # Timeout
        proxy_connect_timeout  60s;
        proxy_send_timeout     60s;
        proxy_read_timeout     60s;

        # Buffer
        proxy_buffering    on;
        proxy_buffer_size  4k;
        proxy_buffers      8 4k;
    }

    # Static files phục vụ trực tiếp qua Nginx (nhanh hơn)
    location /static/ {
        alias /var/www/app.abc.com/static/;
        expires 30d;
    }
}
```

```nginx
# === Load Balancing đơn giản ===
upstream backend {
    least_conn;                          # Chọn server ít connection nhất
    server 192.168.1.10:8080 weight=3;   # weight=3: nhận 3x traffic
    server 192.168.1.11:8080 weight=1;
    server 192.168.1.12:8080 backup;     # Chỉ dùng khi 2 server kia chết
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

---

## 11.2 Cài đặt nhiều PHP version song song

```bash
# Thêm PPA PHP (hỗ trợ nhiều version)
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update

# Cài PHP 7.4, 8.0, 8.1, 8.2, 8.3 song song
apt install php7.4-fpm php7.4-mysql php7.4-curl php7.4-gd php7.4-mbstring php7.4-xml -y
apt install php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml -y
apt install php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml -y

# Kiểm tra version đang chạy
php7.4 -v
php8.1 -v
php8.3 -v

# Xem các FPM socket đang có
ls /run/php/
# php7.4-fpm.sock
# php8.1-fpm.sock
# php8.3-fpm.sock
```

```nginx
# Cấu hình từng domain dùng PHP version khác nhau

# Site cũ cần PHP 7.4
server {
    server_name old-site.com;
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;   # PHP 7.4
        include snippets/fastcgi-php.conf;
    }
}

# Site mới dùng PHP 8.3
server {
    server_name new-site.com;
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;   # PHP 8.3
        include snippets/fastcgi-php.conf;
    }
}
```

```bash
# Chuyển PHP CLI version mặc định
update-alternatives --config php
# → Chọn version cần dùng

# Xem version hiện tại của CLI
php -v
```

---

## 11.3 Redis cache cho WordPress

```bash
# Cài Redis
apt install redis-server php8.1-redis -y
systemctl enable redis-server && systemctl start redis-server

# Kiểm tra Redis chạy
redis-cli ping
# → PONG

# Cài plugin WordPress Object Cache
# Dùng plugin: Redis Object Cache (by Till Krüss)
wp plugin install redis-cache --activate --path=/var/www/abc.com
```

```php
// Thêm vào wp-config.php (trước dòng "/* That's all, stop editing! */")
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_PREFIX', 'abc_');    // Prefix riêng cho từng site
```

```bash
# Kích hoạt Redis cache
wp redis enable --path=/var/www/abc.com

# Kiểm tra trạng thái
wp redis status --path=/var/www/abc.com

# Xem Redis đang cache gì
redis-cli
KEYS abc_*
INFO stats
# → keyspace_hits, keyspace_misses → tính hit rate
```

---
---

# PHẦN 12 — SCRIPT TỰ ĐỘNG HÓA THỰC TẾ

## 12.1 Script setup VPS mới từ đầu

```bash
nano /usr/local/bin/setup-vps.sh
```

```bash
#!/bin/bash
# =====================================================
# Setup VPS mới — KTV Nhân Hòa
# Cách dùng: bash setup-vps.sh [domain] [php_version]
# Ví dụ:     bash setup-vps.sh abc.com 8.1
# =====================================================

set -e  # Dừng nếu có lỗi

DOMAIN=${1:-"example.com"}
PHP_VER=${2:-"8.1"}
WEBROOT="/var/www/$DOMAIN"
DB_NAME=$(echo "$DOMAIN" | tr '.' '_')
DB_USER="${DB_NAME}_user"
DB_PASS=$(openssl rand -base64 16 | tr -d '=/+')

echo "======================================"
echo "🚀 Setup VPS cho domain: $DOMAIN"
echo "   PHP version: $PHP_VER"
echo "======================================"

# === 1. Update system ===
echo "📦 Updating system..."
apt update -qq && apt upgrade -y -qq

# === 2. Cài packages cơ bản ===
echo "📦 Installing base packages..."
apt install -y -qq curl wget git unzip htop ncdu ufw fail2ban

# === 3. Cài Nginx ===
echo "🌐 Installing Nginx..."
apt install -y -qq nginx
systemctl enable nginx

# === 4. Cài MariaDB ===
echo "🗄️ Installing MariaDB..."
apt install -y -qq mariadb-server
systemctl enable mariadb
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

# === 5. Cài PHP ===
echo "🐘 Installing PHP $PHP_VER..."
apt install -y -qq software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update -qq
apt install -y -qq php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-cli \
    php${PHP_VER}-curl php${PHP_VER}-gd php${PHP_VER}-mbstring \
    php${PHP_VER}-xml php${PHP_VER}-zip php${PHP_VER}-redis

# === 6. Cài Certbot ===
echo "🔐 Installing Certbot..."
apt install -y -qq certbot python3-certbot-nginx

# === 7. Setup database ===
echo "🗄️ Creating database..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# === 8. Setup web directory ===
echo "📁 Setting up web directory..."
mkdir -p "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"

# === 9. Nginx config ===
echo "⚙️ Configuring Nginx..."
cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"
nginx -t && systemctl reload nginx

# === 10. UFW Firewall ===
echo "🔥 Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# === 11. Fail2ban ===
echo "🛡️ Configuring Fail2ban..."
systemctl enable fail2ban && systemctl start fail2ban

# === 12. SSL ===
echo "🔒 Installing SSL certificate..."
if dig "$DOMAIN" A +short | grep -q "."; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" \
        --non-interactive --agree-tos --email "ktv@nhanhoa.com" \
        --redirect
    echo "✅ SSL installed"
else
    echo "⚠️  Domain $DOMAIN chưa trỏ về server này — bỏ qua SSL"
fi

# === DONE ===
echo ""
echo "======================================"
echo "✅ SETUP HOÀN THÀNH!"
echo "======================================"
echo "🌐 Domain:       $DOMAIN"
echo "📁 Web root:     $WEBROOT"
echo "🗄️ Database:     $DB_NAME"
echo "👤 DB User:      $DB_USER"
echo "🔑 DB Password:  $DB_PASS"
echo "🐘 PHP Version:  $PHP_VER"
echo ""
echo "⚠️  LƯU LẠI THÔNG TIN TRÊN!"
echo "======================================"

# Lưu thông tin vào file
cat > "/root/setup-info-$DOMAIN.txt" << EOF
Domain:      $DOMAIN
Web root:    $WEBROOT
DB Name:     $DB_NAME
DB User:     $DB_USER
DB Password: $DB_PASS
PHP:         $PHP_VER
Setup date:  $(date)
EOF
chmod 600 "/root/setup-info-$DOMAIN.txt"
```

```bash
chmod +x /usr/local/bin/setup-vps.sh

# Cách dùng:
setup-vps.sh abc.com 8.1
```

---

## 12.2 Script backup thông minh

```bash
nano /usr/local/bin/smart-backup.sh
```

```bash
#!/bin/bash
# =====================================================
# Smart Backup Script — KTV Nhân Hòa
# Backup web + database + gửi report
# Cách dùng: smart-backup.sh [domain] hoặc smart-backup.sh all
# =====================================================

BACKUP_DIR="/backup"
RETENTION_DAYS=7
ALERT_EMAIL="ktv@nhanhoa.com"
LOG_FILE="/var/log/smart-backup.log"
TARGET=${1:-"all"}

mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

backup_site() {
    local DOMAIN=$1
    local WEBROOT="/var/www/$DOMAIN"
    local DATE=$(date +%Y%m%d_%H%M%S)
    local SUCCESS=true

    log "📦 Bắt đầu backup: $DOMAIN"

    # Backup files
    if [ -d "$WEBROOT" ]; then
        tar -czf "$BACKUP_DIR/${DOMAIN}_web_${DATE}.tar.gz" "$WEBROOT" 2>/dev/null
        local WEB_SIZE=$(du -sh "$BACKUP_DIR/${DOMAIN}_web_${DATE}.tar.gz" | cut -f1)
        log "✅ Web backup: $WEB_SIZE"
    else
        log "⚠️ Không tìm thấy: $WEBROOT"
        SUCCESS=false
    fi

    # Detect và backup database (tìm DB liên quan đến domain)
    local DB_NAME=$(echo "$DOMAIN" | tr '.' '_' | tr '-' '_')
    if mysql -e "USE \`$DB_NAME\`" 2>/dev/null; then
        mysqldump --single-transaction --quick "$DB_NAME" \
            | gzip > "$BACKUP_DIR/${DOMAIN}_db_${DATE}.sql.gz"
        local DB_SIZE=$(du -sh "$BACKUP_DIR/${DOMAIN}_db_${DATE}.sql.gz" | cut -f1)
        log "✅ DB backup: $DB_SIZE"
    fi

    # Xóa backup cũ
    find "$BACKUP_DIR" -name "${DOMAIN}_*" -mtime +$RETENTION_DAYS -delete
    log "🗑️ Xóa backup cũ hơn $RETENTION_DAYS ngày"

    echo "$SUCCESS"
}

check_disk_space() {
    local USAGE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$USAGE" -gt 85 ]; then
        log "🚨 CẢNH BÁO: Disk backup đang dùng ${USAGE}%!"
        echo "⚠️ Disk backup: ${USAGE}%" | mail -s "Disk Alert" "$ALERT_EMAIL"
    fi
}

log "======== Smart Backup bắt đầu: $(date) ========"
check_disk_space

if [ "$TARGET" = "all" ]; then
    # Backup tất cả domain trong /var/www/
    for domain_dir in /var/www/*/; do
        domain=$(basename "$domain_dir")
        [ "$domain" = "html" ] && continue   # Bỏ qua /var/www/html mặc định
        backup_site "$domain"
    done
else
    backup_site "$TARGET"
fi

# Report
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "📊 Tổng dung lượng backup: $TOTAL_SIZE"
log "======== Smart Backup hoàn thành ========"
```

```bash
chmod +x /usr/local/bin/smart-backup.sh

# Thêm cron
crontab -e
# 0 2 * * * /usr/local/bin/smart-backup.sh all
```

---

## 12.3 Script health check server hàng ngày

```bash
nano /usr/local/bin/health-check.sh
```

```bash
#!/bin/bash
# =====================================================
# Server Health Check — KTV Nhân Hòa
# Chạy hàng ngày, gửi report nếu có vấn đề
# =====================================================

ALERT_EMAIL="ktv@nhanhoa.com"
LOG_FILE="/var/log/health-check.log"
REPORT=""
ALERT=false

add_report() {
    REPORT+="$1\n"
    echo "$1" >> "$LOG_FILE"
}

check_alert() {
    local STATUS=$1
    local MSG=$2
    if [ "$STATUS" = "WARN" ] || [ "$STATUS" = "CRIT" ]; then
        ALERT=true
        add_report "[$STATUS] $MSG"
    else
        add_report "[OK]   $MSG"
    fi
}

echo "======== Health Check: $(date) ========" >> "$LOG_FILE"

# === 1. CPU Load ===
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
CORES=$(nproc)
LOAD_INT=$(echo "$LOAD * 100" | bc | cut -d. -f1)
CORES_INT=$((CORES * 100))
if [ "$LOAD_INT" -gt "$((CORES_INT * 2))" ]; then
    check_alert "CRIT" "CPU Load cao: $LOAD (cores: $CORES)"
elif [ "$LOAD_INT" -gt "$CORES_INT" ]; then
    check_alert "WARN" "CPU Load cao: $LOAD (cores: $CORES)"
else
    check_alert "OK" "CPU Load: $LOAD"
fi

# === 2. RAM ===
RAM_AVAIL=$(free | awk '/^Mem:/ {print int($7/$2*100)}')
if [ "$RAM_AVAIL" -lt 10 ]; then
    check_alert "CRIT" "RAM còn lại: ${RAM_AVAIL}%"
elif [ "$RAM_AVAIL" -lt 20 ]; then
    check_alert "WARN" "RAM còn lại: ${RAM_AVAIL}%"
else
    check_alert "OK" "RAM còn lại: ${RAM_AVAIL}%"
fi

# === 3. Disk ===
while IFS= read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    if [ "$USAGE" -gt 90 ]; then
        check_alert "CRIT" "Disk $MOUNT: ${USAGE}% đầy"
    elif [ "$USAGE" -gt 80 ]; then
        check_alert "WARN" "Disk $MOUNT: ${USAGE}% đầy"
    else
        check_alert "OK" "Disk $MOUNT: ${USAGE}%"
    fi
done < 1 && /^\/dev/')

# === 4. Services ===
for service in nginx mariadb mysql php8.1-fpm php8.3-fpm; do
    if systemctl is-active "$service" &>/dev/null; then
        check_alert "OK" "Service $service: running"
    else
        # Thử restart
        systemctl start "$service" 2>/dev/null
        sleep 2
        if systemctl is-active "$service" &>/dev/null; then
            check_alert "WARN" "Service $service: đã down, đã restart thành công"
        else
            check_alert "CRIT" "Service $service: DOWN và không restart được!"
        fi
    fi
done

# === 5. SSL Expiry ===
for DOMAIN in $(ls /etc/nginx/sites-enabled/ 2>/dev/null | head -10); do
    CERT=$(grep "ssl_certificate " "/etc/nginx/sites-enabled/$DOMAIN" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
    if [ -f "$CERT" ]; then
        EXPIRY=$(openssl x509 -in "$CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
        DAYS=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))
        if [ "$DAYS" -lt 7 ]; then
            check_alert "CRIT" "SSL $DOMAIN: hết hạn sau $DAYS ngày!"
        elif [ "$DAYS" -lt 30 ]; then
            check_alert "WARN" "SSL $DOMAIN: hết hạn sau $DAYS ngày"
        else
            check_alert "OK" "SSL $DOMAIN: còn $DAYS ngày"
        fi
    fi
done

echo "========================================" >> "$LOG_FILE"

# Gửi email nếu có vấn đề
if [ "$ALERT" = "true" ]; then
    echo -e "🚨 Server Health Alert\n\n$REPORT" | mail -s "⚠️ Health Alert — $(hostname)" "$ALERT_EMAIL"
fi
```

```bash
chmod +x /usr/local/bin/health-check.sh

# Chạy lúc 6h sáng hàng ngày
crontab -e
# 0 6 * * * /usr/local/bin/health-check.sh
```

---
---

# PHẦN 13 — EDGE CASES & TÌNH HUỐNG KHÓ

> Đây là những tình huống khiến fresher bị stuck nhất. Xử lý được những cái này = lên level hẳn.

## 13.1 Server bị DDoS — Xử lý khẩn cấp

```bash
# === BƯỚC 1: XÁC NHẬN ===
# Tải server bất thường
uptime
# Xem connections đồng thời
ss -s
netstat -ntu | wc -l

# Xác định loại tấn công
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
# → Nhiều IP khác nhau → Distributed DDoS → khó chặn
# → 1-2 IP chiếm phần lớn → DDoS từ ít nguồn → chặn IP được

# === BƯỚC 2: CHẶN IP ĐANG TẤN CÔNG ===
# Chặn 1 IP
iptables -I INPUT -s 1.2.3.4 -j DROP

# Chặn nhiều IP từ file
cat /tmp/attacker-ips.txt | while read ip; do
    iptables -I INPUT -s "$ip" -j DROP
done

# === BƯỚC 3: RATE LIMIT TẤT CẢ ===
# Giới hạn mỗi IP chỉ được 20 connection đến port 80
iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 20 -j DROP
iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above 20 -j DROP

# === BƯỚC 4: NGINX RATE LIMITING ===
# Thêm ngay vào nginx.conf (http block):
# limit_req_zone $binary_remote_addr zone=flood:10m rate=2r/s;
# Trong server block:
# limit_req zone=flood burst=5 nodelay;
nginx -t && systemctl reload nginx

# === BƯỚC 5: NẾU KHÔNG KIỂM SOÁT ĐƯỢC ===
# Liên hệ data center để bật null-routing / upstream filtering
# Hoặc tạm thời tắt website để bảo vệ server
# systemctl stop nginx  ← hạn chót, không nên

# === BƯỚC 6: CLEANUP SAU KHI QUA NGUY ===
# Xem rules hiện tại
iptables -L INPUT -n --line-numbers

# Xóa rules tạm thời (sau khi tấn công qua)
iptables -D INPUT -p tcp --dport 80 -m connlimit --connlimit-above 20 -j DROP

# Lưu rules (nếu dùng lâu dài)
iptables-save > /etc/iptables/rules.v4
```

---

## 13.2 Database bị corrupt

```
Dấu hiệu:
- WordPress hiện "Error establishing database connection"
- MySQL log: "Table './db/wp_posts' is marked as crashed"
- mysqldump lỗi
```

```bash
# === KIỂM TRA ===
# Xem log MySQL
tail -50 /var/log/mysql/error.log | grep -i "corrupt\|crash\|error"

# Kiểm tra tất cả tables
mysqlcheck -u root -p --all-databases

# === FIX — MYISAM TABLE ===
mysql -u root -p
USE abc_db;
# Tìm table bị lỗi
SHOW TABLE STATUS WHERE Comment LIKE '%crash%';

# Fix table bị crash
REPAIR TABLE wp_posts;
REPAIR TABLE wp_options;
# Nếu REPAIR không được:
OPTIMIZE TABLE wp_posts;

# === FIX — INNODB TABLE (phức tạp hơn) ===
# Bật force recovery mode (chỉ đọc, không ghi)
nano /etc/mysql/mariadb.conf.d/50-server.cnf
# Thêm: innodb_force_recovery = 1
# (tăng từ 1-6 nếu vẫn không start được)

systemctl restart mariadb

# Khi MySQL start được → export ngay
mysqldump -u root -p --all-databases > /backup/emergency_dump.sql

# Sau khi dump xong → xóa force recovery, restore từ dump
nano /etc/mysql/mariadb.conf.d/50-server.cnf
# Xóa dòng innodb_force_recovery

systemctl restart mariadb
mysql -u root -p < /backup/emergency_dump.sql
```

---

## 13.3 Server hết RAM — Không SSH được

```
Tình huống: Server OOM (Out Of Memory), SSH timeout, không vào được
```

```bash
# === NẾU VẪN VÀO ĐƯỢC (chậm) ===
# Tìm process ăn RAM nhất và kill ngay
ps aux --sort=-%mem | head -5
kill -9 [PID]

# Xóa cache của hệ thống (không mất data)
sync && echo 3 > /proc/sys/vm/drop_caches

# Restart PHP-FPM (giải phóng memory leak)
systemctl restart php8.1-fpm

# === NẾU KHÔNG SSH ĐƯỢC ===
# Vào qua Console (VPS thường có KVM console trên portal quản lý)
# Đăng nhập → kill process thủ công

# === PHÒNG NGỪA ===
# Thêm swap (nếu server không có)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Cấu hình OOM Killer ưu tiên kill process nào
# Ưu tiên kill PHP-FPM trước MySQL (để DB không bị corrupt)
echo 500 > /proc/$(pgrep php-fpm | head -1)/oom_score_adj   # PHP: dễ bị kill hơn
echo -100 > /proc/$(pgrep mysql | head -1)/oom_score_adj     # MySQL: khó bị kill hơn

# Giới hạn memory cho từng service
# /etc/systemd/system/php8.1-fpm.service.d/override.conf
# [Service]
# MemoryLimit=512M
```

---

## 13.4 Disk đầy 100% — Website chết

```bash
# === XÁC NHẬN ===
df -h
# /dev/vda1   50G   50G    0  100%  /   ← ĐẦY!

# === TÌM THỦ PHẠM ===
# Top 10 thư mục lớn nhất
du -h --max-depth=2 / 2>/dev/null | sort -rh | head -20

# Thường là:
# /var/log/         ← log chưa rotate
# /var/www/         ← backup hay file upload lớn
# /tmp/             ← session, temp files
# /home/            ← dữ liệu người dùng

# === DỌN NGAY (theo thứ tự an toàn) ===

# 1. Dọn apt cache
apt clean
apt autoremove -y

# 2. Dọn journal log (giữ 7 ngày gần nhất)
journalctl --vacuum-time=7d

# 3. Truncate log lớn (KHÔNG xóa — truncate giữ file descriptor)
ls -lh /var/log/nginx/access.log
truncate -s 0 /var/log/nginx/access.log
truncate -s 0 /var/log/nginx/error.log

# 4. Dọn log PHP
find /var/log/php/ -name "*.log" -size +100M -exec truncate -s 0 {} \;

# 5. Dọn session PHP cũ
find /var/lib/php/sessions/ -type f -mtime +1 -delete

# 6. Dọn tmp files
find /tmp -type f -mtime +1 -delete 2>/dev/null

# 7. Nếu vẫn chưa đủ → tìm file lớn bất thường
find / -type f -size +500M 2>/dev/null

# === SAU KHI CÓ SPACE ===
# Restart web server (đôi khi bị treo do không ghi được log)
systemctl restart nginx
systemctl restart php8.1-fpm

# Cấu hình logrotate để không xảy ra lại
logrotate --force /etc/logrotate.d/nginx
```

---

## 13.5 Cert Let's Encrypt lỗi không rõ nguyên nhân

```bash
# === DEBUG TOÀN DIỆN ===

# Bước 1: Xem log chi tiết
certbot renew --dry-run --debug 2>&1 | tee /tmp/certbot-debug.log
cat /tmp/certbot-debug.log

# Bước 2: Các lỗi hay gặp và fix

# Lỗi: "Problem binding to port 80"
# Nguyên nhân: Nginx/Apache đang dùng port 80
ss -tlnp | grep :80
# Fix: dùng certonly với standalone
systemctl stop nginx
certbot certonly --standalone -d abc.com -d www.abc.com
systemctl start nginx

# Lỗi: "DNS problem: NXDOMAIN looking up A for abc.com"
# Nguyên nhân: Domain không resolve
dig abc.com A
# Fix: Đợi DNS propagate, kiểm tra A record

# Lỗi: "The client lacks sufficient authorization"
# Nguyên nhân: Có nhiều server block cùng xử lý domain
grep -r "server_name.*abc.com" /etc/nginx/
# Fix: Đảm bảo chỉ có 1 server block cho domain

# Lỗi: "Failed to connect to host for DVSNI challenge"
# Nguyên nhân: Port 443 bị firewall block
ufw allow 443/tcp
nmap -p 443 [IP của mình]

# Lỗi: "urn:ietf:params:acme:error:rateLimited"
# Nguyên nhân: Vượt rate limit
# Fix: Chờ 1 tuần hoặc dùng staging để test
certbot --nginx --staging -d abc.com  # Test với staging (không bị limit)

# Bước 3: Reset certbot nếu mọi thứ thất bại
# Backup cert cũ trước
cp -r /etc/letsencrypt/live/abc.com /backup/cert_bak_$(date +%Y%m%d)

# Xóa và cài lại
certbot delete --cert-name abc.com
certbot --nginx -d abc.com -d www.abc.com

# Bước 4: Kiểm tra ACME challenge hoạt động không
# Tạo file test
mkdir -p /var/www/abc.com/.well-known/acme-challenge
echo "test" > /var/www/abc.com/.well-known/acme-challenge/testfile
curl http://abc.com/.well-known/acme-challenge/testfile
# Phải ra: test
# Nếu không ra → Nginx config không serve được .well-known

# Fix Nginx serve .well-known
# Thêm vào server block:
# location ~ /.well-known/acme-challenge {
#     allow all;
#     root /var/www/abc.com;
# }
```

---

## 📋 Quick Reference — Những lệnh fresher hay quên

```bash
# Xem service nào đang listen port nào
ss -tlnp

# Xem process nào đang dùng 1 file
lsof /var/log/nginx/access.log

# Xem file nào đang được mở bởi process
lsof -p [PID]

# Theo dõi system call của process (debug nâng cao)
strace -p [PID]

# Xem lịch sử command đã chạy
history | grep certbot
history | grep nginx

# Tìm file bị thay đổi gần đây nhất
find /etc/nginx -newer /etc/nginx/nginx.conf -type f

# So sánh 2 file config
diff /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# Chạy lệnh và ghi cả output lẫn error vào file
command 2>&1 | tee /tmp/output.log

# Test Nginx config chi tiết (in ra full config)
nginx -T

# Kiểm tra syntax PHP file
php -l /var/www/abc.com/wp-config.php

# Xem nginx đang load config từ đâu
nginx -V 2>&1 | grep "conf-path"

# Decode base64 (thường thấy trong webshell)
echo "dGVzdA==" | base64 --decode

# Check port có open từ bên ngoài không
nc -zv [IP] 443

# Xem tất cả cronjob trên hệ thống
for user in $(cut -f1 -d: /etc/passwd); do crontab -u $user -l 2>/dev/null; done
```

---

> **💡 Tips từ senior KTV:**
> 
> 1. **Luôn `nginx -t` trước khi reload** — không bao giờ reload blindly
> 2. **Backup trước khi sửa bất cứ thứ gì** — kể cả sửa 1 dòng config
> 3. **Đọc log từ DƯỚI lên** — lỗi mới nhất ở cuối file
> 4. **Test trên staging trước** — đặc biệt với database migration
> 5. **Khi không biết → hỏi senior, đừng tự xử production** — sai một cái mất cả tiếng fix
> 6. **Ghi lại những gì đã làm** — sau 1 tuần sẽ không nhớ đã sửa gì
> 7. **`set -e` trong shell script** — script dừng ngay khi có lỗi, tránh chạy tiếp gây hại
