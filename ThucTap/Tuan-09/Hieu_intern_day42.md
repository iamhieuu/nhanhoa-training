# Báo cáo thực tập - SSL Termination

## 1 — TỔNG QUAN SSL/TLS  
### 1.1 SSL là gì? TLS là gì?
SSL (Secure Sockets Layer) và TLS (Transport Layer Security) là các giao thức mật mã được thiết kế để cung cấp bảo mật giao tiếp qua mạng máy tính.  
Sự khác nhau giữa SSL và TLS: TLS thực chất là phiên bản nâng cấp, bảo mật hơn của SSL. SSL hiện tại đã "chết" và không còn được sử dụng vì có nhiều lỗ hổng. Tuy nhiên, do thói quen, ngành công nghiệp IT vẫn dùng từ "Chứng chỉ SSL" thay vì gọi đúng là "Chứng chỉ TLS".  
  *  SSL (Secure Sockets Layer) — Giao thức bảo mật ra đời năm 1995, hiện đã lỗi thời và không còn dùng
  *  TLS (Transport Layer Security) — Phiên bản nâng cấp của SSL, đang được dùng thực tế hiện nay

### 1.2 Lịch sử và các phiên bản
Timeline SSL/TLS:  

1995 ──► SSL 2.0    ❌ Deprecated — nhiều lỗ hổng nghiêm trọng  
1996 ──► SSL 3.0    ❌ Deprecated — lỗ hổng POODLE (2014)  
1999 ──► TLS 1.0    ❌ Deprecated từ 2020 — PCI DSS không cho dùng  
2006 ──► TLS 1.1    ❌ Deprecated từ 2020  
2008 ──► TLS 1.2    ✅ Vẫn dùng được — phổ biến nhất hiện nay  
2018 ──► TLS 1.3    ✅ Tốt nhất — nhanh hơn, bảo mật hơn, nên dùng  

#### SSL dùng để làm gì

| Dịch vụ | SSL dùng để làm gì | Công việc kỹ thuật |
|----------|----------|----------|
| Hosting Linux (Apache/Nginx) | Bảo vệ Website bằng HTTPS | Cài đặt Let's Encrypt hoặc SSL thương mại |
| Hosting Windows (IIS) | Mã hóa Website HTTPS | Import SSL vào IIS và Bind Port 443 |
| WordPress Hosting | Bảo vệ trang Web và Admin | Cấu hình HTTPS, Force Redirect HTTP → HTTPS |
| VPS Linux | Bảo mật Website và dịch vụ | Cài SSL cho Nginx, Apache, HAProxy |
| Cloud Server | Mã hóa các dịch vụ Public | Quản lý chứng chỉ SSL/TLS |
| Email Doanh Nghiệp Zimbra | Mã hóa gửi/nhận Email | Cài SSL cho SMTP, IMAP, POP3, Webmail |
| Email Doanh Nghiệp MDaemon | Bảo vệ Email Server | Import SSL Certificate cho Mail Service |
| Domain + SSL | Kích hoạt HTTPS cho tên miền khách hàng | CSR, Install SSL, Renew SSL |
| Website Doanh Nghiệp | Tránh cảnh báo "Not Secure" | Kiểm tra và gia hạn SSL định kỳ |
| HAProxy Load Balancer | SSL Termination | Cài SSL trên HAProxy thay vì Backend |
| Firewall pfSense | Xác thực VPN | Cấu hình Certificate cho OpenVPN |
| Monitoring (Grafana) | Bảo vệ Dashboard | Cấu hình HTTPS cho Grafana |
| DirectAdmin / cPanel / Plesk | Bảo vệ giao diện quản trị | Cài SSL cho Control Panel |
| Chuyển Website sang Server mới | Duy trì HTTPS | Backup và cài lại SSL Certificate |
| Khách hàng báo lỗi SSL | Khắc phục sự cố | Renew, Reissue hoặc sửa Cert Chain |

