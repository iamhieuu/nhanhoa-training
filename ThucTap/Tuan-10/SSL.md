# 🔐 LAB CÁ NHÂN: CÀI ĐẶT SSL/TLS TỪ ĐẦU ĐẾN CUỐI
## Môi trường: Ubuntu 22.04 LTS | IP: 192.168.136.131


---

# ═══════════════════════════════════
### BƯỚC 1: CÀI APACHE & CHUẨN BỊ MÁY
# ═══════════════════════════════════

## 1.1 Cập nhật hệ thống

```bash
# Đăng nhập máy chủ với quyền root
ssh root@192.168.136.131

# Cập nhật package list và upgrade
apt update && apt upgrade -y

# Kiểm tra Ubuntu version (phải là 22.04)
lsb_release -a
```

**Kết quả mong đợi:**
```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
```

---

## 1.2 Cài Apache Web Server

```bash
# Cài Apache
apt install apache2 -y

# Khởi động và bật auto-start
systemctl start apache2
systemctl enable apache2

# Kiểm tra trạng thái
systemctl status apache2
```


```bash
# Mở firewall cho HTTP và HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp   # SSH - ĐỪNG QUÊN cái này
ufw enable
ufw status
```
<img width="329" height="137" alt="image" src="https://github.com/user-attachments/assets/048d21b8-2286-4b9d-b92c-188544e49af5" />

```bash
# Test Apache đang chạy
curl -I http://192.168.136.131
```
<img width="313" height="157" alt="image" src="https://github.com/user-attachments/assets/78afc04f-a9b9-4f68-8a74-b281ecf55a8a" />


---

# ═══════════════════════════════════
### BƯỚC 2: TẠO WEBSITE DEMO THẬT
# ═══════════════════════════════════

> **Giải thích:** Trong môi trường lab, chúng ta giả lập một website
> của khách hàng Nhân Hòa. Tên domain: `lab.nhanhhoa.local`
> (Sau này khi có domain thật, quy trình hoàn toàn giống nhau)

## 2.1 Tạo cấu trúc thư mục website

```bash
# Tạo thư mục cho website (cấu trúc chuẩn Nhân Hòa)
mkdir -p /var/www/lab.nhanhhoa.local/public_html
mkdir -p /var/log/apache2/lab.nhanhhoa.local

# Phân quyền đúng chuẩn
chown -R www-data:www-data /var/www/lab.nhanhhoa.local/
chmod -R 755 /var/www/lab.nhanhhoa.local/
```

## 2.2 Tạo trang HTML demo

```bash
# Tạo file index.html
cat > /var/www/lab.nhanhhoa.local/public_html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lab SSL – Nhân Hòa Hosting</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        .badge {
            display: inline-block;
            background: #1e40af;
            color: #93c5fd;
            padding: 0.4rem 1rem;
            border-radius: 999px;
            font-size: 0.85rem;
            letter-spacing: 0.05em;
            margin-bottom: 1.5rem;
        }
        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            color: #f1f5f9;
            margin-bottom: 1rem;
        }
        .status {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 0.75rem;
            padding: 1.5rem 2.5rem;
            margin: 1.5rem 0;
        }
        .dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #22c55e;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.4; }
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin-top: 2rem;
            max-width: 500px;
            margin-inline: auto;
        }
        .info-card {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 0.5rem;
            padding: 1rem;
        }
        .info-card .label {
            font-size: 0.75rem;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .info-card .value {
            font-size: 1rem;
            color: #94a3b8;
            font-family: monospace;
            margin-top: 0.3rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="badge">🔒 LAB SSL – NHÂN HÒA HOSTING</div>
        <h1>Website Demo</h1>
        <p style="color:#64748b; margin-bottom:1rem;">
            Trang này dùng để thực hành cài đặt SSL/TLS
        </p>
        <div class="status">
            <div class="dot"></div>
            <span>Server đang chạy bình thường</span>
        </div>
        <div class="info-grid">
            <div class="info-card">
                <div class="label">Server IP</div>
                <div class="value">192.168.136.131</div>
            </div>
            <div class="info-card">
                <div class="label">Web Server</div>
                <div class="value">Apache 2.4</div>
            </div>
            <div class="info-card">
                <div class="label">OS</div>
                <div class="value">Ubuntu 22.04</div>
            </div>
            <div class="info-card">
                <div class="label">SSL Status</div>
                <div class="value" id="ssl">HTTP (chưa có)</div>
            </div>
        </div>
        <script>
            if (location.protocol === 'https:') {
                document.getElementById('ssl').textContent = '✅ HTTPS OK';
                document.getElementById('ssl').style.color = '#22c55e';
            }
        </script>
    </div>
</body>
</html>
HTMLEOF

echo "✅ Tạo trang HTML xong!"
```

