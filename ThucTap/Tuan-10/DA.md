PHẦN A — CHUẨN BỊ VM UBUNTU 22.04
A.1 — Tạo VM mới trong VMware
VMware Workstation → Create a New Virtual Machine

├── Configuration:    Typical
├── ISO:              ubuntu-22.04.x-live-server-amd64.iso
├── VM Name:          DirectAdmin-Server
├── Location:         D:\VMs\DirectAdmin\
├── Disk Size:        30 GB (Store as single file)
└── Customize Hardware:
    ├── RAM:          1536 MB (1.5GB)
    ├── CPU:          2 cores
    └── Network:      NAT
Trong quá trình cài Ubuntu, chọn:
├── Language:         English
├── Keyboard:         English (US)
├── Install:          Ubuntu Server (minimized)
├── Network:          Để DHCP trước, fix IP sau
├── Storage:          Use entire disk
├── Profile:
│   ├── Name:         ubuntu
│   ├── Server name:  da-lab
│   ├── Username:     ubuntu
│   └── Password:     Ubuntu@2026!
└── SSH:              ✅ Install OpenSSH server
A.2 — Thiết lập sau khi cài Ubuntu
SSH vào VM từ máy host:
bashssh ubuntu@192.168.136.11
# Password: Ubuntu@2026!

# Lên quyền root
sudo -i
# Hoặc dùng sudo trước mỗi lệnh
A.3 — Đặt hostname
bash# Đặt hostname đúng chuẩn FQDN
hostnamectl set-hostname da.lab.local

# Xác nhận
hostname
# Output: da.lab.local

hostname -f
# Output: da.lab.local
A.4 — Cấu hình IP tĩnh
bash# Xem tên interface
ip link show
# Thường là: ens33

# Xem file netplan hiện tại
ls /etc/netplan/
# Output: 00-installer-config.yaml

# Backup file gốc
cp /etc/netplan/00-installer-config.yaml \
   /etc/netplan/00-installer-config.yaml.bak

# Chỉnh sửa cấu hình
nano /etc/netplan/00-installer-config.yaml
Nội dung file (xóa hết, gõ lại):
yamlnetwork:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.136.11/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      routes:
        - to: default
          via: 192.168.136.2
bash# Apply cấu hình
netplan apply

# Kiểm tra IP
ip addr show ens33
# Phải thấy: inet 192.168.136.11/24

# Test internet
ping -c 3 8.8.8.8
ping -c 3 google.com
A.5 — Cập nhật /etc/hosts
bash# Thêm entry hostname
cat >> /etc/hosts << 'EOF'
192.168.136.11  da.lab.local da
EOF

# Kiểm tra
cat /etc/hosts
A.6 — Cập nhật hệ thống
bash# Update packages
apt update && apt upgrade -y

# Cài các tool cần thiết
apt install -y curl wget git net-tools \
  dnsutils telnet vim htop

# Kiểm tra OS
lsb_release -a
# Output: Ubuntu 22.04.x LTS
A.7 — Tắt AppArmor (tránh conflict với DA)
bash# Tắt AppArmor
systemctl stop apparmor
systemctl disable apparmor

# Xác nhận
systemctl status apparmor
# Output: inactive (dead)

PHẦN B — CÀI ĐẶT DIRECTADMIN
B.1 — Tải script cài đặt DA
bash# Chuyển về /root
cd /root

# Tải script cài đặt chính thức
curl -o setup.sh \
  https://setup.directadmin.com/setup.sh

# Xem quyền và kích thước
ls -lh setup.sh
# Output: -rw-r--r-- 1 root root ~50KB setup.sh

# Cấp quyền thực thi
chmod +x setup.sh
B.2 — Chạy cài đặt DirectAdmin
bash# Chạy cài đặt với tùy chọn:
# auto   = tự động, không hỏi nhiều
# --hostname = FQDN của server
# --email    = email admin
# --adminpass = mật khẩu admin DA

bash setup.sh \
  --hostname da.lab.local \
  --email admin@da.lab.local \
  --adminpass Admin@DA2026!

# Nếu muốn cài interactive (hỏi từng bước):
bash setup.sh

💡 Trong quá trình cài, script sẽ hỏi một số lựa chọn:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Nếu chạy interactive, trả lời như sau:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

