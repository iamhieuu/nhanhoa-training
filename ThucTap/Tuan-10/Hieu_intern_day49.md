## 5. Mã Hóa TLS/SSL
 
### 5.1 Cấu hình TLS cho Postfix
 
```bash
# File: /etc/postfix/main.cf
 
# TLS cho SMTP outbound (gửi mail ra ngoài)
smtp_tls_security_level = may          # Thử TLS, fallback nếu không được
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_scache
smtp_tls_loglevel = 1                  # Log TLS handshake info
 
# TLS cho SMTP inbound (nhận mail từ ngoài)
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.domain.vn/fullchain.pem
smtpd_tls_key_file  = /etc/letsencrypt/live/mail.domain.vn/privkey.pem
smtpd_tls_security_level = may        # Cung cấp TLS, không bắt buộc
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1  # Chỉ TLS 1.2+
smtpd_tls_session_cache_database = btree:/var/lib/postfix/smtpd_scache
smtpd_tls_loglevel = 1
 
# Submission port (587) — STARTTLS bắt buộc
# (Cấu hình trong master.cf)
```
 
```bash
# Cấu hình TLS cho Dovecot
# File: /etc/dovecot/conf.d/10-ssl.conf
# ssl = required
# ssl_cert = </etc/letsencrypt/live/mail.domain.vn/fullchain.pem
# ssl_key  = </etc/letsencrypt/live/mail.domain.vn/privkey.pem
# ssl_min_protocol = TLSv1.2
# ssl_prefer_server_ciphers = yes
```
 
### 5.2 Kiểm tra TLS bằng openssl s_client
 
```bash
# Kiểm tra SMTPS (port 465 - implicit TLS)
openssl s_client -connect mail.domain.vn:465
 
# Kiểm tra SMTP + STARTTLS (port 587)
openssl s_client -connect mail.domain.vn:587 -starttls smtp
 
# Kiểm tra IMAPS (port 993)
openssl s_client -connect mail.domain.vn:993
 
# Kiểm tra POP3S (port 995)
openssl s_client -connect mail.domain.vn:995
 
# Xem chi tiết certificate trong kết nối
openssl s_client -connect mail.domain.vn:993 -showcerts < /dev/null 2>/dev/null | \
    openssl x509 -noout -subject -issuer -dates
 
# Kiểm tra toàn diện với testssl.sh
bash testssl.sh mail.domain.vn:443
bash testssl.sh --starttls smtp mail.domain.vn:587
```
 
**Đọc kết quả openssl s_client:**
 
```
Kết nối thành công sẽ hiện:
  Protocol  : TLSv1.3          ← Protocol version
  Cipher    : TLS_AES_256_GCM_SHA384  ← Cipher suite đang dùng
  Server certificate:
    subject= /CN=mail.domain.vn
    notAfter=Apr 01 2026...   ← Ngày hết hạn cert
 
Kết nối lỗi thường hiện:
  SSL routines:CONNECT_CR_CERT:certificate verify failed
  → Certificate không hợp lệ hoặc chain thiếu
```
 
---
 
## 6. Audit & Theo Dõi Hoạt Động
 
### 6.1 Theo dõi đăng nhập (ai, từ đâu, khi nào)
 
```bash
# Xem tất cả login IMAP thành công với IP nguồn
grep "Login:" /var/log/dovecot.log | awk '{print $1,$2,$3,$8,$9}' | tail -30
 
# Format output: timestamp | user | IP nguồn
grep "Login:" /var/log/dovecot.log | \
    grep -oP "user=<\K[^>]+|rip=\K[\d\.]+" | \
    paste - - | \
    awk '{print strftime("%Y-%m-%d %H:%M"), $0}'
 
# Top IP đăng nhập nhiều nhất (phát hiện anomaly)
grep "Login:" /var/log/dovecot.log | \
    grep -oP "rip=\K[\d\.]+" | \
    sort | uniq -c | sort -rn | head -10
 
# Xem login từ một IP cụ thể
grep "rip=203.0.113.100" /var/log/dovecot.log | tail -20
```
 
### 6.2 Phát hiện tài khoản gửi spam (abuse detection)
 
