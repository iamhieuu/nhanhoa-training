# Labs thực hành cài đặt zabbix

Lab 01 — Cài đặt Zabbix 7.0 LTS trên Ubuntu 22.04
Sơ đồ mô hình Lab:
```
┌─────────────────────────────────────────────────┐
│  VMware / VirtualBox Lab Environment            │
│                                                 │
│  ┌──────────────────────┐   ┌────────────────┐  │
│  │  zabbix-server       │   │  zabbix-agent  │  │
│  │  Ubuntu 22.04        │   │  Ubuntu 22.04  │  │
│  │  192.168.136.131     │   │  192.168.136.146 │  │
│  │  RAM: 4GB, Disk: 40G │   │  RAM: 1GB      │  │
│  └──────────────────────┘   └────────────────┘  │
│                                                 │
│  Host-only Network: 192.168.56.0/24             │
└─────────────────────────────────────────────────┘
```

A.1 Thiết lập hostname và IP tĩnh
Tất cả lệnh dưới đây thực hiện trên VM1 — 192.168.136.131

```
# Đặt hostname
hostnamectl set-hostname zabbix-server

# Xác nhận hostname đã đổi
hostname
# Output: zabbix-server
```

Cấu hình IP tĩnh qua Netplan:
```
# Xem tên interface mạng thực tế
ip link show

# Mở file cấu hình netplan
nano /etc/netplan/00-installer-config.yaml
Nội dung file:
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.136.131/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
# Apply cấu hình
sudo netplan apply

# Kiểm tra IP đã đúng chưa
ip addr show ens33
# Phải thấy: inet 192.168.136.131/24

# Kiểm tra kết nối ra ngoài
ping -c 3 8.8.8.8

```
<img width="647" height="212" alt="image" src="https://github.com/user-attachments/assets/c3267e44-ac9a-4ffe-8d53-884f6355c61c" />

2. Cập nhật hệ thống
```
sudo apt update && apt upgrade -y

# Cài các tool cần thiết
sudo apt install -y curl wget gnupg2 software-properties-common \
  sudo apt-transport-https ca-certificates lsb-release
# Kiểm tra phiên bản OS
lsb_release -a
# Output: Ubuntu 22.04.x LTS
```
<img width="318" height="95" alt="image" src="https://github.com/user-attachments/assets/ed0c8660-d308-4880-9c9e-ca9dd7534c2f" />


### 3 Cài đặt MariaDB 10.11
```
# Thêm MariaDB repository chính thức (10.11 LTS)
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="mariadb-10.11"

# Cài đặt
sudo apt install -y mariadb-server mariadb-client

# Khởi động và bật autostart
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Kiểm tra trạng thái
sudo systemctl status mariadb
```
<img width="925" height="331" alt="image" src="https://github.com/user-attachments/assets/9362370b-d103-4d96-8664-31efb1dcbae2" />


```
# Kiểm tra phiên bản
sudo mysql --version
```
<img width="623" height="45" alt="image" src="https://github.com/user-attachments/assets/1dc48a67-fddb-4db1-80d4-65dde9055d36" />

### Bảo mật MariaDB:
```

sudo mysql_secure_installation
Trả lời theo thứ tự:
Enter current password for root (enter for none):    [nhấn Enter — chưa có mật khẩu]
Switch to unix_socket authentication [Y/n]:           n
Change the root password? [Y/n]:                      Y
New password:                                         123456a@
Re-enter new password:                                123456a@
Remove anonymous users? [Y/n]:                        Y
Disallow root login remotely? [Y/n]:                  Y
Remove test database and access to it? [Y/n]:         Y
Reload privilege tables now? [Y/n]:                   Y
```

## 4 Tạo database Zabbix
```
# Đăng nhập MariaDB với mật khẩu root vừa đặt
sudo mysql -u root -p
# Nhập: 123456a@
Chạy các lệnh SQL sau trong MariaDB prompt:
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'Zabbix@DB2026!';

GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';

SET GLOBAL log_bin_trust_function_creators = 1;

FLUSH PRIVILEGES;

EXIT;
Kiểm tra database và user đã tạo:
mysql -u zabbix -p'Zabbix@DB2026!' -e "SHOW DATABASES;"
```
<img width="485" height="100" alt="image" src="https://github.com/user-attachments/assets/f58a24ae-df14-4c58-aea9-732689e3a587" />