| Giao thức | Không có SSL | Có SSL | Port |
|-----------|-------------|---------|------|
| HTTP | Dữ liệu trần | HTTPS | 80 → 443 |
| SMTP | Mail không mã hóa | SMTPS | 25 → 465 |
| IMAP | Mail client không mã hóa | IMAPS | 143 → 993 |
| POP3 | Mail download không mã hóa | POP3S | 110 → 995 |
| FTP | File transfer không mã hóa | FTPS | 21 → 990 |  

### 1.4 Lợi ích của SSL

| Lợi ích | Ý nghĩa thực tế |
|----------|----------------|
| Mã hóa | Hacker nghe trộm chỉ thấy ký tự vô nghĩa |
| Xác thực | Đảm bảo bạn đang nói chuyện với server thật, không phải fake |
| Toàn vẹn dữ liệu | Phát hiện nếu dữ liệu bị sửa đổi trong quá trình truyền |
| SEO | Google ưu tiên website HTTPS trong kết quả tìm kiếm |
| Tin tưởng | User thấy ổ khóa xanh → tin tưởng nhập thông tin |
| Pháp lý | PCI DSS, GDPR yêu cầu mã hóa dữ liệu nhạy cảm |

---

## 2 - Cách thức hoạt động của SSL
### 2.1 Quy trình mã hóa và giải mã dữ liệu.
#### Mã hóa đối xứng (Symmetric)
```
Cùng 1 khóa để mã hóa và giải mã.
[Dữ liệu] ──Khóa A──► [Mã hóa] ──Khóa A──► [Dữ liệu]

Nhược điểm:
Khó chia sẻ khóa an toàn.
```
#### Mã hóa bất đối xứng (Asymmetric)
```
Dùng Public Key để mã hóa,
Private Key để giải mã.

[Dữ liệu] ──Public Key──► [Mã hóa] ──Private Key──► [Dữ liệu]

```
- Asymmetric để trao đổi khóa  
- Symmetric để truyền dữ liệu

### 2.2 TLS handshake
```
                    QUY TRÌNH SSL/TLS HANDSHAKE

┌─────────────────────┐                    ┌─────────────────────┐
│       CLIENT        │                    │       SERVER        │
│      (Browser)      │                    │    (Web Server)    │
└──────────┬──────────┘                    └──────────┬──────────┘
           │                                          │
           │ 1. ClientHello                           │
           │─────────────────────────────────────────►│
           │ TLS Version                              │
           │ Cipher Suites                            │
           │ Client Random                            │
           │                                          │
           │                                          │
           │ 2. ServerHello                           │
           │◄─────────────────────────────────────────│
           │ TLS Version được chọn                    │
           │ Cipher Suite được chọn                   │
           │ Server Random                            │
           │                                          │
           │                                          │
           │ 3. SSL Certificate                       │
           │◄─────────────────────────────────────────│
           │ Public Key                               │
           │ Thông tin Domain                         │
           │ Chữ ký của CA                            │
           │                                          │
           │                                          │
           │ 4. Certificate Validation                │
           │─────────────────────────────────────────►│
           │ Kiểm tra CA                              │
           │ Kiểm tra Domain                          │
           │ Kiểm tra Hạn sử dụng                     │
           │                                          │
           │                                          │
           │ 5. Key Exchange                          │
           │─────────────────────────────────────────►│
           │ Tạo và trao đổi Session Key             │
           │ (RSA / Diffie-Hellman)                  │
           │                                          │
           │◄─────────────────────────────────────────│
           │ Session Key đã được tạo                  │
           │                                          │
           │                                          │
           │ 6. Encrypted Communication               │
           │═════════════════════════════════════════►│
           │ HTTPS Data (AES Encryption)              │
           │◄═════════════════════════════════════════│
           │ HTTPS Data (AES Encryption)              │
           │                                          │
═══════════╧══════════════════════════════════════════╧═══════════
```

