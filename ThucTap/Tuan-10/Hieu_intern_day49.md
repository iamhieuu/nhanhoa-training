# Báo cáo thực tập ngày 49 - Zimbra

## 5. TLS/SSL cho Email
 
### 5.1 Tại sao Email cần TLS/SSL?
 
Email gốc truyền qua internet hoàn toàn dạng **plain text**. Bất kỳ ai có thể nghe lén (sniff) trên đường truyền đều đọc được nội dung email, username và password. **TLS (Transport Layer Security)** mã hóa kênh truyền này.
 
| Kết nối | Không TLS | Với TLS |
|--------|-----------|---------|
| SMTP (MTA-MTA) | Plain text, có thể bị intercepted | Mã hóa kênh truyền giữa 2 MTA |
| SMTP Submission (Client) | Password lộ | Password được bảo vệ |
| IMAP | Nội dung email và password lộ | Toàn bộ phiên được mã hóa |
| POP3 | Tương tự IMAP | Toàn bộ phiên được mã hóa |
| Webmail (HTTP) | Session token có thể bị hijack | HTTPS bảo vệ toàn bộ phiên |
 
---
 
### 5.2 STARTTLS vs SSL/TLS Implicit
 
#### STARTTLS (Opportunistic TLS)
 
Kết nối bắt đầu bằng plain text trên port chuẩn, sau đó **nâng cấp lên TLS** thông qua lệnh STARTTLS. Nếu TLS không được hỗ trợ, kết nối tiếp tục plain text — đây là điểm yếu có thể bị downgrade attack.
 
```
Port 25  (SMTP giữa MTA):    STARTTLS (opportunistic — không bắt buộc)
Port 587 (Submission):        STARTTLS (required — client phải dùng TLS)
Port 143 (IMAP):              STARTTLS
Port 110 (POP3):              STARTTLS
```
 
#### SSL/TLS Implicit (Wrapper Mode)
 
Kết nối **TLS ngay từ đầu**, không có giai đoạn plain text. Bảo mật hơn vì không thể bị downgrade attack.
 
```
Port 465 (SMTPS):    TLS ngay từ đầu
Port 993 (IMAPS):    TLS ngay từ đầu  ← Khuyến nghị dùng
Port 995 (POP3S):    TLS ngay từ đầu
Port 443 (HTTPS):    TLS ngay từ đầu  ← Webmail
```
 
> ⚠️ **Khuyến nghị:** Với email client, luôn cấu hình **IMAP port 993 (SSL/TLS)** và **SMTP port 587 (STARTTLS)** hoặc **465 (SSL/TLS)**. Tuyệt đối không dùng port 143/25/110 không mã hóa trong doanh nghiệp.
 
---
 
### 5.3 Certificate (Chứng chỉ SSL)
 
#### Các loại Certificate
 
- **Self-signed Certificate:** Do chính server tự ký. Miễn phí nhưng browser/client cảnh báo "not trusted". Chỉ phù hợp cho môi trường nội bộ.
- **CA-signed Certificate:** Được ký bởi Certificate Authority uy tín (DigiCert, Comodo, GlobalSign). Browser/client tin tưởng mà không cảnh báo.
- **Let's Encrypt:** CA miễn phí, tự động gia hạn, được tin tưởng bởi tất cả browser hiện đại. Phù hợp với hầu hết doanh nghiệp.
#### Certificate chain và trust
 
Certificate phải bao gồm đầy đủ chain: **Server Certificate → Intermediate CA → Root CA**. Thiếu Intermediate Certificate là nguyên nhân phổ biến gây lỗi SSL trên một số client.
 
---
 
### 5.4 MTA-STS và DANE
 
- **MTA-STS (Mail Transfer Agent Strict Transport Security):** Cho phép domain công bố chính sách yêu cầu MTA kết nối đến phải dùng TLS. Tương tự HSTS trong web nhưng cho email. Ngăn downgrade attack và MITM.
- **DANE (DNS-based Authentication of Named Entities):** Sử dụng DNSSEC để công bố certificate fingerprint lên DNS (TLSA record). Server nhận có thể xác minh certificate mà không cần CA tập trung.
> 🔵 **Zimbra:** Certificate được dùng cho HTTPS (Webmail/Admin), IMAPS (993), POP3S (995), SMTP/TLS (587).
> - Cài certificate: `zmcertmgr`
> - Kiểm tra: `zmcertmgr viewdeployedcrt all`
> - Nên cài Commercial hoặc Let's Encrypt certificate để email client không cảnh báo.
 
---
 
## 6. Audit, Log Analysis, Fail2ban, Monitoring
 
### 6.1 Email Security Audit
 
#### Audit là gì trong ngữ cảnh Email?
 
