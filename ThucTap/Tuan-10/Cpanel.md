# Báo cáo thực tập ngày 50 - Panel

----

PHẦN A — CHUẨN BỊ HỆ THỐNG
A.1 — Thiết lập hostname
```
# Đặt hostname đúng định dạng FQDN (bắt buộc có dấu chấm)
hostnamectl set-hostname cpanel.lab.local

# Xác nhận
hostname
# Output: cpanel.lab.local

hostname -f
# Output: cpanel.lab.local
```

A.2 — Cấu hình IP tĩnh
```
# Xem tên interface
ip link show
# Thường là: ens160 hoặc eth0

# Xem file cấu hình network hiện tại
ls /etc/NetworkManager/system-connections/
```
Chỉnh sửa file cấu hình:
```
# Tìm đúng tên file (thường là tên interface)
nmcli connection show

# Sửa IP tĩnh qua nmcli (thay ens160 bằng tên interface thực tế)
nmcli connection modify ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.136.148/24 \
  ipv4.gateway 192.168.136.2 \
  ipv4.dns "8.8.8.8,8.8.4.4"

# Áp dụng
nmcli connection up ens160

# Kiểm tra
ip addr show ens160
# Phải thấy: inet 192.168.136.148/24
```
A.3 — Cập nhật /etc/hosts
```
# Thêm entry cho hostname
echo "192.168.136.148  cpanel.lab.local cpanel" >> /etc/hosts

# Kiểm tra
cat /etc/hosts
# Phải thấy dòng vừa thêm
```
A.4 — Cập nhật hệ thống
```
# Update toàn bộ packages
dnf update -y

# Kiểm tra phiên bản OS
cat /etc/almalinux-release
# Output: AlmaLinux release 9.x (...)
```
A.5 — Tắt các dịch vụ xung đột
```
# Tắt và disable firewalld
# (cPanel sẽ cài CSF/firewall riêng)
systemctl stop firewalld
systemctl disable firewalld

# Tắt SELinux tạm thời
setenforce 0

# Tắt SELinux vĩnh viễn
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Xác nhận SELinux đã tắt
getenforce
# Output: Permissive

# Tắt NetworkManager nếu cần (cPanel quản lý network)
# KHÔNG tắt nếu bạn dùng NetworkManager để set IP tĩnh
```
A.6 — Kiểm tra kết nối internet
```
# Ping Google
ping -c 3 8.8.8.8

# Ping domain (kiểm tra DNS)
ping -c 3 google.com

# Kiểm tra có thể kết nối repo cPanel
curl -I https://securedownloads.cpanel.net
# Phải trả về HTTP 200 hoặc 301
```
PHẦN B — CÀI ĐẶT cPANEL/WHM
B.1 — Tải và chạy script cài đặt
```
# Chuyển về thư mục home
cd /home

# Tải script cài đặt chính thức từ cPanel
curl -o latest -L https://securedownloads.cpanel.net/latest

# Kiểm tra file đã tải
ls -lh latest
# Phải thấy file khoảng vài KB (đây là bootstrap script)

# Chạy cài đặt — BẮT ĐẦU TỪ ĐÂY SẼ MẤT 30-60 PHÚT
sh latest
```

B.2 — Theo dõi quá trình cài đặt
Mở terminal thứ 2, SSH vào server và chạy:
```
# Xem log real-time
tail -f /var/log/cpanel-install.log

# Hoặc xem tiến trình cụ thể hơn
tail -f /var/log/cpanel-install.log | grep -E "Installing|Configuring|Starting|Error|Warning"
Các giai đoạn sẽ thấy trong log:
[Giai đoạn 1] Downloading cPanel packages...
[Giai đoạn 2] Installing RPM packages...
[Giai đoạn 3] Configuring Apache/Nginx...
[Giai đoạn 4] Configuring MySQL/MariaDB...
[Giai đoạn 5] Configuring Exim (mail server)...
[Giai đoạn 6] Configuring Dovecot (IMAP/POP3)...
[Giai đoạn 7] Setting up cPanel services...
[Giai đoạn 8] Running final configuration...
```
B.3 — Xác nhận cài đặt thành công
```
# Khi log hiện dòng này là xong:
# "Thank you for installing cPanel & WHM!"
```
<img width="890" height="212" alt="image" src="https://github.com/user-attachments/assets/79e8ac1f-0a04-4e27-a9b1-5a226208433d" />

