# Báo cáo thực tập ngày 07 - Tìm hiểu về Linux, Owner, Quyền và Người dùng

## Tổng quan về Linux
Linux là một hệ điều hành mã nguồn mở được tạo ra bởi Linus Torvalds năm 1991. Đặc điểm nổi bật của Linux là tính bảo mật cao, sự ổn định tuyệt vời và khả năng tùy biến sâu, dùng ít tài nguyên hơn, khiến nó trở thành nền tảng thống trị cho các máy chủ, hệ thống đám mây  

## Kiến trúc hệ thống 
* Hardware (Phần cứng): RAM, CPU, Ổ cứng.
* Kernel: Lõi của hệ điều hành, giao tiếp trực tiếp với phần cứng, quản lý bộ nhớ, CPU, và mạng.
  * uname -a để kiểm tra version
* Shell: Cầu nối giữa người dùng và Kernel. Nó diễn dịch các câu lệnh bạn gõ trên terminal thành chỉ thị cho hệ điều hành.
  * echo $SHELL để kiểm tra shell đang dùng
* File System: Mọi thứ trong Linux đều quy về dạng file và bắt nguồn từ thư mục gốc / (Root).
  / (Root - gốc của tất cả)  
├── /bin        → Chương trình cơ bản (ls, cp, mv, cat)  
├── /sbin       → Chương trình quản trị hệ thống (fdisk, mount)  
├── /boot       → Kernel và boot loader  
├── /dev        → Device files (sda, tty, null)  
├── /etc        → File cấu hình hệ thống  
├── /home       → Thư mục home của users  
│  &emsp;&emsp;  ├── /home/alice  
│  &emsp;&emsp;  └── /home/bob  
├── /lib        → Shared libraries  
├── /media      → Mount points (USB, CD)  
├── /mnt        → Temporary mount points  
├── /opt        → Third-party applications  
├── /proc       → Thông tin kernel & processes (virtual)  
├── /root       → Home của root user  
├── /run        → Runtime data  
├── /srv        → Service data (web files, ftp)  
├── /sys        → Kernel & hardware info (virtual)  
├── /tmp        → Tệp tạm thời (xóa khi reboot)  
├── /usr        → User utilities và applications  
│      &emsp; ├── /usr/bin    → User programs  
│     &emsp;  ├── /usr/lib    → Libraries  
│     &emsp;  └── /usr/share  → Shared resources  
└── /var        → Variable data (logs, cache, mail)  
    &emsp; &emsp;  ├── /var/log    → Log files  
    &emsp; &emsp;  ├── /var/cache  → Cache data  
   &emsp;  &emsp;  └── /var/www    → Web server files
    * tree / -L 2 : xem cây thư mục
   
* Applications: Các ứng dụng phía trên cùng (Web server, Database, Trình soạn thảo nano/vi...).

## Các bản phân phối (distro) phổ biến.
**Họ Debian (Ubuntu):** Quản lý gói bằng apt. Dòng LTS (Long Term Support - như Ubuntu 22.04 LTS) được hỗ trợ cập nhật lên tới 5 năm, là lựa chọn cực kỳ an toàn cho môi trường production.
**Họ Red Hat (RHEL, CentOS, Rocky Linux)**: Tiêu chuẩn vàng của doanh nghiệp, quản lý gói bằng yum/dnf.
**Họ Arch (Arch Linux, Manjaro)**: Dành cho người dùng nâng cao thích tùy chỉnh sâu
check bản đang dùng : uname -a, cat /etc/os-release

## Quản lý người dùng và nhóm
Linux là hệ thống Multi-User, cho phép nhiều người dùng cùng đăng nhập và sử dụng tài nguyên đồng thời. Mỗi thực thể được định danh bằng các chỉ số ID thay vì tên gọi ở mức hệ thống.  
* /etc/passwd:	Thông tin cơ bản về User (UID, GID, Shell, Home).
* /etc/shadow:	Lưu mật khẩu đã được mã hóa (chỉ root mới đọc được).
* /etc/group:	Thông tin về các Nhóm (Groups).
UID 0         → root 
UID 1-99      → System accounts (daemon, bin, etc)
UID 100-999   → System users (applications như nginx, apache)
UID 1000+     → Người dùng root tạo
UID 65534     → nobody
id <username>: check thông tin user
### User
#### Tạo user
* sudo useradd -m -s /bin/bash -c "Nguyen Hieu" -u 1500 nguyenhieu
  * -m = Tạo home directory
  * -s = Chỉ định shell
  * -c = Full name
  * -u = UID cụ thể
  * -g = Primary group