## 5 Cài đặt Zabbix 7.0 repository
```
# Tải Zabbix 7.0 LTS repository cho Ubuntu 22.04
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

# Cài đặt repository package
sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

# Cập nhật package list
sudo apt update

# Xác nhận version Zabbix available
sudo apt-cache policy zabbix-server-mysql | grep Candidate
```
<img width="518" height="46" alt="image" src="https://github.com/user-attachments/assets/9fe5c013-3149-40ab-a9c1-868decf08651" />

## 6 Cài đặt Zabbix Server, Frontend và Agent
```
sudo apt install -y \
  zabbix-server-mysql \
  zabbix-frontend-php \
  zabbix-nginx-conf \
  zabbix-sql-scripts \
  zabbix-agent2

# Xác nhận tất cả packages đã cài
sudo dpkg -l | grep zabbix | awk '{print $2, $3}'
```
<img width="466" height="100" alt="image" src="https://github.com/user-attachments/assets/50688036-93b4-41f4-b27d-640b21490ab0" />

## 7. Import schema database
```
# Import schema — bước này mất 3-5 phút, không được Ctrl+C
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz \
  | mysql --default-character-set=utf8mb4 \
          -u zabbix \
          -p'Zabbix@DB2026!' \
          zabbix

# Tắt log_bin_trust sau khi import xong
sudo mysql -u root -p'123456a@' \
  -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Kiểm tra số bảng đã import
sudo mysql -u zabbix -p'Zabbix@DB2026!' zabbix \
  -e "SELECT COUNT(*) AS total_tables
      FROM information_schema.tables
      WHERE table_schema = 'zabbix';"
```
<img width="461" height="124" alt="image" src="https://github.com/user-attachments/assets/976f1db7-fcf7-4378-899d-03eb24466463" />

## 8 Cấu hình Zabbix Server
```
# Backup file cấu hình gốc trước khi chỉnh
sudo cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bak

# Chỉnh sửa cấu hình
sudo nano /etc/zabbix/zabbix_server.conf
Tìm và sửa các dòng sau (dùng Ctrl+W để tìm trong nano):
# Tìm dòng: # DBPassword=
# Sửa thành:
DBPassword=Zabbix@DB2026!

# Tìm dòng: # DBSocket=
# Sửa thành (dùng Unix socket thay TCP/IP — nhanh hơn):
DBSocket=/var/run/mysqld/mysqld.sock

# Tùy chọn: đặt múi giờ Việt Nam
# Tìm dòng: # LogSlowQueries=
# Thêm dòng mới phía dưới:
# (không cần sửa gì thêm ở bước này)
Lưu file: Ctrl+X → Y → Enter.
```
## 9 Cấu hình Nginx cho Zabbix Frontend
```
sudo nano /etc/zabbix/nginx.conf
Tìm 2 dòng bị comment và bỏ dấu #:
#        listen          8080;
#        server_name     example.com;

# Sửa thành:
        listen          80;
        server_name     192.168.136.131;
```
Lưu file. Sau đó tắt site mặc định của Nginx:
```
# Xóa default site để tránh conflict
sudo rm -f /etc/nginx/sites-enabled/default

# Kiểm tra cấu hình Nginx hợp lệ không
sudo nginx -t
```
<img width="433" height="80" alt="image" src="https://github.com/user-attachments/assets/65de4fac-2bc0-4685-a879-22be935fd837" />

## 10. Cấu hình PHP-FPM timezone
```
sudo nano /etc/zabbix/php-fpm.conf
Tìm dòng timezone và sửa:
; php_value[date.timezone] = Europe/Riga
# Sửa thành (bỏ dấu ; và đổi timezone):
php_value[date.timezone] = Asia/Ho_Chi_Minh
```
## 11 Cấu hình Zabbix Agent 2 trên VM1
Agent này để Zabbix Server tự giám sát chính mình:  
```
sudo nano /etc/zabbix/zabbix_agent2.conf  
Tìm và sửa:
Tìm: Server=127.0.0.1
# Sửa thành:
Server=127.0.0.1

# Tìm: ServerActive=127.0.0.1
# Sửa thành:
ServerActive=127.0.0.1

# Tìm: Hostname=Zabbix server
# Sửa thành:
Hostname=zabbix-server
```
## 12 Khởi động tất cả dịch vụ
```
# Khởi động theo đúng thứ tự
sudo systemctl restart zabbix-server
sudo systemctl restart zabbix-agent2
sudo systemctl restart nginx
sudo systemctl restart php8.1-fpm

# Bật autostart khi reboot
sudo systemctl enable zabbix-server
sudo systemctl enable zabbix-agent2
sudo systemctl enable nginx
sudo systemctl enable php8.1-fpm
```
## 13 Mở firewall
```
# Kiểm tra UFW đang bật không
sudo ufw status

# Nếu UFW đang active, mở các port cần thiết
sudo ufw allow 80/tcp    comment 'Zabbix Frontend HTTP'
sudo ufw allow 443/tcp   comment 'Zabbix Frontend HTTPS'
sudo ufw allow 10051/tcp comment 'Zabbix Server trapper'
sudo ufw allow 10050/tcp comment 'Zabbix Agent'
sudo ufw allow 22/tcp    comment 'SSH'
# Xem lại rules đã thêm
sudo ufw status verbose
sudo ufw reload
```

