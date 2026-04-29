# Báo cáo thực tập ngày 08 - Logs và Security cơ bản trên Linux 
## Các loại Logs quan trọng
### 1. Hệ thống log
* /var/log/
  * syslog          : Tổng hợp events hệ thống (QUAN TRỌNG NHẤT)
  * kern.log        : Log nhân hệ thống
  * dmesg           : Boot-time kernel messages
  * boot.log        : Log nhật kí quá trình boot
  * messages        : Thông báo hệ thống chung
  * dpkg.log        : Lịch sử cài đặt, gỡ gói
  * apt/            : Logs quản lý gói apt
    * history.log : theo dõi lịch sử cài đặt, cập nhật hoặc xóa phần mềm
    * term.log: Ghi lại: Unpacking, Setting up, Processing
  * Ubuntu-advantage-*.log
 
/var/log/syslog: ghi lại toàn bộ những gì xảy ra ở hệ thống
tail -f /var/log/syslog : theo dõi theo thời gian thực file syslog
<img width="1336" height="444" alt="image" src="https://github.com/user-attachments/assets/935d9d76-5b9d-4026-b985-f0c383ef5f9b" />

sudo tail -f /var/log/kern.log: theo dõi mọi hoạt động và thông báo của nhân hệ điều hành theo thời gian thực
<img width="1456" height="224" alt="image" src="https://github.com/user-attachments/assets/f45c79b5-d98e-4d5d-a546-60e9f24fd2d4" />

### 2 Dịch Vụ Cụ Thể (Service Logs)
* /var/log/
  * nginx/
    * access.log  : Ghi lại mọi yêu cầu truy cập
    * error.log   : Ghi lại các lỗi cấu hình, lỗi khởi động hoặc lỗi kết nối
  * apache2/
    * access.log 
    * error.log
  * mysql/
    * error.log   : Ghi lại các lỗi cấu hình, lỗi khởi động hoặc lỗi kết nối
  * mail.log   : Lịch sử gửi/nhận thư của hệ thống.
  * mail.err   : Chỉ lọc ra các lỗi liên quan đến việc gửi/nhận thư.
  * cron.log      : Lịch sử thực thi các tác vụ lập lịch tự động.
sudo tail -f /var/log/apache2/access.log
<img width="1793" height="278" alt="image" src="https://github.com/user-attachments/assets/8f579f98-306d-4ca8-94bf-ddc7f845891b" />

sudo tail -f /var/log/apache2/error.log
<img width="1814" height="543" alt="image" src="https://github.com/user-attachments/assets/fe0f6c33-5ffb-4f27-b6ed-9fce17454bbb" />

* check IP truy cập nhiều nhất
sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -10
* Tìm 404 errors
sudo grep " 404 " /var/log/apache2/access.log | head -20
* Tìm 5xx server errors
sudo grep " 5[0-9][0-9] " /var/log/apache2/access.log
sudo grep "CRON" /var/log/syslog:theo dõi được các tác vụ nào đã chạy tự động và chạy vào lúc nào.
<img width="1597" height="481" alt="image" src="https://github.com/user-attachments/assets/684b86cf-cf05-4994-b1e7-f0a927af9121" />

###  Log Đăng Nhập

* /var/log/
 * auth.log  
 * wtmp  (dùng last)      
 * btmp        (dùng lastb)
 * lastlog    
tail -f /var/log/auth.log: xem tất cả lịch sử đăng nhập , ssh ,sudo
<img width="1593" height="338" alt="image" src="https://github.com/user-attachments/assets/62341081-b1cd-4b61-b8d8-4bf1b3faf62a" />
Failed password for root from [IP lạ] => có người đang cố gắng hack

### Log reboot/shutdown

* last reboot: xem lịch sử reboot
* sudo journalctl --list-boots | head -20:liệt kê lịch sử các lần khởi động
<img width="1147" height="105" alt="image" src="https://github.com/user-attachments/assets/27ccc57d-ab76-4eda-a853-93d739df742e" />

* sudo journalctl | grep -E "shutdown|reboot|halt|poweroff": truy quét toàn bộ lịch sử tắt máy hoặc khởi động lại
<img width="1830" height="273" alt="image" src="https://github.com/user-attachments/assets/e8ed0df1-8499-4b6a-862e-c59f0c3e83ca" />
systemd-analyze : Boot time tổng
systemd-analyze blame : Check xem dịch vụ nào chậm nhất

