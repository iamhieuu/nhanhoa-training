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
 
MTA là thành phần trung tâm chịu trách nhiệm **gửi và nhận email giữa các server**. Nó hoạt động theo giao thức SMTP, nhận mail từ mail client, xếp hàng, phân giải DNS MX record của domain đích, và chuyển mail đi.
 
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
## 2. Logs & Giám Sát Hệ Thống
 
### 2.1 Vị trí file log theo từng thành phần
 
```
┌─────────────────────────────────────────────────────────────┐
│  HỆ ĐIỀU HÀNH / DISTRO    │  FILE LOG                       │
├─────────────────────────────────────────────────────────────┤
│  CentOS/RHEL/AlmaLinux     │  /var/log/maillog              │
│  Ubuntu/Debian             │  /var/log/mail.log( nếu có cấu hình)
│  Zimbra                    │  /var/log/zimbra.log           │
├─────────────────────────────────────────────────────────────┤
│  COMPONENT                 │  FILE LOG                      │
├────────────────────────────────────────────────────────────┤
│  Postfix                   │  /var/log/mail.log            │
│  Exim                      │  /var/log/exim4/mainlog       │
│  Dovecot (IMAP/POP3)       │  /var/log/dovecot.log         │
│                            │  /var/log/dovecot-info.log    │
│  Authentication            │  /var/log/auth.log            │
│  ClamAV                    │  /var/log/clamav/clamav.log   │
│  SpamAssassin/Amavis       │  /var/log/mail.log (inline)   │
│  Fail2ban                  │  /var/log/fail2ban.log        │
└────────────────────────────────────────────────────────────┘
```
 
### 2.2 Đọc và phân tích Postfix log
 
**Anatomy một dòng log Postfix:**
 
```
Nov 20 10:15:32 mail postfix/smtp[12345]: AB12CD34EF56: to=<user@gmail.com>, relay=gmail-smtp-in.l.google.com[142.250.1.26]:25, delay=2.1, delays=0.1/0/1.2/0.8, dsn=2.0.0, status=sent (250 2.0.0 OK)
 
Giải mã:
Nov 20 10:15:32    ← Timestamp
mail               ← Hostname server
postfix/smtp       ← Process (smtp = gửi đi; smtpd = nhận vào)
12345              ← Process ID
AB12CD34EF56       ← Queue ID (dùng để trace toàn bộ hành trình mail)
to=<user@gmail.com> ← Địa chỉ đích
relay=...          ← Server nhận mail đích
delay=2.1          ← Tổng thời gian xử lý (giây)
delays=0.1/0/1.2/0.8 ← Breakdown: queue/connect/transmission/data
status=sent        ← KẾT QUẢ: sent/deferred/bounced/rejected
```
 
**Các lệnh grep phổ biến cho Postfix log:**
 
```bash
# Trace một email theo Queue ID
QUEUEID="AB12CD34EF56"
grep "$QUEUEID" /var/log/mail.log
 
# Tìm mail từ một địa chỉ gửi
grep "from=<sender@domain.vn>" /var/log/mail.log | tail -20
 
# Tìm mail bị bounce (hoàn lại cho người gửi)
grep "status=bounced" /var/log/mail.log | tail -20
 
# Tìm mail bị defer (chưa gửi được, sẽ thử lại)
grep "status=deferred" /var/log/mail.log | tail -20
 
# Đếm số mail gửi ra theo từng giờ
awk '/status=sent/ {print substr($1,1,13)}' /var/log/mail.log | sort | uniq -c
 
# Tìm mail bị reject với lý do
grep "NOQUEUE: reject" /var/log/mail.log | tail -20
 
# Tìm mail từ một IP nguồn cụ thể
grep "client=\[203.0.113.5\]" /var/log/mail.log | tail -20
 
# Thống kê top sender gửi nhiều nhất (phát hiện spam account nội bộ)
grep "status=sent" /var/log/mail.log | \
    grep -oP "from=<\K[^>]+" | sort | uniq -c | sort -rn | head -20
 
# Thống kê top domain đích nhận nhiều mail nhất
grep "status=sent" /var/log/mail.log | \
    grep -oP "to=<\K[^>]+" | sed 's/.*@//' | sort | uniq -c | sort -rn | head -10
```
 
### 2.3 Đọc Dovecot log (IMAP/POP3)
 
