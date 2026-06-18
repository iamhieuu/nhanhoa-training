# Báo cáo thực tập ngày 45 - SSL Termination
---

## 7.5 Công Cụ Kiểm Tra SSL
Trong vận hành thực tế, kỹ thuật viên cần một công cụ **tổng hợp toàn bộ** các tiêu chí (chain, cipher, protocol, HSTS, OCSP...) thành một bản đánh giá duy nhất, dễ trình bày cho khách hàng hoặc dùng để audit định kỳ. Đây là vai trò của SSL Labs và các SSL Checker.
 
## SSL Labs
 
**SSL Labs** là công cụ kiểm tra SSL/TLS được công nhận rộng rãi nhất trong ngành, chấm điểm cấu hình SSL của một domain theo thang hạng chữ.
### SSL Rating — thang điểm A+, A, B, C, F
 
| Hạng | Ý nghĩa chung |
|---|---|
| **A+** | Cấu hình xuất sắc: TLS 1.2/1.3 only, cipher mạnh, HSTS bật đúng, chain đầy đủ, OCSP Stapling hoạt động |
| **A** | Tốt, đạt chuẩn bảo mật hiện hành nhưng thiếu một số điểm cộng (ví dụ chưa bật HSTS) |
| **B** | Còn hỗ trợ giao thức/cipher cũ (ví dụ TLS 1.0/1.1) gây giảm điểm |
| **C** | Có vấn đề rõ ràng hơn: cipher yếu, chain thiếu sót, hoặc cấu hình không tối ưu |
| **F** | Lỗi nghiêm trọng: lỗ hổng đã biết (ví dụ Heartbleed cũ), chain hoàn toàn sai, hoặc cấu hình sai căn bản |


### Các tiêu chí được SSL Labs đánh giá
 
```
Certificate          → Đúng domain, đúng SAN, chưa hết hạn, đúng chain 
Protocol Support     → Có còn bật SSL 2.0/3.0, TLS 1.0/1.1 không 
Key Exchange         → Độ mạnh RSA/ECC, có hỗ trợ Forward Secrecy không 
Cipher Strength      → Có còn 3DES, RC4 (cipher yếu) không 
HSTS                 → Có bật, có includeSubDomains, có preload không
OCSP Stapling        → Có hoạt động không 
Chain of Trust        → Đầy đủ Intermediate CA không 
```
 
**Cách dùng thực tế:**
 
```
1. Truy cập: https://www.ssllabs.com/ssltest/
2. Nhập domain: demo.lab.local hoặc congty.vn
3. Đợi quét (1-3 phút)
4. Xem kết quả:
   - Overall Rating (A+/A/B/C/F)
   - Certificate 
   - Configuration (Protocol, Cipher, Key Exchange)
   - Handshake Simulation
```
 
> Lưu ý: SSL Labs chỉ test được domain có IP **public**, không quét được domain nội bộ như `demo.lab.local` trong lab — cần một domain thật trỏ DNS ra ngoài Internet để test bằng công cụ này.
 
## SSL Checker
 
Là nhóm công cụ nhẹ hơn SSL Labs, tập trung vào kiểm tra nhanh các thông tin cơ bản, không chấm điểm tổng thể chi tiết như SSL Labs. Một số công cụ phổ biến: `sslshopper.com/ssl-checker`, `whatsmychaincert.com`, hoặc tích hợp sẵn trong nhiều đại lý bán SSL (kể cả Nhân Hòa thường có sẵn link kiểm tra nhanh sau khi khách cài cert).
 
### Kiểm tra chứng chỉ
 
Xác nhận cert đang chạy đúng domain, đúng CA cấp, hiển thị thông tin Subject/Issuer giống cấu trúc đã học ở Phần 3 nhưng dạng rút gọn, dễ đọc cho người không chuyên kỹ thuật.
 
### Kiểm tra Chain
 
Tương đương việc dùng `openssl s_client -showcerts` ở Phần 5.4, nhưng hiển thị trực quan: liệt kê từng cert trong chain, cảnh báo rõ nếu thiếu Intermediate CA — đây là công cụ nhanh nhất để xác nhận lỗi "Incomplete Chain" mà không cần nhớ cú pháp OpenSSL.
 
### Kiểm tra ngày hết hạn
 
Hiển thị rõ `Not After` và số ngày còn lại — dùng để theo dõi nhanh nhiều domain cùng lúc trong công việc support hằng ngày, đặc biệt hữu ích khi quản lý nhiều domain khách hàng cùng lúc mà không muốn chạy `openssl` riêng cho từng domain.
 
## So sánh SSL Labs vs SSL Checker
 
| Tiêu chí | SSL Labs | SSL Checker (nhẹ) |
|---|---|---|
| Độ chi tiết | Rất chi tiết, chấm điểm A+ → F | Cơ bản: cert, chain, ngày hết hạn |
| Thời gian quét | 1–3 phút | Vài giây |
| Phù hợp | Audit định kỳ, demo cho khách hàng, kiểm tra trước go-live | Kiểm tra nhanh hằng ngày, theo dõi nhiều domain |
| Test với nhiều OS/Browser | Có (Handshake Simulation) | Không |

 Toàn bộ tài liệu từ Phần 5 đến 7.5 đã đi qua từng thành phần kỹ thuật riêng lẻ: khóa, CSR, định dạng, chain, cài đặt trên từng loại server, redirect, HSTS, OCSP, HTTP/2, và công cụ kiểm tra. Trong công việc thực tế của System Administrator, các thành phần này không được kiểm tra rời rạc mà cần một **quy trình audit có thứ tự, lặp lại được**, áp dụng cho mọi domain trong hạ tầng — đặc biệt quan trọng khi quản lý nhiều domain khách hàng cùng lúc (bối cảnh hosting/mail server tại Nhân Hòa).
 
