# Báo cáo thực tập day 44 - SSL Termination

## 5. Thành phần kỹ thuật cần làm rõ hơn
# 5.1 Public Key và Private Key

## Định nghĩa

Public Key và Private Key là một cặp khóa toán học liên kết với nhau trong hệ mã hóa bất đối xứng (Asymmetric Cryptography).

Nguyên tắc hoạt động:

* Dữ liệu mã hóa bằng Public Key chỉ có thể giải mã bằng Private Key tương ứng.
* Dữ liệu được ký bằng Private Key có thể được xác thực bằng Public Key.

```text
Public Key  → Mã hóa dữ liệu
Private Key → Giải mã dữ liệu

Private Key → Ký số
Public Key  → Xác thực chữ ký
```

---

## Tại sao Public Key và Private Key tồn tại?

Trong mã hóa đối xứng (AES), hai bên phải sở hữu cùng một khóa bí mật trước khi giao tiếp.

Vấn đề đặt ra:

```text
Client ------------------- Server

Làm sao gửi khóa AES cho nhau
mà không bị nghe lén?
```

Đây được gọi là bài toán phân phối khóa (Key Distribution Problem).

Mã hóa bất đối xứng giải quyết vấn đề này bằng cách:

* Public Key được công khai cho mọi người.
* Private Key chỉ chủ sở hữu nắm giữ.
* Không cần trao đổi khóa bí mật trước.

```text
Client nhận Public Key của Server
            │
            ▼
     Mã hóa dữ liệu
            │
            ▼
        Server
            │
            ▼
Dùng Private Key để giải mã
```

---

## Vai trò trong SSL/TLS

Public Key và Private Key không dùng để mã hóa toàn bộ lưu lượng mạng vì tốc độ xử lý chậm.

Trong TLS, chúng chỉ được sử dụng trong giai đoạn Handshake để tạo Session Key.

Sau khi Session Key được tạo:

```text
TLS Handshake
      │
      ▼
Public Key / Private Key
      │
      ▼
Tạo Session Key
      │
      ▼
AES hoặc ChaCha20
      │
      ▼
Mã hóa toàn bộ dữ liệu
```

Do đó:

* Asymmetric Crypto → Trao đổi khóa.
* Symmetric Crypto → Mã hóa dữ liệu thực tế.

---

## Nếu mất Private Key?

Private Key phải được bảo vệ tuyệt đối.

Nếu Private Key bị lộ:

* Kẻ tấn công có thể giả mạo Server.
* Có thể thực hiện tấn công Man-in-the-Middle.
* Chứng chỉ SSL không còn an toàn.

Cách xử lý:

1. Thu hồi (Revoke) chứng chỉ hiện tại.
2. Tạo cặp khóa mới.
3. Tạo CSR mới.
4. Cấp lại chứng chỉ SSL.

---

## Có thể tạo lại Private Key từ Public Key không?

Không.

Đây là tính chất quan trọng nhất của mã hóa bất đối xứng.

```text
Private Key ─────► Public Key

Dễ tính toán
```

```text
Public Key ─────► Private Key

Không khả thi về mặt tính toán
```

Đây được gọi là hàm một chiều (One-Way Function).

Tính chất này là nền tảng bảo mật của:

* SSL/TLS
* SSH
* VPN
* Chữ ký số
* Blockchain

---

## So sánh RSA và ECC

| Tiêu chí                | RSA                                   | ECC                                      |
| ----------------------- | ------------------------------------- | ---------------------------------------- |
| Cơ sở toán học          | Phân tích số nguyên lớn thành thừa số | Logarit rời rạc trên đường cong Elliptic |
| Độ dài khóa tương đương | 2048-bit                              | 256-bit                                  |
| Hiệu năng               | Chậm hơn                              | Nhanh hơn                                |
| Tài nguyên CPU          | Cao hơn                               | Thấp hơn                                 |
| Kích thước chứng chỉ    | Lớn hơn                               | Nhỏ hơn                                  |
| Băng thông sử dụng      | Nhiều hơn                             | Ít hơn                                   |
| Tính tương thích        | Rất cao                               | Cao                                      |
| Khuyến nghị hiện nay    | Vẫn phổ biến                          | Khuyến nghị cho hệ thống mới             |

### Mức bảo mật tương đương

