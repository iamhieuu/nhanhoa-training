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
