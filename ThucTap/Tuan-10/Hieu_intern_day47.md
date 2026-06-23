# Báo cáo thực tập ngày 47 - Thực hành SSL Termination
---

## 1. Tạo SSL 
### 1.1 Self-Signed Certificate
Self-Signed Certificate là chứng chỉ SSL do chính máy chủ tự tạo và tự ký — không thông qua một CA công khai nào như Let's Encrypt hay ZeroSSL. Trình duyệt sẽ **không tự động tin tưởng** loại cert này (hiển thị cảnh báo "Not Secure" hoặc "Your connection is not private"), trừ khi máy client được cài đặt thủ công cert/CA gốc vào danh sách Trusted.  
#### Bước 1 — Cài đặt OpenSSL

```bash
sudo apt update
sudo apt install -y openssl
openssl version
```
 <img width="410" height="43" alt="image" src="https://github.com/user-attachments/assets/9a0e02c1-0451-4367-924c-af0cb1fdb127" />

#### Bước 2 — Tạo thư mục lưu trữ chứng chỉ
 
```bash
sudo mkdir -p /etc/ssl/nhanhoa
sudo chmod 755 /etc/ssl/nhanhoa
cd /etc/ssl/nhanhoa
```
 
#### Bước 3 — Tạo file cấu hình SAN (Subject Alternative Name)
 
> Từ năm 2017, các trình duyệt hiện đại **bắt buộc** cert phải có SAN, không chỉ Common Name (CN). Bỏ qua bước này sẽ gây lỗi `ERR_CERT_COMMON_NAME_INVALID`.
 
```bash
sudo nano /etc/ssl/nhanhoa/san.cnf
```
 
Nội dung file:
 
```ini
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no
 
[req_distinguished_name]
C  = VN
ST = Hanoi
L  = Hanoi
O  = Nhan Hoa Corporation
OU = IT Department
CN = test.nhanhoa.local
 
[v3_req]
keyUsage         = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names
 
[alt_names]
DNS.1 = test.nhanhoa.local
DNS.2 = www.test.nhanhoa.local
IP.1  = 127.0.0.1
```
 <img width="571" height="241" alt="image" src="https://github.com/user-attachments/assets/f992aa6c-f447-454d-ac8e-1ac3216bceb8" />

#### Bước 4 — Tạo Private Key
 
```bash
sudo openssl genrsa -out /etc/ssl/nhanhoa/test.key 2048
 
# Phân quyền bảo mật — chỉ root đọc được
sudo chmod 600 /etc/ssl/nhanhoa/test.key
sudo chown root:root /etc/ssl/nhanhoa/test.key
```

#### Bước 5 — Tạo CSR (Certificate Signing Request)
 
```bash
sudo openssl req -new \
    -key /etc/ssl/nhanhoa/test.key \
    -out /etc/ssl/nhanhoa/test.csr \
    -config /etc/ssl/nhanhoa/san.cnf
```
 
#### Bước 6 — Tự ký Certificate (Self-Sign)
 
```bash
sudo openssl x509 -req \
    -days 365 \
    -in /etc/ssl/nhanhoa/test.csr \
    -signkey /etc/ssl/nhanhoa/test.key \
    -out /etc/ssl/nhanhoa/test.crt \
    -extensions v3_req \
    -extfile /etc/ssl/nhanhoa/san.cnf
 
sudo chmod 644 /etc/ssl/nhanhoa/test.crt
```
 <img width="593" height="178" alt="image" src="https://github.com/user-attachments/assets/2e68f8e3-6919-4036-9bc7-ae4998b7cd9b" />

**Giải thích lệnh:**
- `-req`: input là CSR
- `-days 365`: hiệu lực 1 năm
- `-signkey`: dùng chính private key vừa tạo để ký (đây là điểm khác biệt với cert CA-issued — không có bên thứ 3 nào ký)
#### Bước 7 — Kiểm tra Certificate
 