```bash
# Top 20 sender nội bộ gửi nhiều mail nhất trong 24h
grep "$(date '+%b %e')" /var/log/mail.log | \
    grep "status=sent" | \
    grep -oP "from=<\K[^>]+" | \
    sort | uniq -c | sort -rn | head -20
 
# Cảnh báo nếu một account gửi > 100 mail/giờ
cat > /usr/local/bin/detect_spam_sender.sh << 'EOF'
#!/bin/bash
THRESHOLD=100
LOG_FILE="/var/log/mail.log"
ONE_HOUR_AGO=$(date -d '1 hour ago' '+%b %e %H')
 
grep "$ONE_HOUR_AGO" "$LOG_FILE" | \
    grep "status=sent" | \
    grep -oP "from=<\K[^>]+" | \
    sort | uniq -c | sort -rn | \
    while read count sender; do
        if [ "$count" -gt "$THRESHOLD" ]; then
            echo "SPAM ALERT: $sender gửi $count mail trong 1 giờ qua" | \
                mail -s "[SPAM ALERT] $sender" admin@domain.vn
        fi
    done
EOF
chmod +x /usr/local/bin/detect_spam_sender.sh
echo "0 * * * * /usr/local/bin/detect_spam_sender.sh" | crontab -
```
 
### 6.3 Tích hợp Fail2ban chống brute force
 
```bash
sudo apt install fail2ban -y
 
# Filter cho Postfix SMTP auth
sudo tee /etc/fail2ban/filter.d/postfix-sasl.conf << 'EOF'
[Definition]
failregex = warning: [\w\.\-]+\[<HOST>\]: SASL (PLAIN|LOGIN) authentication failed
ignoreregex =
EOF
 
# Filter cho Dovecot
sudo tee /etc/fail2ban/filter.d/dovecot-auth.conf << 'EOF'
[Definition]
failregex = (?: pam_unix\(dovecot:auth\):.*authentication failure.*rhost=<HOST>
              | authentication failed;.*rip=<HOST>)
ignoreregex =
EOF
 
# Jail configuration
sudo tee /etc/fail2ban/jail.d/mail-server.conf << 'EOF'
[postfix-sasl]
enabled  = true
filter   = postfix-sasl
logpath  = /var/log/mail.log
maxretry = 5
findtime = 300
bantime  = 3600
 
[dovecot-auth]
enabled  = true
filter   = dovecot-auth
logpath  = /var/log/dovecot.log
maxretry = 5
findtime = 300
bantime  = 3600
EOF
 
sudo systemctl restart fail2ban
 
# Xem trạng thái và IP đang bị ban
sudo fail2ban-client status postfix-sasl
sudo fail2ban-client status dovecot-auth
 
# Unban một IP cụ thể
sudo fail2ban-client set postfix-sasl unbanip 203.0.113.100
```
 
### 6.4 Alert qua Grafana/Zabbix
 
Tích hợp với hệ thống monitoring (đã trình bày trong Chương 5 Zimbra và Chương 8 Monitoring) — các metrics quan trọng cần alert:
 
```yaml
# Alert rules gợi ý cho email server
- alert: PostfixQueueHigh
  condition: mail_queue_count > 100
  severity: warning
 
- alert: PostfixQueueDeferred
  condition: mail_queue_deferred > 50
  severity: warning
 
- alert: IMAPLoginFailHigh
  condition: imap_login_fail_per_min > 20
  severity: critical   # Khả năng brute force đang diễn ra
 
- alert: DiskMailSpaceLow
  condition: disk_free_pct{mount="/var/mail"} < 15
  severity: critical   # Sắp đầy disk → mail bị reject
```
 
---
 
# PHẦN III — TÍCH HỢP & HƯỚNG DẪN NGƯỜI DÙNG
 
---
 
## 7. Cài Đặt Email Trên Ứng Dụng 3rd-Party
 
### 7.1 Bảng thông số port chuẩn
 