Email audit là quá trình **ghi lại, phân tích và kiểm soát** toàn bộ hoạt động của hệ thống email: ai gửi email, ai nhận, ai đăng nhập, có xác thực thành công không, có dấu hiệu bất thường không.
 
#### Các sự kiện cần audit
 
| Sự kiện | Log source | Tầm quan trọng |
|---------|-----------|----------------|
| Đăng nhập thành công/thất bại | audit.log / mailbox.log | 🔴 Cao — phát hiện brute force |
| Thay đổi password | audit.log | 🔴 Cao — phát hiện account takeover |
| Email gửi số lượng lớn | mail.log | 🔴 Cao — phát hiện spam bot |
| Truy cập từ IP bất thường | mailbox.log | 🟡 Trung bình — unauthorized access |
| Thay đổi cấu hình | zimbra admin log | 🔴 Cao — unauthorized config change |
| Xóa email hàng loạt | mailbox.log | 🟡 Trung bình — data destruction |
 
---
 
### 6.2 Fail2ban
 
#### Fail2ban là gì?
 
Fail2ban là công cụ **giám sát log file và tự động block IP** khi phát hiện hành vi đáng ngờ (quá nhiều lần đăng nhập thất bại). Fail2ban hoạt động bằng cách thêm rule vào firewall (iptables/nftables).
 
#### Nguyên lý hoạt động
 
```
1. Fail2ban đọc log file (ví dụ: /var/log/auth.log)
2. So sánh với regex pattern (filter)
3. Đếm số lần match từ một IP trong time window
4. Nếu vượt maxretry → Block IP qua iptables
5. Sau bantime → Tự động unblock
```
 
#### Các jail (bẫy) email phổ biến
 
- **postfix-sasl:** Block IP có quá nhiều lần SMTP AUTH thất bại. Ngăn brute force password.
- **dovecot:** Block IP brute force IMAP/POP3 login.
- **postfix:** Block IP bị reject nhiều lần (spam, invalid recipient).
- **zimbra-audit:** Block IP brute force vào Zimbra Web Client.
> ⚠️ **Cảnh báo:** Fail2ban cần được cấu hình cẩn thận với **whitelist** để tránh block nhầm IP nội bộ hoặc IP của email gateway. Thiếu whitelist là nguyên nhân phổ biến tự block chính mình.
 
> 🔵 **Zimbra:** Có cơ chế throttling tích hợp. Fail2ban có thể tích hợp đọc `/opt/zimbra/log/audit.log` để block brute force. Zimbra cũng hỗ trợ IP Whitelist/Blacklist ở cấp độ Admin Console.
 
---
 
### 6.3 Monitoring Email Server
 
#### Các chỉ số cần giám sát
 
| Chỉ số | Ý nghĩa | Ngưỡng cảnh báo gợi ý |
|--------|---------|----------------------|
| Queue size | Số email đang chờ xử lý | > 500 email deferred |
| Bounce rate | Tỷ lệ email bị bounce | > 5% trong 1 giờ |
| SMTP connection rate | Số kết nối SMTP/giây | Tăng đột biến > 3x bình thường |
| CPU/RAM | Tài nguyên hệ thống | CPU > 80%, RAM > 90% |
| Disk `/opt/zimbra` | Dung lượng lưu trữ | > 80% capacity |
| Auth failure rate | Lần đăng nhập thất bại | > 10 lần từ 1 IP trong 5 phút |
| Spam score distribution | Phân bố điểm spam | Tăng đột biến spam cao điểm |
| Certificate expiry | Hạn SSL certificate | < 30 ngày |
 
#### Công cụ giám sát phổ biến
 
- **Zabbix:** Giám sát hạ tầng full-stack, có template sẵn cho Postfix và Zimbra.
- **Prometheus + Grafana:** Thu thập metrics, visualize dashboard realtime.
- **Nagios / Icinga:** Monitoring cổ điển, alerting linh hoạt.
- **Graylog / ELK:** Centralized log management, tìm kiếm log nhanh.
- **Zimbra built-in:** Admin Console > Monitor, `zmstats`, `zmcontrol status`.
> 🔵 **Zimbra:** Lệnh kiểm tra sức khỏe:
> - `zmcontrol status` — trạng thái tất cả service
> - `zmprov gs <server>` — xem cấu hình server
> - `zmstats` — thống kê hệ thống
> - `/opt/zimbra/libexec/zmdisklog` — disk usage
 
---
 
# PHẦN III — TÍCH HỢP & HƯỚNG DẪN NGƯỜI DÙNG
 
---
 
## 7. Outlook, Thunderbird, Apple Mail, Android/iOS
 