License key:        TRIAL    ← Nhập TRIAL để dùng thử 30 ngày
Hostname:           da.lab.local
Email:              admin@da.lab.local
Admin password:     Admin@DA2026!
OS detected:        Ubuntu 22.04  (tự nhận diện)
Web server:         Apache        ← Chọn 1
PHP version:        8.2           ← Chọn phiên bản mới nhất
Database:           MariaDB 10.6  ← Chọn 1
B.3 — Theo dõi quá trình cài
Mở terminal thứ 2, SSH vào và chạy:
bash# Xem log real-time
tail -f /var/log/directadmin-setup.log

# Hoặc xem tiến trình
tail -f /var/log/directadmin-setup.log | \
  grep -E "Installing|Configuring|Starting|ERROR|done"
Các giai đoạn cài đặt:
[1/10] Checking system requirements...     ✅
[2/10] Downloading DirectAdmin...          ✅
[3/10] Installing DirectAdmin binary...    ✅
[4/10] Installing CustomBuild...           ✅
[5/10] Installing Apache...                ✅ (~3 phút)
[6/10] Installing PHP 8.2...              ✅ (~5 phút)
[7/10] Installing MariaDB...              ✅ (~2 phút)
[8/10] Installing Exim (mail)...          ✅
[9/10] Installing Dovecot (IMAP)...       ✅
[10/10] Final configuration...            ✅

DirectAdmin installation complete!
Login: https://192.168.136.11:2222
Username: admin
Password: Admin@DA2026!
B.4 — Xác nhận cài đặt thành công
bash# Kiểm tra service DA đang chạy
systemctl status directadmin
# Phải thấy: Active (running)

# Kiểm tra các port quan trọng
ss -tlnp | grep -E '80|443|2222|25|143|993|21|53'
Output mong đợi:
LISTEN  0  128  0.0.0.0:80    → Apache
LISTEN  0  128  0.0.0.0:443   → Apache SSL
LISTEN  0  128  0.0.0.0:2222  → DirectAdmin Panel
LISTEN  0  128  0.0.0.0:25    → Exim SMTP
LISTEN  0  128  0.0.0.0:143   → Dovecot IMAP
LISTEN  0  128  0.0.0.0:993   → Dovecot IMAPS
LISTEN  0  128  0.0.0.0:21    → ProFTPD
LISTEN  0  128  0.0.0.0:53    → BIND DNS
bash# Kiểm tra phiên bản DA
/usr/local/directadmin/directadmin version
# Output: DirectAdmin x.xx.x

# Kiểm tra tất cả services
/usr/local/directadmin/scripts/check_services.sh

PHẦN C — ĐĂNG NHẬP VÀ CẤU HÌNH BAN ĐẦU
C.1 — Đăng nhập DA Panel
Truy cập từ trình duyệt máy host:
https://192.168.136.11:2222

Username: admin
Password: Admin@DA2026!

⚠️ Bỏ qua cảnh báo SSL (cert tự ký)
   Chrome: Advanced → Proceed to 192.168.136.11
C.2 — Giao diện DA — 3 cấp truy cập
┌─────────────────────────────────────────────────────┐
│              DIRECTADMIN — 3 CẤP                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  CẤP 1: ADMIN (Giống Root WHM của cPanel)           │
│  ├── Login: admin / Admin@DA2026!                   │
│  ├── Quản lý toàn server                           │
│  └── URL: https://192.168.136.11:2222               │
│                                                     │
│  CẤP 2: RESELLER                                    │
│  ├── Do Admin tạo ra                               │
│  ├── Tạo/quản lý User của mình                     │
│  └── Bị giới hạn bởi Admin                         │
│                                                     │
│  CẤP 3: USER (Giống cPanel User)                    │
│  ├── Do Reseller hoặc Admin tạo                    │
│  ├── Quản lý website, email, DB của mình           │
│  └── URL: https://192.168.136.11:2222               │
│                                                     │
│  ⚠️ DA dùng CÙNG PORT 2222 cho cả 3 cấp            │
│     Phân biệt bằng username khi login              │
└─────────────────────────────────────────────────────┘
C.3 — Cấu hình Admin ban đầu
Sau khi đăng nhập Admin:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BƯỚC 1: Đổi mật khẩu Admin
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin Panel → Your Account
→ Change Password
→ New Password: NewAdmin@2026!
→ Save

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BƯỚC 2: Cấu hình Administrator Email
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin Panel → Admin Settings
→ Administrator Email: admin@da.lab.local
→ Save Settings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BƯỚC 3: Kiểm tra License
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin Panel → Admin Settings → License
→ Xem ngày hết hạn Trial
→ IP đăng ký license