```
┌──────────────────────────────────────────────────────────────┐
│  GIAO THỨC      │  PORT │  SECURITY      │ DÙNG KHI NÀO      │
├──────────────────────────────────────────────────────────────┤
│  SMTP (gửi)     │   25  │  Plain/TLS     │  Server-to-server  │
│  SMTP Submit    │  587  │  STARTTLS      │  Mail client gửi   │
│  SMTPS          │  465  │  SSL/TLS       │  Mail client gửi   │
├──────────────────────────────────────────────────────────────┤
│  IMAP           │  143  │  STARTTLS      │  Đọc mail (sync)   │
│  IMAPS          │  993  │  SSL/TLS       │  Đọc mail (sync)   │
├──────────────────────────────────────────────────────────────┤
│  POP3           │  110  │  STARTTLS      │  Tải mail về        │
│  POP3S          │  995  │  SSL/TLS       │  Tải mail về        │
└──────────────────────────────────────────────────────────────┘
 
Khuyến nghị: IMAPS (993) + SMTPS (465) hoặc SMTP (587) + STARTTLS
             Không dùng plain text (143, 110, 587 không có TLS)
```
 
### 7.2 Cấu hình Outlook
 
```
File → Add Account → Nhập email → Advanced options → Let me set up manually
 
IMAP:
  Incoming server:  mail.domain.vn
  Port:             993
  Encryption:       SSL/TLS
 
SMTP:
  Outgoing server:  mail.domain.vn
  Port:             587 (hoặc 465)
  Encryption:       STARTTLS (hoặc SSL/TLS nếu port 465)
  Authentication:   Yes — dùng username/password email
 
Username: user@domain.vn (địa chỉ email đầy đủ, không phải chỉ tên)
Password: [mật khẩu email]
```
 
### 7.3 Cấu hình Thunderbird
 
```
Thunderbird → Account Settings → Add Mail Account
 
Nhập: Tên, Email, Password → Continue
 
Nếu Thunderbird tự detect sai, chọn "Manual Config":
 
  Incoming: IMAP | mail.domain.vn | 993 | SSL/TLS | Normal password
  Outgoing: SMTP | mail.domain.vn | 587 | STARTTLS | Normal password
  Username: user@domain.vn
```
 
### 7.4 Cấu hình Apple Mail (macOS/iOS)
 
```
macOS: System Preferences → Internet Accounts → Add Other Account → Mail
 
Nhập email + password → Manual setup nếu cần:
  IMAP: mail.domain.vn:993 (SSL)
  SMTP: mail.domain.vn:587 (STARTTLS) hoặc 465 (SSL)
 
iOS: Settings → Mail → Add Account → Other → Add Mail Account
  Nhập tên, email, password, description
  IMAP Host: mail.domain.vn | SSL | Port 993
  SMTP Host: mail.domain.vn | SSL | Port 465
```
 
### 7.5 Cấu hình Android
 
```
Email app hoặc Gmail app:
  Add Account → Other → Manual setup → IMAP
 
  IMAP:
    Server:   mail.domain.vn
    Port:     993
    Security: SSL/TLS
    Username: user@domain.vn
    Password: [password]
 
  SMTP:
    Server:   mail.domain.vn
    Port:     587 hoặc 465
    Security: STARTTLS / SSL
    Authentication required: Yes
    Username: user@domain.vn
```
 
### 7.6 Tự động cấu hình — Autodiscover và autoconfig
 
Thay vì hướng dẫn từng bước thủ công, mail server có thể cấu hình để **mail client tự detect thông số** khi người dùng chỉ nhập địa chỉ email.
 
**autoconfig.xml (cho Mozilla Thunderbird, Android):**
 
```bash
# Tạo file tại: http://autoconfig.domain.vn/mail/config-v1.1.xml
# Hoặc: http://domain.vn/.well-known/autoconfig/mail/config-v1.1.xml
 
sudo mkdir -p /var/www/html/autoconfig/mail
sudo tee /var/www/html/autoconfig/mail/config-v1.1.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="domain.vn">
    <domain>domain.vn</domain>
    <displayName>Mail Cong Ty</displayName>
    <displayShortName>CongTy</displayShortName>
 
    <incomingServer type="imap">
      <hostname>mail.domain.vn</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
 
    <outgoingServer type="smtp">
      <hostname>mail.domain.vn</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>
EOF
```
 
**Autodiscover (cho Outlook/Exchange protocol):**
 