---

## ════════════════════════════════════════════════════
### BƯỚC 3: CẤU HÌNH VIRTUALHOST CHO APACHE
## ════════════════════════════════════════════════════ 

> **Giải thích VirtualHost là gì:**
> Một server Apache có thể host nhiều website cùng lúc.
> VirtualHost là cấu hình cho từng website riêng biệt.

## 3.1 Tạo file VirtualHost

```bash
# Tạo file cấu hình VirtualHost (HTTP - cổng 80 trước)
cat > /etc/apache2/sites-available/lab.nhanhhoa.local.conf << 'APACHEEOF'
# ─────────────────────────────────────────────────────
# VirtualHost cho lab.nhanhhoa.local
# Cổng 80 (HTTP) – CHƯA có SSL
# ─────────────────────────────────────────────────────
<VirtualHost *:80>

    # Tên domain chính
    ServerName lab.nhanhhoa.local

    # Domain phụ www
    ServerAlias www.lab.nhanhhoa.local

    # Thư mục chứa file website
    DocumentRoot /var/www/lab.nhanhhoa.local/public_html

    # File log riêng cho domain này
    ErrorLog /var/log/apache2/lab.nhanhhoa.local/error.log
    CustomLog /var/log/apache2/lab.nhanhhoa.local/access.log combined

    # Cấu hình quyền truy cập thư mục
    <Directory /var/www/lab.nhanhhoa.local/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>
APACHEEOF

echo "✅ Tạo VirtualHost xong!"
```

## 3.2 Kích hoạt site và kiểm tra

```bash
# Kích hoạt module cần thiết
a2enmod rewrite          # Để sau này dùng redirect HTTP→HTTPS
a2enmod headers          # Để thêm security headers sau này
a2enmod ssl              # Module SSL (cần cho HTTPS)

# Kích hoạt website mới
a2ensite lab.nhanhhoa.local.conf

# Tắt website default của Apache (không cần nữa)
a2dissite 000-default.conf

# Kiểm tra cú pháp cấu hình Apache (LUÔN làm bước này trước khi reload)
apache2ctl configtest
systemctl reload apache2

```



## 3.3 Thêm hosts file để test local

```bash
# Vì đây là lab local (không có domain thật),
# cần thêm vào /etc/hosts để trình duyệt nhận ra domain

# Trên máy SERVER (192.168.136.131)
echo "127.0.0.1  lab.nhanhhoa.local www.lab.nhanhhoa.local" >> /etc/hosts

# Trên máy WINDOWS của bạn (mở Notepad as Admin):
# File: C:\Windows\System32\drivers\etc\hosts
# Thêm dòng:
# 192.168.136.131  lab.nhanhhoa.local www.lab.nhanhhoa.local

# Trên máy Linux/Mac client:
# sudo nano /etc/hosts
# Thêm: 192.168.136.131  lab.nhanhhoa.local
```

## 3.4 Kiểm tra website đang chạy (chưa có SSL)

```bash
# Test bằng curl từ chính server
curl -I http://lab.nhanhhoa.local
```

**Kết quả mong đợi:**
```
HTTP/1.1 200 OK
Date: ...
Server: Apache/2.4.52 (Ubuntu)
Content-Type: text/html; charset=UTF-8
```

```bash
# Xem file log để chắc chắn request đã vào
tail -f /var/log/apache2/lab.nhanhhoa.local/access.log
# Nhấn Ctrl+C để thoát
```
<img width="959" height="456" alt="image" src="https://github.com/user-attachments/assets/22325ca8-8e82-4e0a-957f-34eecf6649d0" />

---