### 7.1 Nguyên tắc cấu hình Mail Client
 
Khi cấu hình bất kỳ mail client nào với Zimbra, cần cung cấp đúng ba thông số: **server nhận (IMAP), server gửi (SMTP), và phương thức xác thực**.
 
| Thông số | Giá trị cho Zimbra | Lưu ý |
|---------|-------------------|-------|
| IMAP Server | `mail.company.com` | Phân giải từ zimbraMailHost |
| IMAP Port | `993` (SSL/TLS) hoặc `143` (STARTTLS) | Luôn dùng **993** |
| SMTP Server | `mail.company.com` | Cùng hostname |
| SMTP Port | `587` (STARTTLS) hoặc `465` (SSL/TLS) | Luôn dùng **587 hoặc 465** |
| Username | `user@company.com` hoặc `user` | Zimbra dùng full email |
| Password | Zimbra password | Hoặc AD password nếu dùng AD auth |
| Authentication | Normal Password / PLAIN | Qua TLS là an toàn |
 
---
 
### 7.2 Microsoft Outlook
 
#### Phương thức kết nối Outlook với Zimbra
 
- **Zimbra Connector for Outlook (ZCO):** Plugin chính thức của Zimbra. Đồng bộ email, calendar, contacts, tasks qua Outlook MAPI. Trải nghiệm tốt nhất nhưng cần cài thêm plugin.
- **IMAP/SMTP thuần túy:** Kết nối qua IMAP 993 và SMTP 587. Đơn giản, không cần plugin, nhưng không đồng bộ Calendar/Contacts.
- **Exchange ActiveSync (EAS):** Zimbra hỗ trợ EAS. Outlook 2013+ có thể dùng EAS không cần ZCO. Đồng bộ đầy đủ email, calendar, contacts.
#### Autodiscover
 
Autodiscover là cơ chế Outlook tự động tìm cấu hình server. Outlook tra cứu theo thứ tự: `autodiscover.company.com` → `company.com/autodiscover` → SRV record DNS.
 
> 🔵 **Zimbra:** Hỗ trợ Autodiscover. Cần cấu hình DNS CNAME: `autodiscover.company.com → mail.company.com`. Sau đó Outlook kết nối `https://mail.company.com/autodiscover/autodiscover.xml` để lấy cấu hình tự động. Giúp người dùng không cần cấu hình thủ công.
 
---
 
### 7.3 Mozilla Thunderbird
 
Thunderbird kết nối Zimbra qua IMAP/SMTP chuẩn. Thunderbird cũng hỗ trợ **Autoconfig** (tương tự Autodiscover). Để đồng bộ Calendar và Contacts từ Zimbra:
 
- **TbSync add-on + EAS provider:** Đồng bộ qua Exchange ActiveSync.
- **Lightning + CalDAV/CardDAV:** Đồng bộ Calendar qua CalDAV, Contacts qua CardDAV.
---
 
### 7.4 Apple Mail / iOS / macOS
 
Apple Mail, iPhone và Mac đều hỗ trợ tốt với Zimbra qua:
 
- **IMAP/SMTP:** Kết nối chuẩn cho email.
- **Exchange ActiveSync:** Cấu hình nhanh qua "Exchange" account type trên iOS/macOS. Đồng bộ email, calendar, contacts tự động.
- **CalDAV / CardDAV:** Thêm thủ công nếu không dùng EAS.
**URL CalDAV/CardDAV trong Zimbra:**
```
CalDAV:  https://mail.company.com/dav/user@company.com/Calendar/
CardDAV: https://mail.company.com/dav/user@company.com/Contacts/
```
 
---
 
### 7.5 Android
 
- **Ứng dụng Gmail / Android Mail:** Thêm account IMAP thủ công.
- **Zimbra Mobile :** Dành cho Zimbra có bản quyền, đồng bộ đầy đủ.
- **Exchange ActiveSync:** Thêm account kiểu "Exchange" trong Settings → Accounts. Đồng bộ email, calendar, contacts.
> 🔵 **Zimbra:** EAS là phương thức khuyến nghị cho thiết bị di động.
> - Bật EAS: `zmprov ms <server> zimbraEASEnabled TRUE`
> - Kiểm tra: `zmcontrol status | grep eas`
 
---
 
## 8. Chữ ký, Filter, Forward, Out-of-Office, Quota
 
### 8.1 Email Signature (Chữ ký email)
 
#### Phân loại chữ ký
 
- **User signature:** Người dùng tự tạo trong webmail hoặc mail client. Áp dụng cho email họ gửi đi.
- **Global/Domain signature (chữ ký toàn doanh nghiệp):** Admin cấu hình, tự động thêm vào cuối mọi email gửi đi. Thường chứa thông tin pháp lý, logo công ty.
#### Cơ chế thêm chữ ký toàn hệ thống
 
