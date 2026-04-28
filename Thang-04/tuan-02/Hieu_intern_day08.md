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
*.* @192.168.1.100:514 (Dùng UDP - nhanh, dễ mất gói). 
*.* @@192.168.1.100:514 (Dùng TCP - chậm, an toàn/tin cậy).
Lệnh kích hoạt: sudo systemctl restart rsyslog

#### Cấu hình Máy Nhận (Server - 192.168.1.100)
Mục tiêu: Mở cổng để hứng log từ bên ngoài
File cấu hình: sudo nano /etc/rsyslog.conf
<img width="626" height="185" alt="image" src="https://github.com/user-attachments/assets/8a6ace4e-1551-4de8-adc0-848eb46b29d4" />
Lệnh kích hoạt: sudo systemctl restart rsyslog