## ══════════════════════════════════════════════════
### BƯỚC 4A: CÀI SSL – DÙNG SELF-SIGNED (CHO LAB KHÔNG CÓ DOMAIN)
## ══════════════════════════════════════════════════

> **Lưu ý quan trọng:** Let's Encrypt yêu cầu domain phải trỏ về
> server từ internet. Trong lab local (192.168.x.x) KHÔNG dùng được
> Let's Encrypt. Chúng ta sẽ học CÁCH CÀI giống hệt nhau với
> Self-Signed Certificate trước.
>
> Phần 4B sẽ hướng dẫn Let's Encrypt khi bạn có domain thật.

## 4A.1 Hiểu Self-Signed Certificate

```
Let's Encrypt (domain thật):              Self-Signed (lab):
┌─────────────────────────┐               ┌─────────────────────────┐
│  CA: Let's Encrypt      │               │  CA: Chính bạn ký       │
│  Browser tin tưởng      │               │  Browser KHÔNG tin       │
│  Dùng cho production    │               │  Dùng để học/test       │
│  Miễn phí, 90 ngày      │               │  Có thể tự đặt ngày HH  │
└─────────────────────────┘               └─────────────────────────┘

→ Cách CÀI VÀO SERVER hoàn toàn giống nhau!
→ Chỉ khác ở chỗ: Ai ký certificate
```

## 4A.2 Tạo Self-Signed Certificate

```bash
# Tạo thư mục lưu SSL cho lab
mkdir -p /etc/ssl/lab.nhanhhoa.local

# Tạo Private Key (2048-bit RSA)
openssl genrsa -out /etc/ssl/lab.nhanhhoa.local/private.key 2048

# Xem Private Key vừa tạo (để hiểu nó trông như thế nào)
cat /etc/ssl/lab.nhanhhoa.local/private.key
````
<img width="657" height="366" alt="image" src="https://github.com/user-attachments/assets/e2ed2919-9289-4b8d-b301-9e8133c0a78a" />


```

# Tạo Certificate (tự ký) - hiệu lực 365 ngày
openssl req -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -key /etc/ssl/lab.nhanhhoa.local/private.key \
    -out /etc/ssl/lab.nhanhhoa.local/certificate.crt \
    -subj "/C=VN/ST=Ha Noi/L=Ha Noi/O=Nhan Hoa Lab/CN=lab.nhanhhoa.local"

# Giải thích từng tham số:
# -x509            → Tạo self-signed (không cần gửi cho CA)
# -nodes           → Private key KHÔNG đặt password (tiện cho server)
# -days 365        → Hiệu lực 1 năm
# -newkey rsa:2048 → Tạo key mới 2048 bit đồng thời
# -subj "..."      → Thông tin chủ sở hữu certificate
# CN=              → Common Name = TÊN DOMAIN (quan trọng nhất)

echo "✅ Tạo Self-Signed Certificate xong!"
```

```bash
# Kiểm tra certificate vừa tạo
openssl x509 -in /etc/ssl/lab.nhanhhoa.local/certificate.crt -noout -text
```

<img width="603" height="365" alt="image" src="https://github.com/user-attachments/assets/6ba51058-a983-4e08-9247-3c3adbc1bd1e" />

**Giải thích output:**
```
Certificate:
    Data:
        Version: 3
        Validity
            Not Before: Jan  1 00:00:00 2024 GMT   ← Ngày bắt đầu
            Not After : Jan  1 00:00:00 2025 GMT   ← Ngày hết hạn
        Subject:
            C=VN, ST=Ha Noi, O=Nhan Hoa Lab,
            CN=lab.nhanhhoa.local                  ← Domain được bảo vệ