#### Password
* sudo passwd <username> : tạo mật khẩu cho username
  * -u: unlock
  * -l: lock
  * -S: xem trạng thái
#### Sửa, xóa
* sudo usermod -aG <group> <username>: thêm người dùng vào nhóm
* sudo userdel <username>: xóa user nhưng vẫn còn home directory
  * sudo userdel -r <username>: xóa tất cả
 
**Lệnh tắt**: adduser <username>: tạo user,  hỏi từng bước password, full name, v.v.
**chage**: cài đặt yêu cầu cho mật khẩu
* sudo chage <username>

### Group
* sudo groupadd groupname
  * sudo groupadd -g 1500 groupname: Tạo group chỉ định GID
  * sudo usermod -aG group1,group2,group3 username: Thêm user vào nhiều group
* sudo gpasswd -d username groupname: xóa user khỏi grp
* sudo groupmod -n newname oldname : Sửa tên group
  * sudo groupmod -g 2100 groupname: Sửa GID
  * sudo groupdel groupname: Xóa group
## Owner (Chủ sở hữu) trong Linux
Trong Linux, mỗi file hoặc thư mục luôn gắn liền với 3 nhóm đối tượng:  
* Owner (u): Người tạo ra file hoặc được gán quyền sở hữu.  
* Group (g): Nhóm người dùng có chung quyền hạn với file đó.  
* Others (o): Tất cả những người dùng khác trên hệ thống.  
<img width="813" height="132" alt="image" src="https://github.com/user-attachments/assets/75eb324d-7aca-4469-8029-5a36848fd9a1" />

## Quyền (Permissions) trên file/folder
Chuỗi quyền hạn thường có dạng rwxrwxrwx  

Ý nghĩa của r-w-x:  
* r (Read - 4): Đọc nội dung file / Xem danh sách file trong thư mục.  
* w (Write - 2): Sửa, xóa nội dung file / Tạo, xóa file trong thư mục.  
* x (Execute - 1): Thực thi, chạy file / Truy cập vào thư mục.  
* -(0) : không có quyền
 
|số|kí hiệu|ý nghĩa|
| :--- | :--- | :--- |  
|777|rwxrwxrwx|Tất cả quyền (❌ Không an toàn)|
|755|rwxr-xr-x|Owner full, others read+exec (Thư mục, scripts)|
|750|rwxr-x---|Owner full, group read+exec (Thư mục private)|
|700|rwx------|Chỉ owner (Thư mục riêng tư)|
|644|rw-r--r--|Owner read+write, others read (Files thông thường)|
|640|rw-r-----|Owner rw, group read (Config files)|
|600|rw-------|Chỉ owner read+write (SSH keys, secrets)|
|400|r--------|Chỉ owner đọc (Sensitive files)|

Các quyền kinh điển:  
* 755: Owner làm mọi thứ, Group/Others chỉ được xem và chạy (Dùng cho **thư mục** web, script).
* 644: Owner đọc/ghi, Others chỉ được đọc (Dùng cho **file** cấu hình công khai).
* 600: Chỉ Owner được đọc/ghi (Dùng cho SSH Key, file mật khẩu).
* -R: Áp dụng cho tất cả ở trong thư mục 
chmod [numbers] file/directory: thay đổi quyền
ví dụ : chmod 755 install-lamp.sh
chmod 644 hieu.txt

* Dùng kí hiệu
  *  u = user (owner)
  * g = group
  * o = others
  * a = all (u+g+o)
  * + = thêm quyền
  * - = bỏ quyền
  * = = đặt chính xác quyền
ví dụ : chmod +x install-lamp.sh

Lệnh đổi quyền
* chown owner file
* chown owner:group file
  
### SPECIAL PERMISSIONS
* SUID (SetUID-4): Cho phép người chạy file thực thi với quyền của Owner file (thường là root).
* SGID (SetGID-2): Khi đặt lên thư mục, mọi file mới tạo bên trong sẽ tự động thuộc về Group của thư mục đó (Rất hữu ích cho team làm việc chung).
* Sticky Bit (+t): Đặt lên thư mục dùng chung (như /tmp), giúp ngăn người này xóa file của người kia dù cả hai đều có quyền ghi.