```bash
# File: https://autodiscover.domain.vn/autodiscover/autodiscover.xml
# Hoặc: https://domain.vn/autodiscover/autodiscover.xml
 
sudo mkdir -p /var/www/html/autodiscover
sudo tee /var/www/html/autodiscover/autodiscover.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>IMAP</Type>
        <Server>mail.domain.vn</Server>
        <Port>993</Port>
        <SSL>on</SSL>
        <LoginName/>
      </Protocol>
      <Protocol>
        <Type>SMTP</Type>
        <Server>mail.domain.vn</Server>
        <Port>587</Port>
        <SSL>STARTTLS</SSL>
        <LoginName/>
      </Protocol>
    </Account>
  </Response>
</Autodiscover>
EOF
```
 
```bash
# Thêm DNS SRV record để Thunderbird tự tìm autoconfig
# _imap._tcp.domain.vn.     SRV 0 1 993 mail.domain.vn.
# _imaps._tcp.domain.vn.    SRV 0 1 993 mail.domain.vn.
# _submission._tcp.domain.vn. SRV 0 1 587 mail.domain.vn.
# _autodiscover._tcp.domain.vn. SRV 0 1 443 autodiscover.domain.vn.
```
 
---
 
## 8. Hướng Dẫn Sử Dụng Cho Người Dùng Cuối
 
### 8.1 Tạo chữ ký email
 
**Trong Webmail Roundcube:**
 
```
Settings → Identities → [chọn email] → Signature
 
Ví dụ chữ ký HTML:
<div style="font-family:Arial;font-size:13px;color:#333">
  <b>Nguyễn Văn A</b><br>
  Chức vụ: Trưởng phòng Kinh doanh<br>
  📞 0901 234 567<br>
  🌐 <a href="https://congty.vn">congty.vn</a>
</div>
 
Bật: ☑ HTML Signature
Chọn: Insert signature: before the replied message
```
 
### 8.2 Lọc thư (Filter/Rules)
 
**Trong Roundcube:**
 
```
Settings → Filters → Add Filter
 
Ví dụ — Chuyển newsletter vào folder riêng:
  Filter name: Newsletter
  For incoming messages
    ALL of the following rules apply:
    Subject contains "Newsletter" OR "Unsubscribe"
  Execute the following actions:
    Move to folder: Newsletter (tạo folder này trước)
    ☑ Stop evaluating subsequent rules
 
Ví dụ — Xóa tự động mail quảng cáo từ domain cụ thể:
  Sender (From) contains: @spam-domain.com
  Action: Delete
```
 
### 8.3 Forward email
 
**Trong Roundcube:**
 
```
Settings → Identities → Forwarding (nếu server hỗ trợ)
Hoặc:
Settings → Filters → Add Filter
  Action: Redirect to [email-khac@gmail.com]
  ☑ Keep a copy: Yes (giữ bản gốc trong mailbox)
```
 
**Qua admin (Zimbra, Postfix):**
 
```bash
# Zimbra
zmprov modifyAccount user@domain.vn zimbraPrefMailForwardingAddress forward@gmail.com
 
# Postfix virtual alias
echo "user@domain.vn    user@domain.vn, forward@gmail.com" >> /etc/postfix/virtual
postmap /etc/postfix/virtual
postfix reload
```
 
### 8.4 Out-of-Office (Vacation Reply)
 
**Trong Roundcube:**
 
```
Settings → Vacation/Autoresponder (nếu có plugin)
 
Subject: Tôi đang vắng mặt
Message:
  Kính chào,
  Tôi hiện đang vắng mặt từ [ngày] đến [ngày].
  Trong trường hợp khẩn cấp, vui lòng liên hệ: colleague@domain.vn
  Trân trọng, Nguyễn Văn A
 
Active period: [ngày bắt đầu] → [ngày kết thúc]
```
 
**Qua server (Dovecot + Sieve):**
 
```bash
# Cài Sieve plugin
sudo apt install dovecot-sieve dovecot-managesieved -y
 
# Script Sieve cho vacation
cat > /home/user/vacation.sieve << 'EOF'
require ["vacation"];
 
vacation
  :days 1
  :subject "Tự động trả lời: Tôi đang vắng mặt"
  :from "user@domain.vn"
  "Kính chào, tôi đang vắng mặt và sẽ trả lời sau khi quay trở lại.";
EOF
```
 
