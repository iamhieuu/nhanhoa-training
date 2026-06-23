## Triển khai và Quản trị Zimbra Collaboration Suite trên Ubuntu 22.04

> **Phiên bản Zimbra:** Zimbra OSE (Open Source Edition) 10.x  
> **Hệ điều hành:** Ubuntu Server 22.04 LTS  
5

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
                    │   IP:           │
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
                    │   IP: 192.168.136.131          │
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
| IP Address |  | 192.168.136.131 |
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

> ⚠️ **Toàn bộ chương này thực hiện trên VM2 — 192.168.136.131**

## 3.1 Mục tiêu

Cấu hình đúng hostname, hosts, DNS và các điều kiện tiên quyết để Zimbra installer không bị lỗi.

## 3.2 Lý thuyết — Tại sao phải chuẩn bị?

Zimbra installer rất **khắt khe** với DNS và hostname. Nếu hostname không resolve được → installer sẽ dừng lại và báo lỗi. Đây là nguyên nhân số 1 khiến người mới bị fail khi cài Zimbra.

> 💡 **Quy tắc vàng:** `hostname -f` phải trả về FQDN đúng trước khi chạy installer.

## 3.3 Bước 1 — Đặt Hostname

**Thực hiện trên: VM2 – 192.168.136.131**

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

**Thực hiện trên: VM2 – 192.168.136.131**

```bash
# Mở file hosts để chỉnh sửa
nano /etc/hosts
```

**Nội dung file /etc/hosts sau khi chỉnh sửa:**
```
127.0.0.1       localhost
192.168.136.131   mail.lab.local mail

# Client VM (để 2 máy nhận ra nhau)
   client.lab.local client
```

> ⚠️ **Lưu ý cực kỳ quan trọng:** KHÔNG để `127.0.1.1 mail.lab.local` — dòng này thường có sẵn và sẽ làm Zimbra installer bị lỗi. Xóa dòng đó đi nếu thấy.

```bash
# Kiểm tra sau khi sửa
ping -c 2 mail.lab.local
```


<img width="515" height="111" alt="image" src="https://github.com/user-attachments/assets/5bf938d6-7b61-4117-95f2-f9f1ae185d17" />

## 3.5 Bước 3 — Cấu hình DNS (dùng /etc/resolv.conf)

**Thực hiện trên: VM2 – 192.168.136.131**

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
DNS=192.168.136.131
FallbackDNS=8.8.8.8
Domains=mail.lab.local
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
Server:         192.168.136.131
Address:        192.168.136.131#53

Name:   mail.lab.local
Address: 192.168.136.131
```

## 3.6 Bước 4 — Cập nhật hệ thống và cài packages tiên quyết

**Thực hiện trên: VM2 – 192.168.136.131**

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

**Thực hiện trên: VM2 – 192.168.136.131**

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

**Thực hiện trên: VM2 – 192.168.136.131**

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

**Thực hiện trên: VM2 – 192.168.136.131**

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
- [ ] `/etc/hosts` có dòng `192.168.136.131 mail.lab.local mail`
- [ ] Không có dòng `127.0.1.1 mail.lab.local` trong hosts
- [ ] Port 25 không có process nào đang dùng
- [ ] AppArmor đã disabled
- [ ] Timezone là Asia/Ho_Chi_Minh
- [ ] RAM tối thiểu 4GB khả dụng
- [ ] Disk tối thiểu 20GB trống

---

# CHƯƠNG 4. CÀI ĐẶT ZIMBRA MAIL SERVER

> ⚠️ **Toàn bộ chương này thực hiện trên VM2 — 192.168.136.131**

## 4.1 Mục tiêu

Cài đặt thành công Zimbra OSE và khởi động được tất cả service.

## 4.2 Bước 1 — Download Zimbra

**Thực hiện trên: VM2 – 192.168.136.131**

```bash
cd /tmp

# Download Zimbra OSE cho Ubuntu 22.04
wget https://files.zimbra.com/downloads/10.1.0_GA/zcs-NETWORK-10.1.0_GA_4655.UBUNTU22_64.20240819064312.tgz

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
        +Admin user to create:                 admin@mail.lab.local
        +Admin password:                       set
   8) zimbra-spell:                            Enabled
   9) zimbra-proxy:                            Enabled
  10) Default Class of Service Configuration:
   s) Save config to file
   x) Expand menu
   q) Quit

Address unconfigured (**) items  (? - help) 
```

> 📌 **Kiểm tra:** Mục 7 phải hiển thị "Admin user to create: admin@mail.lab.local" và "Admin password: set". Nếu chưa, gõ số 7 để vào cấu hình.

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

> 🖥️ **Thực hiện trên: VM1 –  (mở trình duyệt)**

**URL truy cập:**
```
https://192.168.136.131:7071
```

> ⚠️ Trình duyệt sẽ cảnh báo SSL certificate không tin cậy (self-signed cert). Chọn **"Advanced" → "Proceed anyway"** để tiếp tục.

**Đăng nhập:**
```
Username: admin
Password: 123456a@
```
<img width="959" height="427" alt="image" src="https://github.com/user-attachments/assets/d09e69d8-ee0a-4dd7-9164-6ac4febeab96" />



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

> 🖥️ **Thực hiện trên: VM1 – **

**URL truy cập:**
```
https://192.168.136.131
# hoặc
https://mail.lab.local
```

**Đăng nhập:**
```
Username: admin@mail.lab.local
Password: [mật khẩu admin]
```

Giao diện WorldClient:
<img width="959" height="474" alt="image" src="https://github.com/user-attachments/assets/c8190791-0f2d-4e70-b546-eea5d10972da" />


-----

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

> 🖥️ **Thực hiện trên: VM1 –  (Admin Console)**

### Tạo admin@mail.lab.local (đã có sẵn)
Tài khoản này được tạo tự động khi cài. Kiểm tra tại:
```
Admin Console → Manage → Accounts
→ Thấy admin@mail.lab.local trong danh sách
```
<img width="951" height="212" alt="image" src="https://github.com/user-attachments/assets/eaf0776e-2aca-482a-b8e7-479d2fd1b49a" />

### Tạo iamhieu@mail.lab.local

```
Bước 1: Admin Console → Manage (menu trái) → Accounts
Bước 2: Click nút [New] (góc trên phải)
Bước 3: Điền thông tin:
         ┌─────────────────────────────────────┐
         │ Account Name:  iamhieu@mail.lab.local      │
         │ Last Name:     Nguyen                │
         │ First Name:    hieu                │
         │ Display Name:  Nguyen Thanh Hieu       │
         │ Password:      123456a@          │
         │ Confirm Pwd:   123456a@          │
         └─────────────────────────────────────┘