Chữ ký toàn hệ thống thường được thêm ở cấp **MTA (Postfix)** thông qua content filter, hoặc ở cấp MDA. Công cụ như `altermime` hay `Disclaimer` có thể thêm/sửa email trước khi deliver.
 
> 🔵 **Zimbra:** Hỗ trợ chữ ký cá nhân qua Preferences → Signatures trong ZWC. Admin có thể lock chữ ký không cho user thay đổi thông qua **COS (Class of Service)**.
 
---
 
### 8.2 Mail Filter (Bộ lọc email)
 
#### Sieve Filter
 
**Sieve** là ngôn ngữ scripting chuẩn (RFC 5228) để viết filter email. Sieve filter chạy **phía server**, áp dụng ngay khi email đến hộp thư, không phụ thuộc mail client.
 
```sieve
# Ví dụ: Chuyển email từ sếp vào thư mục Important
if header :contains "From" "boss@company.com" {
    fileinto "Important";
}
 
# Ví dụ: Xóa email spam
if header :contains "X-Spam-Flag" "YES" {
    discard;
}
 
# Ví dụ: Auto-reply và forward
if header :contains "Subject" "Invoice" {
    fileinto "Finance";
    redirect "accountant@company.com";
}
```
 
> 🔵 **Zimbra:** Sử dụng Sieve filter. Người dùng tạo filter qua Preferences → Filters trong ZWC. Admin xem/quản lý filter của user: `zmprov ga user@company.com zimbraMailSieveScript`
 
---
 
### 8.3 Email Forwarding 
 
#### Các loại forwarding
 
- **User-level forwarding:** Người dùng cấu hình trong Preferences → Accounts.
- **Admin-level forwarding:** Admin cấu hình qua `zmprov`. Dùng khi nhân viên nghỉ việc.
- **Distribution list:** Một địa chỉ email nhóm, phân phối cho tất cả thành viên.
> ⚠️ **Cảnh báo:** Cần cẩn thận với **external forwarding** (chuyển email ra bên ngoài doanh nghiệp). Đây là vector rò rỉ dữ liệu phổ biến. Nên có policy kiểm soát forwarding ra domain ngoài.
 
---
 
### 8.4 Out-of-Office (Vacation Auto-reply)
 
Out-of-Office tự động trả lời email khi người dùng vắng mặt. Được triển khai bằng **Sieve vacation extension (RFC 5230)**.
 
**Đặc điểm quan trọng:**
- Chỉ gửi auto-reply **một lần** cho mỗi địa chỉ người gửi (trong khoảng thời gian nhất định), tránh spam loop.
- Không gửi auto-reply cho email từ mailing list, email hàng loạt hoặc địa chỉ `noreply`.
- Có thể cấu hình thời gian bắt đầu/kết thúc.
> 🔵 **Zimbra:** Preferences → Out of Office. Xem trạng thái OOO của user: `zmprov ga user@company.com zimbraOutOfOfficeReply`
 
---
 
### 8.5 Quota Management
 
#### Quota là gì?
 
Quota là **giới hạn dung lượng hộp thư** của mỗi user. Khi đạt quota, user không nhận được email mới — email gửi đến bị bounce với mã lỗi `452 (insufficient storage)`.
 
#### Các cấp quota trong Zimbra
 
| Cấp | Áp dụng cho | Ưu tiên |
|-----|------------|---------|
| COS (Class of Service) | Nhóm người dùng cùng COS | Thấp nhất |
| Domain | Toàn bộ user trong domain | Trung bình |
| User | Cá nhân user cụ thể | **Cao nhất (override COS/Domain)** |
 
> 🔵 **Zimbra:**
> - Đặt quota: `zmprov ma user@company.com zimbraMailQuota 1073741824` (1GB tính bằng bytes)
> - Xem quota: `zmprov ga user@company.com zimbraMailQuota`
> - Cảnh báo được gửi tự động khi user đạt 80% và 90% quota.
 
---
 
## 9. Dịch vụ bổ trợ: Roundcube, RainLoop, CardDAV, CalDAV, Rspamd
 
### 9.1 Webmail Alternatives
 
#### Roundcube
 
Roundcube là webmail client mã nguồn mở viết bằng PHP, được sử dụng rộng rãi trong môi trường không phải Zimbra (cPanel, Plesk, server Postfix+Dovecot thuần túy).
 
- **Kiến trúc:** PHP application, kết nối đến IMAP server để đọc email, đến SMTP server để gửi.
- **Đặc điểm:** Giao diện đẹp, plugin phong phú, hỗ trợ ACL cho shared folders.
- **Giới hạn:** Là mail client thuần túy, không tích hợp calendar/tasks như Zimbra ZWC.
#### RainLoop (Snappymail)
 