Quy trình dưới đây tổng hợp lại toàn bộ kiến thức đã học thành một checklist hành động theo đúng thứ tự ưu tiên xử lý vấn đề.
 
## Quy trình Audit SSL — 8 Bước
 
```
1. Kiểm tra Certificate
        |
        v
2. Kiểm tra Chain
        |
        v
3. Kiểm tra Cipher
        |
        v
4. Kiểm tra TLS Version
        |
        v
5. Kiểm tra HSTS
        |
        v
6. Kiểm tra OCSP
        |
        v
7. Kiểm tra Expiration
        |
        v
8. Đánh giá SSL Labs
```
 
Thứ tự này không tùy ý: các bước 1–4 kiểm tra **tính đúng đắn cấu trúc** của cert , bước 5–7 kiểm tra **cấu hình vận hành**, bước 8 là bước **tổng hợp xác nhận** lại toàn bộ.
 
---
 
### Bước 1 — Kiểm tra Certificate
 
Xác nhận cert đúng domain, đúng SAN, còn hiệu lực, đúng Issuer (liên hệ Phần 3, 5.2).
 
```bash
openssl x509 -in cert.pem -noout -subject -issuer -dates -ext subjectAltName
```
 
**Tiêu chí pass:** CN/SAN khớp đúng domain đang chạy, `Not After` còn hạn, Issuer là CA hợp lệ (không phải self-signed nếu là production).
 
### Bước 2 — Kiểm tra Chain
 
Xác nhận chain đầy đủ tới Root CA, không thiếu Intermediate (liên hệ Phần 5.4, 5.5).
 
```bash
openssl s_client -connect domain.vn:443 -showcerts < /dev/null 2>/dev/null
```
 
**Tiêu chí pass:** trả về đủ 2 cert (website cert + Intermediate CA), không có dòng cảnh báo `unable to verify the first certificate` hoặc `Verify return code` khác 0.
 
### Bước 3 — Kiểm tra Cipher
 
Xác nhận không còn cipher yếu như 3DES, RC4 .
 
```bash
nmap --script ssl-enum-ciphers -p 443 domain.vn
```
 
**Tiêu chí pass:** danh sách cipher không chứa `3DES`, `RC4`, `NULL`, hoặc cipher gắn nhãn "weak"/"insecure" trong kết quả scan.
 
### Bước 4 — Kiểm tra TLS Version
 
Xác nhận đã loại bỏ SSL 2.0/3.0, TLS 1.0/1.1.
 
```bash
openssl s_client -connect domain.vn:443 -tls1   2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_1 2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_2 2>&1 | grep "Cipher is"
openssl s_client -connect domain.vn:443 -tls1_3 2>&1 | grep "Cipher is"
```
 
**Tiêu chí pass:** TLS 1.0/1.1 trả về lỗi kết nối (handshake failure), chỉ TLS 1.2/1.3 thành công.
 
### Bước 5 — Kiểm tra HSTS
 
Xác nhận header có tồn tại và cấu hình đúng.
 
```bash
curl -I https://domain.vn | grep -i strict-transport-security
```
 
**Tiêu chí pass:** có header `Strict-Transport-Security` với `max-age` đủ dài (khuyến nghị tối thiểu vài tháng trước khi tăng lên 1 năm).
 
### Bước 6 — Kiểm tra OCSP
 
Xác nhận OCSP Stapling đang hoạt động.
 
```bash
openssl s_client -connect domain.vn:443 -status < /dev/null 2>/dev/null | grep "OCSP Response Status"
```
 
**Tiêu chí pass:** trả về `OCSP Response Status: successful (0x0)`, không phải `no response sent`.
 
### Bước 7 — Kiểm tra Expiration
 
Xác nhận cert chưa gần hết hạn và cơ chế auto-renewal đang hoạt động đúng.
 
```bash
echo | openssl s_client -connect domain.vn:443 2>/dev/null | \
    openssl x509 -noout -enddate
 
# Kiểm tra timer renew có đang chạy đúng lịch
systemctl status certbot.timer
```
 