Bước 4: Click [Finish] để tạo
```

### Tạo hieu@mail.lab.local

Làm lại các bước trên với thông tin:
```
Account Name:  hieu@mail.lab.local
Last Name:     Nguyen
First Name:    Hiu
Display Name:  Nguyen Thanh Hieu
Password:      123456a@
```
<img width="959" height="214" alt="image" src="https://github.com/user-attachments/assets/638b860a-31f9-4a94-9b08-91d823768e50" />

## 6.4 Tạo Group (Distribution List)

> 📌 **Distribution List** = Danh sách gửi thư nhóm. Khi gửi mail đến `all@lab.local` → tất cả thành viên trong nhóm đều nhận được.

```
Admin Console → Manage → Distribution Lists → [New]
┌────────────────────────────────────────────────┐
│ Email: all@lab.local                           │
│ Display Name: All                              │
│                                                │
│ Tab Members → Add:                             │
│   admin@mail.lab.local                         │
│   iamhieu@mail.lab.local                       │
│   hieu@mail.lab.local                          │
└────────────────────────────────────────────────┘
Click [Finish]
```
<img width="959" height="199" alt="image" src="https://github.com/user-attachments/assets/1c7ea4b2-ac16-419c-b12a-f30114057d63" />

## 6.5 Tạo Alias (Bí danh)

> 📌 **Alias** = Địa chỉ bí danh. Ví dụ: mail gửi đến `deptraicute@mail.lab.local` sẽ được chuyển vào hộp thư `iamhieu@mail.lab.local`. Dùng khi bạn muốn có nhiều địa chỉ nhưng chỉ 1 hộp thư.

```
Admin Console → Manage → Aliases → [New]
┌────────────────────────────────────────────────┐
│ Alias: deptraicute@mail.lab.local              │
│ Account Target: iamhieu@mail.lab.local         │
└────────────────────────────────────────────────┘
Click [OK]
```
<img width="317" height="96" alt="image" src="https://github.com/user-attachments/assets/49accc4d-6f30-46a1-b76e-4dd6c5100144" />

## 6.6 Kiểm tra kết quả

```
su - zimbra
zmprov -l gaa lab.local
```

**Output mong đợi:**
```
admin@mail.lab.local
iamhieu@mail.lab.local
hieu@mail.lab.local
```
<img width="299" height="113" alt="image" src="https://github.com/user-attachments/assets/3a113d39-c9b7-458f-95b7-736b3560f795" />


---

# CHƯƠNG 7. THIẾT LẬP CHÍNH SÁCH MẬT KHẨU

## 7.1 Mục tiêu

Cấu hình Password Policy bắt buộc toàn bộ user đặt mật khẩu đủ mạnh.

## 7.2 Lý thuyết — Tại sao cần Password Policy?

Thực tế cho thấy: **70% tài khoản email bị hack là do mật khẩu yếu**. Nếu không có policy → nhân viên sẽ đặt mật khẩu `123456` hay `password`. Việc của Admin là ép buộc họ đặt mật khẩu đủ mạnh bằng cơ chế hệ thống.

## 7.3 Cấu hình qua GUI

> 🖥️ **Thực hiện trên: VM1 –  (Admin Console)**

```
Admin Console
→ Configure (menu trái)
→ Class of Service
→ Click vào "default" (CoS mặc định áp dụng cho tất cả user)
→ Tab: Advanced
→ Tìm phần: Password
```
<img width="959" height="389" alt="image" src="https://github.com/user-attachments/assets/59193227-eac4-4314-816c-feae41f88bb1" />

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
<img width="959" height="446" alt="image" src="https://github.com/user-attachments/assets/10c005f9-5848-4981-ae5a-71e21991146a" />

## 7.4 Kiểm tra policy hoạt động

```
1. Đăng nhập WorldClient bằng iamhieu@mail.lab.local
2. Thử đổi mật khẩu thành "123" (quá ngắn)
3. Zimbra phải từ chối và hiển thị lỗi mô tả yêu cầu
```
<img width="218" height="391" alt="image" src="https://github.com/user-attachments/assets/3e5a75bf-462b-468a-b22e-fd39c0caf898" />

đã có yêu cầu, giới hạn thời gian đổi mật khẩu

---

# CHƯƠNG 8. THIẾT LẬP CHỮ KÝ EMAIL

## 8.1 Mục tiêu

Tạo chữ ký email (Signature) tự động xuất hiện ở cuối mỗi email gửi đi.

## 8.2 Lý thuyết — Signature dùng để làm gì?

Chữ ký email = "Danh thiếp điện tử". Mỗi email gửi đi đều có thông tin liên hệ đầy đủ, tạo tính chuyên nghiệp cho doanh nghiệp.

## 8.3 Tạo Signature cho user01

> 🖥️ **Thực hiện trên: VM1 –  (WorldClient — đăng nhập bằng user01)**

### Cách 1: User tự tạo signature

```
WorldClient (đăng nhập iamhieu@mail.lab.local)
→ Click biểu tượng [Settings/Cài đặt] (góc trên phải — hình bánh răng)
→ Preferences
→ Signatures (menu trái)
→ Click [New Signature]
→ Điền:

→ Click [Save]

Gắn signature vào email:
→ Preferences → Accounts
→ Tại "Primary Account"
→ Signature: chọn "Chữ ký chính"
→ [Save]
```
<img width="959" height="374" alt="image" src="https://github.com/user-attachments/assets/cef49d02-7ccb-44fd-bd90-338e7c1114e1" />

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
# Thực hiện trên: VM2 – 192.168.136.131
su - zimbra

# Tạo signature cho user01 qua CLI
zmprov modifyAccount iamhieu@mail.lab.local \
  zimbraPrefMailSignature "-- \nNguyen Van A\nSystem Administrator\nEmail: iamhieu@mail.lab.local"

# Đặt signature mặc định tự động thêm khi compose mail
zmprov modifyAccount iamhieu@mail.lab.local \
  zimbraPrefMailSignatureEnabled TRUE
```

## 8.4 Kiểm tra kết quả

```
WorldClient (iamhieu@mail.lab.local)
→ Click [Compose] (Soạn thư mới)
→ Cuối khung soạn thảo phải thấy chữ ký xuất hiện tự động
```

<img width="959" height="365" alt="image" src="https://github.com/user-attachments/assets/55778aa8-1669-4413-91cc-21ffffc8356c" />

---

# CHƯƠNG 9. FORWARD EMAIL