### 8.5 Giải thích quota mailbox cho người dùng
 
```
Khi nhận được cảnh báo "Mailbox của bạn gần đầy":
 
1. Xóa mail không cần thiết:
   - Kiểm tra Sent Items — thường chứa nhiều file đính kèm lớn
   - Dọn Trash và Junk/Spam folder
   - Xóa mail cũ có file đính kèm nặng
 
2. Lưu file đính kèm quan trọng ra ngoài trước khi xóa mail
 
3. Nếu cần dung lượng nhiều hơn:
   - Liên hệ quản trị viên để nâng quota
   - Quota mặc định: 1 GB — nâng cấp lên 2 GB, 5 GB tùy nhu cầu
 
4. Xem quota hiện tại:
   - Roundcube: góc dưới trái hiện bar dung lượng
   - Thunderbird: không hiện trực tiếp, dùng webmail để xem
```
 
---
 
## 9. Các Dịch Vụ Bổ Trợ
 
### 9.1 Webmail — Roundcube và RainLoop
 
**Roundcube** (đã trình bày ở mục 1.4) — phổ biến, đầy đủ tính năng với hệ sinh thái plugin.
 
**RainLoop (SnappyMail):**
 
```bash
# Cài SnappyMail (fork hiện đại của RainLoop)
cd /var/www/html
wget https://github.com/the-djmaze/snappymail/releases/latest/download/snappymail.tar.gz
tar xzf snappymail.tar.gz -C webmail/
 
# Phân quyền
sudo chown -R www-data:www-data /var/www/html/webmail
 
# Truy cập admin: https://mail.domain.vn/webmail/?admin
```
 
### 9.2 Calendar (CalDAV) và Danh Bạ (CardDAV)
 
**Radicale** — CalDAV/CardDAV server nhẹ, đơn giản:
 
```bash
sudo pip3 install radicale --break-system-packages
 
sudo tee /etc/radicale/config << 'EOF'
[server]
hosts = 0.0.0.0:5232
 
[auth]
type = htpasswd
htpasswd_filename = /etc/radicale/users
htpasswd_encryption = bcrypt
 
[storage]
filesystem_folder = /var/lib/radicale/collections
EOF
 
# Tạo user
sudo htpasswd -B -c /etc/radicale/users user@domain.vn
 
sudo systemctl enable --now radicale
```
 
**Kết nối từ Thunderbird (Calendar):**
 
```
Thunderbird → Calendar → New Calendar → On the Network
  Protocol: CalDAV
  Location: https://mail.domain.vn:5232/user@domain.vn/calendar/
  Username: user@domain.vn
```
 
### 9.3 Anti-Spam Nâng Cao — Rspamd
 
Rspamd là giải pháp anti-spam thế hệ mới, thay thế SpamAssassin + Amavis với hiệu năng cao hơn nhiều:
 
```bash
# Cài Rspamd
curl https://rspamd.com/apt-stable/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/rspamd.gpg
echo "deb [signed-by=/usr/share/keyrings/rspamd.gpg] https://rspamd.com/apt-stable/ $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/rspamd.list
sudo apt update && sudo apt install rspamd -y
 
# Tích hợp với Postfix qua milter
# /etc/postfix/main.cf
smtpd_milters = inet:localhost:11332
non_smtpd_milters = inet:localhost:11332
milter_default_action = accept
 
# Truy cập Web UI
# http://mail.domain.vn:11334
# (cần đặt password trong /etc/rspamd/worker-controller.inc)
```
 
**So sánh SpamAssassin vs Rspamd:**
 
| Tiêu chí | SpamAssassin | Rspamd |
|---|---|---|
| Ngôn ngữ | Perl | C |
| Hiệu năng | Chậm hơn (fork mỗi mail) | Nhanh hơn nhiều (event-driven) |
| Machine Learning | Bayes cơ bản | Neural network tích hợp |
| Web UI | Không | Có (dashboard đẹp) |
| DKIM ký | Cần OpenDKIM riêng | Tích hợp sẵn |
| Phổ biến | Rất phổ biến (legacy) | Đang dần thay thế SA |
 
---
