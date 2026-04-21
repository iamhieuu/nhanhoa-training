# BÁO CÁO THỰC TẬP NGÀY 02
## Báo cáo DNS SERVER
## 1. Giới thiệu
Domain Name Server (DNS) là một thành phần cốt lõi của hạ tầng mạng Internet, là hệ thống chuyển đổi tên miền thân thiện thành địa chỉ IP số  mà máy tính hiểu được.
Ví dụ : Google -> 192.168.1.10  
DNS hoạt động như danh bạ internet, giúp người dùng truy cập web mà không cần nhớ dãy số phức tạp, đóng vai trò cốt lõi trong việc kết nối trình duyệt với máy chủ chứa website


## 2. Các loại bản ghi DNS
| Record Type | Mục đích |
| :--- | :--- |
| **A** | Phân giải tên miền thành IPv4. |
| **AAAA** | Phân giải tên miền thành IPv6. |
| **CNAME** | dùng để tạo bí danh (alias) cho một tên miền, dùng để trỏ tiền miền này sang tên miền khác |
| **MX** | Chỉ định máy chủ nào chịu trách nhiệm nhận email cho tên miền đó. |
| **TXT** | Xác thực tên miền và bảo mật email (SPF, DKIM). |
| **NS** | Khai báo máy chủ DNS nào đang có thẩm quyền quản lý tên miền này. |
| **PTR** | Ngược lại với bản A phân giải  IPv4 → domain |
## 3. Thực hành với Bind9 (Linux)
Trong quá trình cấu hình DNS Server trên môi trường Linux Ubuntu server 22.04, file cấu hình chính thường nằm tại `/etc/bind/named.conf`.
#### Bước 1 : cài đặt bind9, dnsutils, bind9utils
<img width="335" height="67" alt="image" src="https://github.com/user-attachments/assets/72e1dccf-3ed7-424c-bec5-00c5f1edbb40" />

#### Bước 2 : khai báo tên miền /etc/named.conf.local
<img width="441" height="190" alt="image" src="https://github.com/user-attachments/assets/3b2fb5c9-3547-4714-bf1e-18fcbdb6e9a8" />  

#### Bước 3 : Tạo bản ghi DNS
<img width="436" height="206" alt="image" src="https://github.com/user-attachments/assets/9ed28b91-830e-4e3e-a226-2b5111cfae41" />   

#### Bước 4: Check
<img width="493" height="56" alt="image" src="https://github.com/user-attachments/assets/252282d9-dc76-45eb-882d-808c2423b24b" />  

#### Bước 5: Mở tường lửa, restart và check dịch vụ
<img width="746" height="346" alt="image" src="https://github.com/user-attachments/assets/6a6abdb9-4f9d-412b-b13e-0f4ac0cf76d8" />  

#### Bước 6 : check dig
<img width="460" height="257" alt="image" src="https://github.com/user-attachments/assets/23a07f1d-4c51-467f-aa0b-8db15aaaeab1" />
DNS đã hoạt động thành công


---
## Wordpress trên LAMP/LEMP stack
### Tổng quan 
* Stack là tập hợp các phần mềm kết hợp với nhau để tạo nên một môi trường máy chủ hoàn chỉnh
### Cấu tạo
* **LAMP Stack**
  * Là mô hình truyền thống và ổn định nhất, xuất hiện từ những ngày đầu của web động.
    * Linux
    * Apache
    * MySQL/MariaDB
    * PHP/Python/Perl
* **LEMP Stack**
  * Biến thể hiện đại hơn, tập trung vào hiệu suất cao và khả năng chịu tải.
    * Linux.
    * Engine-X (Nginx).
    * MySQL/MariaDB.
    * PHP/Python/Perl.
## Triển khai Wordpress LAMP stack
#### 1. cài đặt apache2
<img width="491" height="258" alt="image" src="https://github.com/user-attachments/assets/b96bc83b-774c-482b-bae5-c818b26321f8" />

#### 2. Mở cổng tường lửa
<img width="286" height="78" alt="image" src="https://github.com/user-attachments/assets/64619360-1c59-4e1a-8e0e-1425c5a566b7" />