## 9.1 Mục tiêu

Cấu hình iamhieu@mail.lab.local tự động chuyển tiếp email đến hieu@mail.lab.local.

## 9.2 Lý thuyết — Forward dùng khi nào?

**Tình huống thực tế:**
- Nhân viên đi nghỉ phép → forward mail về cho người thay thế
- Địa chỉ chung `info@congty.vn` → forward về email cá nhân của nhân viên trực
- Thằng iamhieu nghỉ thì forward sang mail thằng hieu


  
## 9.3 Cấu hình Forward qua GUI (cách nhanh nhất)

> 🖥️ **Thực hiện trên: VM1 –  (WorldClient — đăng nhập user01)**

```
WorldClient (iamhieu@mail.lab.local)
→ Settings 
→ Preferences
→ Mail (menu trái)
→ Tìm phần: "Receiving Messages"
→ Forward a copy to: hieu@mail.lab.local
→ Tick ô: "Don't keep a local copy of messages" (tuỳ chọn)
→ Click [Save]
```
<img width="951" height="433" alt="image" src="https://github.com/user-attachments/assets/8caff8c7-a25d-45a3-a530-4c83eda7381b" />  
Thư đi thẳng sang hộp thư đích (hieu), hộp thư gốc (iamhieu) hoàn toàn trống rỗng sau khi nhận.  

## 9.4 Cấu hình Forward qua Admin Console (Admin thay người dùng)