##  Bộ soạn thảo trên linux: vi, nano
Nano là một trình soạn thảo văn bản dạng văn bản. Nó hoạt động giống như Notepad trên Windows, các phím tắt chính luôn được hiển thị ở dưới đáy màn hình để bạn không cần phải ghi nhớ.  
Mở file với nano
* nano filename.txt: Mở file (tạo nếu chưa có)
* nano /etc/hosts: Mở file config
* sudo nano /etc/fstab: Mở file dưới quyền root

   <img width="1790" height="800" alt="image" src="https://github.com/user-attachments/assets/3cdf9bbd-e936-4eb2-9684-892da264bca2" />
giao diện nano

Vi là trình soạn thảo văn bản dạng chế độ. Nghĩa là ta không thể gõ chữ ngay khi vừa mở file. Ta phải chuyển đổi giữa các "chế độ" khác nhau (như chế độ chèn lệnh, chế độ nhập văn bản). Nó được thiết kế để ta có thể soạn thảo code cực nhanh mà không cần dùng đến chuột  
NORMAL MODE (default)                 
  ├─ Navigation                           
  ├─ Delete, Copy, Paste                 
  ├─ Undo/Redo                          
  └─ Nhấn 'i' → INSERT, ':' → COMMAND  
                                        
  INSERT MODE                           
  ├─ Gõ văn bản bình thường            
  └─ Nhấn ESC → quay về NORMAL         
                                        
  COMMAND MODE (LAST LINE MODE)         
  ├─ Save, Quit, Search, Replace       
  └─ Nhấn ESC → quay về NORMAL  
<img width="1833" height="803" alt="image" src="https://github.com/user-attachments/assets/08facc3b-9c46-4aa8-8194-9662a061912a" />

 1. Normal Mode - Chỉnh sửa

|Kí hiệu|Giải thích|Ý nghĩa|
| :--- | :--- | :--- |
|i|Insert|Chèn trước con trỏ|
|a|Append|Chèn sau con trỏ|
|I|Insert line|Chèn vào đầu dòng|
|A|Append line|Chèn vào cuối dòng|
|o|Open line below|Thêm dòng mới bên dưới|
|O|Open line above|Thêm dòng mới bên trên|
|r|Replace char|Thay thế 1 ký tự|
|R|Replace mode|Thay thế nhiều ký tự|
|x|Delete char|Xóa ký tự tại con trỏ|
|dd|Delete line|Xóa cả dòng|
|dw|Delete word|Xóa từ con trỏ đến hết từ|
|yy|Yank line|Copy dòng hiện tại|
|p|Paste after|Dán vào sau con trỏ|
|u|Undo|Hoàn tác|
|Ctrl+R|Redo|Làm lại|

2. Command Mode (:)

|Kí hiệu|Giải thích|Ý nghĩa|
| :--- | :--- | :--- |
|:w|Save|Lưu file|
|:q|Quit|Thoát|
|:wq|Save & Quit|Lưu và thoát|
|:q!|Force quit|Thoát không lưu|
|:set nu|Number|Hiện số dòng|
|/pattern|Search|Tìm kiếm|
|n|Next|Kết quả tiếp theo|
|:%s/old/new/g|Replace all|Thay thế tất cả|
|:!ls|Shell cmd|Liệt kê file mà không thoát Vim|

## Process trong Linux
Process = Chương trình đang chạy

Mỗi process có:  
├─ PID (Process ID) - số duy nhất  
├─ PPID  - process cha  
├─ UID   
├─ CPU & Memory usage  
└─ Status  

* ps aux : Lệnh xem process
<img width="1446" height="688" alt="image" src="https://github.com/user-attachments/assets/60c12af1-985c-42e4-b13e-7e532714fa49" />
* top,htop
<img width="1805" height="797" alt="image" src="https://github.com/user-attachments/assets/cad271c0-505d-46d7-aa19-0e49b2ad0a28" />
* Kill process:
  * kill <PID>: bỏ PID, process có thể cleanup
  * kill -9 <PID>: bắt buộc kill
  * killall/pkill nginx: kill process tên nginx
sudo systemctl start <process>: bắt đầu
sudo systemctl stop <process>: Dừng
sudo systemctl restart <process>: khởi động lại
sudo systemctl reload <process>: load lại
sudo systemctl enable <process>: khả dụng
sudo systemctl disable <process>: không khả dụng
sudo systemctl status <process>: check trạng thái
## NETWORK TRONG LINUX
* ifconfig: tất cả interfaces
* IP
  * ip addr: Hiển thị địa chỉ IP
  * ip link: Xem trạng thái interface
  * ip route: xem bảng định tuyến