## 14 Kiểm tra Zabbix Server đang chạy
```
# Xem log Zabbix Server — 3 dòng quan trọng phải thấy
tail -50 /var/log/zabbix/zabbix_server.log | grep -E "started|database|error|warning"
Output mong đợi (bình thường):
... zabbix_server #0 started [main process]
... connection to database 'zabbix' established
... zabbix_server #1 started [configuration syncer #1]
... zabbix_server #2 started [db watchdog #1]
```
Nếu thấy lỗi:
```
# Xem toàn bộ log lỗi
tail -100 /var/log/zabbix/zabbix_server.log | grep -i "error\|cannot\|failed"
```
Kiểm tra process đang chạy:
```
# Tất cả 4 service phải Active (running)
sudo systemctl is-active zabbix-server zabbix-agent2 nginx php8.1-fpm

# Kiểm tra port đang lắng nghe
ss -tlnp | grep -E '80|10050|10051'
Output mong đợi:
LISTEN  0  128  0.0.0.0:80      0.0.0.0:*  users:(("nginx"))
LISTEN  0  128  0.0.0.0:10050   0.0.0.0:*  users:(("zabbix_agent2"))
LISTEN  0  128  0.0.0.0:10051   0.0.0.0:*  users:(("zabbix_server"))
```
_____________

## Mở trình duyệt trên máy host hoặc VM2, truy cập:
http://192.168.136.131  
<img width="740" height="392" alt="image" src="https://github.com/user-attachments/assets/8a79c649-8f21-4138-b202-c5527051029c" />

### Bước 1 — Check prerequisites

Trang đầu tiên kiểm tra môi trường PHP. Tất cả dòng phải hiển thị "OK" màu xanh. Nếu có dòng "Fail":  
```
# Kiểm tra lại PHP extensions
php -m | grep -E "bcmath|mbstring|gd|xml|ldap|json"
# Nếu thiếu extension nào, cài thêm:
apt install -y php8.1-bcmath php8.1-mbstring php8.1-gd \
  php8.1-xml php8.1-ldap php8.1-xmlrpc
# Khởi động lại PHP-FPM
systemctl restart php8.1-fpm
```
<img width="481" height="276" alt="image" src="https://github.com/user-attachments/assets/7d5dac5d-650f-4ac6-a688-2c5c55fd332a" />


### Bước 2 — Configure DB connection

<img width="466" height="277" alt="image" src="https://github.com/user-attachments/assets/f381fbd3-d8a8-4890-b149-055e39838e63" />  

```
Database type:    MySQL
Database host:    localhost
Database port:    0      (để 0 = dùng default socket)
Database name:    zabbix
Store credentials in: Plain text
User:             zabbix
Password:         Zabbix@DB2026!
Database TLS encryption: [bỏ trống]
```
Nhấn "Next step" — nếu thấy thông báo màu đỏ "Cannot connect to the database", xem phần Troubleshooting bên dưới.  

```
### Bước 3 — Settings
Zabbix server name:  My Zabbix Lab
Default time zone:   Asia/Ho_Chi_Minh
Default theme:       Blue
```
<img width="494" height="305" alt="image" src="https://github.com/user-attachments/assets/3d8baf83-7b7b-4a6c-ae82-5a0dac9d0d2e" />