> 🖥️ **Thực hiện trên: VM1 –  (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click đúp vào iamhieu@mail.lab.local
→ Tab: Features
→ Tìm: "Mail forwarding"
   ┌──────────────────────────────────────────────┐
   │ Forward to: hieu@mail.lab.local                 │
   │ ☑ Keep a local copy                          │
   └──────────────────────────────────────────────┘
→ Click [Save]
```
<img width="948" height="427" alt="image" src="https://github.com/user-attachments/assets/2e6544a8-84dc-4764-83eb-5a40a3a38143" />

## 9.5 Kiểm tra Forward hoạt động

```
1. Đăng nhập WorldClient bằng admin@mail.lab.local
2. Compose email mới:
   To: iamhieu@mail.lab.local
   Subject: Test Forward
   Body: Đây là email test forward
3. Click [Send]

4. Đăng nhập WorldClient bằng hieu@mail.lab.local
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

> 🖥️ **Thực hiện trên: VM1  (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click vào iamhieu@mail.lab.local
→ Tab: General Information
→ Xem phần: "Account ID" (UUID dạng hex)
   Ví dụ: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```
<img width="1918" height="707" alt="image" src="https://github.com/user-attachments/assets/d428a27d-b62d-49b6-b6de-742d74115890" />

## 10.4 Tìm qua CLI

>  **Thực hiện trên: VM2 – 192.168.136.131**

```bash
su - zimbra

# Tìm Account ID (UUID)
zmprov ga iamhieu@mail.lab.local | grep zimbraId
```
<img width="445" height="58" alt="image" src="https://github.com/user-attachments/assets/266f30fc-00ff-4aff-8468-8e5a29c88059" />


```bash


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
admin@mail.lab.local → Mailbox ID: 1
iamhieu@mail.lab.local → Mailbox ID: 3
hieu@mail.lab.local → Mailbox ID: 4
```


---

# CHƯƠNG 11. ĐỔI MẬT KHẨU ADMIN

## 11.1 Mục tiêu

Đổi mật khẩu Admin bằng cả GUI và CLI, biết khi nào dùng cách nào.

## 11.2 Cách 1 — GUI (Thông thường)

> 🖥️ **Thực hiện trên: VM1 –  (Admin Console)**

```
Admin Console
→ Manage → Accounts
→ Click đúp vào admin@mail.lab.local
→ Tab: General Information
→ Password: [nhập mật khẩu mới]
→ Confirm Password: [nhập lại]
→ Click [Save]
```
<img width="785" height="97" alt="image" src="https://github.com/user-attachments/assets/db5ee8fd-0c03-43f5-8788-0892f471045b" />

## 11.3 Cách 2 — CLI (Dùng khi mất mật khẩu / không vào được GUI)

>  **Thực hiện trên: VM2 – 192.168.136.131**

```bash
su - zimbra

# Đổi mật khẩu admin qua CLI
zmprov sp admin@mail.lab.local 'NewAdmin@2026!'

# Verify bằng cách thử đăng nhập
zmaccts | grep admin
```

---

# CHƯƠNG 12. KIỂM TRA LOG GỬI NHẬN EMAIL
 
> ⭐ **Đây là kỹ năng quan trọng nhất của một Mail Admin**
 
## 12.1 Mục tiêu
 
Đọc và phân tích được log email để tìm nguyên nhân mail bị lỗi.
 
---
 
## 12.2 Lý thuyết — Tại sao phải đọc log?
 
Khi khách hàng báo "tôi không gửi/nhận được mail" → bạn **KHÔNG thể đoán mò**. Phải đọc log để biết chính xác:
 
- Mail có đến server chưa?
- Bị chặn ở bước nào?
- Lỗi gì? Do spam filter? Do DNS? Do full disk?
---
 
## 12.3 File log tập trung của Zimbra
 
> 💻 **Thực hiện trên: VM2 – 192.168.136.131**
 
Trong cấu hình Lab này, **toàn bộ log của Zimbra được gộp vào một file duy nhất:**
 
```
/var/log/zimbra.log
```
 
File này tập hợp log từ **tất cả các thành phần** của Zimbra, bao gồm:
 
| Thành phần | Ghi log về |
|-----------|-----------|
| `postfix/smtpd` | Nhận kết nối SMTP đến |
| `postfix/smtp` | Gửi mail đi |
| `postfix/qmgr` | Quản lý hàng đợi (queue) |
| `postfix/cleanup` | Làm sạch header email |
| `amavis` | Lọc spam, virus (SpamAssassin + ClamAV) |
| `dovecot` | IMAP/POP3 — client đọc mail |
| `zimbra` | Zimbra mailbox service |
 
```bash
# Kiểm tra file log tồn tại
ls -lh /var/log/zimbra.log
 
# Xem dung lượng file log
du -sh /var/log/zimbra.log
```
 
---
 
## 12.4 Xem log realtime
 
> 💻 **Thực hiện trên: VM2 – 192.168.136.131**
 
```bash
# Xem log realtime — Ctrl+C để thoát
tail -f /var/log/zimbra.log
 
# Xem 50 dòng gần nhất
tail -50 /var/log/zimbra.log
 
# Xem log và lọc chỉ các dòng liên quan đến postfix
tail -f /var/log/zimbra.log | grep postfix
 
# Xem log và lọc chỉ các dòng liên quan đến amavis
tail -f /var/log/zimbra.log | grep amavis
```
 
> 💡 **Mẹo thực tế:** Mở 2 terminal song song:
> - Terminal 1: `tail -f /var/log/zimbra.log`
> - Terminal 2: Gửi email test
> → Quan sát log xuất hiện realtime khi email được xử lý
 
---
 
## 12.5 Phân tích log — Ví dụ thực tế
 
### Kịch bản 1: Email gửi thành công (Happy Path)
 
Khi `iamhieu@mail.lab.local` gửi mail cho `hieu@mail.lab.local`, file `/var/log/zimbra.log` sẽ ghi lại toàn bộ hành trình:
 
```
Jun 15 10:30:01 mail postfix/smtpd[1234]: connect from client.lab.local[172.16.16.237]
Jun 15 10:30:01 mail postfix/smtpd[1234]: A1B2C3D4E5F6: client=client.lab.local[172.16.16.237]
Jun 15 10:30:01 mail postfix/cleanup[1235]: A1B2C3D4E5F6: message-id=<abc123@mail.lab.local>
Jun 15 10:30:01 mail postfix/qmgr[1236]: A1B2C3D4E5F6: from=<iamhieu@mail.lab.local>, size=1024, nrcpt=1 (queue active)
Jun 15 10:30:02 mail amavis[1237]: (12345-01) Passed CLEAN, <iamhieu@mail.lab.local> -> <hieu@mail.lab.local>, Message-ID: <abc123@mail.lab.local>, mail_id: xyz789, Hits: -1.9, size: 1024, 823 ms
Jun 15 10:30:02 mail postfix/smtp[1238]: A1B2C3D4E5F6: to=<hieu@mail.lab.local>, relay=127.0.0.1[127.0.0.1]:10024, delay=0.8, status=sent (250 2.0.0 from MTA(smtp:[127.0.0.1]:10025))
Jun 15 10:30:02 mail postfix/qmgr[1236]: A1B2C3D4E5F6: removed
```
 <img width="848" height="226" alt="image" src="https://github.com/user-attachments/assets/804e6f46-af97-4e03-9ca3-2225d6f4fe4f" />

#### Giải thích từng dòng
 
```
Dòng 1: postfix/smtpd
         → Postfix nhận kết nối từ client 172.16.16.237
         → ✅ Client kết nối được vào server
 
Dòng 2: A1B2C3D4E5F6 = Queue ID
         → Mã định danh duy nhất của email này trong hệ thống
         → Dùng Queue ID này để grep trace toàn bộ hành trình
 
Dòng 3: postfix/cleanup
         → Email được làm sạch header
         → message-id: ID duy nhất do email client tạo ra
 
Dòng 4: postfix/qmgr
         → Queue Manager nhận email, đưa vào hàng đợi xử lý
         → from: người gửi
         → size: kích thước email (bytes)
         → nrcpt=1: số người nhận
 
Dòng 5: amavis
         → Amavis filter đã kiểm tra xong
         → "Passed CLEAN" = email sạch, không spam, không virus
         → Hits: -1.9 = điểm spam âm → rất sạch (càng âm càng tốt)
 
Dòng 6: postfix/smtp
         → Postfix giao email cho mailbox server
         → relay=127.0.0.1:10024 = Amavis đang xử lý trung gian
         → status=sent ✅ = GIAO THÀNH CÔNG
 
Dòng 7: postfix/qmgr → removed
         → Email đã xử lý xong, xóa khỏi queue
         → ✅ Toàn bộ quá trình hoàn tất
```
 
**Sơ đồ luồng tương ứng với log trên:**
 
```
[iamhieu@mail.lab.local]
         │
         │ SMTP connect (Dòng 1-2)
         ▼
[postfix/smtpd] ──► Tạo Queue ID: A1B2C3D4E5F6
         │
         │ cleanup (Dòng 3)
         ▼
[postfix/cleanup] ──► Gán message-id
         │
         │ queue active (Dòng 4)
         ▼
[postfix/qmgr] ──► Đưa vào hàng đợi
         │
         │ gửi qua Amavis port 10024
         ▼
[amavis] ──► Kiểm tra spam/virus ──► Passed CLEAN (Dòng 5)
         │
         │ trả về port 10025
         ▼
[postfix/smtp] ──► status=sent (Dòng 6)
         │
         ▼
[hieu@mail.lab.local] ✅ Đã nhận được mail
```
 
---
 
### Kịch bản 2: Mail bị từ chối — Relay denied
 
```
Jun 15 10:35:01 mail postfix/smtpd[1240]: NOQUEUE: reject: RCPT from unknown[1.2.3.4]: 554 5.7.1 <spam@hacker.com>: Relay access denied; from=<spam@hacker.com> to=<victim@mail.lab.local> proto=SMTP helo=<hacker.com>
```
 
**Phân tích:**
 
```
NOQUEUE   → Email bị chặn TRƯỚC khi vào queue (tiết kiệm tài nguyên)
reject    → Từ chối hoàn toàn
554 5.7.1 → Mã lỗi SMTP: "Transaction failed - Delivery not authorized"
Relay access denied → Server từ chối relay mail
IP 1.2.3.4 → IP không được phép gửi mail qua server này
 
→ Đây là BẢO MẬT BÌNH THƯỜNG, không phải lỗi hệ thống
→ Server đang tự bảo vệ khỏi bị dùng làm spam relay
```
 
---
 
### Kịch bản 3: Mail bị spam filter chặn
 
```
Jun 15 10:40:01 mail amavis[1245]: (12350-01) Blocked SPAM, <sender@external.com> -> <iamhieu@mail.lab.local>, Message-ID: <spam123@external.com>, mail_id: abc999, Hits: 8.5, tag_level=3.0, tag2_level=6.0, kill_level=6.9, 1245 ms
```
 
**Phân tích:**
 
```
Blocked SPAM  → Email bị chặn vì bị nhận dạng là spam
Hits: 8.5     → Điểm spam = 8.5 (vượt kill_level)
 
Bảng ngưỡng điểm spam (Hits):
┌──────────────────────────────────────────────────────┐
│  tag_level  = 3.0 → Thêm header X-Spam-Status: Yes  │
│  tag2_level = 6.0 → Thêm [SPAM] vào Subject         │
│  kill_level = 6.9 → CHẶN email, không giao          │
│                                                      │
│  Hits: 8.5 > kill_level: 6.9 → BỊ CHẶN ✅           │
│  Hits: -1.9 < tag_level: 3.0 → Sạch ✅              │
└──────────────────────────────────────────────────────┘
 
→ Hành động: Mail bị chuyển vào Junk/Spam folder hoặc bị xóa
→ Kiểm tra trong Admin Console: Monitor → Mail Queue
```
 
---
 
### Kịch bản 4: Mail bị deferred — gửi tạm thời thất bại
 
```
Jun 15 10:45:01 mail postfix/smtp[1260]: B2C3D4E5F6A1: to=<user@external.com>, relay=none, delay=30, delays=0.1/0/30/0, dsn=4.4.1, status=deferred (connect to external.com[93.184.216.34]:25: Connection timed out)
```
 
**Phân tích:**
 
```
status=deferred → Gửi thất bại TẠM THỜI (sẽ retry sau)
                  (khác với "bounced" = thất bại vĩnh viễn)
relay=none      → Không connect được đến server đích
Connection timed out → Server đích không phản hồi port 25
dsn=4.4.1       → "Temporary failure in name resolution or connection"
 
→ Nguyên nhân thường gặp:
   - Server đích đang down
   - Port 25 bị chặn bởi firewall
   - DNS không resolve được domain đích
 
→ Postfix sẽ tự retry theo schedule:
   5 phút → 10 phút → 20 phút → 40 phút → ...
   Sau 5 ngày không thành công → bounce
```
 
---
 
## 12.6 Lệnh tra cứu log hữu ích
 
> 💻 **Thực hiện trên: VM2 – 192.168.136.131**
 
```bash
# ── Tra cứu theo Queue ID ────────────────────────────────────
# Trace toàn bộ hành trình của 1 email cụ thể
grep "A1B2C3D4E5F6" /var/log/zimbra.log
```
<img width="932" height="203" alt="image" src="https://github.com/user-attachments/assets/4e19e9f3-d2d3-418b-8738-a2ad56ce9602" />
```
# ── Tra cứu theo địa chỉ email ──────────────────────────────
# Xem tất cả log liên quan đến 1 địa chỉ email
grep "iamhieu@mail.lab.local" /var/log/zimbra.log | tail -30
```
<img width="925" height="350" alt="image" src="https://github.com/user-attachments/assets/1efd1eae-e8de-470d-9235-f8a44de6cb73" />
```
# ── Tìm email bị lỗi ────────────────────────────────────────
# Tìm email bị reject
grep "reject" /var/log/zimbra.log | tail -50
```
<img width="924" height="49" alt="image" src="https://github.com/user-attachments/assets/71b13bd9-8719-4a2a-8985-7f325cbac486" />
```
# Tìm email bị deferred (gửi tạm thời thất bại)
grep "status=deferred" /var/log/zimbra.log | tail -20
```
<img width="938" height="355" alt="image" src="https://github.com/user-attachments/assets/f9895ae5-76f5-446d-bc0e-db498158f189" />
```
# Tìm email bị bounced (gửi thất bại vĩnh viễn)
grep "status=bounced" /var/log/zimbra.log | tail -20
 ```
<img width="929" height="340" alt="image" src="https://github.com/user-attachments/assets/bb0dca0f-ed91-47fc-8bbc-0abb1da6e79f" />
 ```
# Tìm email bị spam filter chặn
grep "Blocked SPAM" /var/log/zimbra.log | tail -20
  ```

 ```
# ── Thống kê ────────────────────────────────────────────────
# Đếm số email gửi thành công trong ngày
grep "status=sent" /var/log/zimbra.log | wc -l
 ```
<img width="370" height="36" alt="image" src="https://github.com/user-attachments/assets/b76da21f-6d1c-4c61-a1fd-8a6ef4093f82" />

 ``` 
# Đếm số email bị reject trong ngày
grep "reject" /var/log/zimbra.log | wc -l
 
# Xem 100 dòng log mới nhất của amavis
grep "amavis" /var/log/zimbra.log | tail -100
```
<img width="938" height="212" alt="image" src="https://github.com/user-attachments/assets/28fc0ce2-efe4-442e-8630-00aa24233f11" />
```
# ── Lọc theo khoảng thời gian ───────────────────────────────
# Xem log từ 10:00 đến 11:00
grep "Jun 15 10:" /var/log/zimbra.log
 
# ── Mail queue ──────────────────────────────────────────────
# Xem mail đang kẹt trong queue
su - zimbra -c "postqueue -p"
 
# Xem chi tiết 1 mail trong queue
su - zimbra -c "postcat -q A1B2C3D4E5F6"
 
# Flush queue — thử gửi lại tất cả mail đang kẹt
su - zimbra -c "postqueue -f"
 
# Xóa 1 mail cụ thể khỏi queue
su - zimbra -c "postsuper -d A1B2C3D4E5F6"
 
# Xóa toàn bộ queue (⚠️ cẩn thận — không thể hoàn tác)
su - zimbra -c "postsuper -d ALL"
```
 
---
 
## 12.7 Xem log qua Admin Console GUI
 
> 🖥️ **Thực hiện trên: VM1 – trình duyệt → `https://192.168.136.131:7071`**
 
```
Admin Console
→ Monitor (menu trái)
→ Mail Queue
→ Thấy danh sách email đang chờ xử lý
→ Click vào từng email để xem:
   - Người gửi / người nhận
   - Lý do kẹt
   - Số lần đã retry
→ Có thể Delete hoặc Flush từng mail từ GUI
```
 
---
 
## 12.8 Workflow xử lý khi khách hàng báo lỗi mail
 
Khi nhận ticket "không gửi/nhận được mail", thực hiện theo thứ tự sau:
 
```
Bước 1: Hỏi khách hàng
  └── Lỗi từ lúc nào? Gửi hay nhận? Địa chỉ email cụ thể?
 
Bước 2: Kiểm tra service còn chạy không
  └── su - zimbra -c "zmcontrol status" | grep -E "mta|mailbox|amavis"
 
Bước 3: Xem log theo địa chỉ email
  └── grep "iamhieu@mail.lab.local" /var/log/zimbra.log | tail -50
 
Bước 4: Tìm Queue ID từ log → trace toàn bộ hành trình
  └── grep "QUEUE_ID" /var/log/zimbra.log
 
Bước 5: Đọc dòng cuối cùng liên quan
  └── status=sent ✅    → Mail đã giao, kiểm tra folder Spam của người nhận
  └── status=deferred   → Đang retry, chờ hoặc flush queue
  └── status=bounced    → Thất bại vĩnh viễn, xem lý do
  └── Blocked SPAM      → Amavis chặn, kiểm tra điểm Hits
  └── Relay denied      → Cấu hình firewall/relay
 
Bước 6: Xử lý theo nguyên nhân → thông báo khách hàng
```
 
---

# CHƯƠNG 13. THAY ĐỔI LOGO ZIMBRA
 
> 💻 **Toàn bộ chương này thực hiện trên: VM2 – 192.168.136.131**
 
## 13.1 Mục tiêu
 
Thay thế logo mặc định của Zimbra bằng logo của công ty trên trang đăng nhập và giao diện webmail.
 
---
 
## 13.2 Lý thuyết
 
Zimbra 10.1. **không hỗ trợ thay logo qua GUI Admin Console**.  
Phải thay file trực tiếp trên server theo 2 phương pháp:
 
| Phương pháp | Ưu điểm | Nhược điểm |
|------------|---------|-----------|
| **Copy file đè trực tiếp** | Nhanh, đơn giản | Bị mất sau khi upgrade Zimbra |
| **zmprov (cách chính thức)** | Bền vững, không bị upgrade xóa | Cần URL public hoặc path nội bộ hợp lệ |
 
---
 
## 13.3 Xác định đúng file logo trong Zimbra 10.1.x
 
Từ ảnh thực tế, thư mục img của Zimbra 10.1.x có cấu trúc:
 
```
/opt/zimbra/jetty/webapps/zimbra/img/
```
 
Trong Zimbra 10.1.x, logo được quản lý qua **skin**. Vị trí file logo nằm tại:
 
```bash

# Tìm đúng các file logo đang dùng
find /opt/zimbra/jetty/webapps/zimbra -name "*.png" | grep -iE "logo|banner|brand" 2>/dev/null
 
```
 
**Các file logo quan trọng trong Zimbra 10.1.x:**
 
```bash
# Tìm chính xác tất cả file logo
find /opt/zimbra/jetty/webapps/zimbra/skins -name "*.png" 2>/dev/null | grep -iE "logo|LoginBanner|AppBanner"
```
 <img width="706" height="167" alt="image" src="https://github.com/user-attachments/assets/82e9c4ba-4128-4e2f-82b2-f46fb3c2b099" />

File logo thường nằm tại các đường dẫn sau:
 
```
/opt/zimbra/jetty/webapps/zimbra/skins/_base/logos/ZimbraInside/LoginBanner.png
→ Logo hiển thị trên trang đăng nhập
 
/opt/zimbra/jetty/webapps/zimbra/skins/_base/logos/AppBanner.png
→ Logo hiển thị trong giao diện webmail (sau khi đăng nhập)
```
 
```bash
# Confirm đường dẫn thực tế trên server của bạn
find /opt/zimbra -name "LoginBanner.png" 2>/dev/null
find /opt/zimbra -name "AppBanner.png" 2>/dev/null
```
 
---
 
## 13.4 Thực hiện thay logo
 
### Bước 1 — Chuẩn bị file logo
 
Logo cần đáp ứng yêu cầu kỹ thuật:
 
| Thông số | Yêu cầu |
|---------|---------|
| Định dạng | PNG (khuyến nghị), GIF, JPG |
| Kích thước LoginBanner | ~120 x 30 pixels (trang đăng nhập) |
| Kích thước AppBanner | ~200 x 38 pixels (giao diện webmail) |
| Nền | Trong suốt (transparent) nếu dùng PNG |
 
### Bước 2 — Upload logo lên VM2
 
```bash

# Ví dụ nếu file logo ở Desktop của VM1:
scp ~/Desktop/logo.png iamhieu@192.168.136.131:/tmp/logo-moi.png
```
 <img width="664" height="197" alt="image" src="https://github.com/user-attachments/assets/c979c321-c8eb-4914-9e1c-be0d54f11484" />

### Bước 3 — Backup file logo gốc
 
```bash
LOGIN_BANNER=$(find /opt/zimbra -name "LoginBanner.png" 2>/dev/null | head -1)
APP_BANNER=$(find /opt/zimbra -name "AppBanner.png" 2>/dev/null | head -1)
 
echo "LoginBanner: $LOGIN_BANNER"
echo "AppBanner:   $APP_BANNER"
```
<img width="558" height="103" alt="image" src="https://github.com/user-attachments/assets/f9b117c3-340d-4592-b815-1cf093bdeb9c" />

```
# Backup — LUÔN backup trước khi thay
cp "$LOGIN_BANNER" "${LOGIN_BANNER}.bak"
cp "$APP_BANNER" "${APP_BANNER}.bak"
 
# Verify backup tồn tại
ls -lh "${LOGIN_BANNER}.bak"
ls -lh "${APP_BANNER}.bak"
```
 
### Bước 4 — Copy logo mới vào đúng vị trí
 
```bash
# Thay LoginBanner (trang đăng nhập)
sudo cp /tmp/logo-moi.png "$LOGIN_BANNER"
 
# Thay AppBanner (giao diện webmail)
sudo cp /tmp/logo-moi.png "$APP_BANNER"
 
# Quan trọng: đặt đúng owner cho Zimbra
sudo chown zimbra:zimbra "$LOGIN_BANNER"
sudo chown zimbra:zimbra "$APP_BANNER"
 
# Đặt quyền đúng
sudo chmod 644 "$LOGIN_BANNER"
sudo chmod 644 "$APP_BANNER"
 
# Verify
ls -lh "$LOGIN_BANNER"
ls -lh "$APP_BANNER"
```
<img width="728" height="53" alt="image" src="https://github.com/user-attachments/assets/92b646f0-10f9-45f7-a62f-a831593a12e1" />

### Bước 5 — Cách thay theo từng skin cụ thể (nếu bước 4 không hiệu quả)
 
Zimbra 10.1.x sử dụng skin system. Thay logo trong đúng skin đang dùng:
 
```bash
# Xem skin đang được cấu hình
su - zimbra
zmprov gd lab.local zimbraSkinName
 
# Thường là "serenity" trong Zimbra 10.x
# Tìm logo trong skin đó
ls /opt/zimbra/jetty/webapps/zimbra/skins/serenity/logos/ 2>/dev/null
 
# Thay logo trong skin serenity
cp /tmp/company-logo.png \
   /opt/zimbra/jetty/webapps/zimbra/skins/serenity/logos/LoginBanner.png
 
cp /tmp/company-logo.png \
   /opt/zimbra/jetty/webapps/zimbra/skins/serenity/logos/AppBanner.png
 
# Set owner
chown -R zimbra:zimbra /opt/zimbra/jetty/webapps/zimbra/skins/serenity/logos/
```
 
### Bước 6 — Clear cache và restart
 
```bash
sudo su - zimbra
 
# Clear browser cache phía server
zmprov flushCache skin
 
# Restart mailbox để apply thay đổi
zmmailboxdctl restart
 
# Đợi ~60 giây cho Zimbra khởi động lại xong
# Kiểm tra trạng thái
zmcontrol status | grep mailbox
```
 
---
 
## 13.5 Cách thay logo qua zmprov (bền vững hơn)
 
Phương pháp này dùng khi bạn có web server riêng host file logo:
 
```bash
su - zimbra
 
# Cách 1: Trỏ đến URL ngoài
zmprov md lab.local zimbraSkinLogoURL "http://192.168.136.131/logo/company.png"
 
# Cách 2: Dùng đường dẫn tương đối trong Zimbra
zmprov md lab.local zimbraSkinLogoURL "/img/company-logo.png"
 
# Thay AppBanner (banner trong app sau khi đăng nhập)
zmprov md lab.local zimbraSkinLogoAppBanner "/img/company-logo.png"
 
# Clear cache và restart
zmprov flushCache skin
zmmailboxdctl restart
```
 
---
 
## 13.6 Kiểm tra kết quả
 
```bash
# Kiểm tra file logo mới đã đúng chưa
file "$LOGIN_BANNER"
# Output mong đợi: PNG image data, 120 x 30, ...
 
# Kiểm tra owner đúng chưa
ls -lh "$LOGIN_BANNER"
# Output mong đợi: -rw-r--r-- 1 zimbra zimbra ...
```
 
Trên trình duyệt VM1:
 
```
1. Truy cập: https://192.168.136.131
2. Nhấn Ctrl+Shift+R (hard refresh — xóa cache trình duyệt)
3. Trang đăng nhập phải hiển thị logo mới
4. Đăng nhập vào webmail → logo trong header cũng phải thay đổi
 
Nếu vẫn thấy logo cũ:
→ Thử mở tab ẩn danh (Ctrl+Shift+N) để tránh cache
→ Hoặc thử trình duyệt khác
```
 

---
 
# CHƯƠNG 14. THAY ĐỔI TITLE WEB ZIMBRA
 
## 14.1 Mục tiêu
 
Đổi tiêu đề tab trình duyệt và các banner text từ "Zimbra" thành tên riêng của công ty/lab.
 
---
 
## 14.2 Lý thuyết
 
Trong Zimbra 10.1.x, có **3 vị trí text** có thể thay đổi:
 
```
┌─────────────────────────────────────────────────────────┐
│ Tab trình duyệt: [LAB MAIL SERVER]                      │  ← zimbraProductName
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  [LAB MAIL SERVER]  ← Login Banner text         │    │  ← zimbraSkinLogoLoginBanner
│  │                                                 │    │
│  │  Username: __________                           │    │
│  │  Password: __________                           │    │
│  │  [Sign In]                                      │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
 
Sau khi đăng nhập:
┌─────────────────────────────────────────────────────────┐
│ [LAB MAIL SERVER] ← App Banner text                     │  ← zimbraSkinLogoAppBanner
│ ─────────────────────────────────────────────────────── │
│  Inbox | Sent | ...                                     │
└─────────────────────────────────────────────────────────┘
```
 
---
 
## 14.3 Thực hiện
 
### Bước 1 — Xem giá trị hiện tại
 
```bash
sudo su - zimbra
 
# Xem tất cả cấu hình title/banner hiện tại
zmprov gd lab.local | grep -iE "zimbraSkinLogo|zimbraProductName"
 
# Hoặc xem từng giá trị riêng lẻ
zmprov gd lab.local zimbraSkinLogoLoginBanner
zmprov gd lab.local zimbraSkinLogoAppBanner
zmprov gcf zimbraProductName
```
 
**Output mẫu (giá trị mặc định Zimbra 10.1.x):**
```
zimbraSkinLogoLoginBanner: Zimbra
zimbraSkinLogoAppBanner: Zimbra
zimbraProductName: Zimbra Collaboration
```
 
### Bước 2 — Thay đổi title tab trình duyệt
 
```bash
su - zimbra
 
# Đổi tên hiển thị trên tab trình duyệt (global — áp dụng toàn server)
zmprov mcf zimbraProductName "LAB MAIL SERVER"
 
# Verify
zmprov gcf zimbraProductName
# Output: zimbraProductName: LAB MAIL SERVER
```
 
### Bước 3 — Thay đổi Login Banner (trang đăng nhập)
 
```bash
# Đổi text banner trên trang đăng nhập (per-domain)
zmprov md lab.local zimbraSkinLogoLoginBanner "LAB MAIL SERVER"
 
# Verify
zmprov gd lab.local zimbraSkinLogoLoginBanner
# Output: zimbraSkinLogoLoginBanner: LAB MAIL SERVER
```
 
### Bước 4 — Thay đổi App Banner (trong giao diện webmail)
 
```bash
# Đổi text banner trong giao diện sau khi đăng nhập (per-domain)
zmprov md lab.local zimbraSkinLogoAppBanner "LAB MAIL SERVER"
 
# Verify
zmprov gd lab.local zimbraSkinLogoAppBanner
# Output: zimbraSkinLogoAppBanner: LAB MAIL SERVER
```
 
### Bước 5 — Clear cache và restart
 
```bash
# Vẫn đang ở user zimbra
 
# Clear skin cache
zmprov flushCache skin
 
# Clear all cache (triệt để hơn)
zmprov flushCache -a
 
# Restart mailbox service để apply
zmmailboxdctl restart
 
# Chờ ~60 giây, kiểm tra đã start lại xong
zmcontrol status | grep mailbox
```
 
**Output mong đợi:**
```
        mailbox                 Running
```
 
---
 
## 14.4 Thay đổi các text khác (nâng cao)
 
Zimbra 10.1.x còn có một số text có thể tùy chỉnh thêm:
 
```bash
su - zimbra
 
# Đổi tên hiển thị trong email headers (From name của system mail)
zmprov mcf zimbraDefaultDomainName "lab.local"
 
# Đổi địa chỉ email gửi thông báo hệ thống
zmprov mcf zimbraNewMailNotificationFrom "no-reply@lab.local"
 
# Đổi tên hiển thị của sender thông báo hệ thống
zmprov mcf zimbraNewMailNotificationSender "LAB MAIL SERVER"
 
# Sau khi thay đổi: clear cache
zmprov flushCache -a
zmmailboxdctl restart
```
 
---
 
## 14.5 Kiểm tra kết quả
 
```bash
# Kiểm tra nhanh tất cả giá trị đã thay đổi
su - zimbra
echo "=== Product Name ==="
zmprov gcf zimbraProductName
 
echo "=== Login Banner ==="
zmprov gd lab.local zimbraSkinLogoLoginBanner
 
echo "=== App Banner ==="
zmprov gd lab.local zimbraSkinLogoAppBanner
```
 
**Output mong đợi:**
```
=== Product Name ===
zimbraProductName: LAB MAIL SERVER
 
=== Login Banner ===
zimbraSkinLogoLoginBanner: LAB MAIL SERVER
 
=== App Banner ===
zimbraSkinLogoAppBanner: LAB MAIL SERVER
```
 
Trên trình duyệt VM1:
 
```
1. Mở tab ẩn danh: Ctrl+Shift+N
2. Truy cập: https://192.168.136.131
3. Kiểm tra:
   ✅ Tab trình duyệt hiển thị: "LAB MAIL SERVER"
   ✅ Header trang đăng nhập hiển thị: "LAB MAIL SERVER"
4. Đăng nhập vào webmail
5. Kiểm tra header top-left:
   ✅ Phải hiển thị: "LAB MAIL SERVER"
```
 
> 💡 **Bắt buộc dùng tab ẩn danh** để test — trình duyệt thường đang cache title cũ, tab ẩn danh đảm bảo lấy fresh từ server.
 
---
 
## 14.6 Troubleshooting
 
| Triệu chứng | Nguyên nhân | Cách fix |
|------------|-------------|---------|
| Title vẫn là "Zimbra" | Browser cache | Mở tab ẩn danh thay vì Ctrl+Shift+R |
| Lệnh `zmprov md` báo lỗi | Sai domain name | Kiểm tra: `zmprov gad` để xem tên domain đúng |
| `zmmailboxdctl restart` timeout | Zimbra đang bận | Chờ 2-3 phút rồi thử lại |
| Title đổi nhưng logo vẫn cũ | Chỉ flush text cache | Làm thêm Chương 13 để đổi logo |
| Thay đổi mất sau upgrade | Dùng `zmprov` đúng cách | Đảm bảo dùng `zmprov mcf/md` không phải sửa file tay |
 
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

> 🖥️ **Thực hiện trên: VM1 –  (Admin Console)**

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
→ Click đúp vào iamhieu@mail.lab.local
→ Tab: General Information
→ Mailbox Quota: 2147483648  (2 GB riêng cho user này)
→ Click [Save]
```

> 📌 **Lưu ý:** Quota cấu hình riêng tại Account sẽ **ghi đè** quota của CoS.

## 15.4 Cấu hình Quota qua CLI

```bash
# Thực hiện trên: VM2 – 192.168.136.131
su - zimbra

# Đặt quota 1GB cho user01
zmprov ma iamhieu@mail.lab.local zimbraMailQuota 1073741824

# Đặt quota 2GB cho user02
zmprov ma hieu@mail.lab.local zimbraMailQuota 2147483648

# Đặt unlimited quota
zmprov ma admin@mail.lab.local zimbraMailQuota 0
```

## 15.5 Kiểm tra Quota đang dùng

```bash
# Xem quota và dung lượng đang dùng của tất cả user
zmprov gqu lab.local

# Output mẫu:
# iamhieu@mail.lab.local  1073741824  102400000
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

>  **Thực hiện trên: VM2 – 192.168.136.131**

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
zmbackup -f -a iamhieu@mail.lab.local -t /backup/zimbra/user01

# Backup nhiều user
zmbackup -f -a iamhieu@mail.lab.local,hieu@mail.lab.local -t /backup/zimbra/users
```

## 16.5 Backup theo dạng Export TGZ (Portable)

```bash
# Export mailbox user01 ra file .tgz
zmmailbox -z -m iamhieu@mail.lab.local getRestURL "//?fmt=tgz" > \
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

>  **Thực hiện trên: VM2 – 192.168.136.131**

```bash
su - zimbra

# Restore user01 từ backup gần nhất
zmrestore -f -a iamhieu@mail.lab.local -t /backup/zimbra/full_20260615_0200

# Tham số:
# -f = restore full
# -a = account cần restore
# -t = thư mục backup nguồn
```

## 17.4 Import TGZ vào Mailbox hiện tại

Dùng khi: User xóa nhầm folder, muốn khôi phục lại

```bash
# Import file TGZ backup vào mailbox user01
zmmailbox -z -m iamhieu@mail.lab.local postRestURL "//?fmt=tgz&resolve=skip" \
  @/backup/zimbra/user01_20260615.tgz

# Tham số resolve:
# skip    = bỏ qua nếu đã tồn tại
# replace = thay thế nếu đã tồn tại
# reset   = xóa hết trước rồi import lại
```

## 17.5 Kiểm tra sau Restore

```bash
# Kiểm tra số lượng email trong mailbox user01
zmmailbox -z -m iamhieu@mail.lab.local getMailboxStats
```

**Output mong đợi:**
```
NumMessages: 25
NumUnread: 3
MailboxSize: 15728640
```

**Kiểm tra qua WorldClient:**
```
1. Đăng nhập WorldClient bằng iamhieu@mail.lab.local
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
  VM2: 192.168.136.131           VM3: 172.16.16.240 (giả lập)
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

>  **Thực hiện trên: VM2 – 192.168.136.131**

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
echo "Test từ CLI" | sendmail hieu@mail.lab.local
```

## 19.4 Lỗi 2 — Không nhận mail được

**Triệu chứng:** Người ngoài gửi mail vào → không thấy trong Inbox

```bash
# Bước 1: Kiểm tra port 25 có mở không
nc -zv 192.168.136.131 25

# Bước 2: Kiểm tra firewall
ufw status | grep 25

# Bước 3: Telnet test SMTP
telnet 192.168.136.131 25
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
grep "192.168.136.131" /etc/hosts

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
| `https://192.168.136.131:7071` | Admin Console |
| `https://192.168.136.131` | WorldClient (Webmail) |
| `http://192.168.136.131:7780` | Webmail HTTP |

### Tài liệu tham khảo

- Zimbra Wiki: https://wiki.zimbra.com
- Zimbra Forums: https://forums.zimbra.org
- Zimbra Source: https://github.com/zimbra

---

*Tài liệu được biên soạn bởi Senior SysAdmin — Nhân Hòa*  
*Phiên bản: 1.0 | Ngày: 2026-06-15*  
*Dành cho: Fresher / System Admin Intern*
