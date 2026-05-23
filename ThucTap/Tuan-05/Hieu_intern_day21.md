# Báo cáo thực tập ngày 21 - Thực hành cài đặt Ftp server 
---

## 1. Cài đặt FTP Server trên Ubuntu vsftpd.
#### Yêu cầu: Đổi sang mạng bridge

#### Cập nhật, cài đặt vsftps
sudo apt update && sudo apt upgrade -y  
sudo apt install vsftpd -y  
<img width="627" height="207" alt="{105DAB68-0C44-45D0-8A61-DD4AFA8DC9D9}" src="https://github.com/user-attachments/assets/c3de51f4-3f28-4a6a-8383-0f3eb5c1314d" />

#### Cấu hình file config
sudo nano /etc/vsftpd.conf
```
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
log_ftp_protocol=YES
connect_from_port_20=YES

chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/home/$USER/ftp

pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
pasv_address=192.168.1.100

userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

ftpd_banner=Lab FTP Server 2026
```

####  Tạo user & thư mục
```
sudo adduser --shell /usr/sbin/nologin ftplab
# mk 123456a@
Thêm user vào whitelist:
echo "ftplab" | sudo tee -a /etc/vsftpd.userlist
Tạo cấu trúc thư mục:
sudo mkdir -p /home/ftplab/ftp/upload

# Thư mục gốc: root sở hữu, KHÔNG ghi được 
sudo chown nobody:nogroup /home/ftplab/ftp
sudo chmod a-w /home/ftplab/ftp

# Thư mục upload: ftplab sở hữu, ghi được
sudo chown ftplab:ftplab /home/ftplab/ftp/upload
sudo chmod 755 /home/ftplab/ftp/upload

# Tạo file test để kiểm tra
echo "Hello from Ubuntu FTP Lab 2026!" | sudo tee /home/ftplab/ftp/upload/test.txt
Kiểm tra cấu trúc đúng chưa:
ls -la /home/ftplab/ftp/
```

#### Mở firewall & restart 
````
sudo ufw allow 21/tcp
sudo ufw allow 10000:10100/tcp
sudo ufw allow ssh
sudo ufw --force enable
sudo ufw status
````

````
Khởi động lại vsftpd với config mới:
sudo systemctl restart vsftpd
sudo systemctl status vsftpd
````
<img width="623" height="196" alt="{E162C78C-1ED6-4F51-BF1E-975A4EF8F783}" src="https://github.com/user-attachments/assets/69aca000-0cb6-4bfb-b051-5d40dbaf5a50" />

#### Tải filezila bên windows 
https://filezilla-project.org/download.php?type=client  
```
Mở FileZilla → File → Site Manager → New Site, điền:
Protocol  FTP - File Transfer Protocol
Host 172.16.16.5  (IP Ubuntu VM)
Port 21
Encryption Use explicit FTP over TLS if available
Logon Type Normal
User  ftplab
Password 123456a@
```
<img width="489" height="245" alt="{E76B7EEE-8DFD-49E1-B887-8FE0E9861FE4}" src="https://github.com/user-attachments/assets/77231e76-5a19-4322-92b1-97a203c56d6e" />

kết quả đạt được  

<img width="590" height="312" alt="{263C556A-2F5E-4CE9-827C-97DB2967FDCE}" src="https://github.com/user-attachments/assets/a98ddebf-3636-426a-a152-bd990f228daa" />

-----------------
## 2 Cài đặt ftp trên window server  
#### Yêu cầu để mạng Bridge 
<img width="281" height="118" alt="image" src="https://github.com/user-attachments/assets/45b1c9f9-43dd-4226-9b3a-f120f260e415" />

#### Cài IIS FTP Feature  
<img width="490" height="348" alt="image" src="https://github.com/user-attachments/assets/ec8890c7-0dea-457c-90b0-56b191ca9db6" />

#### Tạo site FTP
<img width="415" height="318" alt="image" src="https://github.com/user-attachments/assets/ca01785c-bce3-4e78-9cd6-9e9ec9cb0929" />

<img width="414" height="316" alt="image" src="https://github.com/user-attachments/assets/ade490c7-ea91-45b3-ab4a-b2a911a306bc" />
<img width="415" height="316" alt="{050B0EA9-587D-4D95-819F-ED64E34963C7}" src="https://github.com/user-attachments/assets/78b1b5ad-1c7b-4dd6-8ba4-46c46181ab2b" />

#### Trên máy client

Vào file exporter, gõ ftp://IPSERVER

<img width="577" height="307" alt="{AF87282D-07EA-49D7-B507-33CF746F4BEA}" src="https://github.com/user-attachments/assets/36d037d8-def0-4705-8787-53e678f1743e" />

----
# Database Server

## 1. Mô Hình Client-Server Trong Hệ Thống Database
### 1.1 Tổng quan mô hình

Mô hình Client-Server là kiến trúc nền tảng của hầu hết hệ thống database hiện đại. Trong mô hình này:  
Client gửi request/query đến Database Server  
Database Server xử lý request và trả kết quả  
Hai thành phần có thể chạy trên hai máy vật lý khác nhau  

### 1.2 Kiến trúc tổng quan
``````
┌─────────────────────────────────────────────────────────────────┐
│                        NETWORK / LAN / WAN                     │
│                                                                 │
│   ┌──────────────┐    SQL Query / Request    ┌───────────────┐ │
│   │    CLIENT    │ ────────────────────────► │ DATABASE      │ │
│   │              │                           │ SERVER        │ │
│   │ - Web App    │ ◄──────────────────────── │               │ │
│   │ - API        │      Result / Data        │ - Query Engine│ │
│   │ - BI Tool    │                           │ - Storage     │ │
│   │ - Admin Tool │      Port 3306/5432       │ - Auth Module │ │
│   └──────────────┘                           └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
``````
1.3 Vai trò từng thành phần
Client
Client là phía gửi yêu cầu đến database server.  
Nhiệm vụ:  
* Gửi câu lệnh SQL
* Nhận dữ liệu trả về
* Hiển thị dữ liệu cho người dùng
* Không trực tiếp lưu trữ dữ liệu

Ví dụ:
* NodeJS
* DBeaver
* Grafana
* Metabase
* Database Server


Database Server là thành phần xử lý và lưu trữ dữ liệu.  
Nhiệm vụ:  

* Xử lý query
* Quản lý transaction
* Quản lý user và permission
* Quản lý concurrency
* Đọc/ghi dữ liệu trên disk