RainLoop (fork hiện tại là Snappymail) là webmail client nhẹ, hiệu suất cao, giao diện hiện đại. Phù hợp cho shared hosting environment.
 
> 🔵 **Zimbra:** Có Zimbra Web Client (ZWC) tích hợp sẵn, không cần Roundcube hay RainLoop. Hiểu Roundcube giúp bạn biết cách hoạt động của webmail layer khi troubleshoot hoặc khi migrate từ Postfix+Dovecot sang Zimbra.
 
---
 
### 9.2 CalDAV — Calendar Synchronization
 
#### CalDAV là gì?
 
**CalDAV** (Calendar Extensions to WebDAV, RFC 4791) là giao thức chuẩn để đồng bộ calendar giữa server và các ứng dụng. CalDAV dùng HTTP/HTTPS làm transport, format **iCalendar (.ics)** làm dữ liệu.
 
```
Client (Thunderbird/Apple Calendar/Android)  ←→  CalDAV Server
           |                                              |
    GET /dav/user/Calendar/        ←── HTTPS ──→  [Zimbra CalDAV]
    PUT event.ics                               Lưu vào Zimbra store
    DELETE event.ics                            Sync với tất cả devices
```
 
> 🔵 **Zimbra:** URL CalDAV: `https://mail.company.com/dav/user@company.com/Calendar/`  
> Kiểm tra: `curl -u user:pass https://mail.company.com/dav/user@company.com/`
 
---
 
### 9.3 CardDAV — Contacts Synchronization
 
**CardDAV** (vCard Extensions to WebDAV, RFC 6352) là giao thức chuẩn đồng bộ danh bạ. Tương tự CalDAV nhưng cho contacts, dùng format **vCard (.vcf)**.
 
> 🔵 **Zimbra:** URL CardDAV: `https://mail.company.com/dav/user@company.com/Contacts/`  
> Hỗ trợ đồng bộ với iOS, macOS Contacts, Thunderbird (CardBook plugin), Android (DAVx5 app).
 
---
 
### 9.4 Rspamd — Modern Anti-Spam
 
#### Rspamd là gì?
 
Rspamd là hệ thống anti-spam hiện đại, hiệu suất cao, thay thế cho SpamAssassin. Rspamd sử dụng nhiều module phân tích: DKIM, SPF, DMARC checking, neural network, fuzzy hashing, RBL, Bayes learning.
 
#### So sánh Rspamd vs SpamAssassin
 
| Tiêu chí | SpamAssassin | Rspamd |
|---------|-------------|--------|
| Hiệu suất | Chậm (Perl, fork mỗi email) | Nhanh (C, async, daemon) |
| Neural Network | Không | ✅ Có (tự học từ feedback) |
| DKIM signing | Cần plugin | ✅ Tích hợp sẵn |
| Web UI | Không | ✅ Có |
| Redis integration | Không | ✅ Có (rate limit, token) |
 
#### Luồng xử lý Rspamd
 
```
Postfix (milter) → Rspamd → Các module:
  ├── SPF check
  ├── DKIM check/sign
  ├── DMARC check
  ├── RBL/URIBL lookup
  ├── Bayes classifier
  ├── Neural network
  └── Fuzzy hash
         |
   Score tổng hợp → Action:
   < 0  : Ham (email hợp lệ) ✅
   0–6  : Add header [SPAM]
   > 6  : Reject hoặc Quarantine ❌
```
 
> 🔵 **Zimbra:** Mặc định dùng SpamAssassin + Amavis. Rspamd không tích hợp mặc định nhưng một số admin thay thế hoặc bổ sung. Hiểu Rspamd giúp bạn biết cơ chế anti-spam hiện đại khi cần tùy chỉnh hoặc tích hợp Zimbra với gateway bên ngoài.
 
---
 
# PHẦN IV — NÂNG CAO
 
---
 
## 10. Cluster Mail Server
 
### 10.1 Tại sao cần Cluster?
 
Một server email đơn lẻ (single point of failure) không phù hợp với môi trường doanh nghiệp có yêu cầu cao về availability.
 
| Vấn đề | Không cluster | Với cluster |
|--------|--------------|-------------|
| Server down | Email không hoạt động | Dịch vụ tiếp tục trên node khác |
| Tải cao | Hiệu suất giảm | Phân tải giữa nhiều node |
| Bảo trì | Phải dừng hệ thống | Rolling maintenance, không downtime |
| Mở rộng | Phải thay server | Thêm node vào cluster |
 
---
 
### 10.2 Kiến trúc Cluster Email
 