```

```
# Phân quyền bảo mật cho Private Key
chmod 600 /etc/ssl/lab.nhanhhoa.local/private.key   # Chỉ root đọc được
chmod 644 /etc/ssl/lab.nhanhhoa.local/certificate.crt
chown root:root /etc/ssl/lab.nhanhhoa.local/*

# Kiểm tra quyền
ls -la /etc/ssl/lab.nhanhhoa.local/
```
<img width="460" height="124" alt="image" src="https://github.com/user-attachments/assets/f75d5e42-394f-412c-82fb-e2a530eb5aa6" />

---

## 4A.3 Cấu hình Apache với SSL (Thêm VirtualHost cổng 443)

```bash
# Xóa file cũ và tạo lại với cả HTTP và HTTPS
cat > /etc/apache2/sites-available/lab.nhanhhoa.local.conf << 'APACHEEOF'
# ═══════════════════════════════════════════════════════════
# VIRTUALHOST HTTP (cổng 80) → Redirect sang HTTPS
# ═══════════════════════════════════════════════════════════
<VirtualHost *:80>
    ServerName  lab.nhanhhoa.local
    ServerAlias www.lab.nhanhhoa.local

    # Chuyển hướng TẤT CẢ request HTTP → HTTPS
    # 301 = Permanent Redirect (trình duyệt nhớ và không quay lại)
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]

    # Log
    ErrorLog  /var/log/apache2/lab.nhanhhoa.local/error.log
    CustomLog /var/log/apache2/lab.nhanhhoa.local/access.log combined
</VirtualHost>


# ═══════════════════════════════════════════════════════════
# VIRTUALHOST HTTPS (cổng 443) → Website thật
# ═══════════════════════════════════════════════════════════
<VirtualHost *:443>
    ServerName  lab.nhanhhoa.local
    ServerAlias www.lab.nhanhhoa.local

    # Thư mục website
    DocumentRoot /var/www/lab.nhanhhoa.local/public_html

    # ─────────────────────────────────────────────────────
    # BẬT SSL
    # ─────────────────────────────────────────────────────
    SSLEngine on

    # Đường dẫn đến Certificate (file .crt)
    SSLCertificateFile    /etc/ssl/lab.nhanhhoa.local/certificate.crt

    # Đường dẫn đến Private Key (file .key)
    SSLCertificateKeyFile /etc/ssl/lab.nhanhhoa.local/private.key

    # ─────────────────────────────────────────────────────
    # CẤU HÌNH GIAO THỨC TLS (Bảo mật)
    # ─────────────────────────────────────────────────────

    # Chỉ cho phép TLS 1.2 và 1.3 (bỏ các phiên bản cũ lỗi thời)
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1

    # Danh sách cipher suite an toàn (theo khuyến nghị Mozilla)
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384

    # Để server quyết định cipher (không để client tự chọn)
    SSLHonorCipherOrder off

    # ─────────────────────────────────────────────────────
    # SECURITY HEADERS (Thêm vào response để tăng bảo mật)
    # ─────────────────────────────────────────────────────

    # HSTS: Buộc trình duyệt dùng HTTPS trong 1 năm
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # Chống clickjacking (nhúng trang vào iframe)
    Header always set X-Frame-Options "SAMEORIGIN"

    # Chống MIME type sniffing
    Header always set X-Content-Type-Options "nosniff"

    # ─────────────────────────────────────────────────────
    # DIRECTORY VÀ LOG
    # ─────────────────────────────────────────────────────
    <Directory /var/www/lab.nhanhhoa.local/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog  /var/log/apache2/lab.nhanhhoa.local/ssl-error.log
    CustomLog /var/log/apache2/lab.nhanhhoa.local/ssl-access.log combined

</VirtualHost>
APACHEEOF

echo "✅ Tạo cấu hình HTTPS xong!"
```
----
## 4A.4 Kích hoạt và kiểm tra

```bash
# Kiểm tra cú pháp TRƯỚC KHI reload (rất quan trọng)
apache2ctl configtest
```

<img width="940" height="50" alt="image" src="https://github.com/user-attachments/assets/8144bf4c-2ce2-41db-9d58-b6f76c5cacb9" />


```bash
# Reload Apache để áp dụng cấu hình mới
systemctl reload apache2

# Kiểm tra cổng 443 đang lắng nghe chưa
ss -tlnp | grep 443
```
<img width="885" height="71" alt="image" src="https://github.com/user-attachments/assets/94aa67ee-7a4b-4002-8aac-4d187ba6da27" />


```bash
# Test HTTPS (dùng -k để bỏ qua cảnh báo self-signed)
curl -k -I https://lab.nhanhhoa.local
```
<img width="435" height="185" alt="image" src="https://github.com/user-attachments/assets/71136c47-ba7e-4803-8d9f-a03761ec096f" />


```bash
# Test redirect HTTP → HTTPS
curl -I http://lab.nhanhhoa.local
```

<img width="334" height="110" alt="image" src="https://github.com/user-attachments/assets/60975137-2d93-406a-bead-8e184fd7c361" />
<img width="814" height="473" alt="image" src="https://github.com/user-attachments/assets/abff736a-3c93-4994-9c88-fea10ecb5982" />
<img width="956" height="422" alt="image" src="https://github.com/user-attachments/assets/3622a4a5-ed46-452a-8431-702313087b5b" />

---

# ═══════════════════════════════════════════════
### BƯỚC 4B: CÀI LET'S ENCRYPT – KHI CÓ DOMAIN THẬT
### (Thực hiện khi domain đã trỏ về server)
# ═══════════════════════════════════════════════

> **Điều kiện để thực hiện:**
> - Bạn có domain thật hieucute.id.vn
> - Domain đã trỏ A record về IP server
> - Server mở port 80 và 443 từ internet

## 4B.1 Kiểm tra điều kiện trước khi cài

```bash
# Domain: hieucute.id.vn

# 1. Kiểm tra DNS đã trỏ đúng chưa
dig hieucute.id.vn A +short
# Kết quả phải là IP của server (192.168.136.131 hoặc IP public)
```

```
# 2. Kiểm tra port 80 từ internet mở chưa
# Dùng https://portchecker.co/ kiểm tra domain:port 80
```

<img width="511" height="271" alt="image" src="https://github.com/user-attachments/assets/13cca2e2-8648-421a-a9f1-b81c913bf0fd" />

```
# 3. Kiểm tra certbot có thể vào được chưa
curl -I http://hieucute.id.vn  
# Phải trả về 200 hoặc redirect
```

<img width="374" height="184" alt="image" src="https://github.com/user-attachments/assets/1439493d-05f7-4776-ab8f-858ff7083564" />

## 4B.2 Cài Certbot

```
# Ubuntu 22.04 apt update
apt install -y certbot python3-certbot-apache
ln -s /snap/bin/certbot /usr/bin/certbot

# Kiểm tra
certbot --version
# Kết quả: certbot 2.x.x
```
<img width="410" height="57" alt="image" src="https://github.com/user-attachments/assets/f9bdc8b1-1684-4bfe-ab42-87aff12e2ca0" />


## 4B.3 Tạo VirtualHost cơ bản TRƯỚC khi cài Let's Encrypt

```bash
# Let's Encrypt cần truy cập vào /.well-known/acme-challenge/ trên server
# Nên ta phải có VirtualHost HTTP chạy sẵn

cat > /etc/apache2/sites-available/hieucute.id.vn.conf << 'EOF'
<VirtualHost *:80>
    ServerName hieucute.id.vn
    ServerAlias www.hieucute.id.vn
    DocumentRoot /var/www/hieucute.id.vn/public_html

    <Directory /var/www/hieucute.id.vn/public_html>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog  /var/log/apache2/hieucute.id.vn-error.log
    CustomLog /var/log/apache2/hieucute.id.vn-access.log combined
</VirtualHost>
EOF

# Tạo thư mục web
mkdir -p /var/www/hieucute.id.vn/public_html
echo "<h1>Đang cài SSL...</h1>" > /var/www/hieucute.id.vn/public_html/index.html

# Kích hoạt site
a2ensite hieucute.id.vn.conf
systemctl reload apache2
```

## 4B.4 Chạy Certbot – Let's Encrypt phát hành chứng chỉ

```bash
# Certbot tự động:
# 1. Tạo file xác minh tại /.well-known/acme-challenge/
# 2. Báo Let's Encrypt CA kiểm tra
# 3. LE CA truy cập http://hieucute.id.vn/.well-known/acme-challenge/xxxxx
# 4. Nếu đúng → LE cấp certificate
# 5. Certbot lưu vào /etc/letsencrypt/live/hieucute.id.vn/
# 6. Certbot TỰ ĐỘNG sửa Apache config thêm HTTPS

certbot --apache \
    -d hieucute.id.vn \
    -d www.hieucute.id.vn \
    --email nthieu.dhmt16a1hn@sv.uneti.edu.vn \
    --agree-tos \
    --no-eff-email
```
<img width="727" height="353" alt="image" src="https://github.com/user-attachments/assets/85feb24a-dc34-496c-9996-f79535acfc73" />



```bash
# Xem kết quả - Certbot đã tạo file config SSL mới
cat /etc/apache2/sites-available/hieucute.id.vn-le-ssl.conf
```

```bash
# Xem certificate Let's Encrypt vừa được cấp
ls -la /etc/letsencrypt/live/hieucute.id.vn/
```
<img width="624" height="124" alt="image" src="https://github.com/user-attachments/assets/7cc5f16c-0351-4508-83d7-f36bf809fc36" />



```bash
# Kiểm tra ngày hết hạn
openssl x509 -in /etc/letsencrypt/live/hieucute.id.vn/cert.pem -noout -dates
```
<img width="608" height="55" alt="image" src="https://github.com/user-attachments/assets/a368e9fa-8898-4252-a19b-c3240d864c5d" />  

Hạn là 90 ngày  

---

# ═══════════════════════════════════
### BƯỚC 5: KIỂM TRA SSL HOẠT ĐỘNG
# ═══════════════════════════════════

## 5.1 Kiểm tra cơ bản

```
# Test 1: HTTPS trả về 200
 curl -I https://hieucute.id.vn
```
<img width="349" height="138" alt="image" src="https://github.com/user-attachments/assets/8352d045-627c-48dd-8907-f1e3b3658aa2" />
```
# Test 2: HTTP tự redirect sang HTTPS
curl -I http://hieucute.id.vn
```

<img width="323" height="86" alt="image" src="https://github.com/user-attachments/assets/24e9e2cd-4fcb-404b-898e-e995c676a7d3" />


```
# Test 3: Xem thông tin certificate từ server
echo | openssl s_client -connect hieucute.id.vn:443 -servername hieucute.id.vn 2>/dev/null | openssl x509 -noout -text | head -30
```

## 5.2 Kiểm tra từng chi tiết của certificate

```bash
# Xem ngày hết hạn
echo | openssl s_client -connect hieucute.id.vn:443 -servername hieucute.id.vn \
    2>/dev/null | openssl x509 -noout -dates

# Xem domain được bảo vệ
echo | openssl s_client -connect hieucute.id.vn:443 -servername hieucute.id.vn \
    2>/dev/null | openssl x509 -noout -subject

# Xem CA đã ký (Issuer)
echo | openssl s_client -connect hieucute.id.vn:443 -servername hieucute.id.vn \
    2>/dev/null | openssl x509 -noout -issuer

# Xem Security Headers có đầy đủ không
curl -k -I https://hieucute.id.vn | grep -E "Strict|Frame|Content-Type"
```
<img width="593" height="150" alt="image" src="https://github.com/user-attachments/assets/a1f824e1-809c-44d1-b499-446156cb9ea8" />

## 5.3 Kiểm tra Private Key khớp Certificate

```bash
# Bước này RẤT QUAN TRỌNG trong thực tế
# Nếu key và cert không cùng cặp → HTTPS sẽ không hoạt động

# Lấy MD5 của Private Key
echo "Private Key MD5:"
openssl rsa -in /etc/ssl/hieucute.id.vn/private.key -noout -modulus 2>/dev/null | md5sum

# Lấy MD5 của Certificate
echo "Certificate MD5:"
openssl x509 -in /etc/ssl/hieucute.id.vn/certificate.crt -noout -modulus 2>/dev/null | md5sum

# Hai dòng PHẢI GIỐNG NHAU → key và cert khớp
# Nếu khác nhau → sai key hoặc sai cert
```
<img width="582" height="113" alt="image" src="https://github.com/user-attachments/assets/15f111b0-511f-4455-8a49-cb04fd8abf06" />

## 5.4 Xem log Apache để theo dõi

```bash
# Xem log truy cập HTTPS
tail -f /var/log/apache2/hieucute.id.vn/ssl-access.log

# Xem log lỗi nếu có vấn đề
tail -f /var/log/apache2/hieucute.id.vn/ssl-error.log

# Xem log Apache tổng hợp
journalctl -u apache2 -f
```

---

# ════════════════════════════════════
### CÀI THÊM SSL CHO NGINX
# ════════════════════════════════════

```bash
# Cài Nginx (sẽ chạy song song với Apache trên port khác)
apt install nginx -y

# Dừng Nginx trước (tránh xung đột port 80/443 với Apache)
systemctl stop nginx
systemctl disable nginx
# Chúng ta sẽ dùng Nginx trên port riêng cho lab này
```

```bash
# Tạo thư mục web cho Nginx lab
mkdir -p /var/www/nginx-lab/
cat > /var/www/nginx-lab/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>Nginx SSL Lab</title></head>
<body style="background:#0f172a;color:#e2e8f0;font-family:sans-serif;padding:2rem;text-align:center">
<h1>🟢 Nginx SSL Lab</h1>
<p>Port: <strong>8443</strong> (HTTPS via Nginx)</p>
<script>document.write('<p>Protocol: <strong>' + location.protocol + '</strong></p>')</script>
</body></html>
EOF
```

```bash
# Tạo cấu hình Nginx (dùng port 8080 HTTP, 8443 HTTPS để tránh xung đột)
cat > /etc/nginx/sites-available/nginx-lab << 'NGINXEOF'
# ─────────────────────────────────────────────────────
# Nginx Server – HTTP (port 8080) → redirect HTTPS
# ─────────────────────────────────────────────────────
server {
    listen 8080;
    server_name hieucute.id.vn;

    # Redirect HTTP sang HTTPS (cổng 8443)
    return 301 https://$host:8443$request_uri;
}

# ─────────────────────────────────────────────────────
# Nginx Server – HTTPS (port 8443)
# ─────────────────────────────────────────────────────
server {
    listen 8443 ssl;
    server_name hieucute.id.vn;

    root /var/www/nginx-lab;
    index index.html;

    # Chỉ định certificate và private key
    ssl_certificate     /etc/ssl/hieucute.id.vn/certificate.crt;
    ssl_certificate_key /etc/ssl/hieucute.id.vn/private.key;

    # Giao thức TLS an toàn
    ssl_protocols TLSv1.2 TLSv1.3;

    # Cipher suite
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # Session cache (tăng hiệu suất)
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/lab-access.log;
    error_log  /var/log/nginx/lab-error.log;
}
NGINXEOF

# Kích hoạt site
ln -s /etc/nginx/sites-available/nginx-lab /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Kiểm tra cú pháp
nginx -t
```

```bash
# Mở firewall cho port Nginx lab
ufw allow 8080/tcp
ufw allow 8443/tcp

# Khởi động Nginx
systemctl start nginx
systemctl enable nginx

# Kiểm tra
ss -tlnp | grep nginx
curl -k -I https://hieucute.id.vn:8443
```

---

# ═══════════════════════════════════
### BƯỚC 6: TỰ ĐỘNG GIA HẠN SSL
# ═══════════════════════════════════

> **Với Let's Encrypt (domain thật):** Certbot tự gia hạn
> **Với Self-Signed (lab):** Tạo script tự làm mới cert

## 6.1 Kiểm tra certbot timer (Let's Encrypt)

```bash
# Ubuntu 22.04 có sẵn certbot.timer qua systemd
systemctl status certbot.timer
systemctl list-timers | grep certbot

# Test thử gia hạn (dry-run = không thực sự gia hạn, chỉ test)
certbot renew --dry-run
```
<img width="646" height="255" alt="image" src="https://github.com/user-attachments/assets/8a4e6953-0ca2-4f8b-960c-368cec51c94b" />

## 6.2 Tạo cronjob backup + gia hạn

```bash
# Mở crontab
crontab -e

# Thêm các dòng sau:
# Gia hạn Let's Encrypt (chạy 2 lần/ngày, certbot tự biết khi nào cần gia hạn)
0 3,15 * * * certbot renew --quiet --deploy-hook "systemctl reload apache2 nginx" >> /var/log/certbot-renew.log 2>&1

# Kiểm tra SSL hết hạn hàng ngày lúc 8:00 sáng
0 8 * * * /opt/scripts/check-ssl.sh >> /var/log/ssl-check.log 2>&1
```

## 6.3 Script kiểm tra SSL hàng ngày

```bash
mkdir -p /opt/scripts

cat > /opt/scripts/check-ssl.sh << 'SCRIPTEOF'
#!/bin/bash
# Script kiểm tra SSL - chạy hàng ngày
DATE=$(date '+%Y-%m-%d %H:%M')
WARNING_DAYS=30

echo "[$DATE] Kiểm tra SSL..."

# Kiểm tra từng certificate Let's Encrypt
for CERT_DIR in /etc/letsencrypt/live/*/; do
    DOMAIN=$(basename "$CERT_DIR")
    [ "$DOMAIN" = "README" ] && continue

    CERT="$CERT_DIR/cert.pem"
    [ ! -f "$CERT" ] && continue

    EXPIRY=$(openssl x509 -in "$CERT" -noout -enddate | cut -d= -f2)
    DAYS=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))

    if [ $DAYS -le 0 ]; then
        echo "[HẾT HẠN] $DOMAIN: ĐÃ HẾT HẠN!"
    elif [ $DAYS -le $WARNING_DAYS ]; then
        echo "[CẢNH BÁO] $DOMAIN: Còn $DAYS ngày"
    else
        echo "[OK] $DOMAIN: Còn $DAYS ngày"
    fi