##  Công cụ quản lý logs
### 1. journalctl - Công cụ chính
sudo journalctl -f: Theo dõi tất cả các log  
sudo journalctl -u apache -f : Theo dõi log của apache2  
sudo journalctl --since "time": THeo dõi theo thời gian  

* Lọc logs theo cấp độ nguy hiểm
sudo journalctl -p err: Chỉ errors  
sudo journalctl -p warning: Warning trở lên  
sudo journalctl -p info: Info trở lên

* dọn dẹp Log hệ thống
sudo journalctl --vacuum-size=500M: Chỉ giữ lại tối đa 500MB log mới nhất.
sudo journalctl --vacuum-time=30days: Chỉ giữ lại log trong vòng 30 ngày gần đây.

### 2. Logrotate - Quản lý kích thước log
#### Cấu hình Máy Gửi (Client)
Mục tiêu: Đẩy log sang máy chủ tập trung.    
File cấu hình: sudo nano /etc/rsyslog.d/50-remote.conf    
*.* @192.168.136.131:514 (Dùng UDP - nhanh, dễ mất gói).    
*.* @@192.168.136.131:514 (Dùng TCP - chậm, an toàn/tin cậy).  
Lệnh kích hoạt: sudo systemctl restart rsyslog  

#### Cấu hình Máy Nhận (Server - 192.168.136.131)
Mục tiêu: Mở cổng để hứng log từ bên ngoài  
File cấu hình: sudo nano /etc/rsyslog.conf  
<img width="626" height="185" alt="image" src="https://github.com/user-attachments/assets/8a6ace4e-1551-4de8-adc0-848eb46b29d4" />
Lệnh kích hoạt: sudo systemctl restart rsyslog

---

## SECURITY CƠ BẢN TRÊN LINUX
### 1. Bảo mật đăng nhập
#### Bảo mật SSH
sudo nano /etc/ssh/sshd_config: file cấu hình    
Thay đổi 1 số cấu hình để bảo mật tốt
<img width="736" height="375" alt="{4FE6C6BB-4FBE-43E4-9DF3-8ACFA6B76D4C}" src="https://github.com/user-attachments/assets/5c1f03ba-e84c-480d-a532-5a0fa801552f" />

sudo sshd -t: Test cấu hình  
sudo systemctl reload sshd  
sudo ufw allow 2222/tcp: Đổi port  
sudo ufw delete allow 22/tcp: Xóa port cũ  

#### SSH Key Authentication
Phương pháp tạo khóa và chìa đăng nhập vào Server mà không cần mật khẩu. Nó không chỉ nhanh hơn mà còn bảo mật hơn gấp nhiều lần.  
* Phía CLIENT: Tạo "Ổ khóa" và "Chìa khóa":
  ssh-keygen -t ed25519: Đây là thuật toán hiện đại, ngắn gọn và bảo mật nhất hiện nay
  <img width="379" height="241" alt="{4F019340-5AB7-4606-B321-8008B18FC063}" src="https://github.com/user-attachments/assets/90b91549-ebc3-4baf-ad1f-0c6558a99172" />
  
Chìa khóa riêng (Private key): Lưu tại /home/hieu/.ssh/id_ed25519.  
Ổ khóa công khai (Public key): Lưu tại /home/hieu/.ssh/id_ed25519.pub  
Copy public key lên server  
<img width="367" height="197" alt="{45FBCECE-7D6B-4138-8700-3B3798B12823}" src="https://github.com/user-attachments/assets/121f1087-1e77-4788-b9a0-2064973b95dd" />

* Phía SERVER : check key
<img width="588" height="400" alt="{DDA88A8A-F353-4146-84D3-771869648188}" src="https://github.com/user-attachments/assets/0b252de5-7421-4d34-8900-8610dbf5bc24" />
xác nhận key hoạt động-> tắt pass auth
<img width="579" height="340" alt="{DE5D3E56-3308-40BE-8531-974FA82FC0C4}" src="https://github.com/user-attachments/assets/0d89b72b-9926-4c28-97d8-426787cff5df" />

#### Fail2Ban - Chặn Brute Force
sudo apt install -y fail2ban: cài fail2ban
<img width="388" height="94" alt="{24A31CDF-A453-4292-A4CA-23E266967EC2}" src="https://github.com/user-attachments/assets/1af5589b-bfa4-4fe5-8ca9-8ebfcebffbc8" />

* Tạo config riêng (không sửa file gốc)
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local  
sudo nano /etc/fail2ban/jail.local  
<img width="641" height="356" alt="{908B6841-25E9-45CE-B6AA-38514EA5EFD1}" src="https://github.com/user-attachments/assets/cd06851a-8e09-49c6-9d16-119891fe78ba" />


