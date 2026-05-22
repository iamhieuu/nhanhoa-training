# Báo cáo học tập ngày 19 - FTP Server

## 1. Tổng quan về FTP Server
File Transfer Protocol (FTP) — giao thức tầng ứng dụng ra đời năm 1971, chuẩn hóa qua RFC 959 (1985). Mục đích duy nhất của FTP là chuyển file giữa hai máy tính qua mạng TCP/IP.  
FTP hoạt động theo mô hình client–server và dùng hai kết nối TCP riêng biệt: một kênh điều khiển và một kênh truyền dữ liệu.  

###  So sánh FTP với các giao thức khác

Giao thức |	Port |	Mã hóa |	Xác thực |	Firewall |	Đánh giá 2026
-- | -- |  -- | -- | -- | --
FTP |	21/20	| Không	| User/Pass | cleartext	| Khó	 | Tránh dùng
FTPS	| 21 / 990	| SSL/TLS |	User/Pass + Cert	| Trung bình	| Legacy
SFTP	| 22 |	SSH	| Key / Password |	Dễ	| Khuyến nghị
SCP	| 22 |	SSH	| Key / Password | 	Dễ	| Tốt
HTTPS |	443	 | TLS 1.3	| Đa dạng	 |Dễ	| Web/API

### Thành phần chính của FPT 
* FTP Server: Lưu & cung cấp file  
* FTP Client: Kết nối & tải file  
* Network: TCP/IP transport

FTP vẫn còn dùng ở Web hosting control panels (cPanel, Plesk), hệ thống ERP/SCADA cũ, thiết bị IoT công nghiệp, và một số ISP legacy.  

## 2. Nguyên lý hoạt động của FTP
FTP hoạt động theo mô hình Client – Server:  

FTP Client  <---------------->  FTP Server  

Trong đó:  

Thành phần |	Chức năng  
-- | --
FTP Client |	Gửi yêu cầu upload/download   
FTP Server |	Lưu trữ và cung cấp dữ liệu  

FTP sử dụng hai kết nối TCP riêng biệt:  

Kết nối |	Port	|Chức năng
-- | -- | --
Control Connection |	21	 | Điều khiển phiên làm việc
Data Connection |	20 hoặc port ngẫu nhiên |	Truyền dữ liệu

Nguyên lý hoạt động của FTP Active Mode  
Client kết nối tới Server qua port 21 -> Client mở một port ngẫu nhiên -> Server chủ động kết nối ngược lại Client qua port 20  
<img width="916" height="230" alt="image" src="https://github.com/user-attachments/assets/c9556280-964f-43de-b93a-834b03579ac0" />  
* Ưu điểm
  * Hoạt động đơn giản
  * Ít yêu cầu mở nhiều port trên server
* Nhược điểm
  * Server phải kết nối ngược về client
  * Dễ bị NAT/Firewall chặn
  * Không phù hợp mạng hiện đại
Nguyên lý hoạt động FTP Passive Mode
Client kết nối control connection -> Client gửi yêu cầu Passive Mode -> Server cấp port dữ liệu -> Client chủ động kết nối
<img width="971" height="243" alt="image" src="https://github.com/user-attachments/assets/cf38881a-6cbd-4716-9b66-b91bb6caae08" />

* Ưu điểm
  * Tương thích NAT/Firewall
  * Client luôn chủ động kết nối
  * Hoạt động ổn định trong thực tế
* Nhược điểm
  * Server cần mở nhiều passive ports
 

 --- 
Các phương thức xác thực trong FTP  
FTP hỗ trợ hai phương thức xác thực phổ biến:  
* anonymous
* authenticated users


* Xác thực Anonymous
Cho phép người dùng truy cập FTP mà không cần tài khoản thật.
Username: anonymous hoặc ftp. Password: bất kỳ email. Không cần tài khoản thật. Rủi ro bảo mật cao — chỉ dùng cho public download server, chia sẻ dữ liệu công khai.

