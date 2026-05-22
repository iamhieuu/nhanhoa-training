# Báo cáo thực tập ngày 20 - FTP Server phần 2

## 7.  Ứng dụng thực tế của FTP Server
Mặc dù hiện nay có nhiều giao thức chia sẻ file hiện đại (như cloud storage), FTP vẫn đóng vai trò quan trọng trong nhiều hệ thống nhờ tính ổn định và khả năng kiểm soát cao.  

* Chia sẻ file trong nội bộ doanh nghiệp: FTP Server đóng vai trò như một kho lưu trữ tập trung    
* Lưu trữ và truyền tải dữ liệu lớn (backup, media, v.v.): FTP được thiết kế chuyên biệt để truyền tải các file "khổng lồ" và có khả năng tiếp tục tải lại nếu đường truyền bị đứt giữa chừng    
* Tích hợp với các hệ thống web hosting    
* Sử dụng trong phát triển phần mềm  

#### Thực hành chia sẻ file trong nội bộ doanh nghiệp
````
# Tạo các nhóm theo phòng ban
sudo groupadd ketoan
sudo groupadd kinh_doanh
sudo groupadd it_dept

# Tạo thư mục shared
sudo mkdir -p /home/ftp_shared/{ketoan,kinh_doanh,it_dept,chung}

# Phân quyền theo phòng ban
sudo chown root:ketoan /home/ftp_shared/ketoan
sudo chmod 770 /home/ftp_shared/ketoan     # Chỉ group ketoan đọc/ghi

sudo chown root:kinh_doanh /home/ftp_shared/kinh_doanh
sudo chmod 770 /home/ftp_shared/kinh_doanh

sudo chmod 775 /home/ftp_shared/chung      # Tất cả đọc, group ghi
````
<img width="359" height="93" alt="{DDF79CFE-3CB8-4D11-BAB5-6EBB36E2995A}" src="https://github.com/user-attachments/assets/e4b1bb3d-e4ea-400b-8d8b-1bcb07006ae8" />

````
# Tạo user và gán vào phòng ban
sudo adduser --shell /usr/sbin/nologin nhanvien_kt
sudo usermod -aG ketoan nhanvien_kt
````

<img width="502" height="42" alt="image" src="https://github.com/user-attachments/assets/21fb482a-4077-4552-bfab-0bb5cc9c6d9a" />

#### Thực hành Backup Server với FTP
Cài trên client
sudo apt install lftp -y  

Script backup trên ubuntu client  
```
sudo nano /usr/local/bin/ftp_backup.sh
#!/bin/bash
# FTP Backup Script 2026

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backups"
FTP_HOST="192.168.136.147"
FTP_USER="backup_user"
FTP_PASS="123456a@"
FTP_DIR="/backup"

# 1. Tạo backup archive tại máy Client
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" /var/www /etc/nginx /home
# 2. Upload lên FTP Server dùng lftp
lftp -c "
  set ftp:ssl-force true
  set ssl:verify-certificate no
  open -u $FTP_USER,$FTP_PASS $FTP_HOST
  cd $FTP_DIR
  put $BACKUP_DIR/backup_$DATE.tar.gz
  quit
"
# 3. Xóa backup cũ hơn 7 ngày trên FTP Server
lftp -c "
  open -u $FTP_USER,$FTP_PASS $FTP_HOST
  cd $FTP_DIR
  glob -a rm *$(date -d '7 days ago' +%Y%m%d)*.tar.gz
  quit
"
# 4. Dọn dẹp file backup tạm trên máy Client cho đỡ tốn dung lượng
rm "$BACKUP_DIR/backup_$DATE.tar.gz"
echo "Backup $DATE completed!"
```
<img width="361" height="239" alt="{071F8BFD-F4C8-4766-9AEC-303EBA9D124F}" src="https://github.com/user-attachments/assets/83290f98-b3ec-420c-a284-bf0b5c980d15" />  

Lên lịch chạy tự động  

<img width="366" height="219" alt="{54DC9739-5B89-493D-8866-57D2CE41EFC0}" src="https://github.com/user-attachments/assets/2f8beeb3-5336-4c6f-a301-bc3073cc3319" />

Bên Server  
Tạo user, gán quyền  
<img width="405" height="276" alt="{6121CB1A-77CD-464D-A915-B1A8E3559926}" src="https://github.com/user-attachments/assets/ef9f0b89-2c70-46dd-8675-6b151eddda75" />

## 8. Hiệu suất và tối ưu hóa
• Tối ưu băng thông và tốc độ truyền tải.
Nếu một người dùng tải file với tốc độ tối đa, họ có thể chiếm trọn băng thông (Bandwidth) của công ty.  