```
### Bước 4 — Pre-installation summary
Xem lại thông tin và nhấn "Next step".
### Bước 5 — Finish
Nhấn "Finish". Trang đăng nhập hiện ra.
Đăng nhập lần đầu
Username: Admin
Password: zabbix
```
<img width="476" height="283" alt="image" src="https://github.com/user-attachments/assets/a69e8f56-93ee-4d02-9b18-7739862ff499" />
<img width="958" height="448" alt="image" src="https://github.com/user-attachments/assets/ba3feec2-e275-426d-82dd-f91d9a340e57" />

sau đó **đổi mật khẩu Admin ngay lập tức**  
<img width="959" height="476" alt="image" src="https://github.com/user-attachments/assets/b9e14c28-0876-43c9-8325-cb9190c746f6" />

----

## Cấu hình VM2 (Zabbix Agent)

#### 1 Kiểm tra mạng và hostname
```
# Đặt hostname
sudo hostnamectl set-hostname zabbix-agent01
# Kiểm tra hostname
hostnamectl
# Kiểm tra IP được cấp từ DHCP
ip addr
# Test kết nối đến Zabbix Server (VM1)
ping -c 3 192.168.136.131
```
<img width="681" height="214" alt="image" src="https://github.com/user-attachments/assets/de8fa604-2d1e-424f-82d1-c16c8ab63d21" />

---

#### 2 Cập nhật hệ thống

```bash
sudo apt update && sudo apt upgrade -y
```

---

#### 3 Cài đặt Zabbix Agent 2

```bash
# Tải repository Zabbix 7.0 cho Ubuntu 22.04
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb

# Cài repository
sudo dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb

# Cập nhật package
sudo apt update

# Cài Zabbix Agent 2
sudo apt install -y zabbix-agent2

# Kiểm tra phiên bản
zabbix_agent2 --version
```
<img width="627" height="304" alt="image" src="https://github.com/user-attachments/assets/0b695230-d888-48d2-bc89-ffc73bc77ba4" />

---

#### 4 Cấu hình Zabbix Agent 2

```bash
# Backup file cấu hình
sudo cp /etc/zabbix/zabbix_agent2.conf /etc/zabbix/zabbix_agent2.conf.bak

# Mở file cấu hình
sudo nano /etc/zabbix/zabbix_agent2.conf
```

Tìm và sửa các dòng:

```ini
Server=192.168.136.131

ServerActive=192.168.136.131

Hostname=zabbix-agent01
```

Giải thích:

* `Server`: IP của Zabbix Server được phép truy vấn Agent.
* `ServerActive`: Agent chủ động gửi dữ liệu về Server.
* `Hostname`: Phải trùng với Hostname khi tạo Host trên Zabbix Frontend.

Lưu file và thoát.

---

#### 5 Khởi động Agent

```bash
sudo systemctl start zabbix-agent2
sudo systemctl enable zabbix-agent2
# Kiểm tra trạng thái
sudo systemctl status zabbix-agent2
```

<img width="747" height="236" alt="image" src="https://github.com/user-attachments/assets/124b88f3-bf97-4661-8187-bc159f04c913" />
  

Kiểm tra port Agent:  

```bash
sudo ss -tlnp | grep 10050
```

Kết quả mong đợi:
<img width="706" height="47" alt="image" src="https://github.com/user-attachments/assets/96e2458b-fce7-4201-aed0-c8a3278d93c1" />


---

#### 6 Cấu hình Firewall

```bash
sudo ufw allow 10050/tcp comment 'Zabbix Agent'

sudo ufw allow 22/tcp comment 'SSH'

sudo ufw reload

sudo ufw status
```

---

#### 7 Kiểm tra Agent từ Zabbix Server (VM1)

Nếu chưa có công cụ test:

```bash
sudo apt install -y zabbix-get
```

Thực hiện các lệnh kiểm tra:

```bash
zabbix_get -s 192.168.136.146 -p 10050 -k "agent.ping"
```
<img width="574" height="47" alt="image" src="https://github.com/user-attachments/assets/7fc94823-3984-4004-abb6-1decfa99c1dd" />


---

```bash
zabbix_get -s 192.168.136.146 -p 10050 -k "agent.version"
```

<img width="557" height="48" alt="image" src="https://github.com/user-attachments/assets/2ae842e9-9e38-494b-b24b-361e5ca192c8" />


---

```bash
zabbix_get -s 192.168.136.146 -p 10050 -k "system.hostname"
```

