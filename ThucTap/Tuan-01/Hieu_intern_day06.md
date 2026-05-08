# Báo cáo thực tập ngày 6: HAProxy 

## Các công cụ cần chuẩn bị
* Cài 4 ubuntu server
  * 192.168.254.100  ← HAProxy Master (Server 1)
  * 192.168.254.120  ← HAProxy Backup (Server 2)
  * 192.168.254.121  ← Apache  1
  * 192.168.254.122  ← Apache  2
  * 192.168.254.50   <- VIP

Client 1 → HAProxy → Apache 1  
Client 2 → HAProxy → Apache 2  
Nếu Apache 1 chết → HAProxy tự chuyển sang Apache 2  

Client → VIP (192.168.254.50)
Keepalived quản lý: VIP trên Server 1 
Nếu Server 1 chết → Keepalived tự động di chuyển VIP sang Server 2
### Cài LAMP Stack 1,2 cho 2 máy
Cách thực hiện và cài bash script giống buổi thứ 2 
<img width="953" height="454" alt="image" src="https://github.com/user-attachments/assets/ec3ea293-d327-4165-bc1c-87280b24e901" />

### Cài HAProxy trên server 1
#### Thêm resposit, cài HAProxy
<img width="889" height="344" alt="image" src="https://github.com/user-attachments/assets/867df925-f3fa-4717-84ea-9f70ea297d59" />
<img width="550" height="99" alt="image" src="https://github.com/user-attachments/assets/fb1ce556-1b25-45c3-a3bc-cc31df2c8018" />

#### Tạo file cấu hình HAProxy
<img width="788" height="347" alt="image" src="https://github.com/user-attachments/assets/aa663bfb-a7da-40c0-a953-c4e031a3e310" />

*  haproxy -f /etc/haproxy/haproxy.cfg -c : check xem cấu hình oke chưa
#### Khởi động dịch vụ
<img width="919" height="375" alt="image" src="https://github.com/user-attachments/assets/97642302-7231-43c3-ba52-c19e251381a4" />

<img width="949" height="433" alt="image" src="https://github.com/user-attachments/assets/848a7d5d-88a2-44a5-a005-d51eff70f54d" />
Giao diện HAProxy với 2 apache hoạt động tốt

### Cài HAProxy trên server 2
* Giống cài HAProxy 1
  <img width="883" height="405" alt="image" src="https://github.com/user-attachments/assets/60513431-c2cf-4a7d-8aa2-a783b5071177" />
  Đã test tắt apache 1, hoạt động apache 2
## Cài KEEPALIVED
SAU KHI CÀI KEEPALIVED :
  Client → VIP (192.168.254.50)  
           ↓  
           Keepalived chọn:  
           - Server 1 (Master - Priority 100) ← VIP ở đây  
           - Server 2 (Backup - Priority 50)  
  
  Nếu Server 1 chết:  
    → Keepalived tự động di chuyển VIP sang Server 2  
    → Client vẫn kết nối được   
### CÀI ĐẶT TRÊN MÁY CHỦ 1
<img width="714" height="202" alt="image" src="https://github.com/user-attachments/assets/8236de7d-935c-48a1-9b40-d977c048e7ea" />
#### Tạo file config Keepaliving
<img width="722" height="350" alt="image" src="https://github.com/user-attachments/assets/da8cf23e-1d05-43f9-b48e-df19e452ed49" />

File check keepaliving
<img width="685" height="142" alt="image" src="https://github.com/user-attachments/assets/6e3c9bd9-9d53-4a13-94ff-c5b9c930bc41" />

File thông báo
<img width="599" height="173" alt="image" src="https://github.com/user-attachments/assets/a6934163-da62-4e29-aaf4-78157ed07c80" />
#### Khởi động dịch vụ 
<img width="893" height="397" alt="image" src="https://github.com/user-attachments/assets/42ef1067-2791-4712-886c-62795dca3bc6" />
<img width="865" height="399" alt="image" src="https://github.com/user-attachments/assets/b70a65a6-5cce-4bfa-b2a1-1bc9fc77c378" />
Đã có VIP 192.168.254.50

### CÀI ĐẶT TRÊN MÁY CHỦ 2 (BACKUP)

#### Tạo file config Keepaliving

<img width="850" height="361" alt="image" src="https://github.com/user-attachments/assets/eb8d2cee-23a4-42d9-95da-ac4fbbb46e3e" />  

ưu tiên thấp hơn server 1  
Các file check, thông báo tương tự server 1
#### Khởi động dịch vụ