Giải pháp: Quản trị viên thường thiết lập giới hạn băng thông trên FTP Server. Ví dụ: giới hạn tốc độ tải xuống tối đa là 5MB/s cho mỗi tài khoản để đảm bảo đường truyền chung không bị ảnh hưởng.  

sudo nano /etc/vsftpd.conf
```
# Giới hạn tốc độ upload/download (bytes/s)
local_max_rate=5242880      # 5 MB/s cho user thường
anon_max_rate=1048576       # 1 MB/s cho anonymous (nếu bật)
```

<img width="469" height="266" alt="{CE6B99BC-2855-4306-B677-A562FEBFE7AA}" src="https://github.com/user-attachments/assets/e4fe08a3-f640-4c99-9a21-c12eee8a613c" />

```
# Giới hạn riêng cho từng user
# Tạo file /etc/vsftpd/user_conf/username
# Nội dung: local_max_rate=2097152 (2MB/s)
```

---

 • Quản lý số lượng kết nối đồng thời.  
sudo nano /etc/vsftpd.conf
```
max_clients=100              # Tổng kết nối tối đa
max_per_ip=10                # Mỗi IP tối đa 10 kết nối
connect_timeout=60           # Timeout kết nối (giây)
data_connection_timeout=300  # Timeout truyền data
idle_session_timeout=600     # Timeout session rảnh (10 phút)
```

<img width="261" height="253" alt="{28EA5C96-0809-45B3-BC15-6801C24BE012}" src="https://github.com/user-attachments/assets/270bfba4-6b21-4d25-b0ef-afddf95a0c80" />

  • Tối ưu TCP cho truyền file lớn
````
# Tối ưu cho FTP Server
net.core.rmem_max = 134217728        # 128MB receive buffer
net.core.wmem_max = 134217728        # 128MB send buffer
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr  # BBR - thuật toán tối ưu nhất 2026
````

• Giám sát hiệu suất và khắc phục sự cố (timeout, kết nối bị gián đoạn).
````
# Xem FTP log real-time
sudo tail -f /var/log/vsftpd.log
````
<img width="578" height="36" alt="{1EB0E7B7-8D82-436A-BC55-D6AD4DA38A8A}" src="https://github.com/user-attachments/assets/3a8c96a8-56a5-401d-930d-cc4076241134" />

````
# Đếm số kết nối hiện tại
sudo netstat -an | grep :21 | grep ESTABLISHED | wc -l
````
<img width="460" height="25" alt="{2D63ABB5-9685-4C20-BCFD-E61EAB117218}" src="https://github.com/user-attachments/assets/3cad1474-d7d6-40d3-bb99-fbde5822eaa5" />

````
# Xem kết nối chi tiết
sudo ss -tnp | grep vsftpd
````
````
# Xem CPU/RAM của vsftpd
ps aux | grep vsftpd
htop -p $(pgrep vsftpd)
````

<img width="607" height="44" alt="{3B2B33A9-4144-4361-BFD7-EEF67EE95917}" src="https://github.com/user-attachments/assets/30bb81d7-d509-467c-bcc8-6efad8486659" />

<img width="621" height="171" alt="{50136E0E-E6C5-4D14-875C-817A5A4F57A0}" src="https://github.com/user-attachments/assets/78f02d3f-f1fc-4190-bcb3-e0658c9a1936" />

Script giám sát tự động  
sudo nano /usr/local/bin/ftp_monitor.sh  

```
#!/bin/bash
# FTP Monitor Script

THRESHOLD_CONNECTIONS=80   # Cảnh báo khi >80 kết nối
LOGFILE="/var/log/ftp_monitor.log"

# Đếm kết nối
CURRENT_CONN=$(ss -tnp | grep vsftpd | wc -l)

echo "[$(date)] Connections: $CURRENT_CONN" >> $LOGFILE

if [ $CURRENT_CONN -gt $THRESHOLD_CONNECTIONS ]; then
    echo "CẢNH BÁO: FTP có $CURRENT_CONN kết nối!" | \
    mail -s "FTP Alert" admin@company.com
fi

# Kiểm tra service còn chạy không
if ! systemctl is-active --quiet vsftpd; then
    echo "[$(date)] vsftpd DOWN - Restarting..." >> $LOGFILE
    systemctl restart vsftpd
    echo "vsftpd đã restart!" | mail -s "FTP Emergency" admin@company.com
fi
```
Cấp quyền và gán tự động  
```
chmod +x /usr/local/bin/ftp_monitor.sh

# Chạy mỗi 5 phút
echo "*/5 * * * * root /usr/local/bin/ftp_monitor.sh" | sudo tee -a /etc/crontab
```