```bash
# Xem tất cả login IMAP thành công hôm nay
grep "Login:" /var/log/dovecot.log | grep "$(date '+%b %e')" | tail -30
 
# Xem login thất bại (brute force detection)
grep "authentication failed" /var/log/dovecot.log | tail -20
 
# Xem chi tiết một user: login từ đâu, IMAP command gì
grep "user=<user@domain.vn>" /var/log/dovecot.log | tail -20
 
# Xem disconnect log (session duration, bytes transferred)
grep "Disconnected" /var/log/dovecot.log | tail -20
```
 
### 2.4 Đọc log file nén (zgrep)
 
Log thường được rotate hàng ngày và nén thành `.gz`. Dùng `zgrep` để tìm trong log nén mà không cần giải nén:
 
```bash
# Tìm trong log hôm qua (đã nén)
zgrep "AB12CD34EF56" /var/log/mail.log.1.gz
 
# Tìm trong nhiều file nén cùng lúc
zgrep "user@domain.vn" /var/log/mail.log*.gz
 
# Xem log nén
zcat /var/log/mail.log.2.gz | grep "status=bounced" | wc -l
```
 
### 2.5 Syslog tập trung — Graylog / ELK
 
Khi quản lý nhiều mail server cùng lúc, đọc log từng server thủ công là không thực tế. Giải pháp: tập trung log vào một hệ thống trung tâm.
 
**Cấu hình rsyslog gửi log về server tập trung:**
 
```bash
# File: /etc/rsyslog.d/forward-mail.conf
# Gửi tất cả mail log về Graylog/ELK server
mail.*    @@syslog-server.nhanhoa.vn:514    # @@ = TCP, @ = UDP
```
 
```bash
sudo systemctl restart rsyslog
```
 
**Truy vấn log trong Graylog/ELK:**
 
```
# Query Graylog — tìm bounce mail trong 24h qua
facility:mail AND message:"status=bounced" AND timestamp:[now-24h TO now]
 
# Query ELK (Kibana) — thống kê spam score phân phối
program:amavis AND spam_score:[* TO *]
```
 
### 2.6 pflogsumm — Báo cáo thống kê Postfix hàng ngày
 
```bash
# Cài pflogsumm
sudo apt install pflogsumm -y
 
# Tạo báo cáo từ log hôm nay
pflogsumm /var/log/mail.log
 
# Báo cáo top sender, top recipient, top bounce
pflogsumm -d today /var/log/mail.log --problems-first
 
# Gửi báo cáo qua email mỗi ngày (crontab)
echo "0 6 * * * /usr/sbin/pflogsumm /var/log/mail.log | mail -s 'Mail Report $(date +%F)' admin@domain.vn" | crontab -
```
 
---

## 3. Quản Lý Queue Mail
 
### 3.1 Kiểm tra queue — Postfix
 
```bash
# Xem toàn bộ queue (active + deferred)
postqueue -p
# Hoặc lệnh ngắn hơn
mailq
 
# Kết quả mẫu:
# -Queue ID-  --Size-- ----Arrival Time---- -Sender/Recipient-------
# AB12CD34EF56!    2481 Thu Nov 21 10:15:32  sender@domain.vn
#                                            recipient@gmail.com
# (deferred) ...
 
# Đếm số mail trong queue
postqueue -p | grep -c "^[A-Z0-9]"
 
# Xem chi tiết nội dung một message trong queue
postcat -qv AB12CD34EF56
```
 
### 3.2 Xử lý mail stuck trong queue
 
```bash
# Xóa một message cụ thể khỏi queue (không bounce, xóa thẳng)
postsuper -d AB12CD34EF56
 
# Xóa tất cả mail trong queue — CỰC KỲ THẬN TRỌNG
postsuper -d ALL
 
# Xóa chỉ mail trong deferred queue
postsuper -d ALL deferred
 
# Thử gửi lại tất cả mail đang defer ngay lập tức (không đợi retry timer)
postqueue -f
# Hoặc
postfix flush
 
# Chuyển mail từ deferred sang active (thử gửi lại một mail cụ thể)
postsuper -H AB12CD34EF56   # Hold
postsuper -R AB12CD34EF56   # Release (thử lại)
 
# Xóa mail đến một recipient cụ thể (ví dụ địa chỉ bounce)
postqueue -p | grep -B5 "badrecipient@spam.com" | grep "^[A-Z0-9]" | awk '{print $1}' | tr -d '*!' | \
    xargs -I{} postsuper -d {}
```
 
### 3.3 Kiểm tra queue — Exim
 
```bash
# Xem queue
exim -bp
 
# Đếm số mail trong queue
exim -bpc
 
# Xóa một message
exim -Mrm MESSAGE_ID
 
# Xóa tất cả — thận trọng
exiqgrep -i | xargs exim -Mrm
 
# Thử gửi lại ngay
exim -M MESSAGE_ID
```
 