**Tiêu chí pass:** còn trên 15–30 ngày trước hết hạn (với Let's Encrypt 90 ngày, đây là ngưỡng cảnh báo cần theo dõi sát); `certbot.timer` ở trạng thái `active`.
 
### Bước 8 — Đánh giá SSL Labs
 
Chạy bài test tổng hợp để xác nhận lại toàn bộ 7 bước trên cùng lúc, lấy hạng điểm chính thức để báo cáo (liên hệ Phần 7.5).
 
```
Truy cập: https://www.ssllabs.com/ssltest/
Nhập: domain.vn
Mục tiêu tối thiểu: hạng A
Mục tiêu tốt nhất: hạng A+
```
 
**Tiêu chí pass:** hạng A hoặc A+; nếu thấp hơn, đối chiếu lại báo cáo chi tiết của SSL Labs với từng bước 1–7 ở trên để xác định bước nào đang gây giảm điểm.
 
---
 
## Bảng tổng hợp Checklist Audit (dùng khi audit nhiều domain)
 
| # | Bước | Lệnh kiểm tra chính | Pass khi |
|---|---|---|---|
| 1 | Certificate | `openssl x509 -noout -dates -ext subjectAltName` | Đúng domain, còn hạn |
| 2 | Chain | `openssl s_client -showcerts` | Đủ Intermediate, verify return 0 |
| 3 | Cipher | `nmap --script ssl-enum-ciphers` | Không còn 3DES/RC4 |
| 4 | TLS Version | `openssl s_client -tls1/-tls1_1/...` | Chỉ TLS 1.2/1.3 thành công |
| 5 | HSTS | `curl -I \| grep strict-transport` | Có header, max-age hợp lý |
| 6 | OCSP | `openssl s_client -status` | `successful (0x0)` |
| 7 | Expiration | `openssl x509 -enddate` + `systemctl status certbot.timer` | Còn hạn, timer active |
| 8 | SSL Labs | Web UI ssllabs.com | Hạng A hoặc A+ |
 
## Ứng dụng thực tế trong công việc
 
Khi audit hàng loạt domain trên một server hosting, có thể viết script bash lặp qua danh sách domain, chạy 7 bước dòng lệnh (1–7) tự động, xuất kết quả ra file log, chỉ domain nào fail mới cần vào SSL Labs kiểm tra sâu — tránh phải chạy SSL Labs cho từng domain.
 
```bash
#!/bin/bash
# Audit nhanh nhiều domain — 7 bước dòng lệnh đầu tiên
DOMAINS=("congty.vn" "shop.congty.vn" "mail.congty.vn")
 
for d in "${DOMAINS[@]}"; do
    echo "===== $d ====="
    echo | openssl s_client -connect "$d:443" -servername "$d" 2>/dev/null | \
        openssl x509 -noout -subject -enddate
    echo "---"
done
```
-----
## 8.Xử lý lỗi SSL thường gặp
 
Trong môi trường production, các lỗi SSL/TLS là nguyên nhân hàng đầu gây gián đoạn dịch vụ và ảnh hưởng niềm tin khách hàng. Phần này cung cấp quy trình **check → diagnose → fix** cho từng loại lỗi phổ biến nhất.
 
| Lỗi | Nguyên nhân chính | Công cụ check |
|-----|-------------------|---------------|
| Mixed Content | HTTP resource trên HTTPS page | `curl`, Chrome DevTools |
| ERR_CERT_COMMON_NAME_INVALID | Domain không khớp SAN trong cert | `openssl x509 -ext subjectAltName` |
| SSL Handshake Failure | Cipher/protocol mismatch, cert lỗi | `openssl s_client`, `nmap ssl-enum-ciphers` |
| Expired Certificate | Cert hết hạn, không gia hạn kịp | `openssl x509 -dates`, `check-certs.sh` |
| Missing Intermediate | Thiếu intermediate CA cert | `openssl s_client -showcerts`, `sslyze` |
 
---
 
## 8.1 Mixed Content
 
Mixed Content xảy ra khi trang HTTPS tải tài nguyên (ảnh, script, CSS, iframe) qua HTTP. Trình duyệt sẽ **block hoặc warn**, ảnh hưởng UX và SEO ranking.
 
### Check lỗi
 
```bash
# Kiểm tra Mixed Content bằng curl — scan toàn bộ response headers
curl -sI https://example.com | grep -i 'content-security-policy\|strict-transport'
 
# Dùng grep để tìm các link HTTP trong source HTML
curl -sk https://example.com | grep -oE 'http://[^"'\''> ]+' | sort -u
 
# Kiểm tra bằng OpenSSL (verbose TLS info)
openssl s_client -connect example.com:443 -servername example.com < /dev/null
 
# Dùng nmap để audit SSL
nmap --script ssl-enum-ciphers -p 443 example.com
```
 
### Fix trên Nginx
 
```nginx
# /etc/nginx/sites-available/example.com
 
server {
    listen 80;
    server_name example.com www.example.com;
    # Redirect toàn bộ HTTP -> HTTPS (301 permanent)
    return 301 https://$host$request_uri;
}
 
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
 
    # HSTS: bắt buộc HTTPS trong 1 năm, bao gồm subdomain
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
 
    # Content Security Policy — upgrade HTTP requests tự động
    add_header Content-Security-Policy "upgrade-insecure-requests;" always;
 
    ssl_certificate     /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
}
```
 
### Fix trên Apache
 
```apache
# /etc/apache2/sites-available/example.com.conf
 
<VirtualHost *:80>
    ServerName example.com
    Redirect permanent / https://example.com/
</VirtualHost>
 
<VirtualHost *:443>
    ServerName example.com
    SSLEngine on
 
    # HSTS header
    Header always set Strict-Transport-Security \
        "max-age=31536000; includeSubDomains; preload"
 
    # Upgrade insecure requests
    Header always set Content-Security-Policy "upgrade-insecure-requests;"
 
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
 
# Kích hoạt modules cần thiết
# sudo a2enmod ssl rewrite headers
# sudo systemctl reload apache2
```
 
> 💡 **Mẹo thực tế từ Senior**
>
> - Sau khi thêm HSTS, dùng https://hstspreload.org để submit domain vào Chrome preload list.
> - Kiểm tra Mixed Content nhanh nhất: mở Chrome DevTools > Console tab — lỗi hiển thị màu đỏ/vàng.
> - Với WordPress: thêm vào `wp-config.php`:
>   ```php
>   define('FORCE_SSL_ADMIN', true);
>   define('WP_HOME', 'https://example.com');
>   ```
 
---
 
## 8.2 ERR_CERT_COMMON_NAME_INVALID
 
Lỗi này xuất hiện khi domain trong certificate không khớp với domain người dùng truy cập. Ví dụ: cert cấp cho `example.com` nhưng user truy cập `www.example.com` hoặc `sub.example.com`.
 
### Check lỗi
 
```bash
# Xem thông tin chi tiết certificate (CN và SAN)
openssl s_client -connect example.com:443 -servername example.com < /dev/null 2>/dev/null \
  | openssl x509 -noout -text | grep -A5 'Subject:\|Subject Alternative Name'
 
# Cách nhanh hơn — chỉ lấy CN và ngày hết hạn
echo | openssl s_client -connect example.com:443 2>/dev/null \
  | openssl x509 -noout -subject -dates
 
# Check tất cả SAN (Subject Alternative Names)
openssl x509 -in /etc/ssl/certs/example.com.crt -noout -ext subjectAltName
 
# Verify cert match với domain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/example.com.crt
```
 
### Cấp lại cert với SAN đúng bằng OpenSSL
 
```bash
# Tạo file config với SAN
cat > /tmp/san.cnf << 'EOF'
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no
 
[req_distinguished_name]
C  = VN
ST = Hanoi
L  = Hanoi
O  = My Company
CN = example.com
 
[v3_req]
keyUsage         = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names
 
[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = api.example.com
EOF
 
# Sinh private key + CSR
openssl req -new -newkey rsa:2048 -nodes \
  -keyout /etc/ssl/private/example.com.key \
  -out /tmp/example.com.csr \
  -config /tmp/san.cnf
 
# Verify CSR có đủ SAN chưa
openssl req -text -noout -in /tmp/example.com.csr | grep -A3 'Subject Alternative'
```
 
## 8.3 SSL Handshake Failure
 
Handshake failure là lỗi phức tạp nhất — có thể do: cipher suite không khớp, protocol mismatch, cert bị reject, SNI sai, hoặc timeout.
 
### Quy trình Diagnose chi tiết
 
```bash
# Step 1: Test kết nối TLS cơ bản
openssl s_client -connect example.com:443 -servername example.com
 
# Step 2: Force TLS version cụ thể để tìm version nào work
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3
 
# Step 3: List cipher suites server hỗ trợ
nmap --script ssl-enum-ciphers -p 443 example.com 2>/dev/null | grep -E 'TLS|cipher'
 
# Step 4: Kiểm tra certificate chain đầy đủ chưa
openssl s_client -connect example.com:443 -showcerts < /dev/null 2>/dev/null \
  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' | grep -c 'BEGIN CERT'
# Kết quả: 1 = thiếu intermediate | 2+ = có chain (tốt)
 
# Step 5: Check log để tìm lỗi cụ thể
tail -100 /var/log/nginx/error.log | grep -i 'ssl\|tls\|handshake'
tail -100 /var/log/apache2/error.log | grep -i 'ssl\|tls\|handshake'
 
# Step 6: Xem chi tiết SSL bằng sslyze
pip3 install sslyze --break-system-packages
sslyze example.com --regular
```
 
### Fix cấu hình SSL Nginx — chuẩn production
 
```nginx
# /etc/nginx/conf.d/ssl-params.conf
# Include file này vào tất cả HTTPS server blocks
 
# Chỉ cho phép TLS 1.2 và 1.3 (bỏ 1.0 và 1.1)
ssl_protocols TLSv1.2 TLSv1.3;
 
# Cipher suites an toàn, ưu tiên theo thứ tự
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:
            ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:
            ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:
            DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
 
ssl_prefer_server_ciphers on;
 
# Session caching để tăng performance
ssl_session_cache   shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
 
# OCSP Stapling — giảm latency khi verify cert
ssl_stapling        on;
ssl_stapling_verify on;
resolver            8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout    5s;
 
# DH params (sinh trước: openssl dhparam -out /etc/nginx/dhparam.pem 2048)
ssl_dhparam /etc/nginx/dhparam.pem;
```
 
### Fix cấu hình SSL Apache
 
```apache
# /etc/apache2/conf-available/ssl-hardening.conf
 
# Chỉ TLS 1.2 và 1.3
SSLProtocol -all +TLSv1.2 +TLSv1.3
 
# Cipher suites mạnh
SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!RC4
SSLHonorCipherOrder on
 
# Compression OFF (tránh CRIME attack)
SSLCompression off
 
# OCSP Stapling
SSLUseStapling on
SSLStaplingCache shmcb:/var/run/ocsp(128000)
 
# Kích hoạt config
# sudo a2enconf ssl-hardening
# sudo systemctl reload apache2
```
 
> - Nếu thấy `SSL_ERROR_RX_RECORD_TOO_LONG`: server đang trả HTTP trên port 443. Check xem SSL block có đúng port không.
> - Lỗi `no shared cipher`: client và server không có cipher chung — thường gặp với thiết bị/app cũ.
> - Sinh DH params trước khi deploy: `openssl dhparam -out /etc/nginx/dhparam.pem 2048` (mất ~1–2 phút).
> - Test nhanh SSL rating: `curl 'https://api.ssllabs.com/api/v3/analyze?host=example.com' | python3 -m json.tool`
 
---  

## 1.4 Expired Certificate
 
Cert hết hạn là lỗi nguy hiểm nhất vì ảnh hưởng **100% người dùng ngay lập tức**. Cần hệ thống monitoring và quy trình gia hạn rõ ràng.
 
### Check expiry date
 
```bash
# Check cert đang dùng trên server
openssl s_client -connect example.com:443 -servername example.com < /dev/null 2>/dev/null \
  | openssl x509 -noout -dates
 
# Check file cert local
openssl x509 -in /etc/ssl/certs/example.com.crt -noout -dates -subject
 
# Script check tất cả cert và cảnh báo nếu hết hạn trong 30 ngày
cat > /usr/local/bin/check-certs.sh << 'SCRIPT'
#!/bin/bash
WARN_DAYS=30
for CERT in /etc/ssl/certs/*.crt /etc/letsencrypt/live/*/cert.pem; do
  [ -f "$CERT" ] || continue
  EXPIRY=$(openssl x509 -in "$CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
  NOW_EPOCH=$(date +%s)
  DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
  if [ "$DAYS_LEFT" -le "$WARN_DAYS" ]; then
    echo "[WARN] $CERT expires in $DAYS_LEFT days ($EXPIRY)"
  else
    echo "[OK]   $CERT valid for $DAYS_LEFT days"
  fi
done
SCRIPT
chmod +x /usr/local/bin/check-certs.sh
 
# Thêm vào crontab — check mỗi ngày lúc 8 giờ sáng
echo '0 8 * * * root /usr/local/bin/check-certs.sh | mail -s "SSL Cert Check" admin@example.com' \
  >> /etc/cron.d/ssl-check
```
 
### Gia hạn cert thủ công
 
```bash
# Let's Encrypt — gia hạn manual
sudo certbot renew --dry-run        # Test trước (không thực sự renew)
sudo certbot renew                  # Gia hạn thật
sudo certbot renew --force-renewal  # Ép renew dù chưa hết hạn
 
# Reload web server sau khi renew
sudo systemctl reload nginx
# hoặc
sudo systemctl reload apache2
 
# Với cert mua từ CA (VeriSign, Digicert...): upload file mới lên server
sudo cp new-certificate.crt /etc/ssl/certs/example.com.crt
sudo cp new-private.key     /etc/ssl/private/example.com.key
sudo cp intermediate-ca.crt /etc/ssl/certs/intermediate.crt
 
# Ghép cert chain (nếu cần)
cat new-certificate.crt intermediate-ca.crt root-ca.crt > /etc/ssl/certs/fullchain.crt
 
# Test config trước khi reload
sudo nginx -t && sudo systemctl reload nginx
sudo apache2ctl configtest && sudo systemctl reload apache2
```
 

> - Thiết lập Prometheus alertmanager rule: cảnh báo khi cert còn < 14 ngày.
> - Let's Encrypt cert có hạn **90 ngày** — Certbot tự renew khi còn 30 ngày nếu cài đúng cron/systemd timer.
> - Luôn test renew bằng `--dry-run` trước khi chạy thật trên production.
> - Backup private key và cert vào S3/remote ngay sau khi cấp mới.
 
---
## 1.5 Thiếu Intermediate Certificate
 
Đây là lỗi **âm thầm nguy hiểm**: trang web vẫn load bình thường trên desktop Chrome (vì browser cache intermediate), nhưng crash trên mobile, API client, và `curl` mặc định.
 
### Check lỗi
 
```bash
# Kiểm tra chain đầy đủ — đếm số cert trong response
openssl s_client -connect example.com:443 -showcerts < /dev/null 2>/dev/null \
  | grep -c 'BEGIN CERTIFICATE'
# Kết quả 1: THIẾU intermediate cert
# Kết quả 2+: chain đầy đủ (tốt)
 
# Verify toàn bộ chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
  -untrusted /etc/ssl/certs/intermediate.crt \
  /etc/ssl/certs/example.com.crt
 
# Check bằng curl (sẽ báo lỗi nếu thiếu intermediate)
curl -v https://example.com 2>&1 | grep -i 'certificate\|verify\|issuer'
```
 
### Fix trên Nginx
 
```bash
# Tạo fullchain.pem = cert + intermediate + root
cat /etc/ssl/certs/example.com.crt \
    /etc/ssl/certs/intermediate.crt \
    /etc/ssl/certs/root-ca.crt \
  > /etc/ssl/certs/fullchain.pem
```
 
```nginx
# /etc/nginx/sites-available/example.com
server {
    listen 443 ssl http2;
    ssl_certificate     /etc/ssl/certs/fullchain.pem;   
    ssl_certificate_key /etc/ssl/private/example.com.key;
}
```
 
```bash
# Verify config và reload
sudo nginx -t && sudo systemctl reload nginx
 
# Confirm chain sau khi fix
openssl s_client -connect example.com:443 -showcerts < /dev/null 2>/dev/null \
  | grep -c 'BEGIN CERTIFICATE'
```
 
### Fix trên Apache
 
```apache
<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
    # Chỉ định intermediate cert riêng (Apache 2.4.8+)
    SSLCertificateChainFile /etc/ssl/certs/intermediate.crt
</VirtualHost>
 
# Hoặc gộp tất cả vào 1 file (khuyến nghị)
# cat example.com.crt intermediate.crt > /etc/ssl/certs/apache-fullchain.crt
# SSLCertificateFile /etc/ssl/certs/apache-fullchain.crt
```
 

> - Khi mua cert từ CA, họ thường gửi kèm file `ca-bundle` hoặc `chain.crt` — đó chính là intermediate cert.
> - Let's Encrypt tự động tạo `fullchain.pem` tại `/etc/letsencrypt/live/example.com/fullchain.pem` — **luôn dùng file này**.
> - Test trên môi trường sạch: `curl --capath /etc/ssl/certs https://example.com`
 
---
## 9. SSL trong các giao thức & Tắt TLS cũ
 
SSL/TLS không chỉ dùng cho HTTPS. Hệ thống email (SMTP, IMAP, POP3) và nhiều dịch vụ khác đều cần được bảo vệ bằng TLS. Đồng thời, việc tắt TLS 1.0/1.1 là yêu cầu bắt buộc theo PCI-DSS và các tiêu chuẩn bảo mật hiện đại.
 
---
 
## 9.1 HTTPS (HTTP over TLS — Port 443)
 
### Nginx HTTPS — Cấu hình hoàn chỉnh production-ready
 
```nginx
# /etc/nginx/sites-available/example.com
 
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://example.com$request_uri;
}
 
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
 
    # Cert paths (Let's Encrypt)
    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
 
    # Include SSL hardening params
    include /etc/nginx/conf.d/ssl-params.conf;
 
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
 
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
 
> 
> - Luôn dùng directive `http2` — HTTP/2 tăng performance đáng kể nhờ multiplexing.
> - Kiểm tra HTTP/2: `curl -I --http2 https://example.com` — nếu thấy `HTTP/2 200` là thành công.
> - `add_header` chỉ inherit trong cùng 1 level — nếu override trong `location` block, phải khai báo lại tất cả headers.
 
---

 ## 9.2 SMTPS (SMTP over SSL — Port 465 & STARTTLS 587)
 
Có 2 cơ chế bảo mật SMTP: **SMTPS (implicit TLS, port 465)** — kết nối TLS ngay từ đầu, và **STARTTLS (port 587)** — bắt đầu bằng plaintext rồi upgrade lên TLS. Modern mail server nên hỗ trợ cả hai.
 
### Cấu hình Postfix với TLS
 
```ini
# /etc/postfix/main.cf — TLS configuration
 
# ── OUTBOUND TLS (khi gửi mail ra ngoài) ──
smtp_use_tls = yes
smtp_tls_security_level = may        
smtp_tls_note_starttls_offer = yes
smtp_tls_loglevel = 1                  # Log TLS connections
smtp_tls_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1
smtp_tls_ciphers = high
 
# ── INBOUND TLS (khi nhận mail từ ngoài vào) ──
smtpd_use_tls = yes
smtpd_tls_security_level = may
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file  = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_tls_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1
smtpd_tls_loglevel = 1
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
```
 
```ini
# /etc/postfix/master.cf — Enable port 465 (implicit SSL) và 587 (STARTTLS)
 
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
 
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
```
 
```bash
# Apply config
sudo postfix check && sudo systemctl reload postfix
 
# Test SMTP TLS
openssl s_client -connect mail.example.com:465
openssl s_client -connect mail.example.com:587 -starttls smtp
```
 
> 💡 **Mẹo thực tế từ Senior**
>
> - Ưu tiên port **587** (submission) với STARTTLS — đây là standard hiện đại theo RFC 8314.
> - Port 465 (SMTPS) là legacy nhưng vẫn được nhiều email client (Outlook, Thunderbird) sử dụng.
> - Sau khi cấu hình TLS, check SPF/DKIM/DMARC — SSL không đủ để email không vào spam.
> - Log check: `tail -f /var/log/mail.log | grep -i 'tls\|ssl'`
 
---
 
## 9.3 IMAPS (IMAP over SSL — Port 993)

IMAPS bảo vệ kết nối đọc mail của email client. Dovecot là mail server phổ biến nhất cho IMAP/POP3 trên Linux.
 
### Cấu hình Dovecot IMAPS
 
```ini
# /etc/dovecot/conf.d/10-ssl.conf
 
ssl = required   # Bắt buộc TLS (không cho phép plaintext)
ssl_cert = </etc/letsencrypt/live/mail.example.com/fullchain.pem
ssl_key  = </etc/letsencrypt/live/mail.example.com/privkey.pem
 
# Tắt protocol cũ
ssl_min_protocol = TLSv1.2
 
# Cipher suites mạnh
ssl_cipher_list = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:
                  ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
ssl_prefer_server_ciphers = yes
 
# DH params — sinh bằng: openssl dhparam -out /etc/dovecot/dh.pem 2048
ssl_dh = </etc/dovecot/dh.pem
```
 
```ini
# /etc/dovecot/conf.d/10-master.conf — Enable port 993 (IMAPS)
 
service imap-login {
  inet_listener imap {
    port = 143   # IMAP với STARTTLS
  }
  inet_listener imaps {
    port = 993   # IMAPS — implicit SSL
    ssl  = yes
  }
}
```

---
## 9.4 POP3S (POP3 over SSL — Port 995)
 
POP3S ít phổ biến hơn IMAPS nhưng vẫn cần cấu hình đúng cho các email client cũ.
 
### Cấu hình Dovecot POP3S
 
```ini
# /etc/dovecot/conf.d/10-master.conf — Enable port 995 (POP3S)
 
service pop3-login {
  inet_listener pop3 {
    port = 110   # POP3 với STARTTLS
  }
  inet_listener pop3s {
    port = 995   # POP3S — implicit SSL
    ssl  = yes
  }
}
```
 
```bash
sudo systemctl restart dovecot
 
# Test kết nối POP3S
openssl s_client -connect mail.example.com:995
# Sau khi connect:
# USER user@example.com
# PASS password
# LIST
```
 
> 💡 **Mẹo thực tế từ Senior**
>
> - Nên disable POP3 plaintext (port 110) nếu business không có nhu cầu — chỉ mở POP3S (995).
> - Kiểm tra port đang mở: `ss -tlnp | grep -E '110|143|465|587|993|995'`
> - Firewall rule mẫu cho mail server: `ufw allow 25,465,587,993,995/tcp`
 
---
 
## 9.5 Tắt TLS 1.0 và TLS 1.1 — Bảo vệ hệ thống
 
TLS 1.0 (1999) và TLS 1.1 (2006) có nhiều lỗ hổng nghiêm trọng: **BEAST, POODLE, CRIME, SWEET32**. Từ 2020, tất cả browser lớn và PCI-DSS đều yêu cầu tắt 2 protocol này.
 
| Protocol | Trạng thái | Lý do |
|----------|-----------|-------|
| SSL 2.0 / 3.0 | ❌ Tắt từ lâu | DROWN, POODLE — cực kỳ nguy hiểm |
| TLS 1.0 | ❌ Tắt ngay | BEAST, POODLE — CVE-2014-3566 |
| TLS 1.1 | ❌ Tắt ngay | Deprecated RFC 8996 — Chrome 84+ block |
| TLS 1.2 | ✅ Giữ lại | Hiện tại vẫn an toàn với cipher mạnh |
| TLS 1.3 | ✅ Bật | Nhanh hơn, an toàn hơn, forward secrecy |
 
### Tắt TLS 1.0/1.1 trên Nginx
 
```nginx
# /etc/nginx/conf.d/ssl-params.conf
ssl_protocols TLSv1.2 TLSv1.3;
```
 
```bash
# Verify sau khi reload
sudo nginx -t && sudo systemctl reload nginx
 
# Test — kết nối TLS 1.0 phải fail
openssl s_client -connect example.com:443 -tls1
# Kết quả mong đợi: 'no protocols available' hoặc handshake failure
 
openssl s_client -connect example.com:443 -tls1_1
# Kết quả mong đợi: handshake failure
 
openssl s_client -connect example.com:443 -tls1_2
# Kết quả mong đợi: Handshake thành công ✓
```
 
### Tắt TLS 1.0/1.1 trên Apache
 
```apache
# /etc/apache2/mods-enabled/ssl.conf
SSLProtocol -all +TLSv1.2 +TLSv1.3
```
 
```bash
sudo apache2ctl configtest && sudo systemctl reload apache2
```
 
### Tắt TLS 1.0/1.1 ở cấp hệ điều hành (OpenSSL)
 
```ini
# /etc/ssl/openssl.cnf — thêm vào cuối file
[system_default_sect]
MinProtocol = TLSv1.2
CipherString = DEFAULT@SECLEVEL=2
```
 
```bash
# Kiểm tra OpenSSL version và default settings
openssl version -a
openssl ciphers -v 'DEFAULT@SECLEVEL=2' | head -10
```
 
> - Trước khi tắt TLS 1.0/1.1, check log xem còn client nào đang dùng không:
>   ```bash
>   grep 'TLSv1.0\|TLSv1.1' /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn
 
```bash
# Apply và test
sudo doveconf -n | grep ssl
sudo systemctl restart dovecot
 
# Test kết nối IMAPS
openssl s_client -connect mail.example.com:993
# Sau khi connect, gõ: . LOGIN user@example.com password
```
 
---

## 10. Xu hướng tương lai & Tự động hóa
Bảo mật TLS không đứng yên. TLS 1.3, HTTP/3 và tự động hóa Certbot là 3 nền tảng mà mọi SysAdmin hiện đại cần nắm vững.  
## 10.1 TLS 1.3 
 
TLS 1.3 mang đến 2 cải tiến đột phá: **1-RTT handshake** (giảm từ 2 roundtrips xuống 1) và **0-RTT resumption** cho session đã biết trước. Tất cả cipher suite TLS 1.3 đều có Perfect Forward Secrecy bắt buộc.
 
### So sánh TLS 1.2 vs TLS 1.3
 
| Tiêu chí | TLS 1.2 | TLS 1.3 |
|----------|---------|---------|
| Handshake | 2-RTT | 1-RTT (nhanh hơn ~50ms) |
| Session Resume | Session ID / Tickets | 0-RTT Pre-Shared Key |
| Cipher Suites | Nhiều, kể cả yếu | Chỉ 5 suite mạnh, loại bỏ RSA key exchange |
| Forward Secrecy | Tùy cipher (ECDHE có, RSA không) | Bắt buộc — tất cả suite |
| Compression | Có (dễ bị CRIME attack) | Không có |
| Downgrade Protection | Không | Có (server random poisoning) |
 
### Bật TLS 1.3 trên Nginx
 
```bash
# Nginx 1.13+ hỗ trợ TLS 1.3 — Ubuntu 22.04 có Nginx 1.18+
nginx -v
```
 
```nginx
# /etc/nginx/conf.d/ssl-params.conf
ssl_protocols TLSv1.2 TLSv1.3;
 
# TLS 1.3 cipher suites (explicit)
ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:
             ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
```
 
```bash
sudo nginx -t && sudo systemctl reload nginx
 
# Kiểm tra TLS 1.3 đang hoạt động
openssl s_client -connect example.com:443 -tls1_3 < /dev/null 2>/dev/null \
  | grep 'Protocol\|Cipher'
# Kết quả mong đợi: Protocol : TLSv1.3
 
# Check qua curl
curl -v --tlsv1.3 https://example.com 2>&1 | grep 'TLSv1.3\|SSL connection'
```
 
### Bật TLS 1.3 trên Apache
 
```bash
# Apache 2.4.36+ hỗ trợ TLS 1.3 (cần OpenSSL 1.1.1+)
apache2 -v && openssl version
```
 
```apache
# /etc/apache2/mods-enabled/ssl.conf
SSLProtocol -all +TLSv1.2 +TLSv1.3
 
# TLS 1.3 cipher suites
SSLOpenSSLConfCmd Ciphersuites \
  "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256"
```
 
```bash
sudo apache2ctl configtest && sudo systemctl reload apache2
openssl s_client -connect example.com:443 -tls1_3 2>/dev/null | grep 'Protocol'
```

## 10.2 HTTP/3 và QUIC Protocol
 
HTTP/3 (RFC 9114, 2022) chạy trên giao thức **QUIC** thay vì TCP. QUIC = UDP + TLS 1.3 tích hợp sẵn + multiplexing không head-of-line blocking. Kết quả: nhanh hơn đáng kể trên mạng không ổn định (mobile, WiFi yếu).
 
### So sánh HTTP/2 vs HTTP/3
 
| Tiêu chí | HTTP/2 (TCP+TLS) | HTTP/3 (QUIC) |
|----------|-----------------|---------------|
| Transport | TCP | UDP (QUIC) |
| Handshake | TCP 3-way + TLS 1-RTT | QUIC 0-RTT/1-RTT (kết hợp) |
| HOL Blocking | Có (TCP level) | Không (QUIC multiplexing) |
| Connection Migration | Không (IP đổi = reconnect) | Có (Connection ID) |
| TLS | TLS 1.2/1.3 (riêng) | TLS 1.3 (tích hợp bắt buộc) |
| Browser support | 100% modern browsers | ~95% modern browsers (2024) |
 
### Bật HTTP/3 trên Nginx (Nginx 1.25+)
 
```bash
# Kiểm tra Nginx version hỗ trợ HTTP/3
nginx -V 2>&1 | grep -i 'quic\|http3'
 
# Nếu chưa hỗ trợ, cài từ nginx.org
sudo apt install -y nginx-extras
```
 
```nginx
# /etc/nginx/sites-available/example.com
 
server {
    listen 443 ssl;
    listen 443 quic reuseport;  # HTTP/3 qua QUIC (UDP)
    http2 on;
 
    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
 
    # Thông báo cho browser biết server hỗ trợ HTTP/3
    add_header Alt-Svc 'h3=":443"; ma=86400';
 
    location / {
        root /var/www/html;
    }
}
```
 
```bash
# Mở UDP port 443 trên firewall
sudo ufw allow 443/udp
sudo ufw reload
 
# Test HTTP/3
curl -v --http3 https://example.com
# Hoặc test online: https://http3check.net
```
> - HTTP/3 cần mở **UDP/443** trên firewall — nhiều cloud firewall mặc định chặn UDP


----------

## 10.3 Tự động hóa Certbot (Let's Encrypt)
 
Let's Encrypt + Certbot là combo **miễn phí, tự động, và đủ tin cậy cho production** (dùng bởi hàng triệu domain). Certbot tự gia hạn cert trước khi hết hạn, không cần can thiệp thủ công.
 
### Cài đặt Certbot
 
```bash
# Ubuntu 22.04 — Cài Certbot từ snap (khuyến nghị)
sudo apt update && sudo apt install -y snapd
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
 
certbot --version
 
# Hoặc cài từ apt (version cũ hơn nhưng stable)
sudo apt install -y certbot python3-certbot-nginx python3-certbot-apache
```
 
### Cấp cert tự động với Nginx
 
```bash
# Cấp cert và tự động cấu hình Nginx
sudo certbot --nginx -d example.com -d www.example.com -d api.example.com
 
# Certbot sẽ tự động:
#  1. Verify domain ownership qua HTTP challenge
#  2. Tải cert về /etc/letsencrypt/live/example.com/
#  3. Sửa Nginx config để dùng cert mới
#  4. Reload Nginx
 
# Cấu trúc file cert sau khi cấp:
ls -la /etc/letsencrypt/live/example.com/
# cert.pem       — cert của domain
# chain.pem      — intermediate cert
# fullchain.pem  — cert + intermediate (dùng cái này cho Nginx)
# privkey.pem    — private key (giữ bí mật tuyệt đối!)
```
 
### Cấp cert cho Apache
 
```bash
sudo certbot --apache -d example.com -d www.example.com
```
 
### Cấp cert bằng DNS Challenge (Wildcard)
 
```bash
# Wildcard cert (*.example.com) BẮT BUỘC dùng DNS challenge
sudo certbot certonly \
  --manual \
  --preferred-challenges=dns \
  -d 'example.com' \
  -d '*.example.com'
 
# Certbot sẽ yêu cầu tạo TXT record:
# _acme-challenge.example.com  ->  [giá trị Certbot cung cấp]
 
# Sau khi tạo TXT record, xác nhận propagate:
dig TXT _acme-challenge.example.com @8.8.8.8
```
 
### DNS Challenge tự động với Cloudflare API
 
```bash
sudo apt install -y python3-certbot-dns-cloudflare
 
cat > /etc/letsencrypt/cloudflare.ini << 'EOF'
dns_cloudflare_api_token = YOUR_CF_API_TOKEN
EOF
chmod 600 /etc/letsencrypt/cloudflare.ini
 
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d 'example.com' \
  -d '*.example.com'
```
 
### Tự động gia hạn — Systemd Timer
 
```bash
# Certbot snap tự cài sẵn systemd timer — check:
sudo systemctl status snap.certbot.renew.timer
sudo systemctl list-timers | grep certbot
 
# Timer chạy 2 lần/ngày, renew khi cert còn < 30 ngày
 
# Test renew (dry run — không thực sự renew):
sudo certbot renew --dry-run
 
# Xem log renew:
sudo journalctl -u snap.certbot.renew.service --since '7 days ago'
```
 
### Deploy hook — tự động reload web server sau khi renew
 
```bash
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << 'EOF'
#!/bin/bash
systemctl reload nginx
 
# Gửi notification (tùy chọn)
echo "SSL cert renewed for $(hostname) at $(date)" \
  | mail -s '[INFO] SSL Cert Renewed' admin@example.com
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```
 
### Cấu hình Cron thủ công 
 
```bash
# /etc/cron.d/certbot — chạy 2 lần/ngày theo best practice Let's Encrypt
0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' \
  && certbot renew --quiet --deploy-hook 'systemctl reload nginx'
```
### Monitoring SSL với Prometheus + Alertmanager
 
```yaml
# prometheus.yml — Thêm job scrape cert expiry
scrape_configs:
  - job_name: 'ssl_expiry'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
          - example.com:443
          - mail.example.com:993
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: blackbox-exporter:9115
```
 
```yaml
# /etc/prometheus/rules/ssl.yml — Alert rules
groups:
  - name: ssl_alerts
    rules:
      - alert: SSLCertExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 14
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: 'SSL cert expires in < 14 days: {{ $labels.instance }}'
 
      - alert: SSLCertExpired
        expr: probe_ssl_earliest_cert_expiry - time() < 0
        labels:
          severity: critical
        annotations:
          summary: 'SSL cert EXPIRED: {{ $labels.instance }}'
```
 