```
# Kiểm tra các service cPanel đang chạy
systemctl status cpanel
# Phải thấy: Active (running)

# Kiểm tra các port quan trọng đang lắng nghe
ss -tlnp | grep -E '80|443|2083|2087|2086|2082'
Output mong đợi:
LISTEN  0  128  0.0.0.0:80    → Apache/Nginx (HTTP)
LISTEN  0  128  0.0.0.0:443   → HTTPS
LISTEN  0  128  0.0.0.0:2083  → cPanel SSL
LISTEN  0  128  0.0.0.0:2087  → WHM SSL
LISTEN  0  128  0.0.0.0:2086  → cPanel non-SSL
LISTEN  0  128  0.0.0.0:2082  → WHM non-SSL
```
<img width="922" height="265" alt="image" src="https://github.com/user-attachments/assets/6d63a7bc-7336-4f7a-8216-33db7b1ef7c6" />


PHẦN C — CẤU HÌNH BAN ĐẦU WHM
C.1 — Đăng nhập WHM lần đầu
```
Truy cập từ máy host (trình duyệt):

https://192.168.136.148:2087 (bỏ qua cảnh báo SSL)
```
<img width="956" height="466" alt="image" src="https://github.com/user-attachments/assets/942765f4-efa8-431c-8bb1-a80d4f1742cd" />

```
Username: root
Password: 123456a@
```
C.2 — WHM Initial Setup Wizard
Khi đăng nhập lần đầu, WHM sẽ hiện Setup Wizard gồm 5 bước:  
```
BƯỚC 1 — Agree to License
├── Đọc và tick "I agree to these terms"
└── Click "Agree to All"

BƯỚC 2 — Networking Setup
├── Server Contact Email: admin@lab.local
├── Nameserver 1: ns1.lab.local  (192.168.136.148)
├── Nameserver 2: ns2.lab.local  (192.168.136.148)
└── Click "Save & Go to Step 3"

BƯỚC 3 — FTP Server
├── Chọn: Pure-FTPd (recommended)
└── Click "Save & Go to Step 4"

BƯỚC 4 — Mail Preferences  
├── Mail Server: Exim
├── IMAP/POP3: Dovecot
└── Click "Save & Go to Step 5"

BƯỚC 5 — Database
├── MySQL/MariaDB: MariaDB 10.6 (default)
└── Click "Finish"
```
<img width="955" height="445" alt="image" src="https://github.com/user-attachments/assets/5efd9924-68b2-4fe0-abf0-a4db6aece68d" />

C.3 — Cấu hình thiết yếu sau Setup Wizard