<img width="585" height="307" alt="{D6112EAF-98F6-4E5A-A6F5-CBC022DE1647}" src="https://github.com/user-attachments/assets/5b58ddc2-ca14-499a-bccc-ffda852483fc" />
sudo tail -f /var/log/fail2ban.log: Xem logs fail2ban
#### Password Policy
sudo apt install -y libpam-pwquality
<img width="385" height="90" alt="{C80F537C-1E7A-4A5D-A3D3-B95AD67760D6}" src="https://github.com/user-attachments/assets/78706394-f8a1-495e-9d09-750183e4b1aa" />
sudo nano /etc/security/pwquality.conf: file cấu hình
*Thiết lập policy*
<img width="594" height="340" alt="{D652F599-EBB2-4AF0-9BD2-CBB2E1D75CC0}" src="https://github.com/user-attachments/assets/07c2b60d-0c6f-47e1-a495-92acffefff77" />
minlen = 8   : Tối thiểu 12 ký tự  
dcredit = -1 : Ít nhất 1 chữ số  
ucredit = -1  :  Ít nhất 1 chữ hoa  
lcredit = -1    :  Ít nhất 1 chữ thường  
ocredit = -1  :  Ít nhất 1 ký tự đặc biệt  
maxrepeat = 3  : Không lặp quá 3 ký tự giống nhau    
gecoscheck = 1 : Không dùng tên trong password  
dictcheck = 1   : Kiểm tra từ điển  

*Cấu hình account lockout*  
sudo nano /etc/pam.d/common-auth  
<img width="535" height="343" alt="{B63FD856-751C-434A-A497-5D87E10A8810}" src="https://github.com/user-attachments/assets/aff13c02-6f67-417c-9726-fef317c384f5" />

nhập mật khẩu bị thất bại, dòng này sẽ ghi nhận lại một "lần sai". Khi số lần sai đạt đến giới hạn (thường mặc định là 3 hoặc 5 lần), tài khoản sẽ bị khóa

*Password aging*: Dùng chage như bài user group đã nói
sudo nano /etc/login.defs: cấu hình việc liên quan đến login mặc định

### QUẢN LÝ USER VÀ QUYỀN
#### Kiểm tra Users Nguy Hiểm
<img width="1552" height="513" alt="image" src="https://github.com/user-attachments/assets/398eb0ca-c3c2-4694-a215-7754e042878b" />

#### Sudo Security
sudo cat /etc/sudoers: Xem tất cả sudo privileges
grep -Po '^sudo.+:\K.*$' /etc/group: xem ai có thể sudo
<img width="408" height="217" alt="{76E84D48-90C2-491A-9678-63CAD399DD24}" src="https://github.com/user-attachments/assets/59bdcef7-2111-42a8-b514-b277d19b0495" />
sudo grep "sudo" /var/log/auth.log | grep "COMMAND" | tail -n: Liệt kê "n" lệnh gần nhất mà bạn (hoặc ai đó) đã dùng quyền sudo để chạy
<img width="871" height="103" alt="{6E321EB4-891F-47FC-AD6A-51733707DEF4}" src="https://github.com/user-attachments/assets/11cefc0d-cd52-4a3b-8160-b2dd06649bdf" />

### FIREWALL (UFW)
* Allow các ports cần thiết
 * sudo ufw allow 22/tcp            
 * sudo ufw allow 80/tcp             
 * sudo ufw allow 443/tcp             
 * sudo ufw allow 25/tcp: SMTP  
 * sudo ufw allow 3306/tcp
 
* Allow từ IP cụ thể
 * sudo ufw allow from 192.168.1.10: Tất cả từ IP này   
 * sudo ufw allow from 192.168.1.0/24 to any port 22: SSH từ subnet  
* sudo ufw limit 22/tcp: Chống brute force SSH  
  
sudo ufw status verbose: xem chi tiết ufw  
sudo ufw delete <> xóa rule ufw  
sudo ufw reset: reset all ufw  
sudo tail -f /var/log/syslog | grep -i ufw: check log chung của hệ thống ufw  

sudo iptables -L -n -v: Xem rules hiện tại  
sudo apt install iptables-persistent  
sudo netfilter-persistent save : Save rule  

### CẬP NHẬT HỆ THỐNG
dùng lệnh sudo apt update && sudo apt full-upgrade -y  
sudo apt autoremove -y  
sudo apt autoclean: cleanup  