<img width="532" height="44" alt="image" src="https://github.com/user-attachments/assets/866567b2-e963-41d6-8f88-beb27a0b9bfe" />


---

```bash
zabbix_get -s 192.168.136.146 -p 10050 -k "system.uname"
```

```bash
zabbix_get -s 192.168.136.146 -p 10050 -k "vm.memory.size[available]"
```
<img width="577" height="63" alt="image" src="https://github.com/user-attachments/assets/b550df27-e96a-42ad-a443-d46fa1284d71" />

-----

## Thêm VM2 vào Zabbix Frontend

#### 1 Thêm Host

Truy cập trình duyệt:

```text
http://<IP_ZABBIX_SERVER>/
```

Đăng nhập Zabbix Frontend.

**Configuration → Hosts → Create host**

#### Vào mục quản lý Hosts
```
Nhìn sang cột menu màu xanh đậm ở bên trái màn hình.
Click vào mục Data collection (nằm ngay dưới mục Reports).
Một menu con sẽ xổ ra, bạn chọn mục Hosts.
Sau khi vào mục Hosts, nhìn lên góc trên cùng bên phải màn hình, bạn sẽ thấy một nút màu xanh dương có chữ Create host. Hãy click vào đó.
```

#### Điền thông tin

```
Host name: Điền zabbix-agent01 
Templates: Click vào ô này, gõ tìm từ khóa Linux by Zabbix agent 2 (hoặc Linux by Zabbix agent tùy thuộc vào bản agent bạn cài dưới client) rồi chọn nó.
Host groups: Click vào, tìm nhóm Linux servers.
Interfaces: Nhìn ngay bên dưới mục Groups sẽ có phần Interfaces.
Click vào chữ Add màu xanh -> Chọn Agent.
Ở ô IP address: Điền IP của máy Client vào (Máy cần được giám sát).
Ở ô Port: Giữ nguyên là 10050.
Cuối cùng, cuộn xuống dưới cùng bấm nút Add (Màu xanh dương) để lưu lại là xong!
```
<img width="581" height="338" alt="image" src="https://github.com/user-attachments/assets/fd37bb85-0280-49a4-b2c6-1d6a20ed4a2c" />

---

### 2 Kiểm tra Host đã kết nối

**Data → Hosts**

Kiểm tra cột **Availability**:

```text
 màu xanh  : Agent kết nối thành công
 màu đỏ    : Không kết nối được
 màu xám   : Chưa poll dữ liệu (đợi 1–2 phút)
```

#### Kiểm tra từ Server bằng lệnh

```bash
sudo zabbix_get -s 192.168.136.146 -p 10050 -k "agent.ping"
```

Kết quả mong đợi:
<img width="860" height="79" alt="image" src="https://github.com/user-attachments/assets/91f84486-4d1b-46a5-b5f5-d57927d62fe1" />

---

### 3 Kiểm tra dữ liệu thu thập

**Monitoring → Latest data**
````
Tại ô Hosts: Nhấp Select -> Chọn đúng máy zabbix-agent01.  
Nhấn nút Apply (hoặc Filter).
Các thẻ thông tin (Item) cốt lõi cần chú ý:system.cpu.util $\rightarrow$ Tải xử lý của CPU (đơn vị %)
vm.memory.size[available] (Dung lượng RAM còn trống (đơn vị Bytes))
vfs.fs.size[/,free] (Dung lượng ổ cứng còn trống tại thư mục gốc /)
system.uptime(Thời gian máy Client đã hoạt động liên tục kể từ lần bật gần nhất.)
````
<img width="944" height="437" alt="image" src="https://github.com/user-attachments/assets/d8edeae0-5f61-4cad-b0aa-6acee0137f66" />

<img width="945" height="440" alt="image" src="https://github.com/user-attachments/assets/3992c592-78cb-4c2f-a69f-e90a9fd3109c" />

### Kiểm tra trực tiếp từ Server

```bash
sudo zabbix_get -s 192.168.136.146 -p 10050 -k "system.cpu.util"
```

```bash
sudo zabbix_get -s 192.168.136.146 -p 10050 -k "vm.memory.size[available]"
```

```bash
sudo zabbix_get -s 192.168.136.146 -p 10050 -k "vfs.fs.size[/,free]"
```
<img width="619" height="101" alt="image" src="https://github.com/user-attachments/assets/efaba1cc-fe22-4994-a5db-19f393c46226" />