Kích hoạt Trial License
```
# Chạy lệnh này trên server để kích hoạt trial 15 ngày
/usr/local/cpanel/cpkeyclt
Cấu hình Firewall cơ bản trong WHM
WHM → Plugins → ConfigServer Security & Firewall (CSF)
→ Firewall Configuration
→ Tìm dòng TESTING = "1"
→ Đổi thành TESTING = "0"
→ Save Settings
→ Restart csf+lfd
Thiết lập Nameserver (Bind DNS)
WHM → DNS Functions → Nameserver Selection
→ Chọn: BIND
→ Click Save
```
PHẦN D — TẠO HOSTING ACCOUNT ĐẦU TIÊN
D.1 — Tạo Package (Gói hosting)  
```
WHM → Add a Package
Điền thông tin:
Package Name:    basic-hosting
Disk Space:      1024 MB  (1GB)
Monthly Bandwidth: 10240 MB (10GB)
Max FTP Accounts:  5
Max Email Accounts: 10
Max Databases:     5
Max Sub Domains:   5
Max Addon Domains: 1
Max Parked Domains: 2
CGI Access:        ✅ Enabled
Shell Access:      ❌ Disabled (bảo mật)
Nhấn Add để lưu package.
```
D.2 — Tạo Account khách hàng đầu tiên
```
WHM → Account Functions → Create a New Account
Điền thông tin:
Domain:       customer1.local
Username:     customer1       (tự sinh hoặc tự đặt)
Password:     Customer@2026!
Email:        customer1@lab.local
Package:      basic-hosting   (chọn package vừa tạo)
Nhấn Create — nếu thành công sẽ thấy:
Account Creation Status: OK
IP: 192.168.136.148
Package: basic-hosting
```
D.3 — Đăng nhập cPanel của Account vừa tạo
```
http://192.168.136.148:2086
Username: customer1
Password: Customer@2026!
Hoặc từ WHM:
WHM → List Accounts → customer1 → Click icon cPanel
(Đăng nhập không cần mật khẩu — WHM có thể login thay)
```
PHẦN E — KIỂM TRA VÀ XÁC NHẬN
E.1 — Checklist kiểm tra sau cài đặt
```
# 1. Kiểm tra tất cả services cPanel
/usr/local/cpanel/scripts/restartsrv_httpd    # Apache
/usr/local/cpanel/scripts/restartsrv_exim     # Mail
/usr/local/cpanel/scripts/restartsrv_dovecot  # IMAP
/usr/local/cpanel/scripts/restartsrv_mysql    # Database

# 2. Xem version cPanel đang cài
cat /usr/local/cpanel/version
# Output: 120.x.x.x (hoặc version mới nhất)

# 3. Kiểm tra disk usage
df -h
# / phải còn ít nhất 5GB free

# 4. Kiểm tra RAM
free -h
# Swap phải được cPanel tạo tự động

# 5. Kiểm tra Apache đang chạy
curl -I http://192.168.136.148
# Phải trả về: HTTP/1.1 200 OK hoặc 301
```
E.2 — Kiểm tra account customer1 hoạt động
```
# Xem danh sách accounts trên server
cat /etc/trueuserdomains

# Xem thư mục home của customer1
ls -la /home/customer1/
# Phải thấy: public_html, mail, logs, etc.

# Kiểm tra virtual host Apache của customer1
cat /etc/apache2/conf.d/userdata/std/2_4/customer1/customer1.local/

# Test tạo file index.html
echo "<h1>Hello from customer1</h1>" > /home/customer1/public_html/index.html
chown customer1:customer1 /home/customer1/public_html/index.html

# Truy cập thử
curl http://192.168.136.148 -H "Host: customer1.local"
# Phải thấy: Hello from customer1
```
PHẦN F — TROUBLESHOOTING PHỔ BIẾN

Lỗi 1: Cài đặt bị treo / timeout
```
# Kiểm tra log xem lỗi ở đâu
tail -100 /var/log/cpanel-install.log | grep -i "error\|fail\|cannot"

# Thử chạy lại installer (tiếp tục từ bước lỗi)
sh latest
# Installer tự detect và resume từ chỗ dừng
```
Lỗi 2: Không truy cập được WHM sau cài
```
# Kiểm tra service cpanel
systemctl status cpanel
systemctl restart cpanel

# Kiểm tra port 2087 có mở không
ss -tlnp | grep 2087

# Kiểm tra CSF firewall có block không
csf -l | grep 2087
# Nếu bị block, mở port
csf -a 192.168.136.0/24  # Cho phép toàn bộ dải IP lab
```
Lỗi 3: Hostname không hợp lệ
```
# cPanel báo lỗi: "Hostname must be fully qualified"
# Kiểm tra hostname hiện tại
hostname -f

# Sửa lại cho đúng
hostnamectl set-hostname cpanel.lab.local

# Cập nhật /etc/hosts
sed -i 's/^127.0.0.1.*/127.0.0.1 localhost/' /etc/hosts
echo "192.168.136.148 cpanel.lab.local cpanel" >> /etc/hosts
```
Lỗi 4: License expired / invalid
```
# Kiểm tra license status
/usr/local/cpanel/cpkeyclt

# Xem thông tin license
cat /usr/local/cpanel/cpanelinfo

# Nếu dùng trial, kích hoạt lại
curl -o /usr/local/cpanel/cpanelinfo \
  https://verify.cpanel.net/getkey?ip=192.168.136.148
```