**Tự động update security**
sudo apt install -y unattended-upgrades  
sudo dpkg-reconfigure unattended-upgrades->chọn yes  
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades: File cấu hình chi tiết
<img width="448" height="140" alt="{F3AD690D-A939-4DC8-B6F5-B567D9847488}" src="https://github.com/user-attachments/assets/e56e47e9-3b86-4294-9a13-9e8b33c40c8b" />
Để tránh đầy ổ cứng sau một thời gian dài update:  
* Unattended-Upgrade::Remove-Unused-Dependencies "true"  
* Unattended-Upgrade::Remove-New-Unused-Dependencies "true"  
Tự động khởi động lại theo time mình cài  
* Unattended-Upgrade::Automatic-Reboot-Time "04:00"

sudo nano /etc/apt/apt.conf.d/20auto-upgrades: file cấu hình bao lâu update 1 lần  
<img width="585" height="87" alt="{F2E22C8D-6588-42FE-BCF1-E02E246768A0}" src="https://github.com/user-attachments/assets/ab5f8853-065a-4780-affa-14f23671d3cc" />
Cứ 1 ngày thì chạy apt update một lần  

sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log: check log  
<img width="866" height="206" alt="{64BA7FCA-4437-4308-8F7B-9F19FC8CDD20}" src="https://github.com/user-attachments/assets/84f2444a-fe8c-4c1a-a33b-b523dcbbeba3" />

### GIÁM SÁT HỆ THỐNG
Giám sát real-time  
top: CPU, Memory, Processes  
htop:   Đẹp hơn - cần cài sudo apt install htop  
iotop :   Disk I/O - cần cài sudo apt install iotop  
nethogs:    Network per process  
iftop :    Network traffic per connection  
- iotop
<img width="593" height="400" alt="{0B34F6A0-E817-4165-A9AF-2FCCB7514174}" src="https://github.com/user-attachments/assets/6bedbfed-7a1a-4680-a433-55c58f5233d9" />
- htop
<img width="860" height="395" alt="{0CDC328F-0F53-4AE5-9AC7-A1C4E7C66652}" src="https://github.com/user-attachments/assets/0e2854c0-4a95-4a51-9e2b-10e8f8f7c5c3" />

Tài nguyên hệ thống  
free -h:   RAM usage  
df -h :    Disk usage  
du -sh /var/log/*:    Log sizes  
lscpu :   CPU info  
uptime  :    Load average  
- du -sh /var/log/*  
<img width="414" height="357" alt="{FBD173E9-C3A1-4240-A2FF-756D4F760F51}" src="https://github.com/user-attachments/assets/c85529af-7a2b-43da-bd94-1b557bf17db7" />

- uptime, df -h
<img width="495" height="98" alt="{FF024681-05DF-40F9-B372-3DD7FBE67580}" src="https://github.com/user-attachments/assets/65c41d8a-8b8f-4c0e-8266-70b7ecd4f0ea" />

Kết nối mạng
ss -tulpn  :     Listening ports
<img width="831" height="131" alt="{D0AC8048-F0C7-4660-B4DC-18861772BBC3}" src="https://github.com/user-attachments/assets/de17386a-3fc0-414a-bbd8-02111547474d" />

netstat -an   :   Tất cả kết nối
<img width="613" height="335" alt="{4BF849EE-0926-4C8F-8E64-D1372CC7AA60}" src="https://github.com/user-attachments/assets/5499094b-6f8b-4caa-9637-71e0828aa57d" />

## Phân tích logs để phát hiện tấn công
<img width="579" height="185" alt="{D41F0B82-D3BD-4617-B85E-4B8BE3D0AFF4}" src="https://github.com/user-attachments/assets/5c5d21c6-77fd-4977-b84d-7b231dc17337" />

<img width="541" height="197" alt="{9782565A-04AA-475E-AB91-D4866DFA9B5E}" src="https://github.com/user-attachments/assets/be5cc734-4c02-47f7-b384-069eb5cca1c8" />

sudo grep "sudo" /var/log/auth.log | grep "COMMAND" | tail -n: Liệt kê "n" lệnh gần nhất mà bạn (hoặc ai đó) đã dùng quyền sudo để chạy  
sudo grep "su:" /var/log/auth.log: ai đã dùng su để vô root  
find / -perm /4000 -newer /bin/bash 2>/dev/null: Files có SUID không quen  
ls -la /etc/cron*: các lệnh chạy theo chu kỳ cố định của cả server  