```bash
# Xem toàn bộ thông tin
sudo openssl x509 -in /etc/ssl/nhanhoa/test.crt -text -noout
```
<img width="715" height="355" alt="image" src="https://github.com/user-attachments/assets/1260f203-e156-4abc-8b62-2351de37542c" />

```

# Xem nhanh subject, issuer, ngày hết hạn
sudo openssl x509 -in /etc/ssl/nhanhoa/test.crt -noout -subject -issuer -dates
```
<img width="688" height="76" alt="image" src="https://github.com/user-attachments/assets/2438f00f-62bb-45a2-8f78-91ec6708d867" />

```
# Kiểm tra SAN
sudo openssl x509 -in /etc/ssl/nhanhoa/test.crt -noout -ext subjectAltName
```
<img width="682" height="54" alt="image" src="https://github.com/user-attachments/assets/f2538802-6d14-46d6-ac81-26071a8855d8" />
 ```
# Verify private key khớp với cert (modulus phải trùng nhau)
openssl rsa  -in /etc/ssl/nhanhoa/test.key -noout -modulus | md5sum
openssl x509 -in /etc/ssl/nhanhoa/test.crt -noout -modulus | md5sum
```
<img width="664" height="71" alt="image" src="https://github.com/user-attachments/assets/40ae1990-9dd8-4273-8643-ab1ed60a07ce" />

---
## 2 ZeroSSL Certificate
 
### Khái niệm
 