### 2.3 Public Key và Private Key
````
┌──────────────────────────────────────────────────────────┐
│                    CẶP KHÓA RSA                          │
│                                                          │
│  PUBLIC KEY                    PRIVATE KEY               │
│  ───────────                   ───────────               │
│  • Chia sẻ công khai           • Giữ bí mật tuyệt đối   │
│  • Ai cũng có thể dùng         • Chỉ chủ sở hữu có      │
│  • Dùng để MÃ HÓA              • Dùng để GIẢI MÃ         │
│  • Có trong Certificate        • Lưu trên server         │
│                                                          │
│  Nằm trong file: .crt / .pem   Nằm trong file: .key     │
└──────────────────────────────────────────────────────────┘
 ````
Ví dụ thực tế tại Nhân Hòa:  
/etc/ssl/certs/congty.vn.crt   ← Public key (gửi cho browser)  
/etc/ssl/private/congty.vn.key ← Private key (KHÔNG BAO GIỜ chia sẻ)   

**Nguyên tắc số 1**: Private key bị lộ = phải thu hồi cert ngay lập tức và reissue.  

## 3 - Chứng chỉ SSL (SSL Certificate)

### 3.1 Khái niệm và mục đích.  
chứng chỉ SSL như CMND/CCCD của một website. Nó chứng minh:  
* Website này thuộc về ai
* Ai đã cấp (CA nào)
* Còn hiệu lực đến khi nào

Chứng chỉ SSL gồm 5 phần cốt lõi:  
* Subject — chủ sở hữu cert: tên miền (CN), tổ chức (O), quốc gia (C).
* Issuer — CA ký và bảo lãnh cert đó: Let's Encrypt, Sectigo, DigiCert...
* Validity — thời hạn hiệu lực. Let's Encrypt = 90 ngày, cert thương mại = 1–2 năm.
* Public Key — khóa công khai dùng để mã hóa. Thường RSA 2048-bit hoặc ECDSA 256-bit.
* SAN — danh sách domain thực sự được bảo vệ. Cái này mới quan trọng — browser kiểm tra SAN, không kiểm tra CN nữa. Muốn bảo vệ cả congty.vn lẫn www.congty.vn thì cả hai phải có trong SAN.

### 3.2 Các loại chứng chỉ SSL
#### DV — Domain Validation (Xác thực tên miền)
##### Đặc điểm

