# Báo cáo thực tập ngày 48 - Mail server ( Lý thuyết )

---

## 1. Cấu Trúc và Thành Phần Của Một Email Server
```
NGƯỜI GỬI                                         NGƯỜI NHẬN
[Mail Client]                                     [Mail Client]
     |                                                  ^
     | SMTP (port 587/465)                              | IMAP/POP3 (port 993/995)
     v                                                  |
[MTA — Mail Transfer Agent]    SMTP         [MDA — Mail Delivery Agent]
 Postfix / Exim / Sendmail  ─────────────> Dovecot / Cyrus IMAP
     |                                          |
     | SMTP qua Internet                        | Lưu vào Maildir/mbox
     v                                          v
[MTA đích]  ──────────────────────────>  [Inbox người nhận]
     ^
     |
[Anti-Spam/AV pipeline]
 Amavis → SpamAssassin → ClamAV
```
### 1.2 MTA — Mail Transfer Agent
 
MTA là thành phần trung tâm chịu trách nhiệm **gửi và nhận email giữa các server**. Nó hoạt động theo giao thức SMTP (Simple Mail Transfer Protocol), nhận mail từ mail client (submission), xếp hàng, phân giải DNS MX record của domain đích, và chuyển mail đi.
 
| MTA | Đặc điểm | Phù hợp |
|---|---|---|
| **Postfix** | Bảo mật, hiệu năng cao, cấu hình rõ ràng, tài liệu tốt | Production Linux phổ biến nhất hiện tại |
| **Exim** | Cấu hình linh hoạt, phức tạp hơn Postfix | cPanel (mặc định), hosting lớn |
| **Sendmail** | Cũ, phức tạp, ít dùng mới | Hệ thống legacy |
| **qmail** | Kiến trúc module, bảo mật tốt, ít được cập nhật | Một số hệ thống cũ |
| **Zimbra MTA** | Postfix + Amavis đã tích hợp sẵn | Doanh nghiệp dùng Zimbra |
 
**Các file cấu hình Postfix quan trọng:**
 
```
/etc/postfix/main.cf          ← Cấu hình chính
/etc/postfix/master.cf        ← Cấu hình các process daemon
/etc/postfix/transport        ← Routing table (domain → server)
/etc/postfix/virtual          ← Virtual mailbox/alias mapping
/etc/postfix/access           ← Access control (whitelist/blacklist)
/var/spool/postfix/           ← Mail queue directory
```
 
**Xem cấu hình Postfix hiện tại:**
 
```bash
postconf -n                   # Chỉ hiện các tham số đã được override
postconf maillog_file         # Xem một tham số cụ thể
postfix check                 # Kiểm tra config file có lỗi không
```
 
### 1.3 MDA — Mail Delivery Agent
 
MDA nhận mail từ MTA và **lưu vào mailbox của từng user**, đồng thời phục vụ mail client truy xuất qua IMAP/POP3.
 
| MDA | Giao thức | Đặc điểm |
|---|---|---|
| **Dovecot** | IMAP, POP3, LMTP | Phổ biến nhất, bảo mật, hiệu năng tốt, dễ cấu hình |
| **Cyrus IMAP** | IMAP, POP3, LMTP | Mạnh, phức tạp hơn, dùng cho hệ thống lớn |
 
**Định dạng lưu trữ mailbox:**
 
```
Maildir (khuyến nghị):
/var/mail/domain.vn/user/
├── cur/    ← Mail đã đọc
├── new/    ← Mail chưa đọc
└── tmp/    ← Mail đang xử lý
Ưu điểm: mỗi mail = 1 file → an toàn khi crash, dễ backup từng mail
 
mbox (cũ):
/var/mail/username  ← Tất cả mail trong 1 file lớn
Nhược điểm: file lớn, dễ corrupt, performance kém khi mailbox nhiều mail
```
 
**File cấu hình Dovecot:**
 
```
/etc/dovecot/dovecot.conf          ← Entry point, include các file con
/etc/dovecot/conf.d/10-auth.conf   ← Cấu hình authentication
/etc/dovecot/conf.d/10-mail.conf   ← Mailbox location, format
/etc/dovecot/conf.d/10-ssl.conf    ← TLS certificate
/etc/dovecot/conf.d/20-imap.conf   ← IMAP settings
/etc/dovecot/conf.d/90-quota.conf  ← Quota plugin
```
 
**Kiểm tra Dovecot:**
 