#### 3. cài mysql server
login vào mysql, tạo database và user bằng lệnh sql
<img width="484" height="170" alt="image" src="https://github.com/user-attachments/assets/2b823631-c6bd-4e53-bed2-dc5f7cf12629" />

#### 4. Cài đặt php và các modul phổ biến 
sudo apt install php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y  

#### 5.Cài wordpress mới nhất 
curl -LO https://wordpress.org/latest.tar.gz rồi giải nén 
* copy vào thư mục web rồi phân quyền thư mục :
<img width="487" height="59" alt="image" src="https://github.com/user-attachments/assets/cdd05d67-ed1d-4595-9484-2ac7f1afce04" />

#### 6. Kiểm tra
<img width="838" height="464" alt="image" src="https://github.com/user-attachments/assets/c89673c6-bd5a-484c-916a-d0a621f9137a" />
Hoàn thành LAMP Stack

---

## Triển khai LEMP Stack
Trước khi bắt đầu làm Nginx, ta cần tắt apache 
  <img width="494" height="101" alt="image" src="https://github.com/user-attachments/assets/9c952f88-ae19-48cd-925c-8bf11eb9ecb9" />
#### 1.Cài đặt Nginx
<img width="377" height="71" alt="image" src="https://github.com/user-attachments/assets/1ab10a0b-2a00-46ec-bc3a-356b02364fbf" />

#### 2.Mở cổng tường lửa
<img width="305" height="70" alt="image" src="https://github.com/user-attachments/assets/5978f7a2-bfc0-4be1-be69-988fdb8b4dfa" />

#### 3.Cài php-fpm
<img width="424" height="98" alt="image" src="https://github.com/user-attachments/assets/3020aea7-ac9d-49db-88be-b9e3e0b1ab36" />  

#### 4.Cài wordpress (giống LAMP)

#### 5.Cấu hình server block
<img width="494" height="289" alt="image" src="https://github.com/user-attachments/assets/83310d39-d0fa-481a-8c9d-2ec489ff24bd" />

#### 6. kích hoạt cấu hình
<img width="482" height="79" alt="image" src="https://github.com/user-attachments/assets/da0baee9-829f-4943-bf85-903cb8ed87b3" />

#### 7.Kiểm tra và khởi động lại
Với nginx, việc kiểm tra trước khi khởi động lại là bắt buộc 
<img width="422" height="56" alt="image" src="https://github.com/user-attachments/assets/9752fdc3-c38a-4dac-84d4-1caa9324f355" />
hiện syntax is ok , test successfull thì reload
<img width="740" height="437" alt="image" src="https://github.com/user-attachments/assets/3901caee-1271-42e8-8dbe-e989c00d2037" />

Hoàn thành LEMP Stack

---

## Triển khai site wordpress tách web server, DB server (1 node web server, 1 node DB server)
### Sơ đồ :
#### Web Server (Node 1):
* OS: Ubuntu
* Services: Nginx, PHP 8.x-FPM
* IP: 192.168.254.100
#### Database Server (Node 2):
* OS: Ubuntu
* Services: MariaDB
* IP: 192.168.254.120

## Tạo Database trên Node 2

#### 1.Cài đặt mariaDB
<img width="309" height="68" alt="image" src="https://github.com/user-attachments/assets/9b178bdf-a6b1-46c4-ba55-f35e09d3d199" />
cấu hình cho phép kết nối qua mạng
<img width="382" height="147" alt="image" src="https://github.com/user-attachments/assets/20305612-46bf-4d89-9771-280089242080" />

#### 2.Tạo Database và user cấp quyền cho web server
<img width="406" height="209" alt="image" src="https://github.com/user-attachments/assets/b09591c4-6da1-4074-b34b-4228db2792fa" />

#### 3. Mở tường lửa 
chỉ mở cho đúng IP của máy Node 1
<img width="294" height="43" alt="image" src="https://github.com/user-attachments/assets/22d3b647-4d11-44f0-90c7-bf94a048c076" />

## Tạo Web trên Node 1

#### 1.Cài mariaDB client
<img width="457" height="88" alt="image" src="https://github.com/user-attachments/assets/635f4e20-f77c-41fe-bb26-58d7a901c4a8" />
sau khi cài, test thử xem có connect database không
 <img width="479" height="123" alt="image" src="https://github.com/user-attachments/assets/2e0da1b4-b032-4b9e-8fab-2f39267e1391" />
 
