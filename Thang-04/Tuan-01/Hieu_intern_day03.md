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
*  IP 192.168.254.50 là client được phép truy cập

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
  <img width="487" height="179" alt="image" src="https://github.com/user-attachments/assets/307a6e5a-723f-4057-bda0-bbc0c0966c68" />

* Kết quả đạt được
  <img width="482" height="126" alt="image" src="https://github.com/user-attachments/assets/1293450a-77ad-4abe-929d-2b96c665ae4e" />


---
## LVM
### Tổng quan
LVM (Logical Volume Manager) là một phương pháp quản lý ổ đĩa trên Linux cho phép bạn quản lý không gian lưu trữ một cách linh hoạt hơn rất nhiều so với cách chia phân vùng truyền thống.
### Quá trình khởi tạo LVM
Tạo 1 ổ cứng vật lý 3G , 1 ổ cứng vật lý 10G
<img width="556" height="335" alt="image" src="https://github.com/user-attachments/assets/7a5f5878-d171-4083-a83b-95cbcbdaac7c" />


#### Bước 1: Tạo Physical Volume
<img width="313" height="114" alt="image" src="https://github.com/user-attachments/assets/1f8a50e1-4e12-4e41-85cf-90870a97dad2" />

#### Bước 2:Tạo Volume Group
<img width="314" height="95" alt="image" src="https://github.com/user-attachments/assets/9f50b9ef-4db7-40d0-9f6b-6f66db6ebc96" />

#### Bước 3:Tạo Logical Volume
<img width="485" height="129" alt="image" src="https://github.com/user-attachments/assets/0d619f65-9fa6-41fb-9389-b3579a9d8a22" />

#### Bước 4:Tạo Filesystem trên LV 
định dạng chuẩn của Linux cho filesystem là ext4
<img width="469" height="160" alt="image" src="https://github.com/user-attachments/assets/0eadd115-2645-45f3-88ed-7db55989e53d" />

#### Bước 5: Chỉnh sửa fstab để tự động mount
sudo mkdir -p /mnt/lvm_storage : tạo thư mục để mount
Mở file để cấu hình mount
<img width="718" height="200" alt="image" src="https://github.com/user-attachments/assets/6e896c21-79ea-4d7a-a7ff-f56ce7968e05" />

Kết quả đạt được

<img width="488" height="167" alt="image" src="https://github.com/user-attachments/assets/c4c90f6e-25a0-4203-878f-d46944e5a985" />

---

### Mở rộng LV
* Ta sử dụng lvextend để thêm dung lượng cho LV
<img width="611" height="100" alt="image" src="https://github.com/user-attachments/assets/a73a8ece-3de0-4693-b566-2b3bc2dfd47d" />
* +/-L 1G : cộng/trừ thêm 1GB vào dung lượng hiện tại
* Mở rộng filesystem sau khi thêm dung lượng LV
  
  kết quả đạt được
  
  <img width="637" height="231" alt="image" src="https://github.com/user-attachments/assets/0de53268-e04f-4253-9061-fe4d27b1b336" />

---

### Thêm ổ cứng mới để mở rộng LV
Sử dụng ổ cứng 10G
#### Bước 1: Tạo Physical Volume
<img width="310" height="32" alt="image" src="https://github.com/user-attachments/assets/cebf9c61-9214-4f50-8c04-403465098cff" />

#### Bước 2:Mở rộng Volume Group vào nhóm vg_new đã tạo ở sdb
Ta sử dụng vgextend để mở rộng 
<img width="313" height="98" alt="image" src="https://github.com/user-attachments/assets/bc36bdbb-df08-4974-bad3-7cd0519ca185" />

#### Bước 3: Mở rộng Logical Volume 
sudo lvextend -L +5G /dev/vg_new/data_lv
<img width="634" height="100" alt="image" src="https://github.com/user-attachments/assets/bc91e76d-200c-48a5-9a9d-1943b9a6e0c8" />

---

### Out/ thay thế 1 ổ cứng ra khỏi hệ thống LVM
Việc này sẽ giúp chuyển dữ liệu sang ổ mới nếu ổ cứng cũ sắp hỏng ngay cả khi web đang hoạt động
#### Bước 1: Chuyển dữ liệu
sử dụng lệnh pvmove để chuyển dữ liệu cho physical volume
<img width="272" height="80" alt="image" src="https://github.com/user-attachments/assets/85adec1b-b816-4dfd-830a-a79cc3c50a26" />

#### Bước 2: Gỡ ổ cứng ra khỏi VG
<img width="302" height="28" alt="image" src="https://github.com/user-attachments/assets/f29042e2-a0ef-461f-9be8-90f4c086385a" />

#### Bước 3: Xóa định dạng LVM, tháo ổ
<img width="565" height="85" alt="image" src="https://github.com/user-attachments/assets/4c89229f-47b7-4dc6-97d7-6cf32931f707" />

---

### Xóa logical volume, volume group, physical volume.
Xóa sẽ làm ngược với tạo
* Ngắt mount
* Xóa logical volume
* xóa volume group
* xóa physical volume
  <img width="562" height="206" alt="image" src="https://github.com/user-attachments/assets/4246cc59-f4a8-4185-be47-cfe278414e49" />