## 8.4 Khắc phục Sự cố Thường gặp

1. Timeout kết nối
Nguyên nhân gây lỗi:  
Lỗi do NAT / Cloud: Nếu Server nằm sau một Router hoặc chạy trên Cloud, nó thường chỉ biết Private IP của nó. Server sẽ gửi nhầm IP nội bộ này cho Client. Client không thể nào kết nối vào một IP nội bộ được, dẫn đến Timeout.
* Giải pháp: check IP trong  /etc/vsftpd.conf
<img width="201" height="78" alt="{EFF1AB6E-39F0-4E7C-BF34-292C0C4D93F4}" src="https://github.com/user-attachments/assets/b722f572-2148-4630-ae21-0f1b9ee99854" />

Lỗi do Firewall: Server đã báo đúng IP, nhưng Tường lửa của Server lại chặn dải Port ngẫu nhiên đó (ví dụ chặn dải 10000-10100), khiến Client không vào được.  

2. Lỗi "500 OOPS: vsftpd: refusing to run with writable root inside chroot"
Để bảo vệ hệ thống tuyệt đối, phần mềm vsftpd phiên bản mới được lập trình để tự sát (refuse to run) nếu phát hiện thư mục gốc của User FTP có quyền Ghi.
* Giải pháp 1: Bỏ quyền ghi trên root dir
sudo chmod a-w /home/ftpuser1/ftp  

* Giải pháp 2: Thêm vào vsftpd.conf
allow_writeable_chroot=YES

3. Lỗi "530 Login incorrect" (Từ chối đăng nhập)
* vsftpd có một danh sách gọi là /etc/vsftpd.userlist. Tùy vào cấu hình trong file vsftpd.conf (userlist_deny=YES hay NO) mà file này sẽ biến thành:  
  * Blacklist (Danh sách đen): Ai có tên trong này sẽ bị cấm (Báo lỗi 530).  
  * Whitelist (Danh sách trắng): Chỉ những ai có tên trong này mới được vào (Ai không có tên sẽ báo lỗi 530).

````
Kiểm tra user có trong /etc/vsftpd.userlist không
cat /etc/vsftpd.userlist

 Kiểm tra shell của user
grep ftpuser1 /etc/passwd
````

* Khi Login, hệ thống bảo mật Linux (PAM) sẽ check file /etc/shells xem cái Shell /usr/sbin/nologin kia có nằm trong danh sách "Các Shell đáng tin cậy của hệ thống" hay không. Nếu không có, PAM sẽ coi User này là bất hợp pháp và trả về lỗi 530 Login incorrect

```
# Đảm bảo /usr/sbin/nologin có trong /etc/shells
cat /etc/shells | grep nologin
# Nếu không có:
echo "/usr/sbin/nologin" | sudo tee -a /etc/shells
```

4. Tốc độ truyền tải chậm
Nghẽn do Mạng (Network): Băng thông của đường truyền từ Client tới Server bị hẹp hoặc bị suy hao. Công cụ iperf3 dùng để đo tốc độ mạng thuần túy.
```
# Kiểm tra băng thông mạng
iperf3 -s    # Phía server
iperf3 -c SERVER_IP -t 30   # Phía client

```
Nghẽn do Ổ cứng (Disk I/O): Server nhận dữ liệu quá nhanh từ mạng nhưng tốc độ ghi của ổ cứng (HDD/SSD) không theo kịp, dẫn đến hàng đợi bị đầy. Lệnh iostat giúp SysAdmin biết ổ cứng có đang bị quá tải hay không.  

```
# Kiểm tra disk I/O
iostat -x 1 5
```

Nghẽn do Cấu hình (Software): Do chính Quản trị viên vô tình cấu hình giới hạn tốc độ thông qua tham số local_max_rate mà không nhớ, hoặc cấu hình con số quá nhỏ.  
```
# Kiểm tra có bị giới hạn băng thông không
grep "max_rate" /etc/vsftpd.conf

```

5. Kết nối bị gián đoạn
Việc duy trì một kết nối mạng (TCP Session) liên tục sẽ ngốn tài nguyên của Server (RAM, CPU, Socket). Do đó, cả Hệ điều hành, Tường lửa lẫn Ứng dụng luôn có các cơ chế Timeout tự động dọn dẹp.  

