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