| RSA      | ECC     |
| -------- | ------- |
| 2048 bit | 256 bit |
| 3072 bit | 384 bit |
| 7680 bit | 521 bit |

---

## Kết luận

* Public Key và Private Key là nền tảng của SSL/TLS.
* Chúng giải quyết bài toán phân phối khóa an toàn trên Internet.
* Trong TLS hiện đại, chúng chỉ dùng để xác thực và trao đổi khóa.
* Dữ liệu thực tế được mã hóa bằng AES hoặc ChaCha20.
* ECC đang dần thay thế RSA nhờ hiệu năng tốt hơn và khóa ngắn hơn nhưng vẫn đảm bảo mức bảo mật tương đương.

Lệnh OpenSSL:

```
# Tạo RSA private key 2048-bit
openssl genrsa -out private.key 2048

# Tạo ECC private key (curve prime256v1)
openssl ecparam -name prime256v1 -genkey -noout -out ecc_private.key

# Xem nội dung chi tiết key
openssl rsa -in private.key -text -noout

# Trích public key ra từ private key
openssl pkey -in private.key -pubout -out public.key
```
## 5.2 CSR (Certificate Signing Request)

### Định nghĩa

CSR (Certificate Signing Request) là một tệp yêu cầu cấp chứng chỉ SSL theo chuẩn PKCS#10.

CSR chứa:

* Public Key của Server.
* Thông tin định danh Domain hoặc Doanh nghiệp.
* Chữ ký được tạo từ Private Key tương ứng.

CSR được gửi tới CA để yêu cầu cấp chứng chỉ SSL/TLS.

---

### Vì sao phải tạo CSR trước khi xin SSL?

Khi cấp SSL, CA cần xác minh hai thông tin:

1. Ai đang yêu cầu cấp chứng chỉ.
2. Public Key nào sẽ được gắn vào chứng chỉ.

CSR đóng gói cả hai thông tin này trong cùng một tệp.

```text
Thông tin Domain/Tổ chức
           +
       Public Key
           +
     Chữ ký số
           ↓
          CSR
```

Điểm quan trọng:

* Private Key luôn được giữ trên Server.
* CA không bao giờ nhận Private Key.
* CA chỉ nhận CSR.

---

## CSR chứa những thông tin gì?