* Xác thực authenticated users
Username + Password thật.Bảo mật cao hơn, Kiểm soát người dùng, có thể phân quyền   
Plain FTP: Gửi cleartext qua mạng. Điều này dẫn tới có thể bị sniff packet, không an toàn trên internet
FTPS/SFTP:
  * Mã hóa thông tin xác thực, dữ liệu truyền tải. Luôn dùng option này kết hợp mã hóa.
  * SFTP hoạt động trên SSH: TCP Port 22. Bảo mật cao, mã hóa toàn bộ phiên làm việc và không cần nhiều kết nối như FTP

## 3. Các loại FTP Server

* Anonymous FTP: Rất rủi ro
Cho phép truy cập công khai không cần tài khoản. Username anonymous, password là email bất kỳ.  
Dùng khi Public software mirror (kernel.org thời xưa), firmware update server nội bộ.    
Hiện nay hầu hết đã thay bằng HTTPS public download.  

* Authenticated FTP: Dùng được
Yêu cầu username + password hợp lệ. Phân quyền theo user/group. Có thể jail user vào thư mục riêng (chroot).  
Vấn đề: Plain FTP vẫn gửi password cleartext qua network.  
Cần kết hợp TLS (FTPS) hoặc dùng SFTP thay thế.    

* FTPS (FTP Secure): Chấp nhận được
FTP gốc + mã hóa SSL/TLS. Hai dạng:  
Explicit TLS / Port 21 STARTTLS  
Implicit TLS / Port 990, luôn mã hóa    

Vẫn có vấn đề với NAT/Firewall do kênh data riêng. Cấu hình phức tạp hơn SFTP.  

* SFTP (SSH FTP): Khuyến nghị
Không phải FTP — là giao thức hoàn toàn khác chạy trên SSH (port 22). Mã hóa toàn bộ phiên làm việc.   
Chỉ 1 port 22, xác thực: SSH key / Password    
Firewall: Rất dễ    
Lựa chọn mặc định cho mọi hệ thống mới trong 2026.    

## 4. Phần mềm FTP Server phổ biến
FileZilla Server bản v1.8.x
Hệ điều hành Windows – GUI thân thiện, dễ dùng  
Free, open-source. GUI quản lý dễ dùng. Hỗ trợ FTPS. Tốt cho môi trường Windows Server không chuyên.  

vsftpd bản v3.0.5  
Hệ điều hành Linux – Khuyến nghị  
Very Secure FTP Daemon. Mặc định trên Ubuntu, Debian, CentOS. Được thiết kế với security-first. Nhẹ, nhanh, ít tài nguyên.  

ProFTPD bản v1.3.8  
Linux – Linh hoạt  
Cú pháp config kiểu Apache httpd. Hệ thống module phong phú. Phù hợp cho hosting provider cần tùy chỉnh sâu. 

IS FTP bản WS 2022/2025
Hệ điều hành Windows Server – Built-in
Tích hợp sẵn trong Windows Server, quản lý qua IIS Manager. Tích hợp tốt với AD. Hỗ trợ FTPS.  

Pure-FTPd là FTP Server mã nguồn mở tập trung vào bảo mật, đơn giản, hiệu năng. Sử dụng hệ điều hành linux thường dùng trong môi trường hosting.  
Cerberus FTP Server là phần mềm FTP thương mại chạy chủ yếu trên Windows có giao diện GUI trực quan nhưng tiêu tốn tài nguyên hơn FTP server Linux.  


## Cài đặt và cấu hình FTP Server trên windows server 2022
Bước 1: Cài đặt IIS và FTP Service  
Vào Server Manager > Add roles and features > Chọn Web Server (IIS) > Trong mục Role Services, tích chọn FTP Server (bao gồm FTP Service và FTP Extensibility).   
<img width="488" height="350" alt="{5ED2F4B8-F3F3-4558-A2F9-13F56595F8C7}" src="https://github.com/user-attachments/assets/11bda58f-c418-4e2a-a2d2-6a774e316aa5" />

