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