### 3.4 Giám sát queue tự động
 
```bash
# Script cảnh báo khi queue > ngưỡng
cat > /usr/local/bin/check_mail_queue.sh << 'EOF'
#!/bin/bash
THRESHOLD=50
QUEUE_SIZE=$(postqueue -p | grep -c "^[A-Z0-9]" 2>/dev/null || echo 0)
 
if [ "$QUEUE_SIZE" -gt "$THRESHOLD" ]; then
    echo "CẢNH BÁO: Mail queue đang có $QUEUE_SIZE message (ngưỡng: $THRESHOLD)" | \
        mail -s "[ALERT] Mail Queue Cao - $(hostname)" admin@domain.vn
fi
EOF
chmod +x /usr/local/bin/check_mail_queue.sh
 
# Chạy mỗi 15 phút
echo "*/15 * * * * /usr/local/bin/check_mail_queue.sh" | crontab -
```
 
**Postfix Admin — Web UI quản lý domain và mailbox:**
 
```bash
# Cài Postfix Admin (web UI cho quản trị viên hosting)
sudo apt install postfixadmin -y
# Truy cập: http://mail.domain.vn/postfixadmin/setup.php
```
 
---
 
# PHẦN II — BẢO MẬT & AUDIT
 
---
 
## 4. Xác Thực & Chống Giả Mạo
 
### 4.1 SPF — Cách tạo, kiểm tra và debug
 
**Tạo SPF record:**
 
```
# Cú pháp đầy đủ:
domain.vn. TXT "v=spf1 [mechanisms] [qualifier]all"
 
# Các mechanism phổ biến:
ip4:203.0.113.10        ← IP cụ thể
ip4:203.0.113.0/24      ← Cả subnet
mx                       ← Tất cả IP trong MX record của domain
include:_spf.google.com  ← Bao gồm SPF của service khác (Google Workspace)
a                        ← IP trong A record của domain
 
# Qualifier cho "all":
+all    ← Pass tất cả (KHÔNG DÙNG - quá nguy hiểm)
~all    ← SoftFail (tag nhưng không reject - phù hợp khi mới triển khai)
-all    ← HardFail (reject hoàn toàn - dùng khi đã chắc chắn)
?all    ← Neutral (không có phán quyết)
 
# Ví dụ thực tế:
domain.vn. TXT "v=spf1 mx ip4:203.0.113.10 include:_spf.google.com ~all"
```
 
**Kiểm tra SPF:**
 
```bash
# Xem SPF record hiện tại
dig TXT domain.vn +short | grep spf
 
# Test SPF evaluation thủ công
sudo apt install libmail-spf-perl -y
spfquery --ip=203.0.113.10 --mailfrom=user@domain.vn --helo=mail.domain.vn
 
# Công cụ online: https://mxtoolbox.com/spf.aspx
```
 
**Debug SPF fail trong log:**
 
```bash
grep "SPF" /var/log/mail.log | grep -i "fail\|softfail\|permerror" | tail -20
 
# Các lỗi SPF phổ biến:
# "SPF PermError" → SPF record có lỗi cú pháp hoặc vượt quá 10 DNS lookups
# "SPF SoftFail"  → IP không trong danh sách, dùng ~all
# "SPF HardFail"  → IP không trong danh sách, dùng -all
```
 
### 4.2 DKIM — Cách tạo, kiểm tra và debug
 
**Cài và cấu hình OpenDKIM (với Postfix):**
 
```bash
sudo apt install opendkim opendkim-tools -y
 
# Tạo DKIM key pair (selector "mail", domain "domain.vn")
sudo mkdir -p /etc/opendkim/keys/domain.vn
sudo opendkim-genkey -s mail -d domain.vn -D /etc/opendkim/keys/domain.vn/
sudo chown -R opendkim:opendkim /etc/opendkim/
 
# Xem public key để publish lên DNS
cat /etc/opendkim/keys/domain.vn/mail.txt
# Nội dung này là DNS TXT record cần tạo tại:
# mail._domainkey.domain.vn  TXT  "v=DKIM1; k=rsa; p=MIGf..."
```
 