Bước 2: Tạo Chứng chỉ SSL (Certificate)  
Để chạy FTPS, bạn cần chứng chỉ. Vào IIS Manager > Nháy đúp vào Server Certificates > Click Create Self-Signed Certificate (Hoặc import chứng chỉ thật từ Let's Encrypt/Comodo nếu công ty bạn có tên miền riêng).  
<img width="416" height="318" alt="{3C560B2E-7381-4ECC-8096-427497C3BAD5}" src="https://github.com/user-attachments/assets/31e6c986-534d-4621-aa72-cf711d2b63d8" />

Bước 3: Cấu hình FTP Site và Passive Mode    
Chuột phải vào Sites > Add FTP Site > Trỏ đường dẫn vật lý (VD: D:\FTP_Data).  
<img width="417" height="320" alt="{7295C077-1810-4A4B-8751-503882CCC1E3}" src="https://github.com/user-attachments/assets/da45f9aa-542b-4edb-9318-d7558107cf74" />

SSL: Chọn chứng chỉ vừa tạo và bắt buộc chọn Require SSL (Để từ chối các kết nối không mã hóa).   
<img width="420" height="324" alt="{C0CC9B82-AC5E-4C14-B882-ABD468024F14}" src="https://github.com/user-attachments/assets/2d4cb201-9fbc-4c53-8706-445917e44f6b" />

Authentication: Chọn Basic (Bỏ chọn Anonymous).   
Authorization: Cấp quyền cho user hoặc group Windows cụ thể (VD: Đối_Tác_Group được Read/Write).  
<img width="419" height="319" alt="{A56DF78C-305A-424F-802E-D067F6524AF7}" src="https://github.com/user-attachments/assets/02a06af1-7e78-49a8-b004-a5c102a17d7a" />


Thiết lập User trên Windows Server 2022 qua powershell

```
# Tạo local user cho FTP
$Password = ConvertTo-SecureString "StrongP@ssw0rd2026!" -AsPlainText -Force
New-LocalUser -Name "ftpuser1" -Password $Password -Description "FTP User 1" -UserMayNotChangePassword
```

<img width="494" height="145" alt="{C6055310-369C-4263-B35F-62912729AB46}" src="https://github.com/user-attachments/assets/f924f9de-ee90-422b-b3d9-acd88cac6b2d" />

```
# Thêm vào group FTP Users
New-LocalGroup -Name "FTPUsers" -Description "FTP Users Group"
Add-LocalGroupMember -Group "FTPUsers" -Member "ftpuser1"

```
<img width="250" height="330" alt="{9239D168-789E-4B5F-A977-F5F0F51E36BF}" src="https://github.com/user-attachments/assets/be25639b-e311-4d4e-aad1-047aa233d64b" />

 Cấp quyền thư mục FTP  
````
$FTPPath = "C:\FTPRoot\ftpuser1"
New-Item -ItemType Directory -Path $FTPPath -Force
$Acl = Get-Acl $FTPPath
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "ftpuser1", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$Acl.SetAccessRule($Rule)
Set-Acl -Path $FTPPath -AclObject $Acl

````

<img width="492" height="361" alt="{D93321ED-94D4-4B20-8665-89DC67F27E59}" src="https://github.com/user-attachments/assets/b14317dd-948a-4275-8bbf-761f37124e39" />
<img width="241" height="300" alt="{2BAB2A59-B2D2-49F9-9D1A-77C9C0BBE173}" src="https://github.com/user-attachments/assets/54f8569b-8847-424f-bb01-162a111d5a8d" />

```
# Cho phép FTP
New-NetFirewallRule -DisplayName "FTP Server" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow

# Cho phép Passive Mode
New-NetFirewallRule -DisplayName "FTP Passive Mode" -Direction Inbound -Protocol TCP -LocalPort 10000-10100 -Action Allow

# Nếu dùng FTPS
New-NetFirewallRule -DisplayName "FTPS" -Direction Inbound -Protocol TCP -LocalPort 990 -Action Allow
```
<img width="495" height="291" alt="{709B2673-8692-4DAF-A43B-06EA1AFAD7E5}" src="https://github.com/user-attachments/assets/cb623990-fcef-4953-bd84-bdff15d7d5a7" />

Giới hạn login attempts qua Account Lockout Policy
<img width="663" height="422" alt="{85C5A07B-6323-454A-8002-8BC2550039D3}" src="https://github.com/user-attachments/assets/25c93382-f060-4517-be86-d76e1fc0182b" />

Cài Windows Firewall Advanced để chặn IP tấn công  
```
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} | Select-Object -First 20
```
## Cài đặt trên Ubuntu Server 22.04  

* vsftpd (Very Secure FTP Daemon) — Phổ biến nhất
```
# Bước 1: cài đặt vsftpd
sudo apt install vsftpd -y

# Bước 3: Kiểm tra version (2026: vsftpd 3.0.5)
vsftpd -v
```
<img width="187" height="39" alt="{54BA1FBB-2501-46CD-93D1-DD69ED10F992}" src="https://github.com/user-attachments/assets/70a4fd26-d2a8-428b-a293-9af38450745c" />

```
# Bước 4: Kích hoạt và start service
sudo systemctl enable vsftpd
sudo systemctl start vsftpd

# Bước 5: Kiểm tra trạng thái
sudo systemctl status vsftpd
```
<img width="563" height="175" alt="{D811546E-0020-4C1B-9E90-5F4F77E6BE57}" src="https://github.com/user-attachments/assets/56ab12c6-1a35-411a-bc2f-0a03ab318442" />

* SFTP qua OpenSSH
```
sudo systemctl status ssh

# Nếu chưa có:
sudo apt install openssh-server -y
sudo systemctl enable ssh && sudo systemctl start ssh

# Kiểm tra version (2026: OpenSSH 8.9p1)
ssh -V
```
<img width="544" height="223" alt="{D127A2F0-B282-4089-9206-10A105DCFB3D}" src="https://github.com/user-attachments/assets/2080df7b-3a55-49ed-9c70-65e280e28444" />
<img width="366" height="44" alt="{0D89C9D3-0F86-4CA5-90C1-1C0BB36F6868}" src="https://github.com/user-attachments/assets/3b84e195-bef8-42be-a849-02e62acd7825" />

---

* Cấu hình vsftpd cơ bản

Backup config gốc trước khi chỉnh  
```
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.backup
```
FIle cấu hình chính :sudo nano /etc/vsftpd.conf    
```
listen=NO
listen_ipv6=YES
anonymous_enable=NO          # TẮT anonymous - BẮT BUỘC về bảo mật
local_enable=YES             # Cho phép user local login
write_enable=YES             # Cho phép upload
local_umask=022              # Quyền file mặc định = 644

# ===== GIỚI HẠN THƯ MỤC =====
chroot_local_user=YES        # Nhốt user trong home dir của họ
allow_writeable_chroot=YES   # Cho phép ghi trong chroot
user_sub_token=$USER
local_root=/home/$USER/ftp   # Thư mục gốc FTP cho mỗi user

# ===== CỔng VÀ PASSIVE MODE =====
listen_port=21
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
pasv_address=YOUR_SERVER_IP  # Thay bằng IP thực của server

# ===== GIỚI HẠN KẾT NỐI =====
max_clients=50               # Tối đa 50 kết nối đồng thời
max_per_ip=5                 # Mỗi IP tối đa 5 kết nối
connect_timeout=60
data_connection_timeout=120

# ===== LOG =====
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
xferlog_std_format=YES
log_ftp_protocol=YES
vsftpd_log_file=/var/log/vsftpd_detail.log

# ===== GIỚI HẠN BĂNG THÔNG =====
# local_max_rate=1048576     # Giới hạn 1MB/s per user (bỏ comment khi cần)
# anon_max_rate=512000       # Giới hạn 500KB/s cho anonymous

# ===== DANH SÁCH USER =====
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO             # Chỉ cho user trong list mới được login

# ===== FTP BANNER =====
ftpd_banner=Welcome to Lab FTP Server 2026
```

Áp dụng cấu hình: sudo systemctl restart vsftpd
<img width="641" height="199" alt="{AEABA8D3-76BC-4A47-BCED-02C733409D99}" src="https://github.com/user-attachments/assets/ef95588f-cf3d-441c-9668-433a855c9d0d" />

* Thiết lập User, Thư mục, Quyền truy cập
Tạo FTP user riêng
```
sudo adduser --shell /usr/sbin/nologin ftpuser1
```
<img width="451" height="208" alt="{3CB6D053-AAF6-47E7-8233-54846C6E0D6C}" src="https://github.com/user-attachments/assets/07d2299f-2c19-4f55-bdcb-e58537fb5b62" />

```
# Tạo thư mục FTP cho user
sudo mkdir -p /home/ftpuser1/ftp/upload
sudo chown nobody:nogroup /home/ftpuser1/ftp
sudo chmod a-w /home/ftpuser1/ftp          
sudo chown ftpuser1:ftpuser1 /home/ftpuser1/ftp/upload
sudo chmod 755 /home/ftpuser1/ftp/upload

# Thêm vào danh sách user được phép FTP
echo "ftpuser1" | sudo tee -a /etc/vsftpd.userlist
```
<img width="264" height="132" alt="{03C29B5F-C364-4B4F-A036-1C148B185F9F}" src="https://github.com/user-attachments/assets/660d7bd8-af9e-46f3-a635-09d6b667b971" />
Nếu là user không trong nhóm /etc/vsftpd.userlist  

<img width="295" height="91" alt="{727196CE-1880-4440-8757-227A2F985AB3}" src="https://github.com/user-attachments/assets/528256d8-da2d-4a03-8c9f-e54dcbf0e29f" />

Thiết lập firewall
```
# Cho phép FTP port 21
sudo ufw allow 21/tcp

# Cho phép Passive Mode ports
sudo ufw allow 10000:10100/tcp

# Nếu dùng SFTP (port 22)
sudo ufw allow ssh

# Kiểm tra
sudo ufw status verbose
```
<img width="351" height="175" alt="{AA335D29-9F4D-4E68-AE37-8D512B35EBF9}" src="https://github.com/user-attachments/assets/ff924302-ab61-40bb-a503-9696041afc40" />

## BẢO MẬT FTP SERVER
#### Các rủi ro bảo mật chính
| Rủi ro | Mức độ | Mô tả |
|---|---|---|
| Truyền dữ liệu không mã hóa |  Cao | Username, password và dữ liệu truyền dưới dạng plain text |
| Brute Force Attack |  Cao | Kẻ tấn công thử mật khẩu tự động hàng nghìn lần mỗi giây |
| Man-in-the-Middle (MITM) |  Cao | Tin tặc nghe lén hoặc chỉnh sửa dữ liệu giữa client và server |
| Anonymous Access |  Trung bình | Bất kỳ ai cũng có thể truy cập nếu bật anonymous FTP |
| Directory Traversal |  Trung bình | Người dùng thoát khỏi thư mục được cấp quyền truy cập |
| Port Scanning |  Thấp | Kẻ tấn công dò quét để phát hiện dịch vụ FTP đang hoạt động |
| Phần mềm lỗi thời | Trung bình | Khai thác các lỗ hổng bảo mật chưa được vá |

####  Giải pháp: FTPS và SFTP
* **Cấu hình FTPS: (FTP thêm TLS)**
Bước 1: Tạo self-signed certificate (cho Lab)
```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/vsftpd.key \
  -out /etc/ssl/certs/vsftpd.pem \
  -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Lab/CN=ftp.lab.local"
```
Cấu hình thêm cho file cấu hình chính FTP

```
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.key
require_ssl_reuse=NO
ssl_ciphers=HIGH 
```

<img width="559" height="270" alt="{5A5CC924-C548-46EE-AD7A-0F11FD3B63F2}" src="https://github.com/user-attachments/assets/0f99205f-b0b1-4354-8dc3-59fe866d1a08" />

* **Cấu hình SFTP Chroot Jail**

Sửa file: sudo nano /etc/ssh/sshd_config  
Thêm vào cuối
```
Match Group sftponly
    ChrootDirectory /home/%u
    ForceCommand internal-sftp -l INFO
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
```

* Tạo group SFTP riêng
```
sudo groupadd sftponly
sudo usermod -aG sftponly ftpuser1
```

```
# Setup thư mục (ChrootDirectory phải owned bởi root)
sudo chown root:root /home/ftpuser1
sudo chmod 755 /home/ftpuser1
sudo mkdir -p /home/ftpuser1/upload
sudo chown ftpuser1:ftpuser1 /home/ftpuser1/upload

sudo systemctl restart ssh
```

#### Chống Brute Force Attack
Cài đặt Brute Force: sudo apt install fail2ban -y  
File cấu hình Brute Force: sudo nano /etc/fail2ban/jail.local  
```
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1 192.168.136.0/24

[vsftpd]
enabled  = true
port     = ftp,ftp-data,ftps,ftps-data
filter   = vsftpd
logpath  = /var/log/vsftpd.log
maxretry = 3

[sshd]
enabled  = true
port     = ssh
filter   = sshd
#logpath  = /var/log/auth.log
maxretry = 5
bantime  = 86400
```
Khởi động 
```
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```
<img width="557" height="202" alt="{FE7930B6-82AF-4F79-804D-8E808FF6BE2D}" src="https://github.com/user-attachments/assets/74466982-cbcd-4504-a061-6d12f04a5a1e" />

Xem IP bị ban
<img width="380" height="139" alt="{8B924C60-47B1-4482-A88C-DB43DA325856}" src="https://github.com/user-attachments/assets/3640d032-b987-408f-8e37-76988369009d" />

### Chính sách mật khẩu mạnh
* Ubuntu

Cài đặt : sudo apt install libpam-pwquality -y
Cấu hình qua file: sudo nano /etc/security/pwquality.conf
```
minlen = 12          # Tối thiểu 12 ký tự
dcredit = -1         # Ít nhất 1 số
ucredit = -1         # Ít nhất 1 chữ hoa
lcredit = -1         # Ít nhất 1 chữ thường
ocredit = -1         # Ít nhất 1 ký tự đặc biệt
maxrepeat = 3        # Không lặp ký tự quá 3 lần
```

### Cập nhật phần mềm định kì
Lệnh unattend để cập nhập tự động cho ubuntu
```
# Cài unattended-upgrades
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Kiểm tra cập nhật thủ công
sudo apt update && sudo apt list --upgradable

# Cập nhật vsftpd khi có bản mới
sudo apt upgrade vsftpd -y
```
Lệnh này tự động cập nhật cho windows server
````
Install-Module -Name PSWindowsUpdate -Force
Enable-WindowsAutoUpdate
````
<img width="481" height="85" alt="{78DF9827-4ED8-4AC3-AE49-9B8E0B3E822E}" src="https://github.com/user-attachments/assets/d0cad690-661e-409b-b46f-191cc52c3464" />
<img width="474" height="113" alt="{4AFF16C1-1A92-4B46-8D4D-4D35F83F32FE}" src="https://github.com/user-attachments/assets/ede58a4d-5006-4fac-a361-cff8ea6b70c7" />
