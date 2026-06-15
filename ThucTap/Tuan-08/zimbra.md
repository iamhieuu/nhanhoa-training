# TÀI LIỆU LAB ZIMBRA MAIL SERVER
## Triển khai và Quản trị Zimbra Collaboration Suite trên Ubuntu 22.04

> **Đối tượng:** Fresher / System Admin Intern  
> **Vai trò giảng viên:** Senior SysAdmin — 10 năm triển khai Mail Server  
> **Phiên bản Zimbra:** Zimbra OSE (Open Source Edition) 10.x  
> **Hệ điều hành:** Ubuntu Server 22.04 LTS  
> **Ngày biên soạn:** 2026-06-15

---

## MỤC LỤC

- [Chương 1. Giới thiệu Zimbra](#chương-1-giới-thiệu-zimbra)
- [Chương 2. Thiết kế mô hình](#chương-2-thiết-kế-mô-hình)
- [Chương 3. Chuẩn bị hệ thống](#chương-3-chuẩn-bị-hệ-thống)
- [Chương 4. Cài đặt Zimbra Mail Server](#chương-4-cài-đặt-zimbra-mail-server)
- [Chương 5. Truy cập giao diện quản trị](#chương-5-truy-cập-giao-diện-quản-trị)
- [Chương 6. Khởi tạo User Email](#chương-6-khởi-tạo-user-email)
- [Chương 7. Thiết lập chính sách mật khẩu](#chương-7-thiết-lập-chính-sách-mật-khẩu)
- [Chương 8. Thiết lập chữ ký Email](#chương-8-thiết-lập-chữ-ký-email)
- [Chương 9. Forward Email](#chương-9-forward-email)
- [Chương 10. Tìm ID Mailbox Account](#chương-10-tìm-id-mailbox-account)
- [Chương 11. Đổi mật khẩu Admin](#chương-11-đổi-mật-khẩu-admin)
- [Chương 12. Kiểm tra Log gửi nhận Email](#chương-12-kiểm-tra-log-gửi-nhận-email)
- [Chương 13. Thay đổi Logo Zimbra](#chương-13-thay-đổi-logo-zimbra)
- [Chương 14. Thay đổi Title Web Zimbra](#chương-14-thay-đổi-title-web-zimbra)
- [Chương 15. Quản lý Quota Mailbox](#chương-15-quản-lý-quota-mailbox)
- [Chương 16. Backup Email](#chương-16-backup-email)
- [Chương 17. Restore Email](#chương-17-restore-email)
- [Chương 18. Chuyển Data sang Server khác](#chương-18-chuyển-data-sang-server-khác)
- [Chương 19. Troubleshooting](#chương-19-troubleshooting)
- [Chương 20. Tổng kết](#chương-20-tổng-kết)

---

# CHƯƠNG 1. GIỚI THIỆU ZIMBRA

## 1.1 Mục tiêu

Sau chương này, bạn hiểu được:
- Zimbra là gì và tại sao doanh nghiệp dùng nó
- Kiến trúc các thành phần bên trong
- Khi nào nên chọn Zimbra thay vì giải pháp khác

## 1.2 Zimbra là gì?

Hãy hình dung **Zimbra** như một **bưu điện + văn phòng làm việc riêng của doanh nghiệp**.

Thay vì thuê Gmail hay Outlook.com (bưu điện công cộng), công ty tự vận hành hệ thống email của mình — toàn quyền kiểm soát dữ liệu, không phụ thuộc bên thứ ba.

Zimbra Collaboration Suite (ZCS) là một nền tảng email và cộng tác mã nguồn mở, bao gồm:
- **Email Server** (gửi/nhận thư)
- **Calendar** (lịch làm việc)
- **Contacts** (danh bạ)
- **Tasks** (công việc)
- **Webmail** (đọc mail trên trình duyệt)

## 1.3 Các thành phần của Zimbra

```
┌─────────────────────────────────────────────────────────┐
│                   ZIMBRA SERVER                          │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Postfix │  │  Dovecot │  │  LDAP    │  │ Nginx  │  │
│  │  (MTA)   │  │  (MDA)   │  │ (Auth)   │  │(Proxy) │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Amavis  │  │ SpamAss- │  │ ClamAV   │  │ MySQL  │  │
│  │ (Filter) │  │  assin   │  │(Antivirus│  │  (DB)  │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Zimbra Web Client (Webmail)              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

| Thành phần | Vai trò | Giải thích đơn giản |
|------------|---------|---------------------|
| **Postfix** | MTA (Mail Transfer Agent) | "Người vận chuyển thư" — nhận thư từ Internet, gửi thư đi |
| **Dovecot** | MDA (Mail Delivery Agent) | "Người phát thư" — đưa thư vào đúng hộp thư |
| **OpenLDAP** | Authentication | "Bảo vệ cổng" — xác thực username/password |
| **Nginx** | Reverse Proxy | "Lễ tân" — nhận request web, chuyển đến đúng nơi |
| **Amavis** | Content Filter | "Nhân viên kiểm tra bưu phẩm" — lọc spam/virus |
| **SpamAssassin** | Anti-Spam Engine | "Chuyên gia nhận diện thư rác" |
| **ClamAV** | Antivirus | "Máy quét virus cho file đính kèm" |
| **MySQL/MariaDB** | Database | "Tủ hồ sơ" — lưu cấu hình, metadata |

## 1.4 Kiến trúc hoạt động — Mail Flow

```
Người gửi bên ngoài                    Người nhận nội bộ
(sender@gmail.com)                     (user@lab.local)
        │                                      ▲
        │ SMTP:25                              │
        ▼                                      │
┌───────────────┐    Lọc Spam/Virus    ┌───────────────┐
│    Postfix    │ ──────────────────►  │    Amavis     │
│  (Nhận thư)  │ ◄──────────────────  │  (Kiểm tra)  │
└───────────────┘    Trả lại nếu OK   └───────────────┘
        │                                      │
        │                                      ▼
        │                             ┌───────────────┐
        │                             │   Dovecot     │
        │                             │ (Phát vào hộp)│
        │                             └───────────────┘
        │                                      │
        │                                      ▼
        │                             ┌───────────────┐
        └──────────────────────────►  │  Mailbox của  │
                                      │  user@lab.local│
                                      └───────────────┘
```

## 1.5 Ưu và nhược điểm

| Ưu điểm | Nhược điểm |
|---------|-----------|
| Mã nguồn mở, miễn phí (OSE) | Yêu cầu RAM cao (tối thiểu 4GB) |
| Webmail đẹp, đầy đủ tính năng | Cài đặt phức tạp hơn Postfix thuần |
| Tích hợp Calendar, Contacts | Phiên bản mới thay đổi nhiều |
| Admin Console trực quan | Tiêu tốn tài nguyên server |
| Backup/Restore dễ dàng | Tài liệu tiếng Việt còn hạn chế |

## 1.6 Trường hợp sử dụng thực tế

- Doanh nghiệp 50–5000 nhân viên cần email nội bộ có branding riêng
- Trường học, bệnh viện, cơ quan nhà nước cần lưu trữ email tại chỗ
- Hosting provider cung cấp dịch vụ Email Hosting cho khách hàng

## ✅ Checklist Chương 1

- [ ] Hiểu Zimbra là gì và gồm những thành phần nào
- [ ] Nắm được luồng email đi qua những dịch vụ nào
- [ ] Biết khi nào nên dùng Zimbra

---

# CHƯƠNG 2. THIẾT KẾ MÔ HÌNH

## 2.1 Mục tiêu

Hiểu rõ vai trò từng máy trong Lab và luồng kết nối giữa chúng.

## 2.2 Sơ đồ mạng Lab

```
                    ┌─────────────────────────────┐
                    │         INTERNET             │
                    │    (Giả lập bằng Host-only) │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │         VM1 — CLIENT        │
                    │   Hostname: client.lab.local │
                    │   IP: 172.16.16.237          │
                    │                              │
                    │   Vai trò:                   │
                    │   • Truy cập Admin Console   │
                    │   • Test gửi/nhận email      │
                    │   • Dùng trình duyệt         │
                    └──────────────┬──────────────┘
                                   │
                          Network: 172.16.16.0/24
                                   │
                    ┌──────────────▼──────────────┐
                    │         VM2 — ZIMBRA        │
                    │   Hostname: mail.lab.local   │
                    │   IP: 172.16.16.239          │
                    │                              │
                    │   Dịch vụ chạy:              │
                    │   • Postfix (SMTP :25)        │
                    │   • Dovecot (IMAP :143/993)  │
                    │   • Zimbra WebClient (:443)  │
                    │   • Admin Console (:7071)    │
                    │   • LDAP (:389)              │
                    └─────────────────────────────┘
```

## 2.3 Bảng thông tin Lab

| Thông số | VM1 — Client | VM2 — Zimbra |
|----------|-------------|--------------|
| Hostname | client.lab.local | mail.lab.local |
| IP Address | 172.16.16.237 | 172.16.16.239 |
| Subnet | /24 | /24 |
| OS | Ubuntu 22.04 | Ubuntu 22.04 |
| RAM | 1 GB | **Tối thiểu 4 GB** |
| Disk | 20 GB | **Tối thiểu 40 GB** |
| Vai trò | Admin/Test client | Mail Server |

## 2.4 Bảng Port cần mở trên VM2

| Port | Protocol | Dịch vụ | Ai kết nối |
|------|----------|---------|-----------|
| 22 | TCP | SSH | Admin |
| 25 | TCP | SMTP | Server khác gửi mail đến |
| 80 | TCP | HTTP redirect | Client browser |
| 110 | TCP | POP3 | Mail client |
| 143 | TCP | IMAP | Mail client |
| 443 | TCP | HTTPS Webmail | Client browser |
| 465 | TCP | SMTPS | Mail client gửi mail |
| 587 | TCP | SMTP Submission | Mail client gửi mail |
| 993 | TCP | IMAPS | Mail client (SSL) |
| 995 | TCP | POP3S | Mail client (SSL) |
| 7071 | TCP | Admin Console HTTPS | Admin browser |
| 7025 | TCP | LMTP | Internal Zimbra |
| 389 | TCP | LDAP | Internal Zimbra |

## ✅ Checklist Chương 2

- [ ] Hiểu rõ vai trò VM1 và VM2
- [ ] Ghi nhớ IP của từng máy
- [ ] Biết các port cần mở và dùng để làm gì

---

# CHƯƠNG 3. CHUẨN BỊ HỆ THỐNG

> ⚠️ **Toàn bộ chương này thực hiện trên VM2 — 172.16.16.239**

## 3.1 Mục tiêu

Cấu hình đúng hostname, hosts, DNS và các điều kiện tiên quyết để Zimbra installer không bị lỗi.

## 3.2 Lý thuyết — Tại sao phải chuẩn bị?

Zimbra installer rất **khắt khe** với DNS và hostname. Nếu hostname không resolve được → installer sẽ dừng lại và báo lỗi. Đây là nguyên nhân số 1 khiến người mới bị fail khi cài Zimbra.

> 💡 **Quy tắc vàng:** `hostname -f` phải trả về FQDN đúng trước khi chạy installer.

## 3.3 Bước 1 — Đặt Hostname

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Đặt hostname đúng chuẩn FQDN
hostnamectl set-hostname mail.lab.local

# Verify ngay lập tức
hostname
hostname -f
```

**Output mong đợi:**
```
mail.lab.local
mail.lab.local
```

> 📌 **Giải thích:** `hostname -f` phải trả về FQDN (Fully Qualified Domain Name) — tức là tên đầy đủ bao gồm cả domain. Nếu chỉ trả về `mail` thì cấu hình chưa đúng.

## 3.4 Bước 2 — Cấu hình file /etc/hosts

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Mở file hosts để chỉnh sửa
nano /etc/hosts
```

**Nội dung file /etc/hosts sau khi chỉnh sửa:**
```
127.0.0.1       localhost
172.16.16.239   mail.lab.local mail

# Client VM (để 2 máy nhận ra nhau)
172.16.16.237   client.lab.local client
```

> ⚠️ **Lưu ý cực kỳ quan trọng:** KHÔNG để `127.0.1.1 mail.lab.local` — dòng này thường có sẵn và sẽ làm Zimbra installer bị lỗi. Xóa dòng đó đi nếu thấy.

```bash
# Kiểm tra sau khi sửa
ping -c 2 mail.lab.local
```

**Output mong đợi:**
```
PING mail.lab.local (172.16.16.239) 56(84) bytes of data.
64 bytes from mail.lab.local (172.16.16.239): icmp_seq=1 ttl=64 time=0.021 ms
```

## 3.5 Bước 3 — Cấu hình DNS (dùng /etc/resolv.conf)

**Thực hiện trên: VM2 – 172.16.16.239**

Trong Lab nội bộ, chúng ta không có DNS server thật. Ta sẽ dùng chính file `/etc/hosts` làm DNS resolver.

```bash
# Kiểm tra cấu hình DNS hiện tại
cat /etc/resolv.conf

# Đảm bảo nameserver trỏ về chính nó (localhost) hoặc DNS nội bộ
# Chỉnh sửa nếu cần:
nano /etc/systemd/resolved.conf
```

Thêm vào section `[Resolve]`:
```ini
[Resolve]
DNS=172.16.16.239
FallbackDNS=8.8.8.8
Domains=lab.local
```

```bash
# Restart DNS service
systemctl restart systemd-resolved

# Kiểm tra resolve
nslookup mail.lab.local
# hoặc
dig mail.lab.local
```

**Output mong đợi:**
```
Server:         172.16.16.239
Address:        172.16.16.239#53

Name:   mail.lab.local
Address: 172.16.16.239
```

## 3.6 Bước 4 — Cập nhật hệ thống và cài packages tiên quyết

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Cập nhật package list
apt update && apt upgrade -y

# Cài các package bắt buộc
apt install -y \
    libgmp10 \
    libexpat1 \
    libstdc++6 \
    libperl5.34 \
    libaio1 \
    unzip \
    wget \
    curl \
    net-tools \
    dnsutils \
    ntp \
    ntpdate \
    sysstat
```

> 📌 **Giải thích:** Zimbra cần nhiều thư viện C/Perl để chạy. Thiếu package nào → installer báo lỗi dependency.

## 3.7 Bước 5 — Tắt các dịch vụ xung đột

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Tắt AppArmor (Zimbra không tương thích)
systemctl stop apparmor
systemctl disable apparmor

# Tắt Postfix nếu đã cài (Zimbra cài Postfix riêng)
systemctl stop postfix 2>/dev/null
systemctl disable postfix 2>/dev/null

# Kiểm tra port 25 đang trống
ss -tlnp | grep :25
# Không có output = port 25 trống = OK
```

## 3.8 Bước 6 — Đồng bộ thời gian

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Thiết lập timezone Việt Nam
timedatectl set-timezone Asia/Ho_Chi_Minh

# Sync time
ntpdate -u pool.ntp.org

# Kiểm tra
timedatectl status
```

**Output mong đợi:**
```
               Local time: Mon 2026-06-15 10:30:00 +07
           Universal time: Mon 2026-06-15 03:30:00 UTC
                 RTC time: Mon 2026-06-15 03:30:00
                Time zone: Asia/Ho_Chi_Minh (+07, +0700)
System clock synchronized: yes
```

> 📌 **Tại sao cần đồng bộ thời gian?** Email có timestamp. Nếu thời gian server lệch quá 5 phút so với server nhận → mail bị reject vì bị nghi là spam hoặc replay attack.

## 3.9 Bước 7 — Tăng file descriptor limit

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Zimbra xử lý nhiều kết nối cùng lúc, cần tăng giới hạn file open
echo "zimbra soft nofile 524288" >> /etc/security/limits.conf
echo "zimbra hard nofile 524288" >> /etc/security/limits.conf

# Kiểm tra
grep zimbra /etc/security/limits.conf
```

## 3.10 Verify toàn bộ trước khi cài

```bash
# Checklist cuối — chạy từng lệnh, kiểm tra output
echo "=== Hostname ==="
hostname -f

echo "=== Hosts file ==="
cat /etc/hosts

echo "=== Port 25 trống? ==="
ss -tlnp | grep :25 || echo "OK - Port 25 trống"

echo "=== Time ==="
date

echo "=== RAM ==="
free -h

echo "=== Disk ==="
df -h /
```

## ✅ Checklist Chương 3

- [ ] `hostname -f` trả về `mail.lab.local`
- [ ] `/etc/hosts` có dòng `172.16.16.239 mail.lab.local mail`
- [ ] Không có dòng `127.0.1.1 mail.lab.local` trong hosts
- [ ] Port 25 không có process nào đang dùng
- [ ] AppArmor đã disabled
- [ ] Timezone là Asia/Ho_Chi_Minh
- [ ] RAM tối thiểu 4GB khả dụng
- [ ] Disk tối thiểu 20GB trống

---

# CHƯƠNG 4. CÀI ĐẶT ZIMBRA MAIL SERVER

> ⚠️ **Toàn bộ chương này thực hiện trên VM2 — 172.16.16.239**

## 4.1 Mục tiêu

Cài đặt thành công Zimbra OSE và khởi động được tất cả service.

## 4.2 Bước 1 — Download Zimbra

**Thực hiện trên: VM2 – 172.16.16.239**

```bash
cd /tmp

# Download Zimbra OSE cho Ubuntu 22.04
wget https://files.zimbra.com/downloads/10.0.7_GA/zcs-10.0.7_GA_4659.UBUNTU22_64.20240330135542.tgz

# Kiểm tra file đã download
ls -lh zcs-*.tgz
```

**Output mong đợi:**
```
-rw-r--r-- 1 root root 485M Jun 15 10:00 zcs-10.0.7_GA_4659.UBUNTU22_64.20240330135542.tgz
```

## 4.3 Bước 2 — Giải nén

```bash
# Giải nén
tar xzf zcs-*.tgz

# Vào thư mục vừa giải nén
cd zcs-*/

# Xem nội dung
ls -la
```

**Output mong đợi:**
```
total 52
drwxr-xr-x  4 root root 4096 Jun 15 10:05 .
drwxrwxrwt 12 root root 4096 Jun 15 10:05 ..
-rw-r--r--  1 root root 7289 Jun 15 10:05 install.sh
drwxr-xr-x  2 root root 4096 Jun 15 10:05 packages
drwxr-xr-x  2 root root 4096 Jun 15 10:05 util
```

## 4.4 Bước 3 — Chạy installer

```bash
# Chạy script cài đặt
./install.sh -s
```

> 📌 **Giải thích tham số `-s`:** Skip repo check — bỏ qua kiểm tra repository online, phù hợp cho môi trường Lab.

### Quá trình installer — từng bước tương tác

Installer sẽ hỏi nhiều câu hỏi. Dưới đây là hướng dẫn trả lời:

```
Do you agree with the terms of the software license agreement? [N] Y
↑ Nhập Y → Enter

Use Zimbra's package repository [Y] N
↑ Nhập N (Lab không cần)

Install zimbra-ldap [Y] Y      ← Enter (chọn Y)
Install zimbra-logger [Y] Y    ← Enter
Install zimbra-mta [Y] Y       ← Enter (Postfix)
Install zimbra-dnscache [Y] Y  ← Enter
Install zimbra-snmp [Y] Y      ← Enter
Install zimbra-store [Y] Y     ← Enter (mailbox + webmail)
Install zimbra-apache [Y] Y    ← Enter
Install zimbra-spell [Y] Y     ← Enter
Install zimbra-memcached [Y] Y ← Enter
Install zimbra-proxy [Y] Y     ← Enter (Nginx)
Install zimbra-drive [N]       ← Enter (bỏ qua)
Install zimbra-imapd [N]       ← Enter (bỏ qua cho OSE)

The system will be modified. Continue? [N] Y
↑ Nhập Y → bắt đầu cài
```

### Cấu hình sau khi giải nén packages

```
DNS ERROR resolving MX for mail.lab.local
It is suggested that the domain name have an MX record...
Re-Enter domain name? [Yes] No
↑ Nhập No — trong Lab không cần MX record thật

Change domain name? [No] No
↑ Enter

Zimbra Admin Password:
↑ Nhập mật khẩu admin (ví dụ: Admin@2026!)
  Phải có ít nhất 6 ký tự
```

### Màn hình Main menu cấu hình

```
Main menu

   1) Common Configuration:
   2) zimbra-ldap:                             Enabled
   3) zimbra-logger:                           Enabled
   4) zimbra-mta:                              Enabled
   5) zimbra-dnscache:                         Enabled
   6) zimbra-snmp:                             Enabled
   7) zimbra-store:                            Enabled
        +Create Admin User:                    yes
        +Admin user to create:                 admin@lab.local
        +Admin password:                       set
   8) zimbra-spell:                            Enabled
   9) zimbra-proxy:                            Enabled
  10) Default Class of Service Configuration:
   s) Save config to file
   x) Expand menu
   q) Quit

Address unconfigured (**) items  (? - help) 
```

> 📌 **Kiểm tra:** Mục 7 phải hiển thị "Admin user to create: admin@lab.local" và "Admin password: set". Nếu chưa, gõ số 7 để vào cấu hình.

```bash
# Tại prompt trên, nhập:
a
# → Apply Configuration → Yes để bắt đầu cài đặt thực sự
# Quá trình này mất 10-20 phút
```

## 4.5 Bước 4 — Kiểm tra sau cài đặt

```bash
# Chuyển sang user zimbra
su - zimbra

# Kiểm tra tất cả service
zmcontrol status
```

**Output mong đợi — tất cả phải Running:**
```
Host mail.lab.local
        antispam                Running
        antivirus               Running
        dnscache                Running
        ldap                    Running
        logger                  Running
        mailbox                 Running
        memcached               Running
        mta                     Running
        opendkim                Running
        proxy                   Running
        service webapp          Running
        snmp                    Running
        spell                   Running
        stats                   Running
        zmconfigd               Running
```

Nếu có service nào chưa Running:
```bash
# Khởi động tất cả service
zmcontrol start

# Hoặc khởi động từng service
zmcontrol start mailbox
zmcontrol start mta
```

## 4.6 Bước 5 — Kiểm tra port đang listen

```bash
# Thoát khỏi user zimbra trước
exit

# Kiểm tra port
ss -tlnp | grep -E ':25|:143|:443|:7071|:80|:993|:587'
```

**Output mong đợi:**
```
LISTEN  0  100   0.0.0.0:25      0.0.0.0:*   users:(("master",pid=xxx))
LISTEN  0  100   0.0.0.0:143     0.0.0.0:*   users:(("dovecot",pid=xxx))
LISTEN  0  100   0.0.0.0:443     0.0.0.0:*   users:(("nginx",pid=xxx))
LISTEN  0  100   0.0.0.0:587     0.0.0.0:*   users:(("master",pid=xxx))
LISTEN  0  100   0.0.0.0:993     0.0.0.0:*   users:(("nginx",pid=xxx))
LISTEN  0  100   0.0.0.0:7071    0.0.0.0:*   users:(("java",pid=xxx))
```

## ✅ Checklist Chương 4

- [ ] Download thành công file Zimbra `.tgz`
- [ ] Installer chạy xong không báo lỗi đỏ (ERROR)
- [ ] `zmcontrol status` tất cả service là `Running`
- [ ] Port 25, 143, 443, 7071 đang `LISTEN`
- [ ] Nhớ mật khẩu Admin đã đặt

---

# CHƯƠNG 5. TRUY CẬP GIAO DIỆN QUẢN TRỊ

## 5.1 Mục tiêu

Truy cập thành công Admin Console và WorldClient (webmail), hiểu bố cục từng giao diện.

## 5.2 Admin Console — Cửa vào của System Admin

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (mở trình duyệt)**

**URL truy cập:**
```
https://172.16.16.239:7071
```

> ⚠️ Trình duyệt sẽ cảnh báo SSL certificate không tin cậy (self-signed cert). Chọn **"Advanced" → "Proceed anyway"** để tiếp tục.

**Đăng nhập:**
```
Username: admin
Password: [mật khẩu bạn đặt lúc cài]
```

### Bố cục Admin Console

```
┌────────────────────────────────────────────────────────────┐
│  ZIMBRA ADMIN CONSOLE                          [Logout]    │
├──────────┬─────────────────────────────────────────────────┤
│          │                                                  │
│ Manage   │              MAIN CONTENT AREA                  │
│ -------  │                                                  │
│ Accounts │  Dashboard hiển thị:                            │
│ Aliases  │  • Tổng số mailbox                              │
│ DLists   │  • Dung lượng đang dùng                        │
│ Resources│  • Trạng thái các service                       │
│          │  • Thống kê mail 24h qua                        │
│ Configure│                                                  │
│ -------  │                                                  │
│ Domains  │                                                  │
│ Servers  │                                                  │
│ CoS      │                                                  │
│          │                                                  │
│ Monitor  │                                                  │
│ -------  │                                                  │
│ Mail Que │                                                  │
│ Services │                                                  │
└──────────┴─────────────────────────────────────────────────┘
```

### Giải thích từng menu

| Menu | Chức năng | Dùng khi nào |
|------|-----------|--------------|
| **Manage → Accounts** | Tạo/sửa/xóa tài khoản email | Thêm nhân viên mới |
| **Manage → Aliases** | Tạo địa chỉ bí danh | sales@ chuyển về cá nhân |
| **Manage → Distribution Lists** | Tạo mailing list | Gửi mail cho cả phòng ban |
| **Configure → Domains** | Quản lý domain | Thêm domain mới |
| **Configure → Class of Service** | Tạo nhóm chính sách | Phân nhóm: VIP, Standard, Intern |
| **Configure → Servers** | Cấu hình server | Sửa cấu hình kỹ thuật |
| **Monitor → Mail Queue** | Xem hàng đợi mail | Debug mail không gửi được |
| **Monitor → Server Statistics** | Biểu đồ hiệu năng | Kiểm tra server có bị quá tải |
| **Tools → Backup** | Backup dữ liệu | Sao lưu định kỳ |

## 5.3 WorldClient — Cửa vào của Người dùng (Webmail)

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237**

**URL truy cập:**
```
https://172.16.16.239
# hoặc
https://mail.lab.local
```

**Đăng nhập:**
```
Username: admin@lab.local
Password: [mật khẩu admin]
```

Giao diện WorldClient gồm:
```
┌─────────────────────────────────────────────────────────┐
│  📧 Zimbra Webmail              [Settings] [Logout]     │
├──────────┬──────────────────────────────────────────────┤
│  Mail    │  INBOX                          [Compose]    │
│  ------  │  ┌──────────────────────────────────────┐   │
│  Inbox(3)│  │ From         Subject       Date       │   │
│  Sent    │  │ user01@..    Hello         Jun 15     │   │
│  Drafts  │  │ ...          ...           ...        │   │
│  Trash   │  └──────────────────────────────────────┘   │
│          │                                              │
│  Calendar│                                              │
│  Contacts│                                              │
│  Tasks   │                                              │
└──────────┴──────────────────────────────────────────────┘
```

## ✅ Checklist Chương 5

- [ ] Vào được Admin Console tại `https://172.16.16.239:7071`
- [ ] Đăng nhập Admin thành công
- [ ] Vào được WorldClient tại `https://172.16.16.239`
- [ ] Biết mỗi menu trong Admin Console dùng để làm gì

---

# CHƯƠNG 6. KHỞI TẠO USER EMAIL

## 6.1 Mục tiêu

Tạo được các tài khoản email cho người dùng qua GUI Admin Console.

## 6.2 Lý thuyết — Account trong Zimbra là gì?

Mỗi Account = 1 hộp thư riêng. Khi tạo account, Zimbra sẽ:
1. Tạo user trong LDAP
2. Tạo thư mục mailbox trên disk
3. Gán Class of Service (chính sách)
4. Cho phép đăng nhập webmail

## 6.3 Tạo Account qua GUI

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

### Tạo admin@lab.local (đã có sẵn)
Tài khoản này được tạo tự động khi cài. Kiểm tra tại:
```
Admin Console → Manage → Accounts
→ Thấy admin@lab.local trong danh sách
```

### Tạo user01@lab.local

```
Bước 1: Admin Console → Manage (menu trái) → Accounts
Bước 2: Click nút [New] (góc trên phải)
Bước 3: Điền thông tin:
         ┌─────────────────────────────────────┐
         │ Account Name:  user01@lab.local      │
         │ Last Name:     Nguyen                │
         │ First Name:    Van A                 │
         │ Display Name:  Nguyen Van A          │
         │ Password:      User01@2026!          │
         │ Confirm Pwd:   User01@2026!          │
         └─────────────────────────────────────┘
Bước 4: Click [Finish] để tạo
```

### Tạo user02@lab.local

Làm lại các bước trên với thông tin:
```
Account Name:  user02@lab.local
Last Name:     Tran
First Name:    Thi B
Display Name:  Tran Thi B
Password:      User02@2026!
```

## 6.4 Tạo Group (Distribution List)

> 📌 **Distribution List** = Danh sách gửi thư nhóm. Khi gửi mail đến `all@lab.local` → tất cả thành viên trong nhóm đều nhận được.

```
Admin Console → Manage → Distribution Lists → [New]
┌────────────────────────────────────────────────┐
│ Email: all@lab.local                           │
│ Display Name: All Staff                        │
│                                                │
│ Tab Members → Add:                             │
│   admin@lab.local                              │
│   user01@lab.local                             │
│   user02@lab.local                             │
└────────────────────────────────────────────────┘
Click [Finish]
```

## 6.5 Tạo Alias (Bí danh)

> 📌 **Alias** = Địa chỉ bí danh. Ví dụ: mail gửi đến `contact@lab.local` sẽ được chuyển vào hộp thư `admin@lab.local`. Dùng khi bạn muốn có nhiều địa chỉ nhưng chỉ 1 hộp thư.

```
Admin Console → Manage → Aliases → [New]
┌────────────────────────────────────────────────┐
│ Alias: contact@lab.local                       │
│ Account Target: admin@lab.local                │
└────────────────────────────────────────────────┘
Click [OK]
```

## 6.6 Kiểm tra kết quả

```bash
# Trên VM2 — kiểm tra qua CLI
su - zimbra
zmprov gaa lab.local
```

**Output mong đợi:**
```
admin@lab.local
user01@lab.local
user02@lab.local
```

## ✅ Checklist Chương 6

- [ ] Tạo thành công `user01@lab.local`
- [ ] Tạo thành công `user02@lab.local`
- [ ] Tạo Distribution List `all@lab.local` với 3 thành viên
- [ ] Tạo Alias `contact@lab.local` → `admin@lab.local`
- [ ] Đăng nhập WorldClient bằng user01 thành công

---

# CHƯƠNG 7. THIẾT LẬP CHÍNH SÁCH MẬT KHẨU

## 7.1 Mục tiêu

Cấu hình Password Policy bắt buộc toàn bộ user đặt mật khẩu đủ mạnh.

## 7.2 Lý thuyết — Tại sao cần Password Policy?

Thực tế cho thấy: **70% tài khoản email bị hack là do mật khẩu yếu**. Nếu không có policy → nhân viên sẽ đặt mật khẩu `123456` hay `password`. Việc của Admin là ép buộc họ đặt mật khẩu đủ mạnh bằng cơ chế hệ thống.

## 7.3 Cấu hình qua GUI

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

```
Admin Console
→ Configure (menu trái)
→ Class of Service
→ Click vào "default" (CoS mặc định áp dụng cho tất cả user)
→ Tab: Advanced
→ Tìm phần: Password
```

### Giá trị đề xuất cho doanh nghiệp

| Cài đặt | Giá trị đề xuất | Giải thích |
|---------|----------------|-----------|
| Minimum Password Length | **8** | Tối thiểu 8 ký tự |
| Maximum Password Length | **64** | Không giới hạn cứng |
| Minimum Upper Case | **1** | Ít nhất 1 chữ HOA |
| Minimum Lower Case | **1** | Ít nhất 1 chữ thường |
| Minimum Numeric Characters | **1** | Ít nhất 1 con số |
| Minimum Punctuation Characters | **1** | Ít nhất 1 ký tự đặc biệt |
| Password Duration (Days) | **90** | Bắt đổi mật khẩu mỗi 90 ngày |
| Minimum Password Age (Days) | **1** | Không đổi liên tục trong ngày |
| Enforce Password History | **5** | Không được dùng lại 5 mật khẩu cũ |

```
Sau khi điền xong các giá trị:
→ Click [Save] (góc trên phải)
→ Thấy thông báo "Class of Service saved" = thành công
```

## 7.4 Kiểm tra policy hoạt động

```
1. Đăng nhập WorldClient bằng user01@lab.local
2. Thử đổi mật khẩu thành "123" (quá ngắn)
3. Zimbra phải từ chối và hiển thị lỗi mô tả yêu cầu
```

## ✅ Checklist Chương 7

- [ ] Password Policy đã cấu hình trong CoS "default"
- [ ] Minimum Length = 8, có yêu cầu Uppercase + Number + Special
- [ ] Test thử đặt mật khẩu yếu → hệ thống từ chối

---

# CHƯƠNG 8. THIẾT LẬP CHỮ KÝ EMAIL

## 8.1 Mục tiêu

Tạo chữ ký email (Signature) tự động xuất hiện ở cuối mỗi email gửi đi.

## 8.2 Lý thuyết — Signature dùng để làm gì?

Chữ ký email = "Danh thiếp điện tử". Mỗi email gửi đi đều có thông tin liên hệ đầy đủ, tạo tính chuyên nghiệp cho doanh nghiệp.

## 8.3 Tạo Signature cho user01

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (WorldClient — đăng nhập bằng user01)**

### Cách 1: User tự tạo signature

```
WorldClient (đăng nhập user01@lab.local)
→ Click biểu tượng [Settings/Cài đặt] (góc trên phải — hình bánh răng)
→ Preferences
→ Signatures (menu trái)
→ Click [New Signature]
→ Điền:
   ┌────────────────────────────────────────────────┐
   │ Signature Name: Chữ ký chính                   │
   │                                                │
   │ [Text editor — nhập nội dung bên dưới]         │
   │                                                │
   │ --                                             │
   │ Nguyen Van A                                   │
   │ System Administrator                           │
   │ Lab Company                                    │
   │ Email: user01@lab.local                        │
   │ Tel: +84 xxx xxx xxx                           │
   └────────────────────────────────────────────────┘
→ Click [Save]

Gắn signature vào email:
→ Preferences → Accounts
→ Tại "Primary Account"
→ Signature: chọn "Chữ ký chính"
→ [Save]
```

### Cách 2: Admin tạo signature cho tất cả user (Enterprise)

```
Admin Console
→ Configure → Class of Service → default
→ Tab: General Information
→ Tìm phần Zimlets hoặc Global Settings
→ (Tính năng này cần Zimlet hoặc config zmprov)
```

**Qua CLI trên VM2:**

```bash
# Thực hiện trên: VM2 – 172.16.16.239
su - zimbra

# Tạo signature cho user01 qua CLI
zmprov modifyAccount user01@lab.local \
  zimbraPrefMailSignature "-- \nNguyen Van A\nSystem Administrator\nEmail: user01@lab.local"

# Đặt signature mặc định tự động thêm khi compose mail
zmprov modifyAccount user01@lab.local \
  zimbraPrefMailSignatureEnabled TRUE
```

## 8.4 Kiểm tra kết quả

```
WorldClient (user01@lab.local)
→ Click [Compose] (Soạn thư mới)
→ Cuối khung soạn thảo phải thấy chữ ký xuất hiện tự động
```

## ✅ Checklist Chương 8

- [ ] Tạo signature cho user01 thành công
- [ ] Signature xuất hiện tự động khi compose email mới
- [ ] Signature hiển thị đúng thông tin (tên, chức vụ, email)

---

# CHƯƠNG 9. FORWARD EMAIL

## 9.1 Mục tiêu

Cấu hình user01@lab.local tự động chuyển tiếp email đến user02@lab.local.

## 9.2 Lý thuyết — Forward dùng khi nào?

**Tình huống thực tế:**
- Nhân viên đi nghỉ phép → forward mail về cho người thay thế
- Địa chỉ chung `info@congty.vn` → forward về email cá nhân của nhân viên trực

## 9.3 Cấu hình Forward qua GUI (cách nhanh nhất)

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (WorldClient — đăng nhập user01)**

```
WorldClient (user01@lab.local)
→ Settings (bánh răng góc trên phải)
→ Preferences
→ Mail (menu trái)
→ Tìm phần: "Receiving Messages"
→ Forward a copy to: user02@lab.local
→ Tick ô: "Don't keep a local copy of messages" (tuỳ chọn)
→ Click [Save]
```

## 9.4 Cấu hình Forward qua Admin Console (Admin thay người dùng)

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click đúp vào user01@lab.local
→ Tab: Features
→ Tìm: "Mail forwarding"
   ┌──────────────────────────────────────────────┐
   │ Forward to: user02@lab.local                 │
   │ ☑ Keep a local copy                          │
   └──────────────────────────────────────────────┘
→ Click [Save]
```

## 9.5 Kiểm tra Forward hoạt động

```
1. Đăng nhập WorldClient bằng admin@lab.local
2. Compose email mới:
   To: user01@lab.local
   Subject: Test Forward
   Body: Đây là email test forward
3. Click [Send]

4. Đăng nhập WorldClient bằng user02@lab.local
5. Kiểm tra Inbox → phải thấy email "Test Forward"
```

## ✅ Checklist Chương 9

- [ ] Forward user01 → user02 đã cấu hình
- [ ] Test gửi mail đến user01 → user02 nhận được
- [ ] Log `/opt/zimbra/log/mailbox.log` ghi nhận forward action

---

# CHƯƠNG 10. TÌM ID MAILBOX ACCOUNT

## 10.1 Mục tiêu

Tìm được Mailbox ID của một account — cần thiết cho Backup/Restore theo mailbox cụ thể.

## 10.2 Lý thuyết — Mailbox ID là gì?

Mỗi mailbox trong Zimbra được gán một **ID số** (ví dụ: `3`) hoặc **UUID** (chuỗi hex dài). ID này dùng để:
- Backup/Restore mailbox cụ thể
- Locate thư mục vật lý trên disk
- Troubleshoot khi mailbox bị lỗi

## 10.3 Tìm qua GUI — Admin Console

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click vào user01@lab.local
→ Tab: General Information
→ Xem phần: "Account ID" (UUID dạng hex)
   Ví dụ: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

## 10.4 Tìm qua CLI

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
su - zimbra

# Tìm Account ID (UUID)
zmprov ga user01@lab.local | grep zimbraId
```

**Output mong đợi:**
```
zimbraId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

```bash
# Tìm Mailbox ID (số)
zmmailbox -z -m user01@lab.local getMailboxInfo
```

**Output mong đợi:**
```
mailboxId: 3
accountId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

```bash
# Tìm vị trí thư mục mailbox trên disk
ls /opt/zimbra/store/0/
# Thư mục có tên là Mailbox ID
# Ví dụ: /opt/zimbra/store/0/3/  ← đây là mailbox của user01
```

## 10.5 Tìm Mailbox ID của tất cả user

```bash
# Liệt kê tất cả mailbox và ID
zmprov gaa lab.local | while read email; do
  id=$(zmmailbox -z -m $email getMailboxInfo 2>/dev/null | grep mailboxId | awk '{print $2}')
  echo "$email → Mailbox ID: $id"
done
```

**Output mong đợi:**
```
admin@lab.local → Mailbox ID: 1
user01@lab.local → Mailbox ID: 3
user02@lab.local → Mailbox ID: 4
```

## ✅ Checklist Chương 10

- [ ] Tìm được Account UUID của user01 qua GUI
- [ ] Tìm được Mailbox ID (số) của user01 qua CLI
- [ ] Biết vị trí thư mục mailbox trên disk

---

# CHƯƠNG 11. ĐỔI MẬT KHẨU ADMIN

## 11.1 Mục tiêu

Đổi mật khẩu Admin bằng cả GUI và CLI, biết khi nào dùng cách nào.

## 11.2 Cách 1 — GUI (Thông thường)

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click đúp vào admin@lab.local
→ Tab: General Information
→ Password: [nhập mật khẩu mới]
→ Confirm Password: [nhập lại]
→ Click [Save]
```

## 11.3 Cách 2 — CLI (Dùng khi mất mật khẩu / không vào được GUI)

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
su - zimbra

# Đổi mật khẩu admin qua CLI
zmprov sp admin@lab.local 'NewAdmin@2026!'

# Verify bằng cách thử đăng nhập
zmaccts | grep admin
```

## 11.4 So sánh 2 cách

| Tiêu chí | GUI | CLI |
|---------|-----|-----|
| Dễ sử dụng | ✅ Dễ | ❌ Cần biết lệnh |
| Dùng khi | Bình thường | Mất mật khẩu, không vào GUI được |
| Cần login GUI trước | ✅ Có | ❌ Không cần |
| Tốc độ | Chậm hơn | Nhanh hơn |
| Phù hợp với | Fresher | Senior Admin |

## ✅ Checklist Chương 11

- [ ] Đổi mật khẩu admin thành công qua GUI
- [ ] Đổi mật khẩu qua CLI bằng lệnh `zmprov sp`
- [ ] Đăng nhập lại thành công với mật khẩu mới

---

# CHƯƠNG 12. KIỂM TRA LOG GỬI NHẬN EMAIL

> ⭐ **Đây là kỹ năng quan trọng nhất của một Mail Admin**

## 12.1 Mục tiêu

Đọc và phân tích được log email để tìm nguyên nhân mail bị lỗi.

## 12.2 Lý thuyết — Tại sao phải đọc log?

Khi khách hàng báo "tôi không gửi/nhận được mail" → bạn KHÔNG thể đoán mò. Phải đọc log để biết chính xác:
- Mail có đến server chưa?
- Bị chặn ở bước nào?
- Lỗi gì? Do spam filter? Do DNS? Do full disk?

## 12.3 Các file log quan trọng

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Vị trí thư mục log của Zimbra
ls /opt/zimbra/log/

# Các file log quan trọng nhất:
/opt/zimbra/log/mailbox.log    # Zimbra mailbox service (lưu mail, tìm kiếm)
/opt/zimbra/log/mail.log       # Postfix MTA (gửi/nhận SMTP)
/opt/zimbra/log/clamd.log      # ClamAV antivirus
/var/log/mail.log              # System mail log (Ubuntu)
/var/log/syslog                # System log tổng hợp
```

## 12.4 Xem log realtime

```bash
# Xem log mail realtime (Ctrl+C để thoát)
su - zimbra
tail -f /opt/zimbra/log/mail.log

# Trong khi đang xem, gửi 1 email từ VM1 → quan sát log xuất hiện
```

## 12.5 Phân tích log — Ví dụ thực tế

### Kịch bản: user01 gửi mail cho user02

Khi gửi mail, log sẽ xuất hiện nhiều dòng. Dưới đây là phân tích chi tiết:

```
Jun 15 10:30:01 mail postfix/smtpd[1234]: connect from client.lab.local[172.16.16.237]
Jun 15 10:30:01 mail postfix/smtpd[1234]: A1B2C3D4E5F6: client=client.lab.local[172.16.16.237]
Jun 15 10:30:01 mail postfix/cleanup[1235]: A1B2C3D4E5F6: message-id=<abc123@lab.local>
Jun 15 10:30:01 mail postfix/qmgr[1236]: A1B2C3D4E5F6: from=<user01@lab.local>, size=1024, nrcpt=1 (queue active)
Jun 15 10:30:02 mail amavis[1237]: (12345-01) Passed CLEAN, <user01@lab.local> -> <user02@lab.local>, Message-ID: <abc123@lab.local>, mail_id: xyz789, Hits: -1.9, size: 1024, 823 ms
Jun 15 10:30:02 mail postfix/smtp[1238]: A1B2C3D4E5F6: to=<user02@lab.local>, relay=127.0.0.1[127.0.0.1]:10024, delay=0.8, status=sent (250 2.0.0 from MTA(smtp:[127.0.0.1]:10025))
Jun 15 10:30:02 mail postfix/qmgr[1236]: A1B2C3D4E5F6: removed
```

### Giải thích từng dòng

```
Dòng 1: postfix/smtpd → Postfix nhận kết nối từ client 172.16.16.237
         → ✅ Client kết nối được vào server

Dòng 2: A1B2C3D4E5F6 → Queue ID (mã định danh của email này)
         → Dùng Queue ID để trace toàn bộ hành trình của 1 email

Dòng 3: cleanup → Email được làm sạch header
         → message-id: ID duy nhất của email

Dòng 4: qmgr → Queue manager nhận email, cho vào hàng đợi xử lý
         → from: người gửi, size: kích thước, nrcpt: số người nhận

Dòng 5: amavis → Amavis filter kiểm tra xong
         → "Passed CLEAN" = email sạch, không spam, không virus
         → Hits: -1.9 = điểm spam rất thấp (âm = sạch)

Dòng 6: postfix/smtp → Postfix gửi email đến mailbox
         → status=sent = GỬI THÀNH CÔNG

Dòng 7: removed → Email đã xử lý xong, xóa khỏi queue
```

### Kịch bản: Mail bị từ chối (Reject)

```
Jun 15 10:35:01 mail postfix/smtpd[1240]: NOQUEUE: reject: RCPT from unknown[1.2.3.4]:
  554 5.7.1 <spam@hacker.com>: Relay access denied
```

```
Phân tích:
→ NOQUEUE: Email bị chặn TRƯỚC khi vào queue
→ reject: Từ chối
→ Relay access denied: Server từ chối relay mail
→ Nguyên nhân: IP 1.2.3.4 không được phép gửi mail qua server này
→ Đây là bảo mật bình thường — không phải lỗi
```

### Kịch bản: Mail bị spam filter chặn

```
Jun 15 10:40:01 mail amavis[1245]: (12350-01) Blocked SPAM,
  <sender@external.com> -> <user01@lab.local>,
  Message-ID: <spam123@external.com>,
  Hits: 8.5,
  tag_level: 3.0, tag2_level: 6.0, kill_level: 6.9
```

```
Phân tích:
→ Blocked SPAM: Email bị chặn vì spam
→ Hits: 8.5 = điểm spam cao (> kill_level 6.9)
→ tag_level 3.0: điểm để đánh dấu [SPAM] vào subject
→ tag2_level 6.0: điểm để cảnh báo
→ kill_level 6.9: vượt ngưỡng này → chặn luôn
→ Hành động: Mail bị chuyển vào Junk/Spam folder
```

## 12.6 Lệnh tra cứu log hữu ích

```bash
# Thực hiện trên: VM2 – 172.16.16.239
su - zimbra

# Tìm tất cả log liên quan đến 1 email bằng Queue ID
grep "A1B2C3D4E5F6" /opt/zimbra/log/mail.log

# Tìm log theo địa chỉ email
grep "user01@lab.local" /opt/zimbra/log/mail.log | tail -20

# Tìm email bị reject trong 1 giờ gần nhất
grep "reject" /opt/zimbra/log/mail.log | tail -50

# Đếm số email được gửi trong ngày
grep "status=sent" /opt/zimbra/log/mail.log | wc -l

# Xem mail queue đang kẹt
postqueue -p

# Xóa toàn bộ mail queue (cẩn thận!)
postsuper -d ALL
```

## 12.7 Xem log qua Admin Console GUI

```
Admin Console
→ Monitor (menu trái)
→ Mail Queue
→ Thấy danh sách email đang chờ xử lý
→ Click vào từng email để xem chi tiết lý do kẹt
```

## ✅ Checklist Chương 12

- [ ] Biết vị trí file log: `/opt/zimbra/log/mail.log`
- [ ] Đọc được Queue ID từ log và trace toàn bộ hành trình email
- [ ] Phân biệt được "sent" (thành công) và "reject" (bị chặn)
- [ ] Biết điểm spam (Hits) cao/thấp có ý nghĩa gì
- [ ] Dùng được `postqueue -p` để xem mail queue

---

# CHƯƠNG 13. THAY ĐỔI LOGO ZIMBRA

## 13.1 Mục tiêu

Thay thế logo mặc định của Zimbra bằng logo của công ty.

## 13.2 Lý thuyết

Zimbra không hỗ trợ thay logo qua GUI Admin Console. Phải thay file trực tiếp trên server và clear cache.

## 13.3 Thực hiện qua CLI

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Tìm vị trí file logo
find /opt/zimbra -name "*.gif" -o -name "*.png" | grep -i logo | head -20

# Logo chính của webmail nằm tại:
ls /opt/zimbra/jetty/webapps/zimbra/img/
# Hoặc
ls /opt/zimbra/web/img/

# File logo thường dùng:
# LoginBanner.png — Logo trang đăng nhập
# AppBanner.png   — Logo trong giao diện webmail
```

```bash
# Backup logo gốc trước khi thay
cp /opt/zimbra/jetty/webapps/zimbra/img/logo.png \
   /opt/zimbra/jetty/webapps/zimbra/img/logo.png.bak

# Upload logo mới (từ VM1 sang VM2)
# Trên VM1:
scp /path/to/your-logo.png root@172.16.16.239:/tmp/company-logo.png

# Trên VM2 — copy vào đúng vị trí
cp /tmp/company-logo.png /opt/zimbra/jetty/webapps/zimbra/img/logo.png
chown zimbra:zimbra /opt/zimbra/jetty/webapps/zimbra/img/logo.png
```

```bash
# Dùng zmprov để thay logo (cách chính thức)
su - zimbra

# Thay logo trang đăng nhập
zmprov md lab.local zimbraSkinLogoURL /logos/company-logo.png

# Thay logo trong giao diện (AppBanner)
zmprov md lab.local zimbraSkinLogoAppBanner /logos/app-banner.png

# Clear cache để áp dụng
zmmailboxdctl restart
```

## 13.4 Kiểm tra kết quả

```
1. Trên VM1, mở trình duyệt
2. Truy cập https://172.16.16.239
3. Trang đăng nhập phải hiển thị logo mới
4. Nếu còn thấy logo cũ: Nhấn Ctrl+Shift+R (Hard refresh)
```

## ✅ Checklist Chương 13

- [ ] Backup logo gốc trước khi thay
- [ ] Copy logo mới vào đúng đường dẫn
- [ ] Clear cache và verify logo mới xuất hiện

---

# CHƯƠNG 14. THAY ĐỔI TITLE WEB ZIMBRA

## 14.1 Mục tiêu

Đổi tiêu đề tab trình duyệt từ "Zimbra Collaboration Suite" thành tên riêng của công ty.

## 14.2 Thực hiện

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
su - zimbra

# Xem title hiện tại
zmprov gd lab.local | grep zimbraSkinLogoLoginBanner

# Đổi title trang đăng nhập
zmprov md lab.local zimbraSkinLogoLoginBanner "LAB MAIL SERVER"

# Đổi title trong App (sau khi đăng nhập)
zmprov md lab.local zimbraSkinLogoAppBanner "LAB MAIL SERVER"

# Đổi title tab trình duyệt (product name)
zmprov mcf zimbraProductName "LAB MAIL SERVER"

# Restart để áp dụng
zmmailboxdctl restart
```

## 14.3 Kiểm tra

```
1. Truy cập https://172.16.16.239
2. Tab trình duyệt phải hiển thị: "LAB MAIL SERVER"
3. Trang đăng nhập: header phải hiển thị "LAB MAIL SERVER"
```

## ✅ Checklist Chương 14

- [ ] Title tab đã đổi thành "LAB MAIL SERVER"
- [ ] Title trang đăng nhập đã đổi
- [ ] Verify trên trình duyệt sau khi hard refresh

---

# CHƯƠNG 15. QUẢN LÝ QUOTA MAILBOX

## 15.1 Mục tiêu

Thiết lập giới hạn dung lượng hộp thư cho từng user và toàn domain.

## 15.2 Lý thuyết — Quota là gì?

**Quota** = Hạn mức dung lượng. Nếu không có quota → 1 user có thể dùng hết toàn bộ disk của server, ảnh hưởng tất cả user khác.

```
Thực tế doanh nghiệp thường phân chia:
- Nhân viên thường:  1 GB
- Trưởng phòng:      2 GB
- Giám đốc/VIP:      5 GB hoặc không giới hạn
```

## 15.3 Cấu hình Quota qua GUI

### Cách 1: Quota mặc định cho toàn bộ domain

> 🖥️ **Thực hiện trên: VM1 – 172.16.16.237 (Admin Console)**

```
Admin Console
→ Configure → Class of Service → default
→ Tab: General Information
→ Tìm: "Storage"
→ Mailbox Quota: 1073741824 (= 1 GB tính bằng bytes)
  ┌─────────────────────────────────────────────────────┐
  │  Bảng quy đổi:                                      │
  │  1 GB  = 1,073,741,824 bytes                        │
  │  2 GB  = 2,147,483,648 bytes                        │
  │  5 GB  = 5,368,709,120 bytes                        │
  │  0     = Không giới hạn (unlimited)                 │
  └─────────────────────────────────────────────────────┘
→ Click [Save]
```

### Cách 2: Quota riêng cho từng user

```
Admin Console
→ Manage → Accounts
→ Click đúp vào user01@lab.local
→ Tab: General Information
→ Mailbox Quota: 2147483648  (2 GB riêng cho user này)
→ Click [Save]
```

> 📌 **Lưu ý:** Quota cấu hình riêng tại Account sẽ **ghi đè** quota của CoS.

## 15.4 Cấu hình Quota qua CLI

```bash
# Thực hiện trên: VM2 – 172.16.16.239
su - zimbra

# Đặt quota 1GB cho user01
zmprov ma user01@lab.local zimbraMailQuota 1073741824

# Đặt quota 2GB cho user02
zmprov ma user02@lab.local zimbraMailQuota 2147483648

# Đặt unlimited quota
zmprov ma admin@lab.local zimbraMailQuota 0
```

## 15.5 Kiểm tra Quota đang dùng

```bash
# Xem quota và dung lượng đang dùng của tất cả user
zmprov gqu lab.local

# Output mẫu:
# user01@lab.local  1073741824  102400000
#   ↑ account        ↑ quota(B)  ↑ used(B)
```

**Qua GUI:**
```
Admin Console
→ Manage → Accounts
→ Xem cột "Mailbox Size" và "Mailbox Quota" trong danh sách
```

## 15.6 Cảnh báo Quota

Khi user dùng gần đầy, Zimbra tự động gửi warning email:
- **75%**: Cảnh báo đầu tiên
- **90%**: Cảnh báo khẩn cấp
- **100%**: Không nhận được mail mới, gửi lại bounce cho người gửi

## ✅ Checklist Chương 15

- [ ] Đặt quota 1GB cho user01 qua GUI
- [ ] Đặt quota 2GB cho user02 qua CLI
- [ ] Admin có quota unlimited
- [ ] Kiểm tra quota đang dùng bằng `zmprov gqu`

---

# CHƯƠNG 16. BACKUP EMAIL

## 16.1 Mục tiêu

Thực hiện được Backup toàn bộ mailbox và từng user riêng lẻ.

## 16.2 Lý thuyết — Tại sao Backup quan trọng?

> 💡 **Quy tắc 3-2-1:** 3 bản copy, 2 loại media khác nhau, 1 bản offsite (ngoài site).

Trường hợp cần Backup:
- Trước khi nâng cấp Zimbra version
- Trước khi migrate sang server mới
- Backup định kỳ hàng ngày theo policy công ty
- Khi user yêu cầu khôi phục email đã xóa

## 16.3 Backup Full qua CLI

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
su - zimbra

# Tạo thư mục backup
mkdir -p /backup/zimbra/full

# Backup Full toàn bộ (có thể mất nhiều giờ với data lớn)
zmbackup -f -a all -t /backup/zimbra/full

# Giải thích tham số:
# -f  = full backup
# -a all = tất cả accounts
# -t  = target directory
```

**Xem tiến trình backup:**
```bash
# Theo dõi log backup
tail -f /opt/zimbra/log/zmmailboxd.out

# Hoặc xem thông qua GUI
Admin Console → Tools → Backup → Status
```

## 16.4 Backup từng User riêng lẻ

```bash
# Backup chỉ user01
zmbackup -f -a user01@lab.local -t /backup/zimbra/user01

# Backup nhiều user
zmbackup -f -a user01@lab.local,user02@lab.local -t /backup/zimbra/users
```

## 16.5 Backup theo dạng Export TGZ (Portable)

```bash
# Export mailbox user01 ra file .tgz
zmmailbox -z -m user01@lab.local getRestURL "//?fmt=tgz" > \
  /backup/zimbra/user01_$(date +%Y%m%d).tgz

# Verify file backup
ls -lh /backup/zimbra/user01_$(date +%Y%m%d).tgz
```

## 16.6 Backup định kỳ tự động

```bash
# Tạo script backup
cat > /usr/local/bin/zimbra_backup.sh << 'SCRIPT'
#!/bin/bash
BACKUP_DIR="/backup/zimbra"
DATE=$(date +%Y%m%d_%H%M)
LOG="/var/log/zimbra_backup.log"

echo "[$DATE] Bắt đầu backup..." >> $LOG
su - zimbra -c "zmbackup -f -a all -t $BACKUP_DIR/full_$DATE" >> $LOG 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] Backup thành công!" >> $LOG
else
    echo "[$DATE] BACKUP THẤT BẠI — kiểm tra log!" >> $LOG
fi

# Xóa backup cũ hơn 7 ngày
find $BACKUP_DIR -name "full_*" -mtime +7 -exec rm -rf {} \;
SCRIPT

chmod +x /usr/local/bin/zimbra_backup.sh

# Thêm cron job chạy lúc 2:00 AM hàng ngày
echo "0 2 * * * root /usr/local/bin/zimbra_backup.sh" \
  >> /etc/cron.d/zimbra-backup
```

## ✅ Checklist Chương 16

- [ ] Backup full thành công với `zmbackup -f -a all`
- [ ] Backup từng user thành công
- [ ] Export mailbox ra file .tgz
- [ ] Cron job tự động backup đã cấu hình
- [ ] File backup tồn tại trong `/backup/zimbra/`

---

# CHƯƠNG 17. RESTORE EMAIL

## 17.1 Mục tiêu

Khôi phục thành công mailbox từ file backup.

## 17.2 Các tình huống Restore

| Tình huống | Phương pháp |
|-----------|-----------|
| Restore toàn bộ sau disaster | `zmrestore -f -a all` |
| Restore 1 user bị xóa nhầm | `zmrestore -f -a user@domain` |
| Restore email bị xóa trong mailbox | Import TGZ vào mailbox hiện tại |

## 17.3 Restore từng User

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
su - zimbra

# Restore user01 từ backup gần nhất
zmrestore -f -a user01@lab.local -t /backup/zimbra/full_20260615_0200

# Tham số:
# -f = restore full
# -a = account cần restore
# -t = thư mục backup nguồn
```

## 17.4 Import TGZ vào Mailbox hiện tại

Dùng khi: User xóa nhầm folder, muốn khôi phục lại

```bash
# Import file TGZ backup vào mailbox user01
zmmailbox -z -m user01@lab.local postRestURL "//?fmt=tgz&resolve=skip" \
  @/backup/zimbra/user01_20260615.tgz

# Tham số resolve:
# skip    = bỏ qua nếu đã tồn tại
# replace = thay thế nếu đã tồn tại
# reset   = xóa hết trước rồi import lại
```

## 17.5 Kiểm tra sau Restore

```bash
# Kiểm tra số lượng email trong mailbox user01
zmmailbox -z -m user01@lab.local getMailboxStats
```

**Output mong đợi:**
```
NumMessages: 25
NumUnread: 3
MailboxSize: 15728640
```

**Kiểm tra qua WorldClient:**
```
1. Đăng nhập WorldClient bằng user01@lab.local
2. Kiểm tra Inbox, Sent, các folder khác
3. Xác nhận email đã được khôi phục đúng
```

## ✅ Checklist Chương 17

- [ ] Restore thành công mailbox user01 từ backup
- [ ] Import TGZ vào mailbox hiện tại
- [ ] Verify email đã restore bằng WorldClient

---

# CHƯƠNG 18. CHUYỂN DATA SANG SERVER KHÁC

## 18.1 Mục tiêu

Biết cách migrate toàn bộ data Zimbra từ server cũ (VM2) sang server mới.

## 18.2 Sơ đồ Migration

```
  MAIL SERVER A (cũ)           MAIL SERVER B (mới)
  VM2: 172.16.16.239           VM3: 172.16.16.240 (giả lập)
  mail.lab.local               mail-new.lab.local

  /opt/zimbra/store/           /opt/zimbra/store/
  /opt/zimbra/db/              /opt/zimbra/db/
  /opt/zimbra/conf/            /opt/zimbra/conf/

       │                              ▲
       │   Phương pháp 1: rsync       │
       └──────────────────────────────┘
       │   Phương pháp 2: backup/restore
       └──────────────────────────────┘
       │   Phương pháp 3: export/import
       └──────────────────────────────┘
```

## 18.3 Phương pháp 1 — rsync (Nhanh nhất)

> 💻 **Thực hiện trên: VM2 – 172.16.16.239**

```bash
# Dừng Zimbra trên server cũ để đảm bảo data nhất quán
su - zimbra -c "zmcontrol stop"

# rsync toàn bộ thư mục Zimbra sang server mới
rsync -avz --progress \
  /opt/zimbra/ \
  root@172.16.16.240:/opt/zimbra/

# Sau khi rsync xong, start lại Zimbra cũ (nếu cần tiếp tục dùng)
su - zimbra -c "zmcontrol start"
```

**Ưu điểm rsync:**
- Nhanh (chỉ copy những file thay đổi nếu chạy lần 2)
- Đơn giản
- Hỗ trợ incremental sync

**Nhược điểm:**
- Phải dừng Zimbra để đảm bảo consistency
- Nếu server mới khác version Zimbra → có thể lỗi

## 18.4 Phương pháp 2 — Backup/Restore

```bash
# Trên VM2 — Backup toàn bộ
su - zimbra
zmbackup -f -a all -t /backup/zimbra/migration

# Copy backup sang server mới
rsync -avz /backup/zimbra/migration/ root@172.16.16.240:/backup/zimbra/migration/

# Trên VM3 (server mới) — Restore
su - zimbra
zmrestore -f -a all -t /backup/zimbra/migration
```

## 18.5 Phương pháp 3 — Export/Import từng User

```bash
# Trên VM2 — Export tất cả user
su - zimbra
for user in $(zmprov gaa lab.local); do
    zmmailbox -z -m $user getRestURL "//?fmt=tgz" > \
      /backup/export/${user}.tgz
    echo "Exported: $user"
done

# Copy sang VM3
scp /backup/export/*.tgz root@172.16.16.240:/backup/import/

# Trên VM3 — Import từng user
for file in /backup/import/*.tgz; do
    user=$(basename $file .tgz)
    zmmailbox -z -m $user postRestURL "//?fmt=tgz" @$file
    echo "Imported: $user"
done
```

## 18.6 So sánh 3 phương pháp

| Tiêu chí | rsync | Backup/Restore | Export/Import |
|---------|-------|----------------|---------------|
| Tốc độ | ⭐⭐⭐ Nhanh nhất | ⭐⭐ Trung bình | ⭐ Chậm |
| Downtime | Cần stop Zimbra | Không cần (khi restore) | Không cần |
| Cross-version | ❌ Không tốt | ❌ Cần cùng version | ✅ Tốt |
| Phức tạp | ⭐ Đơn giản | ⭐⭐ Trung bình | ⭐⭐⭐ Phức tạp |
| Phù hợp khi | Cùng version, khẩn cấp | Cùng version, có kế hoạch | Khác version |

## ✅ Checklist Chương 18

- [ ] Hiểu 3 phương pháp migration
- [ ] Biết dùng rsync để copy data
- [ ] Biết export/import từng user bằng TGZ

---

# CHƯƠNG 19. TROUBLESHOOTING

## 19.1 Mục tiêu

Xử lý được các lỗi phổ biến nhất khi vận hành Zimbra.

## 19.2 Sơ đồ tư duy Troubleshoot

```
Khách hàng báo lỗi email
         │
         ├─► Không GỬI được mail?
         │         │
         │         ├─► Check: zmcontrol status (mta running?)
         │         ├─► Check: postqueue -p (queue kẹt?)
         │         ├─► Check: mail.log (lỗi gì?)
         │         └─► Check: DNS MX record đúng chưa?
         │
         ├─► Không NHẬN được mail?
         │         │
         │         ├─► Check: Port 25 có mở không?
         │         ├─► Check: /etc/hosts cấu hình đúng?
         │         ├─► Check: Spam filter có block không?
         │         └─► Check: Quota có đầy không?
         │
         ├─► Không vào được Webmail?
         │         │
         │         ├─► Check: zmcontrol status (mailbox/proxy running?)
         │         ├─► Check: Port 443/80 có listen không?
         │         └─► Check: SSL cert có hết hạn không?
         │
         └─► Service bị dừng?
                   │
                   ├─► zmcontrol start <service>
                   └─► xem log tại /opt/zimbra/log/
```

## 19.3 Lỗi 1 — Không gửi mail được

**Triệu chứng:** User gửi mail → thư mục Sent không có, hoặc nhận được bounce

```bash
# Bước 1: Kiểm tra MTA service
su - zimbra
zmcontrol status | grep mta

# Nếu MTA Stopped → khởi động lại
zmcontrol start mta

# Bước 2: Kiểm tra mail queue
postqueue -p

# Nếu thấy mail kẹt trong queue → xem lý do
postqueue -p | head -20

# Bước 3: Xem log lỗi cụ thể
grep "status=deferred\|status=bounced" /opt/zimbra/log/mail.log | tail -20

# Bước 4: Thử gửi test mail từ CLI
echo "Test từ CLI" | sendmail user02@lab.local
```

## 19.4 Lỗi 2 — Không nhận mail được

**Triệu chứng:** Người ngoài gửi mail vào → không thấy trong Inbox

```bash
# Bước 1: Kiểm tra port 25 có mở không
nc -zv 172.16.16.239 25

# Bước 2: Kiểm tra firewall
ufw status | grep 25

# Bước 3: Telnet test SMTP
telnet 172.16.16.239 25
# Phải thấy: 220 mail.lab.local ESMTP Postfix

# Bước 4: Kiểm tra log nhận mail
grep "status=delivered" /opt/zimbra/log/mail.log | tail -10

# Bước 5: Kiểm tra spam filter có block nhầm không
grep "Blocked SPAM" /opt/zimbra/log/mail.log | tail -10
# Nếu thấy → mail bị vào Junk, check folder Spam của user
```

## 19.5 Lỗi 3 — Service stopped (không khởi động được)

```bash
su - zimbra

# Xem toàn bộ trạng thái
zmcontrol status

# Khởi động lại tất cả
zmcontrol stop
sleep 10
zmcontrol start

# Nếu vẫn lỗi → xem log từng service
tail -100 /opt/zimbra/log/mailbox.log | grep -i error
tail -100 /opt/zimbra/log/clamd.log | grep -i error

# Restart từng service riêng lẻ
zmmtactl restart        # Restart MTA (Postfix)
zmamavisdctl restart    # Restart Amavis
zmlocalconfig           # Kiểm tra cấu hình local
```

## 19.6 Lỗi 4 — DNS lỗi / hostname không resolve

```bash
# Kiểm tra hostname
hostname -f   # Phải trả về: mail.lab.local

# Kiểm tra /etc/hosts
grep "172.16.16.239" /etc/hosts

# Kiểm tra resolve
nslookup mail.lab.local
dig MX lab.local

# Nếu sai → sửa /etc/hosts và restart Zimbra
nano /etc/hosts
su - zimbra -c "zmcontrol restart"
```

## 19.7 Lỗi 5 — Mail queue bị kẹt

```bash
su - zimbra

# Xem queue
postqueue -p

# Thử gửi lại tất cả mail trong queue
postqueue -f

# Xóa 1 email cụ thể trong queue
postsuper -d <QUEUE_ID>

# Xóa toàn bộ queue (cẩn thận!)
postsuper -d ALL

# Xem lý do kẹt của 1 email cụ thể
postcat -q <QUEUE_ID>
```

## 19.8 Lỗi 6 — SSL Certificate lỗi / hết hạn

```bash
su - zimbra

# Xem thông tin cert hiện tại
zmcertmgr viewdeployedcrt

# Kiểm tra ngày hết hạn
openssl x509 -in /opt/zimbra/ssl/zimbra/public/zimbra.crt -noout -dates

# Tạo và deploy self-signed cert mới
zmcertmgr createca -new
zmcertmgr createcrt -new -days 3650
zmcertmgr deploycrt self
zmcertmgr deployca
zmmailboxdctl restart
```

## ✅ Checklist Chương 19

- [ ] Biết quy trình kiểm tra khi không gửi được mail
- [ ] Biết quy trình kiểm tra khi không nhận được mail
- [ ] Xử lý được service stopped
- [ ] Biết xem và xóa mail queue
- [ ] Biết renew SSL certificate

---

# CHƯƠNG 20. TỔNG KẾT

## 20.1 Tổng kết kiến thức đã học

```
┌─────────────────────────────────────────────────────────┐
│              TOÀN BỘ KIẾN THỨC ZIMBRA LAB               │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │               MAIL FLOW                         │    │
│  │                                                 │    │
│  │  Internet → Postfix(25) → Amavis → Mailbox      │    │
│  │  User → WebClient → Proxy → Mailbox             │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐   │
│  │     USER     │  │   SECURITY   │  │   BACKUP    │   │
│  │ MANAGEMENT   │  │              │  │  & RESTORE  │   │
│  │              │  │ • Password   │  │             │   │
│  │ • Accounts   │  │   Policy     │  │ • zmbackup  │   │
│  │ • Groups     │  │ • Quota      │  │ • zmrestore │   │
│  │ • Aliases    │  │ • Spam Filter│  │ • TGZ       │   │
│  │ • Signature  │  │ • Antivirus  │  │ • rsync     │   │
│  │ • Forward    │  │              │  │             │   │
│  └──────────────┘  └──────────────┘  └─────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │           TROUBLESHOOTING                       │    │
│  │                                                 │    │
│  │  1. Check zmcontrol status                      │    │
│  │  2. Check mail.log                              │    │
│  │  3. Check postqueue -p                          │    │
│  │  4. Check DNS (hostname -f)                     │    │
│  │  5. Check port (ss -tlnp)                       │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## 20.2 Bảng lệnh CLI cần nhớ

| Lệnh | Chức năng |
|------|-----------|
| `zmcontrol status` | Xem trạng thái tất cả service |
| `zmcontrol start/stop/restart` | Điều khiển service |
| `zmprov gaa lab.local` | Liệt kê tất cả account |
| `zmprov ga user@domain` | Xem thông tin account |
| `zmprov ma user@domain attr value` | Sửa thuộc tính account |
| `zmprov sp user@domain 'password'` | Đổi mật khẩu |
| `zmmailbox -z -m user@domain` | Thao tác mailbox |
| `zmbackup -f -a all -t /path` | Backup toàn bộ |
| `zmrestore -f -a all -t /path` | Restore toàn bộ |
| `postqueue -p` | Xem mail queue |
| `postqueue -f` | Flush mail queue |
| `tail -f /opt/zimbra/log/mail.log` | Xem log realtime |

## 20.3 Checklist Nghiệm thu LAB

### Mức Cơ bản (Bắt buộc PASS)

- [ ] Cài đặt Zimbra thành công, `zmcontrol status` tất cả Running
- [ ] Tạo được user01, user02
- [ ] Gửi/nhận mail được giữa user01 và user02
- [ ] Đăng nhập được WorldClient và Admin Console

### Mức Trung bình

- [ ] Cấu hình được Password Policy
- [ ] Tạo được Signature, Distribution List, Alias
- [ ] Thiết lập Forward email
- [ ] Biết đọc mail.log và phân tích 1 email hoàn chỉnh

### Mức Nâng cao

- [ ] Backup và Restore thành công
- [ ] Quản lý Quota cho từng user
- [ ] Xử lý được mail queue bị kẹt
- [ ] Troubleshoot được ít nhất 3 lỗi phổ biến
- [ ] Thay đổi được Logo và Title Zimbra

## 20.4 Lời khuyên từ Senior

> 💡 **Skill quan trọng nhất không phải là cài Zimbra — mà là ĐỌC LOG.**
>
> Khi gặp lỗi, 90% trường hợp log sẽ cho bạn biết chính xác vấn đề là gì. Hãy luyện tập đọc `/opt/zimbra/log/mail.log` mỗi ngày cho đến khi bạn đọc log nhanh như đọc báo.

> 💡 **Luôn backup trước khi làm bất cứ điều gì.**
>
> Trên Production, quy tắc số 1 là: Backup → Test trên Lab → Áp dụng Production. Không bao giờ test trực tiếp trên Production.

---

## PHỤ LỤC — Quick Reference

### Vị trí file quan trọng

```
/opt/zimbra/                    # Thư mục gốc Zimbra
/opt/zimbra/log/mail.log        # Log MTA (Postfix)
/opt/zimbra/log/mailbox.log     # Log Zimbra mailbox
/opt/zimbra/store/              # Nơi lưu email vật lý
/opt/zimbra/conf/localconfig.xml # Cấu hình local
/opt/zimbra/ssl/zimbra/         # SSL certificates
/etc/hosts                      # Quan trọng cho hostname resolution
```

### URL quan trọng

| URL | Dùng để |
|-----|---------|
| `https://172.16.16.239:7071` | Admin Console |
| `https://172.16.16.239` | WorldClient (Webmail) |
| `http://172.16.16.239:7780` | Webmail HTTP |

### Tài liệu tham khảo

- Zimbra Wiki: https://wiki.zimbra.com
- Zimbra Forums: https://forums.zimbra.org
- Zimbra Source: https://github.com/zimbra

---

*Tài liệu được biên soạn bởi Senior SysAdmin — Nhân Hòa*  
*Phiên bản: 1.0 | Ngày: 2026-06-15*  
*Dành cho: Fresher / System Admin Intern*