ZeroSSL là một CA miễn phí, sử dụng giao thức ACME (giống Let's Encrypt) nhưng có thêm tùy chọn tạo cert qua giao diện web thân thiện, hỗ trợ cả HTTP Validation và DNS Validation, và cho phép cấp tới 3 certificate miễn phí song song với thời hạn 90 ngày.    

#### Bước 1 — Đăng ký tài khoản ZeroSSL
 
```
1. Truy cập https://app.zerossl.com/signup
2. Đăng ký bằng email công ty (vd: it@nhanhoa.vn)
3. Xác thực email
4. Đăng nhập vào Dashboard
```
 
#### Bước 2 — Tạo Certificate mới
 
```
1. Vào Dashboard → Certificates → New Certificate
2. Nhập domain: hieucute.id.vn
3. Chọn "90-Day Certificate" (miễn phí)
4. Chọn phương thức tạo CSR:
   - "I'll upload my CSR" 
```
 
#### Bước 3b  — Tự tạo CSR trên Ubuntu để upload lên ZeroSSL
 
```bash
sudo mkdir -p /etc/ssl/zerossl
cd /etc/ssl/zerossl
 
# Tạo private key
sudo openssl genrsa -out yourdomain.key 2048
sudo chmod 600 yourdomain.key
 
# Tạo CSR
sudo openssl req -new \
    -key yourdomain.key \
    -out yourdomain.csr \
    -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Nhan Hoa Corporation/CN=hieucute.id.vn"
 
# Xem nội dung CSR để copy-paste lên ZeroSSL
cat yourdomain.csr
```
 
#### Bước 4 — HTTP Validation
 
ZeroSSL sẽ cung cấp một file cần đặt tại `/.well-known/pki-validation/`.
 
```bash
# Tạo thư mục validation
sudo mkdir -p /var/www/html/.well-known/pki-validation/
 
# Tạo file ZeroSSL yêu cầu (tên file và nội dung do ZeroSSL cung cấp)
sudo nano /var/www/html/.well-known/pki-validation/ABCDEF123456.txt
# Paste nội dung verification string ZeroSSL cung cấp, lưu lại
 
# Kiểm tra file truy cập được từ internet
curl http://yourdomain.nhanhoa.vn/.well-known/pki-validation/ABCDEF123456.txt
```
 
Sau khi curl trả về đúng nội dung, quay lại Dashboard ZeroSSL → nhấn **Verify Domain**.
 
#### Bước 5 — Download Certificate
 
Sau khi verify thành công, ZeroSSL cung cấp 3 file để download:
 
```
certificate.crt   → chứng chỉ domain
ca_bundle.crt      → chứng chỉ trung gian (intermediate)
private.key        → khóa riêng tư (chỉ có nếu dùng Auto-Generate CSR)
```
 
#### Bước 7 — Upload và cài đặt lên Ubuntu Server
 
```bash
# Tạo thư mục lưu trữ
sudo mkdir -p /etc/ssl/zerossl/yourdomain.nhanhoa.vn
 
# Upload 3 file từ máy local lên server (chạy lệnh này từ máy local, không phải server)
scp certificate.crt ca_bundle.crt private.key \
    user@SERVER_IP:/tmp/
 
# Trên server Ubuntu — di chuyển vào đúng vị trí
sudo mv /tmp/certificate.crt /etc/ssl/zerossl/yourdomain.nhanhoa.vn/
sudo mv /tmp/ca_bundle.crt   /etc/ssl/zerossl/yourdomain.nhanhoa.vn/
sudo mv /tmp/private.key     /etc/ssl/zerossl/yourdomain.nhanhoa.vn/
 
# Tạo file fullchain (cert + intermediate) — cần thiết để tránh lỗi thiếu intermediate
sudo bash -c 'cat /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt \
    /etc/ssl/zerossl/yourdomain.nhanhoa.vn/ca_bundle.crt \
    > /etc/ssl/zerossl/yourdomain.nhanhoa.vn/fullchain.crt'
 
# Phân quyền bảo mật
sudo chmod 600 /etc/ssl/zerossl/yourdomain.nhanhoa.vn/private.key
sudo chmod 644 /etc/ssl/zerossl/yourdomain.nhanhoa.vn/fullchain.crt
sudo chown root:root /etc/ssl/zerossl/yourdomain.nhanhoa.vn/*
```
 
#### Bước 8 — Kiểm tra Certificate
 
```bash
# Xem thông tin cert
sudo openssl x509 -in /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt \
    -noout -subject -issuer -dates
 
# Kết quả mong đợi — issuer KHÁC subject (đây là điểm khác Self-Signed):
# subject=CN = yourdomain.nhanhoa.vn
# issuer=C = AT, O = ZeroSSL, CN = ZeroSSL RSA Domain Secure Site CA
 
# Verify chain đầy đủ
sudo openssl verify \
    -CAfile /etc/ssl/zerossl/yourdomain.nhanhoa.vn/ca_bundle.crt \
    /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt
```
 
### Gia hạn ZeroSSL Certificate
 
```bash
# Kiểm tra ngày hết hạn
openssl x509 -in /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt \
    -noout -enddate
 
# ZeroSSL không tự động gia hạn như Certbot (trừ khi setup ACME client riêng)
# Quy trình: lặp lại bước 3-7 trước khi cert hết hạn 7-14 ngày
 
# Tự động hóa bằng ACME client (acme.sh) hỗ trợ ZeroSSL
curl https://get.acme.sh | sh -s email=it@nhanhoa.vn
~/.acme.sh/acme.sh --set-default-ca --server zerossl
~/.acme.sh/acme.sh --issue -d yourdomain.nhanhoa.vn --webroot /var/www/html
```
---
<img width="959" height="433" alt="image" src="https://github.com/user-attachments/assets/0d79c26f-10d2-4bea-ae95-6ec46b3e9dc7" />

## 3. Apache
 
### Cài đặt Apache trên Ubuntu 22.04
 
```bash
sudo apt update
sudo apt install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2
 
# Bật các module cần thiết cho SSL
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod rewrite
 
sudo systemctl restart apache2
sudo apache2 -M | grep ssl
```
<img width="402" height="28" alt="image" src="https://github.com/user-attachments/assets/de278fa1-cef0-4cd6-b807-04fea21ec2de" />

### Cấu hình VirtualHost với Self-Signed Certificate
 
```bash
sudo nano /etc/apache2/sites-available/test-ssl.conf
```
 
```apache
<VirtualHost *:80>
    ServerName test.nhanhoa.local
    Redirect permanent / https://test.nhanhoa.local/
</VirtualHost>
 
<VirtualHost *:443>
    ServerName test.nhanhoa.local
    DocumentRoot /var/www/html
 
    SSLEngine on
    SSLCertificateFile    /etc/ssl/nhanhoa/test.crt
    SSLCertificateKeyFile /etc/ssl/nhanhoa/test.key
 
    SSLProtocol -all +TLSv1.2 +TLSv1.3
 
    ErrorLog  ${APACHE_LOG_DIR}/test-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/test-ssl-access.log combined
</VirtualHost>
```
<img width="634" height="250" alt="image" src="https://github.com/user-attachments/assets/55183a40-299a-47a8-8f48-f20354fa28eb" />

```bash
sudo a2ensite test-ssl.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```
<img width="403" height="104" alt="image" src="https://github.com/user-attachments/assets/2c042c39-66ed-40f6-ab58-c168739d74c0" />

### Cấu hình VirtualHost với ZeroSSL Certificate (production)
 
```bash
sudo nano /etc/apache2/sites-available/yourdomain-ssl.conf
```
 
```apache
<VirtualHost *:80>
    ServerName yourdomain.nhanhoa.vn
    Redirect permanent / https://yourdomain.nhanhoa.vn/
</VirtualHost>
 
<VirtualHost *:443>
    ServerName yourdomain.nhanhoa.vn
    DocumentRoot /var/www/html
 
    SSLEngine on
    SSLCertificateFile    /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt
    SSLCertificateKeyFile /etc/ssl/zerossl/yourdomain.nhanhoa.vn/private.key
    SSLCACertificateFile  /etc/ssl/zerossl/yourdomain.nhanhoa.vn/ca_bundle.crt
 
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
 
    ErrorLog  ${APACHE_LOG_DIR}/yourdomain-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/yourdomain-ssl-access.log combined
</VirtualHost>
```
 
```bash
sudo a2ensite yourdomain-ssl.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```
 
### Kiểm tra kết quả
 
```bash
# Test bằng curl
curl -vk https://test.nhanhoa.local 2>&1 | grep -E "SSL|subject|issuer"
```
<img width="742" height="77" alt="image" src="https://github.com/user-attachments/assets/1c3e3eba-9cf9-4f02-9b09-b3d417cdde3f" />

```
# Test bằng OpenSSL
openssl s_client -connect test.nhanhoa.local:443 -servername test.nhanhoa.local < /dev/null
 ```
<img width="805" height="363" alt="image" src="https://github.com/user-attachments/assets/78177587-7fec-4dc1-a7ac-376df2b915bc" />

```
# Kiểm tra redirect HTTP -> HTTPS
curl -I http://test.nhanhoa.local
```
<img width="455" height="106" alt="image" src="https://github.com/user-attachments/assets/111a023c-5f58-4c96-920d-5c8d11dd8deb" />

## 4.Nginx
 
### Cài đặt Nginx trên Ubuntu 22.04
 
```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
 
nginx -v
```
 <img width="629" height="71" alt="image" src="https://github.com/user-attachments/assets/a2fb13fb-5a1d-4780-817a-c471a0a791af" />

> **Lưu ý:** Nếu cùng lúc cài cả Apache và Nginx trên 1 server để thực hành, cần đổi port hoặc dừng 1 trong 2 service để tránh xung đột port 80/443.
 
```bash
sudo systemctl stop apache2  
```
 
### Cấu hình Server Block với Self-Signed Certificate
 
```bash
sudo nano /etc/nginx/sites-available/test-ssl
```
 
```nginx
server {
    listen 80;
    server_name test.nhanhoa.local;
    return 301 https://$host$request_uri;
}
 
server {
    listen 443 ssl http2;
    server_name test.nhanhoa.local;
    root /var/www/html;
    index index.html;
 
    ssl_certificate     /etc/ssl/nhanhoa/test.crt;
    ssl_certificate_key /etc/ssl/nhanhoa/test.key;
 
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
 
    access_log /var/log/nginx/test-ssl-access.log;
    error_log  /var/log/nginx/test-ssl-error.log;
}
```
<img width="814" height="280" alt="image" src="https://github.com/user-attachments/assets/e8260e49-b8c3-45b7-b728-3cb0c275be5f" />

 
```bash
sudo ln -s /etc/nginx/sites-available/test-ssl /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
<img width="701" height="176" alt="image" src="https://github.com/user-attachments/assets/3e9c37d0-d8e1-4d74-b97e-1c453b47692f" />
 
### Cấu hình Server Block với ZeroSSL Certificate (production)
 
```bash
sudo nano /etc/nginx/sites-available/yourdomain
```
 
```nginx
server {
    listen 80;
    server_name yourdomain.nhanhoa.vn;
    return 301 https://$host$request_uri;
}
 
server {
    listen 443 ssl http2;
    server_name yourdomain.nhanhoa.vn;
    root /var/www/html;
 
    # Dùng fullchain.crt (cert + ca_bundle) để tránh lỗi thiếu intermediate
    ssl_certificate     /etc/ssl/zerossl/yourdomain.nhanhoa.vn/fullchain.crt;
    ssl_certificate_key /etc/ssl/zerossl/yourdomain.nhanhoa.vn/private.key;
 
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
 
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```
 
```bash
sudo ln -s /etc/nginx/sites-available/yourdomain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
 
### Kiểm tra kết quả
 
```bash
# Test config trước khi reload (luôn làm bước này trước production)
sudo nginx -t
 
# Test HTTPS
curl -vk https://test.nhanhoa.local
```
<img width="632" height="350" alt="image" src="https://github.com/user-attachments/assets/01f8e649-4992-4483-b785-3ae709d66157" />
 ```
# Kiểm tra HTTP/2
curl -I --http2 -k https://test.nhanhoa.local
 ```
<img width="500" height="99" alt="image" src="https://github.com/user-attachments/assets/3d4de079-8549-41ab-aa50-2ed9abc7db4f" />

```
# Kiểm tra OCSP/chain (với ZeroSSL cert)
openssl s_client -connect yourdomain.nhanhoa.vn:443 -servername yourdomain.nhanhoa.vn -showcerts < /dev/null
```

----

## 5.Tomcat
 
### Cài đặt Tomcat trên Ubuntu 22.04
 
```bash
sudo apt install -y openjdk-17-jdk tomcat9 tomcat9-admin 
java -version
sudo systemctl enable tomcat9
sudo systemctl start tomcat9
 
# Kiểm tra Tomcat đang chạy port 8080
curl http://localhost:8080
```
<img width="529" height="83" alt="image" src="https://github.com/user-attachments/assets/bdd0de10-ec1b-41c2-9e62-7ced3f0c4502" />
<img width="959" height="269" alt="image" src="https://github.com/user-attachments/assets/78194cf9-e850-4ea4-8683-f4b49b939857" />

### Chuyển đổi Certificate sang định dạng Java Keystore
 
Tomcat không đọc trực tiếp file `.crt`/`.key` như Apache/Nginx — cần chuyển sang định dạng **PKCS12** rồi import vào **Java Keystore (JKS)**.
 
#### Với Self-Signed Certificate
 
```bash
# Bước 1: Gộp cert + key thành file PKCS12
sudo openssl pkcs12 -export \
    -in  /etc/ssl/nhanhoa/test.crt \
    -inkey /etc/ssl/nhanhoa/test.key \
    -out /etc/ssl/nhanhoa/test.p12 \
    -name "test.nhanhoa.local" \
    -passout pass:NhanHoa@2026
 
# Bước 2: Import vào Java Keystore
sudo keytool -importkeystore \
    -deststorepass NhanHoa@2026 \
    -destkeypass NhanHoa@2026 \
    -destkeystore /etc/tomcat9/keystore.jks \
    -srckeystore /etc/ssl/nhanhoa/test.p12 \
    -srcstoretype PKCS12 \
    -srcstorepass NhanHoa@2026 \
    -alias test.nhanhoa.local \
    -noprompt
```
 <img width="485" height="209" alt="image" src="https://github.com/user-attachments/assets/e8b58c70-1136-4d5a-acdf-d4846a956b3b" />

#### Với ZeroSSL Certificate (kèm chain đầy đủ)
 
```bash
# Bước 1: Gộp cert + key + ca_bundle thành PKCS12
sudo openssl pkcs12 -export \
    -in  /etc/ssl/zerossl/yourdomain.nhanhoa.vn/certificate.crt \
    -inkey /etc/ssl/zerossl/yourdomain.nhanhoa.vn/private.key \
    -certfile /etc/ssl/zerossl/yourdomain.nhanhoa.vn/ca_bundle.crt \
    -out /etc/ssl/zerossl/yourdomain.nhanhoa.vn/yourdomain.p12 \
    -name "yourdomain.nhanhoa.vn" \
    -passout pass:NhanHoa@2026
 
# Bước 2: Import vào Java Keystore
sudo keytool -importkeystore \
    -deststorepass NhanHoa@2026 \
    -destkeypass NhanHoa@2026 \
    -destkeystore /etc/tomcat9/keystore.jks \
    -srckeystore /etc/ssl/zerossl/yourdomain.nhanhoa.vn/yourdomain.p12 \
    -srcstoretype PKCS12 \
    -srcstorepass NhanHoa@2026 \
    -alias yourdomain.nhanhoa.vn \
    -noprompt
```
 
### Kiểm tra Keystore
 
```bash
sudo keytool -list -v \
    -keystore /etc/tomcat9/keystore.jks \
    -storepass NhanHoa@2026 \
    | grep -E "Alias name|Valid from|Owner"
 ```
<img width="562" height="119" alt="image" src="https://github.com/user-attachments/assets/dce98eb3-cf3f-443b-abfd-5bd71241efcf" />

```
# Phân quyền
sudo chown tomcat:tomcat /etc/tomcat9/keystore.jks
sudo chmod 640 /etc/tomcat9/keystore.jks
```
 
### Cấu hình HTTPS Connector
 
```bash
sudo cp /etc/tomcat9/server.xml /etc/tomcat9/server.xml.bak
sudo nano /etc/tomcat9/server.xml
```
 
Thêm/sửa Connector:
 
```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150"
           SSLEnabled="true"
           defaultSSLHostConfigName="localhost"
           scheme="https"
           secure="true">
    <SSLHostConfig hostName="localhost">
        <Certificate
            certificateKeystoreFile="/etc/tomcat9/keystore.jks"
            certificateKeystorePassword="NhanHoa@2026"
            certificateKeyAlias="yourdomain.nhanhoa.vn"
            type="RSA" />
    </SSLHostConfig>
</Connector>
```
 
```bash
sudo systemctl restart tomcat9
sudo systemctl status tomcat9
 
ss -tlnp | grep 8443
```
 
### Kiểm tra kết quả
 
```bash
curl -k https://test.nhanhoa.local:8443/
openssl s_client -connect test.nhanhoa.local:8443 -servername test.nhanhoa.local < /dev/null
 
# Xem log nếu lỗi
sudo tail -50 /var/log/tomcat9/catalina.out | grep -iE "ssl|error|certificate"
```
 