* ss/netstat : xem connection
  * ss -tulpn | grep :80
* ufw: tường lửa
  * ufw allow <port>
nmap: công cụ check mạng, dùng cho an ninh  
ping: Kiểm tra kết nối  
traceroute: xem đường đi packet  
wget: download file  
/etc/hosts: cấu hình local DNS  
/etc/resolv.conf: Cấu hình DNS server  
/etc/dhcp/dhcpd.conf: Cấu hình DHCP  
/etc/netplan/: cấu hình IP tĩnh  
nmtui: cấu hình IP có giao diện  

## NFS - NETWORK FILE SYSTEM
NFS là một giao thức hệ thống tệp phân tán cho phép máy tính (client) truy cập vào các thư mục và tệp tin trên một máy tính khác (Server) qua mạng giống như đang nằm trên chính ổ cứng cục bộ của chính họ. Mục đích của NFS là để chia sẻ thư mục cho các máy khác
#### 1.Thiết lập phía server
sudo apt install nfs-kernel-server
Cấu hình chia sẻ (/etc/exports):

| Dạng chia sẻ | Cú pháp trong /etc/exports |
| :--- | :--- |
| Cho 1 IP cụ thể | /srv/nfs/shared 192.168.1.20(rw,sync,no_subtree_check) |
| Cho cả subnet | /srv/nfs/shared 192.168.1.0/24(rw,sync,no_subtree_check) |
| Chỉ cho phép đọc | /srv/nfs/public *(ro,sync) |

Các Option quan trọng:

| Option | Ý nghĩa |
| :--- | :--- |
| rw / ro | Đọc-Ghi / Chỉ đọc |
| sync | Ghi dữ liệu an toàn xuống đĩa trước khi phản hồi |
| no_root_squash | Cho phép root của client có quyền root trên server (Nguy hiểm) |

sudo exportfs -a: Áp dụng cấu hình
showmount -e localhost: Kiểm tra danh sách đang share

#### 2.Thiết lập phía client
sudo apt install nfs-common
* Kết nối (Mount):
  * sudo mount -t nfs 192.168.1.10:/srv/nfs/shared /mnt/nfs
* Tự động Mount khi khởi động (/etc/fstab):
   * Thêm dòng: 192.168.1.10:/srv/nfs/shared /mnt/nfs nfs rw,hard,timeo=600 0 0

## LVM (Logical Volume Manager)
Sơ đồ tư duy (Luồng thực hiện)
Physical Disks → Physical Volume → Volume Group → Logical Volume → Filesystem Format
sudo pvcreate /dev/sdb /dev/sdc
sudo vgcreate VG0 /dev/sdb /dev/sdc
sudo lvcreate -L 5G -n LV_Data VG0: Tạo LV 5G
sudo mkfs.ext4 /dev/VG0/LV_Data: format ext4
### Mở rộng ổ đĩa (Khi server hết dung lượng)
PV: pvcreate /dev/sdd - Khai báo ổ mới.
VG: vgextend VGDATA /dev/sdd - Nạp ổ mới vào nhóm chung.
LV: lvextend -l +100%FREE /dev/VGDATA/LV_WEB - Dùng hết phần trống mới nạp.
Filesystem: resize2fs /dev/VGDATA/LV_WEB - Để hệ điều hành nhận dung lượng mới(dùng cho ext4).

### THÊM Ổ CỨNG
sudo pvcreate /dev/sdd:  Tạo PV mới
sudo vgextend VG0 /dev/sdd: Thêm vào VG
sudo lvextend -L +10G /dev/VG0/LV_Data: Mở rộng LV
sudo resize2fs /dev/VG0/LV_Data: Resize FS

### THAY THẾ Ổ CỨNG (/dev/sdb → /dev/sdd)
sudo pvcreate /dev/sdd : Tạo PV mới
sudo vgextend VG0 /dev/sdd : Thêm vào VG
sudo pvmove /dev/sdb /dev/sdd: Di chuyển data
sudo vgreduce VG0 /dev/sdb: Remove khỏi VG
sudo pvremove /dev/sdb: Remove PV

###  XÓA LV → VG → PV
sudo umount /data: Unmount
sudo lvremove /dev/VG0/LV_Data : Xóa LV
sudo vgremove VG0 : Xóa VG
sudo pvremove /dev/sdb /dev/sdc: Xóa PV