```bash
# File: /etc/opendkim.conf
sudo tee /etc/opendkim.conf << 'EOF'
Mode                    sv
Canonicalization        relaxed/simple
Domain                  domain.vn
Selector                mail
KeyFile                 /etc/opendkim/keys/domain.vn/mail.private
Socket                  unix:/var/spool/postfix/opendkim/opendkim.sock
LogWhy                  Yes
SyslogSuccess           Yes
AutoRestart             Yes
Background              Yes
EOF
 
# Kết nối Postfix với OpenDKIM
sudo mkdir -p /var/spool/postfix/opendkim
sudo chown opendkim:postfix /var/spool/postfix/opendkim
 
# Thêm vào /etc/postfix/main.cf
echo "milter_default_action = accept
milter_protocol = 6
smtpd_milters = unix:/var/spool/postfix/opendkim/opendkim.sock
non_smtpd_milters = \$smtpd_milters" | sudo tee -a /etc/postfix/main.cf
 
sudo systemctl restart opendkim postfix
```
 
**Kiểm tra DKIM:**
 
```bash
# Test key đã đăng ký đúng trên DNS chưa
sudo opendkim-testkey -d domain.vn -s mail -vvv
# Expected: "key OK"
 
# Xác nhận DKIM header trong mail nhận được
# Gửi mail test đến check-auth@verifier.port25.com hoặc mail-tester.com
 
# Debug trong log
grep "DKIM" /var/log/mail.log | tail -20
```
 
**Các lỗi DKIM thường gặp:**
 
```bash
# "key not found in DNS" → TXT record chưa publish hoặc sai selector
# "body hash did not verify" → Nội dung mail bị sửa sau khi ký
#   (thường do anti-spam pipeline hoặc disclaimer thêm vào sau khi ký)
# "signature has expired" → Clock server lệch > 5 phút
```
 
### 4.3 DMARC — Tạo, kiểm tra và debug
 
```bash
# Tạo DMARC record (bắt đầu với p=none để chỉ giám sát)
# _dmarc.domain.vn. TXT "v=DMARC1; p=none; rua=mailto:dmarc@domain.vn; fo=1"
 
# Các tham số quan trọng:
# p=none        → Chỉ giám sát, không chặn
# p=quarantine  → Đưa vào spam folder
# p=reject      → Từ chối hoàn toàn
# pct=50        → Áp dụng policy cho 50% mail (rollout dần)
# rua=          → Địa chỉ nhận Aggregate report (hàng ngày/tuần)
# ruf=          → Địa chỉ nhận Forensic report (từng mail fail)
# fo=1          → Gửi report khi SPF hoặc DKIM fail (bất kỳ một trong hai)
# fo=0          → Gửi report khi cả SPF và DKIM đều fail
 
# Kiểm tra DMARC record
dig TXT _dmarc.domain.vn +short
 
# Parse DMARC report nhận được (file XML)
sudo apt install opendmarc -y
# Hoặc dùng dịch vụ online: dmarcian.com, parsedmarc
```
 
### 4.4 SMTP AUTH — Xác thực người gửi
 
SMTP AUTH buộc người dùng phải cung cấp username/password trước khi server cho phép gửi mail ra ngoài — ngăn server trở thành **Open Relay** (ai cũng gửi được, sẽ bị blacklist ngay).
 
```bash
# Cấu hình trong /etc/postfix/main.cf
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
broken_sasl_auth_clients = yes
 
# Chỉ cho phép relay khi đã xác thực
smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination
 
# Bật submission port (587) với mandatory auth trong master.cf
# submission inet n - y - - smtpd
#   -o smtpd_sasl_auth_enable=yes
#   -o smtpd_tls_security_level=encrypt
```
 
**Test SMTP AUTH:**
 
```bash
# Test thủ công qua openssl (port 587 với STARTTLS)
openssl s_client -connect mail.domain.vn:587 -starttls smtp
# Sau khi kết nối, gõ:
# EHLO test
# AUTH LOGIN
# [nhập base64 của username]
# [nhập base64 của password]
 
# Mã hóa base64 nhanh
echo -n "user@domain.vn" | base64
echo -n "password" | base64
```
 
### 4.5 SASL — Giao thức hỗ trợ SMTP AUTH
 
**SASL (Simple Authentication and Security Layer)** là tầng trừu tượng hóa xác thực — nó cho phép Postfix (MTA) dùng Dovecot (MDA) làm backend xác thực, không cần tự quản lý password database riêng.
 
```
Mail Client ──SMTP AUTH──> Postfix
                               |
                               | SASL
                               v
                           Dovecot (xác thực thật)
                               |
                               v
                           PAM / Shadow / SQL database
```
 
```bash
# Cấu hình Dovecot làm SASL backend cho Postfix
# File: /etc/dovecot/conf.d/10-master.conf
# service auth {
#   unix_listener /var/spool/postfix/private/auth {
#     mode = 0660
#     user = postfix
#     group = postfix
#   }
# }
 
# Verify SASL đang hoạt động
testsaslauthd -u user@domain.vn -p password
```
 
---