<img width="686" height="182" alt="image" src="https://github.com/user-attachments/assets/d860cb23-da39-4883-9df8-74d472a8ef31" />
Không có 192.168.254.50 vì nó ở server 1

#### Test ping 
<img width="467" height="275" alt="image" src="https://github.com/user-attachments/assets/37e8e1c6-fa56-44c8-89fc-673419f6f837" />
=> Master (Server 1) live

* Tắt HAProxy server 1
  <img width="420" height="86" alt="image" src="https://github.com/user-attachments/assets/eb449fa8-681b-46c4-a5d5-2f3e7d017dbf" />
Ping vẫn nhận được

<img width="524" height="189" alt="image" src="https://github.com/user-attachments/assets/8388e47f-622d-4d62-8fa7-7c1c1b445c56" />
<img width="486" height="395" alt="image" src="https://github.com/user-attachments/assets/bce833eb-8106-431c-bf4f-3d3036c20b67" />
Máy chủ 2 phát hiện Máy chủ 1 không gửi nhịp tim    

Máy chủ 2 nhanh chóng lấy VIP    

VIP redirect từ Server 1 → Server 2  

Sau khi khôi phục lại Server 1, Vip quay lại server1  
<img width="669" height="161" alt="image" src="https://github.com/user-attachments/assets/73bf906c-3813-4fa4-8b0d-5134c687a39c" />

## Firewall
* pfSense là một hệ điều hành mã nguồn mở dựa trên nền tảng FreeBSD, được thiết kế chuyên dụng để biến một máy tính hoặc máy chủ thông thường thành một thiết bị Firewall và Router chuyên nghiệp. Nó có giao diện GUI, tính ổn định cao
Triển khai pfsense sẽ có 2 card mạng ảo
Adapter 1 (WAN): Để chế độ  NAT 
Adapter 2 (LAN): Để chế độ Internal Network 
<img width="325" height="238" alt="image" src="https://github.com/user-attachments/assets/9e4df100-f024-4c59-ad8a-3a34e66b452b" />
Giao diện Pfsense
<img width="860" height="419" alt="image" src="https://github.com/user-attachments/assets/34989ff9-b6a1-479e-bd54-9fee52ab7edf" />

### Cài đặt DHCP
Services -> DHCP Server, tích enable.
<img width="863" height="419" alt="image" src="https://github.com/user-attachments/assets/cb09fd74-5d1a-42d9-a490-e783abc13fbf" />

### NAT Local Internet
pfSense sử dụng Automatic Outbound NAT, nghĩa là các máy trong LAN sẽ tự động có Internet nếu WAN đã thông
<img width="725" height="370" alt="image" src="https://github.com/user-attachments/assets/bfc971b7-734a-45ef-9f91-a4d1d3633aa5" />
Đảm bảo đang tích chọn Automatic outbound NAT rule generation

### Firewall Rules
Trong pfSense, quy tắc mặc định là: Chặn mọi thứ từ ngoài vào WAN, và cho phép mọi thứ từ LAN ra ngoài  
Firewall -> Rules -> Tab LAN.  
Cho phép mọi thiết bị trong mạng LAN truy cập vào các trang web (duyệt web) trên Internet qua giao thức HTTP và HTTPS  
<img width="766" height="376" alt="image" src="https://github.com/user-attachments/assets/68369b35-69b1-4b12-87d0-fdbd736a9a7c" />

### Setup OpenVPN với Pfsense 
Sử dụng để truy cập mạng nội bộ từ xa, kết nối hai văn phòng với nhau  
Vào VPN -> OpenVPN -> Tab Wizards -> Local User Access.  
Cho phép WAN port 1194:
<img width="635" height="380" alt="image" src="https://github.com/user-attachments/assets/1fac2c1d-51d7-482b-b7e0-2027372608bf" />

Cho phép OpenVPN Interface
<img width="552" height="359" alt="image" src="https://github.com/user-attachments/assets/406128c4-49ce-49a3-bf80-c334435e53e7" />

Tạo Client Certificate
<img width="513" height="362" alt="image" src="https://github.com/user-attachments/assets/a20b91c6-3b76-4ef1-8684-9c74ceeca58f" />

Export Client Config
<img width="819" height="374" alt="image" src="https://github.com/user-attachments/assets/3660f52c-57e5-49a9-897f-f173d73a013a" />

* Tải openVPN :https://openvpn.net/community-downloads/
* 
Gán file opvn vào thư mụcC:\Users\YourUsername\OpenVPN\config\

chạy openVPN thành công
<img width="497" height="268" alt="image" src="https://github.com/user-attachments/assets/1178f109-ecf4-42cd-bc01-e9c45c9c46e1" />