#### Active-Passive Cluster
 
Một node chạy (active), một node chờ (passive). Khi active node fail, passive node tự động takeover (failover). Đơn giản nhưng lãng phí tài nguyên vì passive node không xử lý tải thường ngày.
 
#### Active-Active Cluster
 
Tất cả node đều xử lý tải. Load balancer phân phối kết nối đến các node. Hiệu quả hơn nhưng phức tạp hơn về đồng bộ dữ liệu.
 
#### Kiến trúc Zimbra Multi-Server
 
```
                    [DNS MX]
                       |
              [Load Balancer / HAProxy]
               /                      \
        [MTA Node 1]              [MTA Node 2]
         (Postfix)                 (Postfix)
               \                      /
         [Shared Config via LDAP]
               /                      \
      [Mailbox Node 1]          [Mailbox Node 2]
       (zimbra mailboxd)         (zimbra mailboxd)
               \                      /
         [LDAP Master] ←→ [LDAP Replica]
```
 
---
 
### 10.3 Các thành phần Cluster Zimbra
 
#### MTA Cluster
 
Nhiều MTA node nhận email từ internet và gửi email đi. Load balancer phân phối kết nối SMTP. Các MTA node chia sẻ cùng cấu hình qua LDAP.
 
#### Mailbox Cluster
 
Mỗi Mailbox node lưu trữ hộp thư của một nhóm user (không phải shared). Load balancer định tuyến HTTP/IMAP đến đúng Mailbox node chứa hộp thư của user đó (**sticky session**).
 
#### LDAP Redundancy
 
Zimbra LDAP lưu tất cả thông tin cấu hình và tài khoản. **LDAP Master-Replica** đảm bảo LDAP không là single point of failure.
 
> 🔵 **Zimbra:** Thứ tự cài đặt multi-server quan trọng: **LDAP Master → Mailbox → MTA → Proxy**. Trong thực tế doanh nghiệp VN, phổ biến nhất là: 1 MTA + 1 Mailbox (small), 2 MTA + 2–4 Mailbox + 1 LDAP (medium).
 
---
 
## 11. High Availability (HA)
 
### 11.1 Khái niệm High Availability
 
High Availability (HA) là khả năng của hệ thống tiếp tục hoạt động khi một thành phần bị lỗi. HA được đo bằng "nines":
 
| Availability | Downtime/năm | Downtime/tháng | Yêu cầu |
|-------------|-------------|----------------|---------|
| 99% | 3.65 ngày | 7.2 giờ | Backup đơn giản |
| 99.9% (3 nines) | 8.76 giờ | 43.8 phút | Failover tự động |
| 99.99% (4 nines) | 52.6 phút | 4.4 phút | Active-Active + monitoring |
| 99.999% (5 nines) | 5.26 phút | 26 giây | Redundancy toàn bộ + automation |
 
---
 
### 11.2 Các thành phần HA cho Email Server
 
#### 1. Network HA
- **Bonding/LACP:** Kết hợp nhiều NIC thành một logical interface, tăng bandwidth và redundancy.
- **Multiple upstream:** Kết nối đến nhiều ISP, failover khi một ISP gặp sự cố.
- **Floating IP / Virtual IP:** IP ảo chuyển giữa các node khi failover, giúp DNS không cần thay đổi.
#### 2. Storage HA
- **RAID (Redundant Array of Independent Disks):** RAID 1 (mirror), RAID 5/6 (parity). Bảo vệ khi ổ cứng hỏng.
- **SAN (Storage Area Network):** Shared block storage, nhiều server cùng truy cập.
- **DRBD (Distributed Replicated Block Device):** Đồng bộ block device giữa 2 server qua network, dùng cho Active-Passive.
- **GlusterFS / Ceph:** Distributed filesystem, phù hợp với môi trường lớn.
#### 3. Service HA — Pacemaker + Corosync
 
**Pacemaker** là cluster resource manager, **Corosync** là cluster communication layer. Phối hợp để:
1. Giám sát trạng thái các node (heartbeat)
2. Phát hiện node fail (split brain detection)
3. Tự động failover resource sang node còn sống
4. Quản lý Virtual IP, dịch vụ, storage mount
#### 4. Load Balancer HA
- **HAProxy:** High-performance TCP/HTTP load balancer. Health check, failover tự động khi backend down.
- **Keepalived:** VRRP (Virtual Router Redundancy Protocol) cho HAProxy, đảm bảo HA cho chính load balancer.
---
 
### 11.3 Split Brain — Vấn đề nghiêm trọng trong cluster
 
