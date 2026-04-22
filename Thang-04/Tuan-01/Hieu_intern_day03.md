# BÁO CÁO THỰC TẬP NGÀY 03 - NFS Server & LVM

## NFS Server
### Tìm hiểu và cài đặt NFS Server
#### Tổng quan
NFS là một giao thức hệ thống tệp phân tán cho phép máy tính (client) truy cập vào các thư mục và tệp tin trên một máy tính khác (Server) qua mạng giống như đang nằm trên chính ổ cứng cục bộ của chính họ.
Mục đích của NFS là để chia sẻ thư mục cho các máy khác
#### Cài đặt NFS server
##### 1. Cài đặt dịch vụ NFS 
<img width="466" height="88" alt="image" src="https://github.com/user-attachments/assets/ce5edb83-7333-4b28-83b8-97803f557513" />
##### 2. Tạo thư mục muốn share và phân quyền
Ở đây làm bài lab test nên em để phân quyền tạm thời là 777 và chủ sở hữu sang mặc định

<img width="428" height="62" alt="image" src="https://github.com/user-attachments/assets/148ac6fb-c4e0-4677-90bc-a779ce7f9df4" />
##### 3. Cấu hình file /etc/exports 
File này là nơi khai báo cho hệ thống biết thư mục nào, cho ai, quyền hạn gì
<img width="472" height="251" alt="image" src="https://github.com/user-attachments/assets/2f90948d-37e8-410b-bfa6-29d0bf7e5702" />
* IP 192.168.254.50 là client được phép truy cập

##### 4. Áp dụng cấu hình, khởi động dịch vụ và mở tường lửa
<img width="448" height="125" alt="image" src="https://github.com/user-attachments/assets/d5ced77c-d9df-4767-895e-097e908bec8d" />

#### Kết nối NFS server đến với client
##### Client là windows
* Bật tính năng NFS Client trên windows 
<img width="203" height="185" alt="image" src="https://github.com/user-attachments/assets/a5e41865-94a2-4036-92d1-077ad95748e1" />
* mount ổ NFS vào windows
  <img width="838" height="301" alt="image" src="https://github.com/user-attachments/assets/cd68b51a-fd04-46bb-b0a3-32ad0ffcdee1" />

##### Client là linux
* Cài đặt gói NFS hỗ trợ 
<img width="385" height="92" alt="image" src="https://github.com/user-attachments/assets/0c1e7801-a9f7-4dd6-a343-3a4b9da230e2" />

* Tạo điểm gắn mount
  sudo mkdir -p /mnt/connect_nfs

* Gắn mount
* <img width="487" height="179" alt="image" src="https://github.com/user-attachments/assets/307a6e5a-723f-4057-bda0-bbc0c0966c68" />

* Kết quả đạt được
  <img width="482" height="126" alt="image" src="https://github.com/user-attachments/assets/1293450a-77ad-4abe-929d-2b96c665ae4e" />


---
## LVM