done
SCRIPTEOF

chmod +x /opt/scripts/check-ssl.sh

# Test script
/opt/scripts/check-ssl.sh
```
<img width="572" height="409" alt="image" src="https://github.com/user-attachments/assets/1030f370-8c11-4984-93eb-bcbc705a1483" />

---



## 📊 So sánh Self-Signed vs Let's Encrypt

| Tiêu chí | Self-Signed (Lab) | Let's Encrypt (Production) |
|---|---|---|
| Browser tin tưởng | ❌ Cảnh báo | ✅ Tin tưởng |
| Phí | Miễn phí | Miễn phí |
| Thời hạn | Tự đặt (365 ngày) | 90 ngày |
| Tự gia hạn | Cần script thủ công | ✅ Tự động |
| Cần domain thật | ❌ Không | ✅ Có |

## 🗂️ Vị trí các file quan trọng

```
/etc/apache2/
├── sites-available/hieucute.id.vn.conf  ← VirtualHost config
├── sites-enabled/        ← Symlink từ sites-available
└── mods-enabled/ssl.load    ← Module SSL

/etc/ssl/lab.nhanhhoa.local/
├── private.key      ← Private Key (bảo mật)
└── certificate.crt  ← Certificate (public)

/etc/letsencrypt/live/hieucute.id.vn/  ← (Khi dùng Let's Encrypt)
├── privkey.pem      ← Private Key
├── cert.pem         ← Certificate
├── chain.pem        ← CA Chain
└── fullchain.pem    ← cert + chain (DÙNG CÁI NÀY)

/var/www/lab.nhanhhoa.local/public_html/
└── index.html       ← Website demo

/var/log/apache2/lab.nhanhhoa.local/
├── access.log       ← Log truy cập HTTP
├── ssl-access.log   ← Log truy cập HTTPS
└── ssl-error.log    ← Log lỗi SSL
```

##  Lệnh xử lý sự cố nhanh

```bash
# Apache không start được sau khi sửa SSL config
apache2ctl configtest           # Xem lỗi cú pháp ở đâu
journalctl -u apache2 -n 20     # Xem 20 dòng log gần nhất

# SSL không hoạt động
openssl s_client -connect lab.nhanhhoa.local:443    # Debug TLS handshake

# Private key không khớp Certificate (lỗi phổ biến nhất)
openssl rsa  -in private.key    -noout -modulus | md5sum
openssl x509 -in certificate.crt -noout -modulus | md5sum
# Hai dòng phải giống nhau

# Let's Encrypt fail
certbot renew --dry-run --debug  # Xem lỗi chi tiết

# Reset lại từ đầu (nếu muốn làm lại)
a2dissite lab.nhanhhoa.local.conf
systemctl reload apache2
rm -f /etc/apache2/sites-available/lab.nhanhhoa.local.conf
rm -rf /etc/ssl/lab.nhanhhoa.local/
```