Split brain xảy ra khi các node trong cluster bị mất liên lạc với nhau (network partition) nhưng **mỗi node đều nghĩ mình là primary**. Kết quả: cả hai node cùng ghi dữ liệu, gây xung đột và mất dữ liệu.
 
> ⚠️ **Cảnh báo:** Giải pháp chống split brain: **Quorum**, **STONITH** (— tắt node kia trước khi takeover), và **Fencing**. Đây là kiến thức quan trọng khi deploy Zimbra HA.
 
> 🔵 **Zimbra:** HA thường triển khai theo mô hình:
> - Active-Passive cho Mailbox (dùng DRBD + Pacemaker)
> - Active-Active cho MTA (nhiều Postfix node sau HAProxy)
> - Zimbra LDAP Master + Replica
> 
> Zimbra không có HA tích hợp sẵn. Một số giải pháp thương mại như **Zextras Suite** cung cấp HA tốt hơn.
 
---
 
## 12. Backup & Restore
 
### 12.1 Tại sao Backup Email quan trọng?
 
Email là dữ liệu business-critical. Backup email bảo vệ khỏi: hardware failure, accidental deletion, ransomware, software bug, và compliance requirements.
 
---
 
### 12.2 Chiến lược Backup 3-2-1
 
| Số | Ý nghĩa | Ví dụ |
|----|---------|-------|
| **3** | 3 bản sao dữ liệu | Production + Backup local + Backup offsite |
| **2** | 2 loại media khác nhau | Disk + Tape, hoặc Disk + Cloud |
| **1** | 1 bản ở nơi khác địa lý | Cloud backup, remote datacenter |
 
---
 
### 12.3 Các loại Backup
 
| Loại | Mô tả | Ưu điểm | Nhược điểm |
|------|-------|---------|-----------|
| **Full Backup** | Backup toàn bộ dữ liệu | Restore đơn giản, nhanh | Tốn nhiều storage và thời gian |
| **Incremental** | Chỉ backup thay đổi kể từ backup cuối | Nhanh, ít storage | Restore chậm (cần chain backup) |
| **Differential** | Backup thay đổi kể từ Full backup cuối | Restore nhanh hơn incremental | Lớn hơn incremental |
| **Snapshot** | Điểm nhất quán tại một thời điểm | Nhanh, không interrupt dịch vụ | Phụ thuộc storage support |
 
---
 
### 12.4 Backup Zimbra — Chiến lược
 
#### Dữ liệu cần backup
 
- `/opt/zimbra/store` — Dữ liệu email (file message). Chiếm nhiều storage nhất.
- `/opt/zimbra/data/ldap` — LDAP database (tài khoản, cấu hình). **Critical.**
- `/opt/zimbra/data/db` — MariaDB (MySQL) database (metadata, index).
- `/opt/zimbra/conf` — File cấu hình Zimbra.
- `/opt/zimbra/data/amavisd` — Cấu hình anti-spam.
#### Công cụ backup Zimbra
 
- **Zimbra built-in backup (Network Edition):** Công cụ chính thức. Incremental theo giờ, full theo ngày. Hỗ trợ restore theo account, mailbox, hoặc toàn bộ.
- **zmbackup (Open Source):** Tool backup cơ bản đi kèm bản miễn phí. Tính năng hạn chế.
- **Scripts tự viết:** Dùng rsync, tar, mysqldump kết hợp với dừng service Zimbra.
- **Zextras Backup (thương mại):** Backup nâng cao, real-time, hỗ trợ S3 storage, granular restore.
#### Quy trình backup cơ bản (Open Source Zimbra)
 
```bash
# 1. Dừng Zimbra
su - zimbra -c "zmcontrol stop"
 
# 2. Backup LDAP
su - zimbra -c "ldapsearch -x -H ldap://localhost \
  -D uid=zimbra,cn=admins,cn=zimbra -w <pass> \
  > /backup/ldap-$(date +%Y%m%d).ldif"
 
# 3. Backup MySQL
mysqldump -u zimbra -p<pass> --all-databases \
  > /backup/mysql-$(date +%Y%m%d).sql
 
# 4. Backup store và conf
rsync -avz /opt/zimbra/store /backup/store/
rsync -avz /opt/zimbra/conf /backup/conf/
 
# 5. Khởi động lại Zimbra
su - zimbra -c "zmcontrol start"
```
 
> ⚠️ **Cảnh báo:** Backup khi Zimbra đang chạy (hot backup) có thể gây inconsistency giữa filesystem, LDAP và MySQL. **Luôn test restore procedure định kỳ. Backup không được test là backup vô giá trị.**
 
---
 
### 12.5 Restore
 
#### Các mức độ restore
 