```bash
dovecot -n                         # Xem cấu hình đang active
doveadm who                        # Ai đang đăng nhập qua IMAP
doveadm user user@domain.vn        # Thông tin user cụ thể
doveadm mailbox list -u user@domain.vn  # Liệt kê mailbox của user
```
 
### 1.4 Webmail
 
Webmail cho phép người dùng truy cập email qua trình duyệt mà không cần cài mail client.
 
| Webmail | Đặc điểm | Phù hợp |
|---|---|---|
| **Roundcube** | Giao diện hiện đại, plugin phong phú, mã nguồn mở | Phổ biến nhất, dùng cho hosting panel |
| **Horde** | Groupware đầy đủ (mail + calendar + contact) | Doanh nghiệp cần groupware |
| **Zimbra Webmail** | Tích hợp sâu với Zimbra Server | Hệ thống dùng Zimbra |
 
**Cài Roundcube trên Ubuntu:**
 
```bash
sudo apt update
sudo apt install roundcube roundcube-mysql -y
 
# Cấu hình kết nối IMAP
sudo nano /etc/roundcube/config.inc.php
```
 
```php
// File: /etc/roundcube/config.inc.php
$config['imap_host'] = 'ssl://mail.domain.vn:993';
$config['smtp_host'] = 'tls://mail.domain.vn:587';
$config['smtp_port'] = 587;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['product_name'] = 'Webmail Nhan Hoa';
$config['default_host'] = 'ssl://mail.domain.vn';
```
 
### 1.5 Anti-Spam / Anti-Virus Pipeline
 
```
SMTP nhận mail
      |
      v
Postfix nhận, chuyển sang Amavis (:10024)
      |
      v
Amavis điều phối:
  ├── SpamAssassin: chấm điểm spam (score 0-100)
  │     - Nếu score > threshold → tag header hoặc reject
  ├── ClamAV: quét virus, malware trong attachment
  │     - Nếu phát hiện → quarantine/reject
  └── Kết quả clean → trả lại Postfix (:10025)
      |
      v
Postfix delivery vào MDA (Dovecot)
```
 
**SpamAssassin scoring:**
 
```
Score 0-3.9:   Không phải spam
Score 4.0-6.9: Có thể là spam → tag header [SPAM]
Score 7.0+:    Spam rõ ràng → reject hoặc discard
```
 
**ClamAV management:**
 
```bash
# Cập nhật virus database
sudo freshclam
 
# Quét thư mục
sudo clamscan -r /var/mail/ --infected --remove
 
# Xem version và database
clamscan --version
```
 
### 1.6 DNS Records Liên Quan Đến Email Server
 
| Record | Cú pháp | Mục đích |
|---|---|---|
| **MX** | `domain.vn. MX 10 mail.domain.vn.` | Server nào nhận mail cho domain |
| **A/AAAA** | `mail.domain.vn. A 203.0.113.10` | IP của mail server |
| **PTR** | `10.113.0.203.in-addr.arpa. PTR mail.domain.vn.` | Reverse DNS — bắt buộc để không bị spam |
| **SPF** | `domain.vn. TXT "v=spf1 mx ip4:203.0.113.10 ~all"` | Xác nhận IP được phép gửi mail |
| **DKIM** | `mail._domainkey.domain.vn. TXT "v=DKIM1; k=rsa; p=..."` | Chữ ký số xác thực nội dung |
| **DMARC** | `_dmarc.domain.vn. TXT "v=DMARC1; p=quarantine; rua=..."` | Policy xử lý mail fail SPF/DKIM |
| **SRV** | `_imaps._tcp.domain.vn. SRV 0 1 993 mail.domain.vn.` | Autodiscovery IMAP/SMTP cho mail client |
 
> **[QUAN TRỌNG] PTR Record:** Đây là record dễ bị bỏ quên nhất nhưng lại là bước đầu tiên mà Gmail, Outlook kiểm tra khi nhận mail. PTR phải trỏ về đúng hostname của mail server (`mail.domain.vn`), và hostname đó phải trỏ ngược lại về đúng IP qua A record. Thiếu hoặc sai PTR → mail bị spam ngay lập tức, không cần phân tích thêm. Với VPS Nhân Hòa, liên hệ đội kỹ thuật để đặt PTR record trên IP.
 
```bash
# Kiểm tra PTR record của IP mail server
dig -x 203.0.113.10 +short
# Expected: mail.domain.vn.
 
# Kiểm tra toàn bộ DNS email setup nhanh
dig domain.vn MX +short
dig domain.vn TXT +short
dig mail._domainkey.domain.vn TXT +short
dig _dmarc.domain.vn TXT +short
```
 
---