| Trường                   | Ý nghĩa                  | Ví dụ                                                 |
| ------------------------ | ------------------------ | ----------------------------------------------------- |
| CN (Common Name)         | Domain chính cần cấp SSL | congty.vn                                             |
| O (Organization)         | Tên tổ chức              | Cong Ty ABC                                           |
| OU (Organizational Unit) | Phòng ban (tùy chọn)     | IT Department                                         |
| C (Country)              | Mã quốc gia              | VN                                                    |
| ST (State/Province)      | Tỉnh/Thành phố           | Ha Noi                                                |
| L (Locality)             | Quận/Huyện               | Dong Da                                               |
| SAN                      | Danh sách Domain bổ sung | [www.congty.vn](http://www.congty.vn), mail.congty.vn |

Ví dụ:

```
CN  = congty.vn
O   = Cong Ty ABC
OU  = IT Department
C   = VN
ST  = Ha Noi
L   = Dong Da
```

---

## CA sử dụng CSR như thế nào?

Sau khi nhận CSR, CA sẽ:

1. Đọc thông tin định danh trong CSR.
2. Xác minh quyền sở hữu Domain.
3. Lấy Public Key từ CSR.
4. Tạo Certificate.
5. Ký Certificate bằng Private Key của CA.

```text
CSR
 │
 ▼
CA đọc thông tin
 │
 ▼
Xác minh Domain
 │
 ▼
Tạo Certificate
 │
 ▼
Ký bằng Private Key của CA
 │
 ▼
SSL Certificate
```

Lưu ý:

* CSR không chứa Private Key.
* Có thể gửi CSR qua Internet mà không lo lộ khóa bí mật.

---

## Luồng xử lý CSR

```
Private Key
(Giữ trên Server)
      │
      │ Ký CSR
      ▼
     CSR
      │
      ▼
      CA
      │
      │ Xác minh Domain
      │ Ký Certificate
      ▼
 SSL Certificate
      │
      ▼
Cài lên Server
      │
      ▼
Sử dụng cùng Private Key ban đầu
```

---

## Tạo CSR bằng OpenSSL

### Tạo CSR và Private Key mới

```
openssl req -new -newkey rsa:2048 -nodes \
-keyout congty.key \
-out congty.csr \
-subj "/C=VN/ST=Ha Noi/L=Dong Da/O=Cong Ty ABC/CN=congty.vn"
```

---
### Tạo CSR từ Private Key có sẵn

```
openssl req -new \
-key congty.key \
-out congty.csr
```

---
### Tạo CSR có SAN (Multi-Domain)

```bash
openssl req -new \
-key congty.key \
-out congty.csr \
-subj "/CN=congty.vn" \
-addext "subjectAltName=DNS:congty.vn,DNS:www.congty.vn,DNS:mail.congty.vn"
```

---

### Kiểm tra nội dung CSR
openssl req -in congty.csr -noout -text

---
## 5.3 Định Dạng Chứng Chỉ

### Khái niệm

Chứng chỉ SSL sử dụng chuẩn X.509 nhưng có thể được lưu dưới nhiều định dạng khác nhau tùy hệ điều hành và ứng dụng.

---

### Các định dạng phổ biến

#### PEM

* Dạng văn bản (Base64).
* Phổ biến nhất trên Linux.
* Dùng cho Apache, Nginx.
* Có thể chứa Certificate, Private Key hoặc Chain.

```text
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

#### CRT

* Thường là Certificate dạng PEM.
* Không chứa Private Key.
* Phổ biến trên Linux/Unix.

#### CER

* Tương tự CRT.
* Thường dùng trên Windows.
* Có thể là PEM hoặc DER.

#### DER

* Dạng nhị phân (Binary).
* Không đọc được bằng text editor.
* Thường dùng cho Java hoặc một số ứng dụng Windows.

#### PFX / P12

* Chuẩn PKCS#12.
* Chứa Certificate + Private Key + Chain.
* Được bảo vệ bằng mật khẩu.
* Thường dùng trên IIS, Windows và Java.

---

### Bảng so sánh

| Định dạng | Dạng lưu trữ  | Chứa Private Key | Thường dùng          |
| --------- | ------------- | ---------------- | -------------------- |
| PEM       | Text          | Có thể           | Apache, Nginx, Linux |
| CRT       | PEM           | Không            | Linux/Unix           |
| CER       | PEM hoặc DER  | Không            | Windows              |
| DER       | Binary        | Có thể           | Java, Windows        |
| PFX       | Binary        | Có               | IIS, Windows         |
| P12       | Binary        | Có               | Java, macOS          |

---

### Server sử dụng định dạng nào?

| Hệ thống | Định dạng         |
| -------- | ----------------- |
| Apache   | PEM (.crt + .key) |
| Nginx    | PEM (.crt + .key) |
| IIS      | PFX               |
| Windows  | CER, PFX          |
| Java     | P12, JKS          |

---

### Chuyển đổi định dạng

#### PEM → DER

```bash
openssl x509 -in cert.pem -outform der -out cert.der
```

#### DER → PEM

```bash
openssl x509 -in cert.der -inform der -out cert.pem
```

#### Tạo PFX cho IIS

```bash
openssl pkcs12 -export \
-out cert.pfx \
-inkey private.key \
-in cert.pem \
-certfile chain.pem
```

#### Tách PFX thành PEM

```bash
openssl pkcs12 -in cert.pfx -nocerts -nodes -out private.key

openssl pkcs12 -in cert.pfx -clcerts -nokeys -out cert.pem
```

---

## 5.4 Certificate Chain

### Định nghĩa

Certificate Chain (chuỗi chứng chỉ) là một dãy các chứng chỉ liên kết với nhau bằng quan hệ ký số, bắt đầu từ chứng chỉ của website, qua một hoặc nhiều Intermediate CA, kết thúc tại một Root CA mà trình duyệt/hệ điều hành đã tin tưởng sẵn từ trước.  

```text
Website Certificate   (cert của congty.vn, ký bởi Intermediate CA)
        |
        v
Intermediate CA        (cert của CA trung gian, ký bởi Root CA)
        |
        v
Root CA                (tự ký, đã có sẵn trong Trusted Root Store của OS/Browser)
```

---

## Vì sao cần Certificate Chain?

Trình duyệt không tin trực tiếp chứng chỉ của Website. Nó phải xác minh được rằng certificate đó được ký bởi một CA mà nó tin tưởng

Nó phải kiểm tra:

```text
Website Cert
      ↓
Intermediate CA
      ↓
Root CA
      ↓
Trusted Root Store
      ↓
Trusted
```

Nếu lần được tới Root CA đáng tin cậy → Website hợp lệ.

---

## Tại sao Certificate Chain bị lỗi?

### Incomplete Chain

Server chỉ gửi Website Certificate nhưng thiếu Intermediate CA.

```text
Website Cert
      ✖
Intermediate CA
      ✖
Root CA
```

Kết quả:

* Chrome có thể vẫn hoạt động.
* Mobile App, Java, curl thường báo lỗi.

---

### Unknown Issuer

Trình duyệt không tìm được CA đã ký chứng chỉ.

Nguyên nhân:

* Thiếu Intermediate CA.
* CA không nằm trong Trusted Root Store.

---

### Certificate Not Trusted

Trình duyệt không tin chứng chỉ.

Nguyên nhân:

* Self-Signed Certificate.
* Chain không đầy đủ.
* CA không được tin cậy.

---

### Kiểm tra và xử lý thực tế:

```
# Kiểm tra chain mà server đang gửi ra (xem có đủ Intermediate không)
openssl s_client -connect congty.vn:443 -showcerts

# Verify chain hoàn chỉnh dựa vào file chain đã ghép
openssl verify -CAfile chain.pem cert.pem

# Ghép website cert + Intermediate CA thành 1 file chain hoàn chỉnh
# (thứ tự bắt buộc: cert website trước, Intermediate sau, Root thường KHÔNG cần gửi)
cat congty_cert.pem intermediate_ca.pem > fullchain.pem
```
### Cấu hình thực tế trên server:
```
Nginx:
  ssl_certificate     fullchain.pem;   # website cert + Intermediate ghép sẵn
  ssl_certificate_key  private.key;

Apache:
  SSLCertificateFile        congty_cert.pem
  SSLCertificateKeyFile     private.key
  SSLCertificateChainFile   intermediate_ca.pem    # khai riêng Intermediate
```

-----
## 5.5 Intermediate CA và Root CA

### Định nghĩa

**Root CA** là tổ chức chứng thực gốc, tự ký certificate của chính mình (self-signed), và certificate đó được cài đặt sẵn trong Trusted Root Store của hệ điều hành và trình duyệt.

**Intermediate CA** là tổ chức chứng thực trung gian, được Root CA ký cấp certificate, và chính Intermediate CA này mới là bên trực tiếp ký certificate cho website/khách hàng cuối.

```
Root CA            (self-signed, có sẵn trong Trusted Root Store)
   |
   | (ký cấp)
   v
Intermediate CA     (không tự ký, được Root CA bảo lãnh)
   |
   | (ký cấp)
   v
Website Certificate (cert của congty.vn)
```

### Vì sao Root CA không ký trực tiếp cho khách hàng

Private key của Root CA là tài sản có giá trị tin cậy cao nhất trong toàn hệ thống PKI — nếu private key này bị lộ, toàn bộ chứng chỉ đã từng phát hành trên thế giới dựa vào Root CA đó đều mất giá trị tin cậy. Vì vậy Root CA private key được:

- Lưu trữ offline (air-gapped), không kết nối Internet
- Chỉ dùng trong những sự kiện ký cấp hiếm hoi và được kiểm soát nghiêm ngặt (key ceremony)

Việc dùng Intermediate CA làm lớp đệm giúp:

| Lợi ích | Giải thích |
|---|---|
| Giảm rủi ro | Nếu Intermediate CA bị lộ key, chỉ cần revoke Intermediate đó, Root CA vẫn an toàn |
| Vận hành linh hoạt | Intermediate CA có thể online để ký hàng loạt cert cho khách hàng mỗi ngày |
| Phân lớp trách nhiệm | Mỗi Intermediate CA có thể giới hạn phạm vi (theo loại cert, khu vực, mục đích) |

### Ví dụ thực tế

| CA | Mô hình |
|---|---|
| Let's Encrypt | Root: ISRG Root X1 → Intermediate: R10/R11 → Cert website |
| DigiCert | Root: DigiCert Global Root → nhiều Intermediate theo dòng sản phẩm |
| Sectigo | Root: USERTrust RSA/ECC → Intermediate: Sectigo RSA/ECC Domain Validation |

### Cơ chế Trust Chain của trình duyệt/OS

Chrome, Firefox, Windows, macOS đều duy trì danh sách Root CA tin cậy riêng (Microsoft và Apple dùng store của OS, Firefox dùng store riêng của Mozilla — gọi là NSS). Khi nhận một certificate, trình duyệt:

1. Đọc thông tin "Issuer" trên website cert → tìm Intermediate CA tương ứng
2. Đọc "Issuer" của Intermediate CA → tìm tiếp lên Root CA
3. Nếu Root CA cuối cùng nằm trong Trusted Root Store → tin cậy toàn chuỗi
4. Nếu không tìm được hoặc đứt đoạn ở bất kỳ mắt xích nào → báo lỗi `Unknown Issuer` / `Not Trusted`

## Kiểm tra thực tế

```bash
# Xem đầy đủ chain mà server trả về, gồm cả Intermediate
openssl s_client -connect congty.vn:443 -showcerts

# Xem Issuer của một certificate cụ thể
openssl x509 -in cert.pem -noout -issuer

# Xem Issuer của chính Intermediate đó (lần lên Root)
openssl x509 -in intermediate.pem -noout -issuer
```

-----------------------------------


## 6.1 Cài Đặt SSL Trên Apache

### Bước 1 — Cài đặt Apache và bật mod_ssl
 
```bash
sudo apt update
sudo apt install -y apache2
sudo a2enmod ssl
sudo a2enmod headers
sudo systemctl restart apache2
```
 
### Bước 2 — Tạo thư mục chứa certificate
 
```bash
mkdir -p /etc/apache2/ssl
# Copy 3 file vào đây: demo.lab.local.crt, demo.lab.local.key, intermediate_ca.crt
```
 
> Trong lab nội bộ không có CA thật, dùng self-signed certificate để demo:
 
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/apache2/ssl/demo.lab.local.key \
    -out /etc/apache2/ssl/demo.lab.local.crt \
    -subj "/C=VN/ST=Ha Noi/O=Lab Demo/CN=demo.lab.local"
```
<img width="931" height="223" alt="image" src="https://github.com/user-attachments/assets/53f8d3c5-f254-43e7-8322-5bc39e9d2daf" />

 
### Bước 3 — File cấu hình VirtualHost HTTPS
 
File: `/etc/apache2/sites-available/demo.lab.local-ssl.conf`
 
```apache
<VirtualHost *:443>
    ServerName demo.lab.local
    DocumentRoot /var/www/demo.lab.local
 
    SSLEngine on
    SSLCertificateFile      /etc/apache2/ssl/demo.lab.local.crt
    SSLCertificateKeyFile   /etc/apache2/ssl/demo.lab.local.key
    # Chỉ khai khi dùng CA thật có Intermediate riêng:
    # SSLCertificateChainFile /etc/apache2/ssl/intermediate_ca.crt
 
    SSLProtocol             -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite          HIGH:!aNULL:!MD5:!3DES
    SSLHonorCipherOrder     on
 
    ErrorLog  ${APACHE_LOG_DIR}/demo.lab.local-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/demo.lab.local-ssl-access.log combined
</VirtualHost>
```
 
> `SSLProtocol` và `SSLCipherSuite` ở trên chủ động loại bỏ TLS 1.0/1.1 và 3DES  — đây là cấu hình tối thiểu để đạt rating tốt trên SSL Labs (Phần 7.5).
 
### Bước 4 — Kích hoạt site và kiểm tra
 
```bash
sudo a2ensite demo.lab.local-ssl.conf
sudo apache2ctl configtest
# phải trả về "Syntax OK"
systemctl reload apache2
 
# Kiểm tra cổng 443 đang lắng nghe
ss -tlnp | grep 443
 
# Test bằng curl
curl -kv https://demo.lab.local
```
 <img width="872" height="61" alt="image" src="https://github.com/user-attachments/assets/8725cd1a-73a5-483f-9636-758928d82849" />
<img width="556" height="381" alt="image" src="https://github.com/user-attachments/assets/fee52f0d-7a35-46a8-a753-095d516362b1" />

----

## 6.2 Cài Đặt SSL Trên Nginx (Let's Encrypt)

### Bước 1 — Cài Nginx và Certbot
 
```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```
 
> `python3-certbot-nginx` là plugin giúp Certbot tự sửa file cấu hình Nginx, không cần thao tác tay.
 
### Bước 2 — Cấu hình HTTP trước khi xin cert
 
File: `/etc/nginx/sites-available/demo.lab.local`
 
```nginx
server {
    listen 80;
    server_name demo.lab.local;
    root /var/www/demo.lab.local;
 
    location / {
        try_files $uri $uri/ =404;
    }
}
```
 
```bash
sudo ln -s /etc/nginx/sites-available/demo.lab.local /etc/nginx/sites-enabled/
sudonginx -t
sudo systemctl reload nginx
```
 <img width="598" height="111" alt="image" src="https://github.com/user-attachments/assets/c6799ecd-e041-42c5-bba0-73a80397e81e" />

> Certbot dùng phương pháp xác minh **HTTP-01** : nó cần domain trỏ DNS đúng về server và port 80 phải mở để CA truy cập file thử thách. Domain `demo.lab.local` chỉ dùng được trong lab nội bộ vì không resolve được từ Internet thật — với domain thật, DNS A record phải trỏ đúng IP public trước khi chạy bước này.
 
### Bước 3 — Xin certificate qua Certbot
 
```bash
sudo certbot --nginx -d demo.lab.local
```
 
Certbot sẽ tự động:
1. Tạo CSR và private key (xem Phần 5.2)
2. Xác minh quyền sở hữu domain qua HTTP-01 challenge
3. Nhận certificate đã ký từ Let's Encrypt
4. **Tự sửa file cấu hình Nginx**, thêm `listen 443 ssl` và đường dẫn cert
5. Hỏi có muốn redirect HTTP → HTTPS tự động không (nên chọn Yes — liên quan Phần 7.1)
### Bước 4 — Kết quả file cấu hình sau khi Certbot chạy xong
 
```nginx
server {
    listen 443 ssl;
    server_name demo.lab.local;
    root /var/www/demo.lab.local;
 
    ssl_certificate     /etc/letsencrypt/live/demo.lab.local/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/demo.lab.local/privkey.pem;
 
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5:!3DES;
    ssl_prefer_server_ciphers on;
 
    location / {
        try_files $uri $uri/ =404;
    }
}
 
server {
    listen 80;
    server_name demo.lab.local;
    return 301 https://$host$request_uri;
}
```
 
> `fullchain.pem` mà Let's Encrypt tạo ra đã tự ghép sẵn website cert + Intermediate CA (R10/R11 — xem Phần 5.5), không cần tự ghép tay như khi mua cert từ CA thương mại trả về file rời.
 
### Bước 5 — Kiểm tra
 
```bash
sudo nginx -t
sudo systemctl reload nginx
 
# Kiểm tra chain và cert đang chạy
openssl s_client -connect demo.lab.local:443 -showcerts
 
curl -v https://demo.lab.local
```

 ---------
 
## 6.3 Cài Đặt SSL Trên IIS
### Bước 1 — Tạo CSR qua IIS Manager (thay cho `openssl req -new`)
 
```
1. Mở IIS Manager
2. Chọn Server node (cấp cao nhất, tên máy chủ)
3. Mục Features View → double-click "Server Certificates"
4. Panel bên phải → chọn "Create Certificate Request..."
5. Điền thông tin (tương đương Phần 5.2):
     Common Name:           demo.lab.local
     Organization:          Cong Ty ABC
     Organizational unit:   IT Department
     City/locality:         Ha Noi
     State/province:        Ha Noi
     Country/region:        VN
6. Cryptographic service provider: Microsoft RSA SChannel Cryptographic Provider
   Bit length: 2048
7. Lưu file CSR ra: C:\CertRequest\demo.lab.local.req
```
 
> File `.req` này tương đương file `.csr` tạo bằng `openssl req -new` — gửi file này cho CA (Sectigo/DigiCert) để xin ký.
 
### Bước 2 — Hoàn tất sau khi nhận Certificate từ CA
 
```
1. CA gửi về file certificate (.cer)
2. IIS Manager → Server Certificates → "Complete Certificate Request..."
3. Chọn file .cer nhận được từ CA
4. Đặt friendly name: demo.lab.local - 2026
5. Certificate tự động nạp vào Windows Certificate Store
   kèm theo private key đã tạo sẵn từ Bước 1 (IIS tự nối lại 2 phần)
```
 
> Nếu mua cert qua đại lý (như Nhân Hòa bán SSL Sectigo) và nhận thẳng về dạng PFX có sẵn key, có thể bỏ qua Bước 1–2, **import PFX trực tiếp**:
> ```
> IIS Manager → Server Certificates → "Import..."
> Chọn file .pfx → nhập Password bảo vệ PFX → Import
> ```
 
### Bước 3 — Bind Certificate vào Site (tương đương VirtualHost :443)
 
```
1. IIS Manager → chọn Site (ví dụ: Default Web Site)
2. Panel bên phải → "Bindings..."
3. Chọn "Add..."
4. Type: https
   IP address: All Unassigned (hoặc IP cụ thể)
   Port: 443
   Host name: demo.lab.local
   SSL certificate: chọn cert vừa tạo/import ở Bước 1-2
5. OK → Close
```
 
### Bước 4 — Kiểm tra
 
```powershell
# Kiểm tra binding đã có port 443
Get-WebBinding -Name "Default Web Site"
 
# Test bằng PowerShell
Invoke-WebRequest -Uri "https://demo.lab.local" -UseBasicParsing
```
 
```bash
# Kiểm tra từ máy khác bằng OpenSSL (tương tự Phần 5.4)
openssl s_client -connect demo.lab.local:443 -showcerts
```
 ----
 ## 6.4 Cài Đặt SSL Trên Tomcat

 Tomcat là application server viết bằng Java, nên cách quản lý certificate cũng theo hệ sinh thái Java: dùng **Keystore** — một file chứa cert và private key được bảo vệ bằng password, quản lý bằng công cụ `keytool` đi kèm JDK, không dùng OpenSSL trực tiếp như Apache/Nginx.  
 ### Bước 1 — Chuẩn bị certificate đã có (CA-signed hoặc Let's Encrypt)
 
Giả sử đã có sẵn 3 file từ các bước trước (Phần 5.2, 5.4):
 
```
demo_lab_local.crt        (website certificate)
demo_lab_local.key        (private key)
intermediate_ca.crt       (Intermediate CA, ghép chain — xem Phần 5.4)
```
 
### Bước 2 — Gộp thành PKCS12 keystore bằng OpenSSL
 
```bash
# Ghép cert + chain trước 
cat demo_lab_local.crt intermediate_ca.crt > fullchain.crt
 
# Export sang PKCS12, đặt password bảo vệ keystore
openssl pkcs12 -export \
    -in fullchain.crt \
    -inkey demo_lab_local.key \
    -out keystore.p12 \
    -name tomcat \
    -password pass:ChangeThisPassword123
```
 
> Tham số `-name tomcat` là **alias** — tên định danh cert bên trong keystore, Tomcat sẽ tham chiếu tới alias này trong `server.xml`.
 
### Bước 3 — Kiểm tra keystore bằng keytool (công cụ Java, tương đương `openssl x509 -text`)
 
```bash
keytool -list -v -keystore keystore.p12 -storetype PKCS12 -storepass ChangeThisPassword123
```
 
### Bước 4 — Copy keystore vào thư mục Tomcat
 
```bash
mkdir -p /opt/tomcat/conf/ssl
cp keystore.p12 /opt/tomcat/conf/ssl/
chown tomcat:tomcat /opt/tomcat/conf/ssl/keystore.p12
chmod 600 /opt/tomcat/conf/ssl/keystore.p12
```
 
### Bước 5 — Cấu hình Connector HTTPS trong server.xml
 
File: `/opt/tomcat/conf/server.xml`
 
```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true">
    <SSLHostConfig protocols="TLSv1.2,TLSv1.3"
                    ciphers="HIGH:!aNULL:!MD5:!3DES">
        <Certificate certificateKeystoreFile="conf/ssl/keystore.p12"
                     certificateKeystorePassword="ChangeThisPassword123"
                     certificateKeystoreType="PKCS12"
                     certificateKeyAlias="tomcat" />
    </SSLHostConfig>
</Connector>
```
 
> `protocols` và `ciphers` ở đây tương đương `SSLProtocol`/`SSLCipherSuite` của Apache (Phần 6.1) — chủ động loại bỏ TLS cũ và 3DES.
 
### Bước 6 — Restart Tomcat và kiểm tra
 
```bash
systemctl restart tomcat
 
# Kiểm tra cổng 8443 đang nghe
ss -tlnp | grep 8443
 
# Kiểm tra cert đang chạy
openssl s_client -connect demo.lab.local:8443 -showcerts
```

 ------------

 # 6.5 SSL Trên Hosting Panel
 
### Bối cảnh
 
Trên VPS/Dedicated Server quản trị thủ công, kỹ thuật viên tự thao tác `openssl`, sửa `server.xml`/`nginx.conf` như các phần trước. Trên môi trường **Shared Hosting**, khách hàng không có quyền root, toàn bộ việc cài SSL được trừu tượng hóa qua giao diện quản trị (control panel) — đây là lý do các hosting panel tồn tại: cho phép cấp SSL hàng loạt cho hàng trăm/nghìn tài khoản hosting mà không cần thao tác dòng lệnh.
 
### cPanel
 
#### AutoSSL
 
Là cơ chế tự động quét toàn bộ domain trên server, tự xin và cài certificate DV miễn phí (thường từc Let's Encrypt hoặc Sectigo DV tùy nhà cung cấp tích hợp), tự renew trước khi hết hạn — không cần thao tác gì từ khách hàng hoặc kỹ thuật viên.
 
```
WHM (quyền quản trị server) → SSL/TLS → Manage AutoSSL
  → Chọn Provider: Let's Encrypt (hoặc Sectigo AutoSSL)
  → Chọn domain cần áp dụng (All Users / Specific Users)
  → Run AutoSSL Now
```
 
#### SSL/TLS Manager (phía khách hàng cPanel)
 
Dùng khi khách hàng muốn cài certificate **mua riêng** (OV/EV từ Sectigo/DigiCert) thay vì dùng AutoSSL miễn phí:
 
```
cPanel (khách hàng) → SSL/TLS Status hoặc SSL/TLS Manager
  → Generate CSR (tương đương Phần 5.2, làm qua giao diện web)
  → Sau khi CA ký, vào "Manage SSL Sites"
  → Paste Certificate (CRT) + Private Key + CA Bundle (Intermediate)
  → Install Certificate
```
 
> "CA Bundle" trong cPanel chính là Intermediate CA certificate (Phần 5.4/5.5) — cPanel tự ghép vào chain khi cài.
 
### Plesk
 
#### SSL/TLS Certificates
 
Tương tự cPanel nhưng giao diện gọi là "SSL/TLS Certificates", nằm trong từng subscription (tài khoản hosting):
 
```
Plesk Panel → Domains → [chọn domain] → SSL/TLS Certificates
  → "Add SSL/TLS Certificate"
  → Cách 1: Upload certificate files (.crt, .key, CA certificate) đã mua từ CA khác
  → Cách 2: "Get free certificate from Let's Encrypt" (tích hợp sẵn, không cần Certbot)
```
 
#### Let's Encrypt Extension
 
Plesk tích hợp Let's Encrypt như một extension riêng, hỗ trợ luôn wildcard certificate (`*.domain.com` — Phần 6.6) và tự động gắn vào tất cả subdomain:
 
```
Domains → [domain] → Let's Encrypt
  ☑ Secure the domain
  ☑ Secure www.domain.com
  ☑ Include wildcard
  → Get it free
```
 
### DirectAdmin
 
#### Free Let's Encrypt
 
```
DirectAdmin User Panel → SSL Certificates
  → Free & automatic certificate from Let's Encrypt
  → Chọn domain → Save
```
 
#### CA Signed SSL Certificate
 
Dùng khi khách hàng có certificate mua riêng:
 
```
DirectAdmin User Panel → SSL Certificates
  → "Paste a pre-existing certificate and key"
  → Dán nội dung Certificate + Private Key + CA Bundle vào 3 ô tương ứng
  → Save
```
 
## So sánh ưu/nhược điểm
 
| Panel | Ưu điểm | Nhược điểm |
|---|---|---|
| **cPanel** | AutoSSL mạnh, tự renew toàn server không cần can thiệp | Chi phí license cao, phổ biến nên là mục tiêu tấn công nhiều |
| **Plesk** | Hỗ trợ wildcard Let's Encrypt tốt, giao diện hiện đại hơn | Thị phần nhỏ hơn cPanel, ít tài liệu cộng đồng |
| **DirectAdmin** | Nhẹ, license rẻ hơn, phù hợp VPS tài nguyên thấp | Giao diện ít trực quan, tính năng tự động hóa SSL kém linh hoạt hơn cPanel |