- **Item-level restore:** Khôi phục một email, folder, contact cụ thể. Cần Zimbra Network Edition hoặc Zextras.
- **Account-level restore:** Khôi phục toàn bộ hộp thư của một user.
- **System-level restore:** Khôi phục toàn bộ server Zimbra. Mất nhiều thời gian nhất.
#### Import .eml / .mbox vào Zimbra
 
```bash
# Import file .eml vào mailbox user
zmmailbox -z -m user@company.com addMessage /Inbox /path/to/email.eml
 
# Import .mbox file
zmmailbox -z -m user@company.com addMessage -t message /Inbox /path/to/backup.mbox
```
 
> 🔵 **Zimbra:** Network Edition có công cụ Backup Manager tích hợp trong Admin Console. Cho phép schedule backup, monitor status, và restore granular đến từng email. Đây là lý do mạnh để cân nhắc Network Edition cho môi trường production.
 
---
 
## 13. Migration Email Server
 
### 13.1 Tại sao Migration là thách thức?
 
Migration (di chuyển) email server là một trong những tác vụ phức tạp nhất. Thách thức bao gồm: không được mất email, không được downtime kéo dài, phải đồng bộ trạng thái (đọc/chưa đọc), và cần migrate calendar/contacts/tasks.
 
---
 
### 13.2 Các kịch bản Migration phổ biến
 
| Kịch bản | Từ | Đến | Phương thức |
|---------|-----|-----|-------------|
| Exchange → Zimbra | MS Exchange | Zimbra | ZCS Migration Tool, PST import, IMAP sync |
| G Suite → Zimbra | Google Workspace | Zimbra | IMAP sync, Google Takeout |
| Zimbra → Zimbra | Zimbra cũ | Zimbra mới | zmzimletdeploy, rsync, backup/restore |
| cPanel/Postfix → Zimbra | Postfix+Dovecot | Zimbra | imapsync, .mbox import |
| Zimbra OSE → NE | Zimbra Open Source | Zimbra Network Ed. | Backup/restore, LDAP migration |
 
---
 
### 13.3 Công cụ Migration
 
#### imapsync
 
**imapsync** là công cụ mạnh nhất để sync email giữa 2 IMAP server. Hoạt động bằng cách kết nối source và destination IMAP, copy folder structure, copy từng email, preserve flags (read/unread, starred).
 
```bash
# Sync một user từ server cũ sang Zimbra
imapsync \
  --host1 old-mail.company.com --port1 993 --ssl1 \
  --user1 user@company.com --password1 "oldpass" \
  --host2 new-zimbra.company.com --port2 993 --ssl2 \
  --user2 user@company.com --password2 "newpass" \
  --addheader --skipcrossduplicates
```
 
#### Zimbra Migration Wizard
 
Zimbra cung cấp Migration Wizard (Network Edition) để import từ Exchange và Lotus Notes, hỗ trợ cả email lẫn calendar/contacts.
 
#### PST Import
 
Microsoft Outlook có thể export hộp thư ra file `.PST`. Zimbra PST Migration Utility import file PST vào Zimbra mailbox, giữ nguyên folder structure.
 
---
 
### 13.4 Quy trình Migration an toàn
 
#### Giai đoạn 1: Chuẩn bị
1. Audit source system: đếm user, tổng dung lượng, các folder đặc biệt.
2. Lập kế hoạch: ai migrate trước (ít email nhất), rollback plan là gì.
3. Cấu hình Zimbra mới hoàn chỉnh: DNS, SSL, SPF/DKIM/DMARC.
4. Test migration với 1–2 tài khoản pilot.
#### Giai đoạn 2: Pre-cutover Migration (Song song)
1. Chạy imapsync sync email từ server cũ sang Zimbra mới (lần đầu, tốn nhiều thời gian).
2. Chạy lại imapsync định kỳ (cron) để sync email mới (incremental sync).
3. User tiếp tục dùng server cũ trong giai đoạn này.
#### Giai đoạn 3: Cutover (Chuyển đổi)
1. **T-24h:** Thông báo đến toàn bộ người dùng.
2. **T-0:** Thay đổi DNS MX record trỏ về Zimbra mới (TTL thấp để propagate nhanh).
3. **T+1h:** Chạy imapsync lần cuối để sync email nhận được trong giai đoạn propagation.
4. **T+4h:** Kiểm tra email nhận/gửi trên Zimbra mới.
5. **T+24h:** Tắt server cũ sau khi xác nhận ổn định.
#### Giai đoạn 4: Post-migration
1. Hỗ trợ người dùng cấu hình lại mail client.
2. Giám sát log, queue, bounce trong 1 tuần đầu.
3. Verify SPF/DKIM/DMARC hoạt động đúng.
4. Backup server cũ (giữ tối thiểu 30 ngày trước khi xóa).