PHẦN D — TẠO RESELLER VÀ USER
D.1 — Tạo Reseller Package
Admin Panel → Reseller Management
→ Add Reseller Package

Package Name:     nh-reseller
Bandwidth:        50000 MB
Disk Space:       20000 MB
Inodes:           250000      ← Số files tối đa
Domains:          20
Sub-domains:      100
Email Accounts:   200
Email Forwarders: 100
Email Lists:      20
FTP Accounts:     100
MySQL Databases:  100
MySQL Users:      200
→ Save
D.2 — Tạo Reseller Account
Admin Panel → Reseller Management → Add Reseller

Username:    reseller1
Email:       reseller1@da.lab.local
Password:    Reseller@2026!
Domain:      reseller1.local
Package:     nh-reseller
IP:          192.168.136.11   (Shared IP)
→ Add
D.3 — Tạo User Package
Admin Panel → Reseller Management → Add Package
(Hoặc login bằng reseller1 → Add Package)

Package Name:     basic-hosting
Bandwidth:        10000 MB
Disk Space:       2000 MB
Inodes:           100000
Domains:          1
Sub-domains:      5
Email Accounts:   10
MySQL Databases:  5
→ Save
D.4 — Tạo User Account
Admin Panel → User Management → Add User
(Hoặc login reseller1 → Add User)

Username:    user001
Email:       user001@khachhang1.local
Password:    User@2026!
Domain:      khachhang1.local
Package:     basic-hosting
→ Add
Xác nhận qua CLI:
bash# Kiểm tra user đã tạo
id user001
# Output: uid=1001(user001) gid=1001(user001)...

# Xem thư mục home
ls -la /home/user001/
# Phải thấy: domains/ backups/ ...

# Xem domain của user
ls /home/user001/domains/
# Output: khachhang1.local/
D.5 — Cấu trúc thư mục DA
bash# Cấu trúc thư mục DA khác cPanel
ls /home/user001/domains/khachhang1.local/

/home/user001/domains/khachhang1.local/
├── public_html/          ← Web root (giống cPanel)
├── private_html/         ← HTTPS riêng (nếu bật)
├── imap/                 ← Email storage
├── logs/                 ← Access + Error logs
└── stats/                ← Awstats statistics

# ⚠️ KHÁC cPanel:
# cPanel: /home/username/public_html/
# DA:     /home/username/domains/domain.com/public_html/

PHẦN E — CUSTOMBUILD 2.0
CustomBuild là công cụ của DA để cài/update Apache, PHP, MariaDB.
E.1 — Kiểm tra CustomBuild
bash# Thư mục CustomBuild
ls /usr/local/directadmin/custombuild/

# Xem version
/usr/local/directadmin/custombuild/build version

# Xem cấu hình hiện tại
cat /usr/local/directadmin/custombuild/options.conf
Output quan trọng trong options.conf:
ini# Web Server
webserver=apache           # apache / nginx / openlitespeed

# PHP
php1_release=8.2           # PHP version chính
php1_mode=php-fpm          # mod_php / php-fpm / suphp

# Database
mysql=mariadb
mysql_inst=yes
mysql_ver=10.6

# Mail
exim=yes
dovecot=yes
spamassassin=yes
E.2 — Cài thêm PHP version (Multi-PHP)
DirectAdmin hỗ trợ chạy nhiều version PHP cùng lúc:
bashcd /usr/local/directadmin/custombuild

# Xem PHP versions có thể cài
./build versions php

# Cài thêm PHP 8.1 (song song với 8.2)
./build set php2_release 8.1
./build set php2_mode php-fpm
./build php n        # n = build php2

# Xác nhận 2 PHP versions đã có
php8.1 -v
php8.2 -v