#### 2.Trỏ WordPress sang Node 2
<img width="659" height="287" alt="image" src="https://github.com/user-attachments/assets/26b2c99f-b0ee-4851-ba83-6fe2160dafd6" />

#### Kiểm tra và khởi động lại 
<img width="953" height="475" alt="image" src="https://github.com/user-attachments/assets/0408cfdb-9037-4868-af44-ac756da16fdc" />
**Trạng thái:** Thành công.  
* **Khả năng kết nối:** Web Server đã khởi tạo thành công bảng dữ liệu vào Database Server từ xa.  
* **Giao diện:** Hiển thị màn hình chào mừng và yêu cầu thiết lập thông tin quản trị website.  

---
## Bash Script tự động cài LAMP/LEMP Stack
#### Tạo file script cài LAMP
Nội dung trong file sẽ là các câu lệnh đã thực hiện ở phần triển khai LAMP Stack, lần này ta dùng Mariadb thay vì SQL
<img width="674" height="284" alt="image" src="https://github.com/user-attachments/assets/57ccf912-824d-4c69-bd09-8df17dafa529" />
#### Tạo file script cài LEMP
<img width="674" height="235" alt="image" src="https://github.com/user-attachments/assets/2c33e9a3-6f6a-42d7-95ef-b4875d7fc42f" />
#### cấp quyền thực thi file
<img width="310" height="37" alt="image" src="https://github.com/user-attachments/assets/12b89f69-7967-4d73-92e5-17c002c78c30" />
#### Sử dụng sudo ./install_...sh để chạy

---
## BÁO CÁO TRIỂN KHAI WEB SERVER IIS
### Triển khai site demo1 html basic trên web server IIS trên windows server 2022
### Sơ đồ :
Hệ điều hành: Windows Server 2022 Datacenter.
Dịch vụ: Internet Information Services (IIS) 10.0.
Địa chỉ IP: 192.168.254.130

### .Bật tính năng IIS
tích chọn các tính năng cần thiết 
<img width="491" height="347" alt="image" src="https://github.com/user-attachments/assets/3a61602c-b1f3-425f-8d51-24fd641771b6" />
#### Tạo cây thư mục demo1_html
<img width="447" height="164" alt="image" src="https://github.com/user-attachments/assets/a01f97a9-8967-4278-890e-fca3c3f3e967" />

### Triển khai site demo1 html basic trên web server IIS trên windows server 2022
####  Tạo file html cơ bản :
<img width="323" height="180" alt="image" src="https://github.com/user-attachments/assets/9f92d45b-b855-4c3c-9243-4c97415d6e91" />

#### Tạo site trên IIS:
trỏ đến C:\inetpub\wwwroot\sites\demo1_html
<img width="646" height="340" alt="image" src="https://github.com/user-attachments/assets/7b9ea65c-9ce9-4d0a-9f68-2a91b10ee3d0" />
kết quả thu về :
<img width="857" height="238" alt="image" src="https://github.com/user-attachments/assets/0a9bf844-4771-4c16-91c4-fc35cbf6bb87" />

### Triển khai site demo2 ASP classic trên IIS
####  Tạo file asp cơ bản :
<img width="419" height="185" alt="image" src="https://github.com/user-attachments/assets/53d2499d-e00f-490b-9467-90ac52863760" />
#### Tạo site trên IIS:
<img width="363" height="341" alt="image" src="https://github.com/user-attachments/assets/215a8555-b6f6-4bbb-be75-4c336cf85436" />
kết quả thu về :
Lỗi 403.3 
####  Tạo file aspx cơ bản :
<img width="452" height="262" alt="image" src="https://github.com/user-attachments/assets/514e54aa-5d03-4a33-ba50-115f208bfc3f" />

#### Tạo site trên IIS:
<img width="367" height="290" alt="image" src="https://github.com/user-attachments/assets/25a02794-225d-4e2f-8e6c-d9388acd34a2" />

kết quả thu về
<img width="715" height="172" alt="image" src="https://github.com/user-attachments/assets/3f5a253e-bfc4-4ceb-9e77-3e5fdb30c0c2" />