- Mức độ xác thực: Thấp 
- Thời gian cấp: Vài phút  
- Chi phí: Miễn phí (Let's Encrypt) đến khoảng 10 USD/năm  
- Hiển thị: HTTPS và biểu tượng ổ khóa  
CA chỉ xác minh: Bạn có SỞ HỮU domain đó không?  
CA KHÔNG xác minh: Công ty có hợp pháp không? Có thật không?  

Phù hợp:  
- Blog cá nhân
- Landing Page
- Website SMB
- Website giới thiệu công ty

Không phù hợp:  
- Ngân hàng
- Thanh toán trực tuyến
- Hệ thống yêu cầu độ tin cậy cao

#### OV — Organization Validation (Xác thực tổ chức)
##### Đặc điểm

- Mức độ xác thực: Trung bình
- Thời gian cấp: 1 – 3 ngày
- Chi phí: 50 – 200 USD/năm
- Hiển thị: HTTPS, thông tin doanh nghiệp trong Certificate

CA xác minh thêm:  
- Công ty có đăng ký kinh doanh không?
- Địa chỉ công ty có thật không?
- Số điện thoại có xác minh được không?

Phù hợp  
- Website doanh nghiệp
- Cổng thông tin nội bộ
- Hệ thống B2B
- API cho đối tác

#### EV — Extended Validation (Xác thực mở rộng)
##### Đặc điểm

- Mức độ xác thực: Cao nhất
- Thời gian cấp: 1 – 2 tuần
- Chi phí: 100 – 500 USD/năm
- Hiển thị: HTTPS và thông tin doanh nghiệp trong chi tiết chứng chỉ

CA xác minh rất kỹ:    
- Giấy phép kinh doanh
- Lịch sử hoạt động doanh nghiệp
- Xác minh qua điện thoại bên thứ 3
- Kiểm tra WHOIS domain

Phù hợp:  
- Ngân hàng, tài chính
- Cổng thanh toán 
- Website chính phủ
- Bất kỳ nơi nào yêu cầu tin tưởng cao nhất

#### Wildcard SSL
Bảo vệ: *.congty.vn  
Nghĩa là bảo vệ TẤT CẢ subdomain cấp 1:  
- mail.congty.vn 
- shop.congty.vn 
- admin.congty.vn  
- api.congty.vn
 Không bảo vệ
- ub.mail.congty.vn (subdomain cấp 2 — không cover)    
Giá: $80–$300/năm  
Dùng khi: Nhiều subdomain, không muốn mua từng cert riêng 

#### SAN SSL (Subject Alternative Name / Multi-domain)
````
Bảo vệ nhiều domain KHÁC NHAU trong 1 cert:
  congty.vn
  congty.com
  shop.congty.vn
  api.partners.com

Dùng khi: Một công ty có nhiều domain cần bảo vệ
Tiết kiệm: Quản lý 1 cert thay vì nhiều cert
````
## So Sánh Self-Signed Certificate và CA-Signed Certificate

| Tiêu chí | Self-Signed Certificate | CA-Signed Certificate |
|-----------|------------------------|------------------------|
| Đơn vị ký chứng chỉ | Tự tạo và tự ký | Được ký bởi CA uy tín |
| Chi phí | Miễn phí | Miễn phí (Let's Encrypt) hoặc có phí |
| Mức độ tin cậy | Thấp | Cao |
| Trình duyệt tin tưởng | Không | Có |
| Cảnh báo trình duyệt | Hiển thị cảnh báo bảo mật | Không cảnh báo |
| Xác thực danh tính | Không | Có |
| Môi trường sử dụng | Lab, Test, Internal | Production |
| Độ phức tạp triển khai | Đơn giản | Cần xác thực với CA |

----

## 4. Các thuật toán mã hóa
### Thuật toán đối xứng (Dùng để mã hóa dữ liệu)

| Thuật toán | Loại khóa | Kích thước khối/khóa | Tình trạng | Dùng ở đâu |
|------------|------------|----------------------|------------|------------|
| AES (GCM) | Đối xứng | Khối 128-bit, khóa 128/256-bit | Khuyến nghị, chuẩn hiện tại | Server, Desktop, TLS 1.2/1.3 mặc định |
| 3DES | Đối xứng | Khối 64-bit, khóa 168-bit hiệu dụng | Lỗi thời, nên loại bỏ | Hệ thống Legacy còn tồn tại |
| ChaCha20-Poly1305 | Đối xứng | Stream Cipher, khóa 256-bit | Khuyến nghị cho Mobile | Mobile, CPU không hỗ trợ AES-NI |

#### Ghi nhớ

- AES-256-GCM là thuật toán phổ biến nhất hiện nay.
- ChaCha20-Poly1305 thường được ưu tiên trên thiết bị di động hoặc CPU không hỗ trợ AES-NI.
- 3DES và RC4 đã lỗi thời.

---


### Ghi nhớ

- RSA là thuật toán bất đối xứng phổ biến nhất.
- ECC cung cấp mức bảo mật tương đương RSA nhưng với khóa ngắn hơn.
- Ed25519 là xu hướng mới nhờ hiệu năng và độ an toàn cao.

## Thuật toán trao đổi khóa

| Thuật toán | Mô tả | Trạng thái |
|------------|--------|------------|
| ECDHE | Diffie-Hellman trên đường cong Elliptic | Khuyến nghị sử dụng |
| DHE | Diffie-Hellman truyền thống | Chấp nhận được |
| RSA Key Exchange | Client mã hóa Session Key bằng Public Key của Server | Không khuyến nghị |
| ECC | Thuật toán mật mã đường cong Elliptic | Xu hướng hiện đại |


## 5. Cấu Trúc Chứng Chỉ SSL
```
Subject (Chủ sở hữu):
  Common Name (CN): congty.vn
  Organization (O): Cong Ty ABC
  Country (C): VN

Issuer (Người cấp):
  Let's Encrypt Authority X3 / Sectigo / DigiCert

Validity Period (Hiệu lực):
  Not Before: 2026-01-01
  Not After:  2026-04-01 (Let's Encrypt = 90 ngày)

Public Key:  RSA 2048-bit
Signature Algorithm: SHA256withRSA

SAN (Subject Alternative Names):
  DNS: congty.vn
  DNS: www.congty.vn
```
Common Name (CN)  
Tên miền chính cert đại diện, ví dụ congty.vn. Trước đây browser chỉ nhìn CN để quyết định cert hợp lệ hay không, nhưng từ Chrome 58 (2017) trở đi, CN bị bỏ qua hoàn toàn — browser chỉ tin SAN. CN giờ chỉ còn mang tính tham khảo, không có giá trị xác thực kỹ thuật.
SAN  

Đây là phần quyết định cert bảo vệ domain nào trên thực tế. Một cert có thể chứa nhiều SAN:  
- DNS: congty.vn  
- DNS: www.congty.vn  
- DNS: mail.congty.vn  
- DNS: *.congty.vn 
Lỗi thường gặp khi đi support: khách báo "SSL lỗi" nhưng domain họ truy cập (shop.congty.vn) không nằm trong SAN dù domain chính (congty.vn) đã có cert.

Issuer    
CA (Certificate Authority) đã ký và bảo lãnh cho cert đó. Issuer + Subject tạo thành chuỗi tin cậy: Root CA → Intermediate CA → cert của bạn. Trình duyệt chỉ tin cert nếu lần ngược chuỗi này về được một Root CA đã có sẵn trong danh sách tin cậy của OS/browser.  

Validity Period  
Khoảng thời gian cert còn hiệu lực, gồm Not Before và Not After. Let's Encrypt cố ý rút ngắn xuống 90 ngày để buộc tự động hóa renew — giảm rủi ro cert hết hạn mà không ai để ý. Cert thương mại thường 1 năm, tối đa hiện tại theo quy định CA/Browser Forum.  

## 6. Các phương pháp xác minh chứng chỉ SSL

| Loại SSL | Xác minh gì | Thời gian cấp | Phù hợp |
|-----------|-------------|---------------|----------|
| DV (Domain Validation) | Quyền sở hữu Domain | Vài phút | Website cá nhân, Blog, Website thông thường |
| OV (Organization Validation) | Domain + Tổ chức tồn tại hợp pháp | 1 – 3 ngày | Website doanh nghiệp nhỏ và vừa |
| EV (Extended Validation) | Domain + Tổ chức + Xác minh pháp lý chuyên sâu | Vài ngày đến vài tuần | Thương mại điện tử, Ngân hàng, Tài chính |

## 7. Nhà cung cấp chứng chỉ

## 7.1 Certificate Authority (CA) là gì?

Certificate Authority (CA) là tổ chức cấp và xác thực chứng chỉ SSL/TLS.  

Vai trò của CA:  
- Xác minh danh tính chủ sở hữu Domain hoặc Doanh nghiệp.
- Ký số lên chứng chỉ SSL.
- Giúp trình duyệt xác định website đáng tin cậy.

Nếu không có CA:  
- Bất kỳ ai cũng có thể tạo chứng chỉ giả mạo.
- Trình duyệt không thể xác định website thật hay giả.

Khi có CA:  
- Trình duyệt tin tưởng các CA nằm trong Root Store.
- Chứng chỉ được CA ký sẽ được chấp nhận.
- Chứng chỉ không đáng tin cậy sẽ bị cảnh báo bảo mật.

---
## 7.2 So sánh các CA phổ biến

| CA | Loại chứng chỉ | Chi phí | Thời hạn | Phù hợp |
|-----|---------------|----------|----------|----------|
| Let's Encrypt | DV | Miễn phí | 90 ngày | Website thông thường, Hosting |
| ZeroSSL | DV | Miễn phí (giới hạn) | 90 ngày | Thay thế Let's Encrypt |
| Sectigo | DV, OV, EV, Wildcard | 10 – 500 USD | 1 – 2 năm | Doanh nghiệp |
| DigiCert | DV, OV, EV | 200 – 2000 USD | 1 – 2 năm | Enterprise, Ngân hàng |
| GlobalSign | DV, OV, EV | 150 – 1000 USD | 1 – 2 năm | Enterprise |
| Nhân Hòa SSL | DV, OV, Wildcard | Liên hệ | 1 – 2 năm | Khách hàng Nhân Hòa |


## 7.3 Let's Encrypt
### Ưu điểm
- Miễn phí hoàn toàn.
- Tự động cấp phát chứng chỉ.
- Hỗ trợ tự động gia hạn.
- Được hầu hết trình duyệt tin cậy.
### Quy trình hoạt động  
1. Cài đặt Certbot.   
2. Gửi yêu cầu cấp chứng chỉ tới Let's Encrypt.
3. Let's Encrypt gửi thử thách xác minh Domain.
4. Certbot thực hiện xác minh quyền sở hữu Domain.
5. Chứng chỉ được cấp và cài đặt tự động.

### Hạn chế
- Chỉ hỗ trợ chứng chỉ DV.
- Thời hạn chứng chỉ 90 ngày.
- Cần cấu hình tự động gia hạn.
- Có giới hạn số lượng chứng chỉ được cấp.
- Không phù hợp cho các hệ thống yêu cầu OV hoặc EV.

## 7.3 Các Phương Pháp Xác Minh Domain (ACME Challenge)

### HTTP-01 Challenge
- Let's Encrypt kiểm tra file xác thực trên Web Server.
- Yêu cầu Port 80 mở và Website Public.
Phù hợp:  
- Website thông thường
Không phù hợp:  
- Wildcard SSL
- Internal Server

---

### DNS-01 Challenge  
- Let's Encrypt kiểm tra TXT Record trong DNS.
Ví dụ: 
```
_acme-challenge.congty.vn TXT "TOKEN"
```
Phù hợp:
- Wildcard SSL
- Internal Server
- Server không có IP Public
---

### TLS-ALPN-01 Challenge
- Xác minh qua kết nối TLS trên Port 443.
- Dùng khi Port 80 bị chặn.
---

## 7.4 CAA Record

### Khái niệm
CAA (Certification Authority Authorization) là bản ghi DNS quy định CA nào được phép cấp SSL cho Domain.
### Ví dụ
```
congty.vn. CAA 0 issue "letsencrypt.org"
congty.vn. CAA 0 issue "sectigo.com"
```
### Lợi ích

- Ngăn cấp SSL trái phép.
- Tăng bảo mật Domain.
- Giảm nguy cơ giả mạo Website.

| Phương pháp | Ưu điểm | Nhược điểm |
|------------|----------|------------|
| HTTP-01 | Cấu hình đơn giản, Certbot hỗ trợ tốt, phổ biến nhất | Yêu cầu mở Port 80, không hỗ trợ Wildcard SSL |
| DNS-01 | Hỗ trợ Wildcard SSL, không cần Web Server, phù hợp Internal Server | Cấu hình DNS phức tạp hơn, cần chờ DNS cập nhật |
| TLS-ALPN-01 | Không cần Port 80, chỉ cần Port 443 | Ít được hỗ trợ hơn, cấu hình phức tạp hơn HTTP-01 |