FTP Idle Timeout (idle_session_timeout): Nếu Client kết nối vào Server nhưng treo máy đi uống cafe (không gửi lệnh gì), Server sẽ tự ngắt để nhường chỗ cho người khác  
```
# Tăng timeout
# Trong vsftpd.conf:
idle_session_timeout=1800    # 30 phút
data_connection_timeout=600  # 10 phút
````

Keep-Alive: Đối với các giao thức chạy trên nền SSH, các Router/Firewall trung gian thường tự động ngắt các kết nối không làm gì quá lâu. Cấu hình ClientAliveInterval sẽ ép hệ thống gửi các gói tin ping ngầm định kỳ để báo với Firewall mình vẫn hoạt động ở đây  

```
# Giữ kết nối SSH/SFTP
# Trong /etc/ssh/sshd_config:
ClientAliveInterval 60
ClientAliveCountMax 10
```
---

# Các công cụ và giao thức liên quan

1. FTP Client là phần mềm được cài đặt trên máy tính của người dùng, đóng vai trò làm giao diện để kết nối, tương tác và truyền tải dữ liệu với máy chủ FTP (FTP Server).

  * FileZilla: Đây là phần mềm mã nguồn mở và miễn phí phổ biến nhất hiện nay. Điểm mạnh của FileZilla là giao diện trực quan (chia đôi màn hình: một bên là máy tính cá nhân, một bên là máy chủ), hỗ trợ đa nền tảng (Windows, macOS, Linux) và tương thích với nhiều giao thức bảo mật như SFTP, FTPS. Nó phù hợp cho cả người mới bắt đầu lẫn quản trị viên web.

  * WinSCP: Đây là một FTP client dành riêng cho hệ điều hành Windows, nổi bật với khả năng bảo mật cao. WinSCP hỗ trợ mạnh mẽ các giao thức mã hóa như SFTP và SCP. Ngoài giao diện đồ họa, nó còn tích hợp công cụ dòng lệnh (command-line), rất lý tưởng cho các lập trình viên hoặc chuyên gia IT muốn tự động hóa quá trình truyền tải file bằng các đoạn mã (script).

  * Cyberduck: Một ứng dụng rất được ưa chuộng trên macOS (dù vẫn có phiên bản cho Windows). Cyberduck có giao diện thân thiện, hiện đại và không chỉ hỗ trợ FTP/SFTP mà còn kết nối trực tiếp được với các dịch vụ lưu trữ đám mây như Amazon S3, Google Drive hay Microsoft Azure.

2. Tích hợp với các công cụ quản lý file
Thay vì dùng phần mềm chuyên dụng (như FileZilla), người dùng có thể kết nối FTP trực tiếp thông qua các trình quản lý file có sẵn trên hệ điều hành để tạo cảm giác quen thuộc như đang thao tác với ổ cứng máy tính.

  * Windows Explorer (File Explorer): Bạn có thể gõ trực tiếp địa chỉ FTP (ví dụ: ftp://diachi_IP) vào thanh địa chỉ của File Explorer trên Windows. Máy chủ FTP sẽ hiện ra như một thư mục mạng (Network Drive). Ưu điểm là thao tác kéo thả, copy/paste vô cùng quen thuộc. Nhược điểm là tốc độ thường chậm hơn phần mềm chuyên dụng, dễ bị ngắt kết nối và không hỗ trợ tính năng tiếp tục tải khi rớt mạng.

  * Total Commander: Đây là một công cụ quản lý file của bên thứ ba vô cùng nổi tiếng với giao diện 2 cửa sổ song song. Total Commander có tích hợp sẵn tính năng kết nối FTP. Nó cho phép những người dùng chuyên nghiệp quản lý đồng thời file trên máy tính và trên máy chủ một cách nhanh chóng bằng hệ thống phím tắt đa dạng, không cần phải dùng chuột quá nhiều.


### So sánh FTP với các dịch vụ lưu trữ đám mây

Mặc dù cả FTP và các dịch vụ lưu trữ đám mây đều được sử dụng để lưu trữ và truyền tải dữ liệu qua mạng, nhưng mục đích sử dụng và cách hoạt động của chúng rất khác nhau.

| Tiêu chí | Giao thức FTP | Lưu trữ đám mây (Google Drive, Dropbox) |
|---|---|---|
| **Mục đích chính** | Truyền tải số lượng lớn file, quản lý mã nguồn website, sao lưu server. | Làm việc nhóm, đồng bộ hóa dữ liệu cá nhân, chia sẻ file dễ dàng. |
| **Cấu trúc quản lý** | Phân cấp thư mục truyền thống, người dùng phải tự quản lý hoặc thuê máy chủ. | Hệ sinh thái dịch vụ (SaaS), mọi thứ được nhà cung cấp tối ưu sẵn. |
| **Tính năng cộng tác** | Không có. Chỉ hỗ trợ tải lên (upload) và tải xuống (download). | Có thể chỉnh sửa file trực tiếp cùng lúc, bình luận và lưu lịch sử phiên bản. |
| **Bảo mật và phân quyền** | Dựa trên tài khoản và quyền đọc/ghi của hệ điều hành trên server. | Chia sẻ linh hoạt qua link, phân quyền xem/chỉnh sửa, hẹn giờ hủy liên kết. |
| **Tính tự động** | Phải dùng lệnh hoặc phần mềm chuyên dụng để đồng bộ hoặc sao lưu theo lịch. | Tự động đồng bộ dữ liệu (auto-sync) ngay khi file có thay đổi. |
| **Khả năng triển khai** | Thường dùng trong doanh nghiệp, hosting, quản trị hệ thống. | Phù hợp cho cá nhân, nhóm làm việc và doanh nghiệp hiện đại. |
| **Khả năng truy cập** | Cần phần mềm FTP Client như FileZilla, WinSCP. | Có giao diện web, ứng dụng desktop và mobile trực quan. |
| **Chi phí vận hành** | Có thể phải tự xây dựng và duy trì máy chủ FTP. | Trả phí theo dung lượng lưu trữ hoặc dùng miễn phí giới hạn. |

- **FTP** phù hợp với quản trị hệ thống, truyền file dung lượng lớn và môi trường kỹ thuật.
- **Google Drive/Dropbox** phù hợp với làm việc nhóm, chia sẻ dữ liệu và đồng bộ hóa tự động trong môi trường hiện đại.
10. Khắc phục sự cố thường gặp

**Lỗi phổ biến nhất:** VM Network Mode sai  
Triệu chứng: Kết nối thành công, login OK, nhưng list thư mục bị timeout hoặc không thấy file → Đây là lỗi Passive Mode do NAT.

VMware: VM Settings → Network Adapter → Bridged    
Sau đó kiểm tra IP mới:  
  Ubuntu:  ip addr show | grep "inet "  
  Windows: ipconfig | findstr "IPv4"  
IP phải cùng dải với máy host (192.168.x.x)  

**Debug Ubuntu:** đọc log realtime  

Mở hai terminal: một chạy FileZilla kết nối, một xem log — bạn sẽ thấy lỗi xảy ra ở đâu ngay lập tức.  
```
sudo tail -f /var/log/vsftpd.log
sudo tail -f /var/log/auth.log | grep vsftpd
sudo systemctl status vsftpd
```
Lỗi thường gặp và fix nhanh:
```
500 OOPS: bad bool value → sửa YES/NO viết hoa
530 Login incorrect  → kiểm tra /etc/vsftpd.userlist
500 OOPS: refusing writable root → chmod a-w ~/ftp
```

**Debug Windows:** xem IIS FTP log  
```
Get-Content "C:\inetpub\logs\LogFiles\FTPSVC*\*.log" -Tail 20  
net stop ftpsvc && net start ftpsvc  
Get-Website -Name "LabFTP" | Select State
```

 **Sửa lỗi Active/Passive** (Thường do Firewall/NAT chặn)  
* Phía Client : Chuyển sang chế độ Passive (Bị động).  
   * Ví dụ trên FileZilla: Vào Settings -> Connection -> FTP -> Chọn Passive. Lúc này máy trạm sẽ chủ động lấy dữ liệu, tránh bị Firewall cá nhân chặn.
* Phía Server:
   * Khai báo một dải port dành riêng cho kết nối Passive (ví dụ: 50000 - 51000) trong file cấu hình của FTP Server.
   * Mở dải port này cùng port 21 trên tường lửa hệ thống


**Tối ưu Hiệu suất & Băng thông** 
* Tăng số lượng kết nối đồng thời: Mở phần cài đặt Client (như FileZilla) và tăng Maximum simultaneous transfers lên mức 5-10. Rất hữu ích khi cần truyền hàng ngàn file mã nguồn nhỏ.
* Tắt giới hạn tốc độ: Kiểm tra và đảm bảo tính năng Speed Limits (trên Client) hoặc Rate Limit (trên Server) đã được vô hiệu hóa.
* Nén dữ liệu trước khi truyền: FTP truyền nhiều file nhỏ rất chậm. Hãy nén tất cả thành 1 file .zip hoặc .tar.gz, tải lên server qua FTP, sau đó dùng lệnh giải nén trực tiếp trên máy chủ.