# Trong DA User Panel:
# → Domain Setup → PHP Version
# → Chọn 8.1 hoặc 8.2 per domain
E.3 — Cập nhật services qua CustomBuild
bashcd /usr/local/directadmin/custombuild

# Update Apache
./build apache

# Update PHP
./build php n

# Update MariaDB
./build mariadb

# Update tất cả
./build update_versions
./build all d          # d = download nếu cần

# Xem trạng thái services
./build versions

PHẦN F — QUẢN LÝ QUA DA USER PANEL
Đăng nhập bằng user001:
https://192.168.136.11:2222
Username: user001
Password: User@2026!
F.1 — Các tính năng chính DA User Panel
DA USER PANEL
│
├── 📁 Files
│   ├── File Manager      ← Upload, edit files
│   └── FTP Management    ← Tạo FTP accounts
│
├── 🌐 Domains
│   ├── Domain Setup      ← Cấu hình domain, PHP version
│   ├── Subdomains        ← Tạo subdomain
│   └── Domain Pointers   ← Giống Addon Domain cPanel
│
├── 📧 Email
│   ├── Email Accounts    ← Tạo email
│   ├── Forwarders        ← Chuyển tiếp email
│   ├── Autoresponders    ← Trả lời tự động
│   ├── Spam Filters      ← SpamAssassin
│   └── Webmail           ← Roundcube
│
├── 🗄️ MySQL Management
│   ├── Create Database
│   ├── Create User
│   └── phpMyAdmin
│
├── 🔒 SSL Certificates
│   ├── Free & Auto (Let's Encrypt)
│   └── Paste a pre-generated certificate
│
└── 📊 Statistics
    ├── Site Statistics   ← Awstats
    └── Resource Usage    ← CPU/RAM/Disk
F.2 — Tạo Database trong DA
User Panel → MySQL Management → Create Database

Database Name:   khach001_wp
Database User:   khach001_wpuser
Password:        DbPass@2026!
→ Create

# Username thực tế sẽ là: user001_khach001_wp
# DA tự thêm prefix username vào DB name
bash# Kiểm tra qua CLI
mysql -u root -p -e "SHOW DATABASES LIKE 'user001%';"
mysql -u root -p -e "SELECT user FROM mysql.user \
  WHERE user LIKE 'user001%';"
F.3 — Cài WordPress qua Softaculous
DA tích hợp Softaculous để auto-install WordPress:
User Panel → Extra Features → Softaculous

→ WordPress → Install Now

Site URL:        http://khachhang1.local
Site Name:       Website Khach Hang 1
Admin Username:  wpadmin
Admin Password:  WpAdmin@2026!
Admin Email:     admin@khachhang1.local
Language:        Vietnamese
→ Install

# Softaculous tự động:
# - Tạo database
# - Upload WordPress files
# - Cấu hình wp-config.php
# - Cài đặt WordPress hoàn toàn tự động

PHẦN G — CẤU HÌNH BẢO MẬT CƠ BẢN
G.1 — Đổi port SSH
bash# Đổi SSH port từ 22 → 2223 (tránh scan)
nano /etc/ssh/sshd_config

# Tìm dòng: #Port 22
# Sửa thành:
Port 2223

# Restart SSH
systemctl restart sshd

# Test kết nối port mới (mở terminal mới trước)
ssh -p 2223 ubuntu@192.168.136.11
G.2 — Cấu hình Firewall (UFW)
bash# Bật UFW
ufw enable

# Các ports cần mở cho DA
ufw allow 2223/tcp  comment 'SSH custom port'
ufw allow 80/tcp    comment 'HTTP'
ufw allow 443/tcp   comment 'HTTPS'
ufw allow 2222/tcp  comment 'DirectAdmin Panel'
ufw allow 25/tcp    comment 'SMTP'
ufw allow 587/tcp   comment 'SMTP Submission'
ufw allow 465/tcp   comment 'SMTPS'
ufw allow 110/tcp   comment 'POP3'
ufw allow 995/tcp   comment 'POP3S'
ufw allow 143/tcp   comment 'IMAP'
ufw allow 993/tcp   comment 'IMAPS'
ufw allow 21/tcp    comment 'FTP'
ufw allow 53/tcp    comment 'DNS TCP'
ufw allow 53/udp    comment 'DNS UDP'

# Xem rules
ufw status verbose
G.3 — Brute Force Protection
bash# DA có built-in Brute Force Monitor
# Kiểm tra cấu hình
cat /usr/local/directadmin/conf/brute.conf

# Xem IP đang bị block
cat /usr/local/directadmin/data/admin/brute_force_notice.log

# Block thủ công 1 IP
echo "192.168.1.100" >> /etc/hosts.deny

# Unblock IP bị block nhầm
/usr/local/directadmin/scripts/unblock_ip.sh 192.168.1.100

PHẦN H — KIỂM TRA TOÀN BỘ SAU CÀI ĐẶT
bash# ── Checklist đầy đủ ───────────────────────────────

# 1. DirectAdmin service
systemctl is-active directadmin
# ✅ active

# 2. Web server
systemctl is-active apache2
curl -I http://192.168.136.11
# ✅ HTTP/1.1 200 OK

# 3. Database
systemctl is-active mariadb
mysql -u root -e "SHOW DATABASES;"
# ✅ Thấy danh sách databases

# 4. Mail
systemctl is-active exim4
systemctl is-active dovecot
# ✅ Cả 2 active

# 5. DNS
systemctl is-active named
dig @192.168.136.11 khachhang1.local
# ✅ Có response

# 6. FTP
systemctl is-active proftpd
ss -tlnp | grep 21
# ✅ Port 21 listening

# 7. DA Panel accessible
curl -k -I https://192.168.136.11:2222
# ✅ HTTP/1.1 200 OK

# 8. User home directory
ls /home/user001/domains/khachhang1.local/public_html/
# ✅ Thư mục tồn tại

PHẦN I — TROUBLESHOOTING PHỔ BIẾN
Lỗi 1: DA service không start
bash# Xem log lỗi
journalctl -u directadmin -n 50

# Xem DA error log
tail -50 /var/log/directadmin/error.log

# Thử restart thủ công
systemctl restart directadmin

# Kiểm tra license
/usr/local/directadmin/directadmin licenseinfo
Lỗi 2: Không truy cập được port 2222
bash# Kiểm tra DA có lắng nghe không
ss -tlnp | grep 2222

# Kiểm tra firewall
ufw status | grep 2222

# Kiểm tra DA config
grep "port" /usr/local/directadmin/conf/directadmin.conf
# Phải thấy: port=2222
Lỗi 3: Apache không start
bash# Xem lỗi chi tiết
apache2ctl configtest
journalctl -u apache2 -n 30

# Kiểm tra port 80 có bị chiếm không
ss -tlnp | grep ':80'

# Restart Apache
systemctl restart apache2
Lỗi 4: CustomBuild lỗi khi cài PHP
bashcd /usr/local/directadmin/custombuild

# Xem log build
tail -100 /var/log/custombuild.log | grep -i "error"

# Clean và build lại
./build clean
./build php n

# Nếu thiếu dependencies
apt install -y build-essential libxml2-dev \
  libssl-dev libcurl4-openssl-dev

🔥 TÌNH HUỐNG HỖ TRỢ THỰC TẾ
Tình huống — KH báo website 500 Error sau khi upload WordPress
bash# BƯỚC 1: Xác định user và domain
grep "khachhang1.local" /etc/virtual/domainowners
# Output: khachhang1.local: user001

# BƯỚC 2: Kiểm tra error log
tail -30 /home/user001/domains/khachhang1.local/logs/error.log
# Thường thấy: Permission denied hoặc PHP Fatal Error

# BƯỚC 3: Fix permission
chown -R user001:user001 \
  /home/user001/domains/khachhang1.local/public_html/

find /home/user001/domains/khachhang1.local/public_html/ \
  -type d -exec chmod 755 {} \;

find /home/user001/domains/khachhang1.local/public_html/ \
  -type f -exec chmod 644 {} \;

# BƯỚC 4: Kiểm tra PHP version đúng chưa
# User Panel → Domain Setup → PHP Version
# WordPress 6.x cần PHP 8.0+

# BƯỚC 5: Kiểm tra wp-config.php
grep -E "DB_NAME|DB_USER|DB_HOST" \
  /home/user001/domains/khachhang1.local/public_html/wp-config.php
# DB_HOST phải là localhost
