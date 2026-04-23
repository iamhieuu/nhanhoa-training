# Báo cáo thực tập ngày 04 - Triển khai ứng dụng mail server MDaemon & Monitor Promethues + Grafana

## Cài đặt email server MDaemon trên windows server  2022
1. Cài DNS các bản ghi A, MX, PTR
   
   <img width="465" height="215" alt="image" src="https://github.com/user-attachments/assets/7fe9005e-35cf-4563-ab2a-6919091fe42a" />
2. Chuẩn bị windows server
   
  * Cài IP tĩnh cho windows server
<img width="396" height="383" alt="image" src="https://github.com/user-attachments/assets/9aaad67b-f4cb-4d70-a2df-841110a9f826" />

   * Đổi hostname
     Rename-Computer -NewName "MAILSERVER" -Restart
<img width="190" height="121" alt="image" src="https://github.com/user-attachments/assets/2fc5e87c-a463-4560-8e5b-f50a705b2244" />

  * Tắt firewall tạm thời để test
<img width="601" height="368" alt="image" src="https://github.com/user-attachments/assets/906cc6fa-e40c-4a33-8c82-03f0ae771c26" />

  * Gỡ IIS tránh xung đột port 80/443
Disable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRoleS
 3. Tải và cài Mdeamon
  * Truy cập trang https://mdaemon.com/pages/downloads-mdaemon-mail-server-free-trial tải bản mới nhất .exe
<img width="642" height="374" alt="image" src="https://github.com/user-attachments/assets/2822eeeb-6f56-4dfe-a32e-9748360b31a0" />

  * Chạy file dưới quyền Admin
<img width="441" height="260" alt="image" src="https://github.com/user-attachments/assets/5f1016fb-0f55-4202-a1f6-f34c84d31c2b" />
<img width="346" height="226" alt="image" src="https://github.com/user-attachments/assets/4cb0e190-5d55-4673-919a-4882b3c40fdf" />

  * Cấu hình domain và hostname
<img width="346" height="230" alt="image" src="https://github.com/user-attachments/assets/60e59b6a-265f-4751-b02b-53cd0070ff1a" />

  * Tạo tài khoản Admin đầu tiên
<img width="341" height="225" alt="image" src="https://github.com/user-attachments/assets/959b63f2-b452-4fdf-bf8c-393087605ccd" />

     Cài đặt thành công
<img width="641" height="374" alt="image" src="https://github.com/user-attachments/assets/975c9679-6eca-4ecb-ab2e-d169d30a6e34" />

## Truy cập admin và enduser
Truy cập Admin và End-User  
Trong MDaemon, có 3 cổng truy cập chính qua trình duyệt:  
WebAdmin: Dành cho quản trị viên cấu hình hệ thống.   
Link mặc định: http://IP-Server:1000  
WorldClient: Dành cho người dùng cuối đọc và gửi thư.  
Link mặc định: http://IP-Server:3000  
Remote Administration: Tương tự WebAdmin nhưng dành cho user được cấp quyền quản lý domain nhỏ.
## Các port cần thiết được sử dụng trên email server MDaemon
| Dịch vụ | Port | Ghi chú |
| :--- | :---: | :--- |
| **SMTP** | 25 | Gửi/Nhận mail giữa các server |
| **POP3** | 110 | Tải mail về máy khách  |
| **IMAP** | 143 | Đồng bộ mail giữa server và thiết bị |
| **WorldClient (HTTP)** | 3000 | Giao diện Webmail dành cho người dùng cuối |
| **WebAdmin (HTTP)** | 1000 | Giao diện quản trị hệ thống qua trình duyệt |
| **SMTP SSL/TLS** | 465 / 587  | Gửi mail bảo mật |
| **IMAP SSL** | 993 | Đồng bộ mail bảo mật qua giao thức IMAP |
| **POP3 SSL** | 995 | Tải mail bảo mật qua giao thức POP3 |
| **WorldClient (HTTPS)** | 443 | Truy cập Webmail qua kết nối bảo mật SSL |

## Khởi tạo domain, user, group, Alias, Mailing lists email
*  Domain
<img width="497" height="319" alt="image" src="https://github.com/user-attachments/assets/206ccffc-3258-48f1-977d-74431c7ba16f" />

*  User
<img width="429" height="317" alt="image" src="https://github.com/user-attachments/assets/16996c3c-809e-4fc3-a6f0-ab916985a360" />

*  Group
<img width="490" height="323" alt="image" src="https://github.com/user-attachments/assets/4d0d1702-3b6b-41ae-9573-94e30bd52560" />

*  Alias
<img width="634" height="374" alt="image" src="https://github.com/user-attachments/assets/c175fb18-0a4a-4b8b-bae8-d96ad0e18dde" />

*  Mailing Lists
  <img width="401" height="316" alt="image" src="https://github.com/user-attachments/assets/02347358-dc46-41fa-95a5-59dda5ffd59c" />

## Thiết lập chính sách về mật khẩu account email
* Vào setup - Account setting - Passwords
  <img width="845" height="414" alt="image" src="https://github.com/user-attachments/assets/e5ef51a6-7fe5-4cb6-b6a6-8545d41b9be7" />
 Chính sách sẽ thiết lập mật khẩu mạnh, Hạn của mật khẩu và cảnh báo đến người dùng


## Thiết lập chữ ký email
#### Cho từng cá nhân:
* Vào account manager - edit người dùng - signature
  
  <img width="580" height="336" alt="image" src="https://github.com/user-attachments/assets/60fe698c-66ac-463d-83bc-b66960d8913e" />
#### Cho cả domain:
* Vào domain - click vào domain cần thiết lập - default signature
  
<img width="761" height="367" alt="image" src="https://github.com/user-attachments/assets/a9937930-97eb-43e2-86d1-48e1e4ac33db" />

## Thiết lập forward email
* Vào Account manager - edit người dùng - Forwarding
  
  <img width="593" height="337" alt="image" src="https://github.com/user-attachments/assets/c24360d9-793f-45d2-8686-bf280d99a572" />
  Nếu muốn giữ lại một bản sao tại hộp thư gốc, hãy tích vào ô *Retain a copy of forwarded mail*.
## Tìm hiểu về Content Filter
### Spam filter 
Là bộ phận đánh giá xem một email có phải là quảng cáo hoặc lừa đảo hay không.

<img width="697" height="339" alt="image" src="https://github.com/user-attachments/assets/aef57d97-6d88-420b-8f50-ae9888e1b17a" />

### Antivirus
Là tấm khiên này bảo vệ server khỏi các phần mềm độc hại (Malware/Virus) đính kèm trong thư.

<img width="771" height="341" alt="image" src="https://github.com/user-attachments/assets/f7f11d20-2fb8-4eb1-bb74-24c4c8610340" />
Nếu phát hiện virus, hệ thống sẽ tự động xóa file đính kèm, xóa toàn bộ thư hoặc cô lập (Quarantine) để Admin kiểm tra

### Attachment Filters
Là bộ lọc dựa trên loại tệp (đuôi file) thay vì nội dung file để ngăn chặn người dùng vô tình tải và chạy các file thực thi có thể chứa mã độc, ngay cả khi virus đó "mới" đến mức Antivirus chưa kịp nhận diện  

<img width="818" height="344" alt="image" src="https://github.com/user-attachments/assets/5cb6e514-b515-47ff-ac20-ce2def8e9b73" />

### Message Filters
là bộ lọc linh hoạt nhất, cho phép bạn tự định nghĩa các quy tắc theo nhu cầu doanh nghiệp.  
Ví dụ: Nếu trong nội dung thư có chữ "Lương tháng 13" Thì chuyển thư đó vào hộp thư của Sếp 

<img width="806" height="365" alt="image" src="https://github.com/user-attachments/assets/1c724917-92d9-4a74-a25a-358256148af7" />
## Phân quyền cho tài khoản thành admin của domain
Domain Admin là tài khoản chỉ có quyền quản lý các user trong một tên miền cụ thể, không được can thiệp vào cấu hình hệ thống server.  
* Account manager - Administrative Roles - Domain Administrator
  
<img width="784" height="342" alt="image" src="https://github.com/user-attachments/assets/009bb0bc-f6ae-4ee6-8fdd-b8e87a1228c4" />

## Đổi mật khẩu account admin global, admin domain
Global Admin là tài khoản có quyền chỉnh sửa mọi thứ trên server  
* Account manager - edit - Account detail - sửa pass
  
  <img width="569" height="353" alt="image" src="https://github.com/user-attachments/assets/65c453e7-6814-4bc6-86c0-845c1bdf57b2" />
* Admin domain :  Global admin

## Kiểm tra log gửi/nhận email 
### Cách 1: Xem qua giao diện Logs
 <img width="822" height="368" alt="image" src="https://github.com/user-attachments/assets/2a835a40-7a01-4640-b7bb-eaec6d678963" />

*   SMTP-In: Ghi lại toàn bộ quá trình các server khác gửi mail đến server của bạn (Nhận).  
*   SMTP-Out: Ghi lại quá trình server của bạn gửi mail đi nơi khác (Gửi).  

<img width="811" height="343" alt="image" src="https://github.com/user-attachments/assets/93445e0a-197a-4c04-af7b-00d7d1259ed0" />
<img width="817" height="327" alt="image" src="https://github.com/user-attachments/assets/ba1783f8-935e-4d9a-bb32-3adaccca100a" />

Các dòng chữ màu đen/xanh là bình thường, dòng chữ màu đỏ thường là báo lỗi
### Cách 2: Xem trạng thái hàng chờ
* Vào Messages and Queues
   * Remote Queue: Đây là nơi chứa các email đang chờ để gửi ra ngoài internet.  
   * Local Queue: Đây là nơi chứa các email gửi nội bộ giữa các user trong công ty bạn.  
<img width="817" height="370" alt="image" src="https://github.com/user-attachments/assets/400567ab-d216-4347-827a-0f4eec2df0e7" />
Nếu thấy email nằm ở đây quá lâu, bạn có thể chuột phải chọn Freeze hoặc Re-queue  
Một số mã lỗi log "đặc biệt chú ý" trong MDaemon:  
   * 250 OK: Email đã được gửi/nhận thành công.  
   * 550 User unknown: Gửi trượt vì địa chỉ email người nhận không tồn tại.  
   * 421 Service unavailable: Server đối phương đang bận hoặc từ chối kết nối.     
   * 554 Transaction failed: Thư bị chặn do dính Content Filter hoặc Spam Filter.      
## Dynamic screening trong Security của MDaemon
Dynamic Screening là một trong những tính năng bảo mật "thông minh" nhất của MDaemon. Nó là bộ lọc theo dõi các kết nối đến Server theo thời gian thực. Nếu một địa chỉ IP có hành vi "xấu" (thử mật khẩu sai nhiều lần, gửi quá nhiều mail rác...), Dynamic Screening sẽ tự động chặn IP đó trong một khoảng thời gian nhất định
<img width="826" height="342" alt="image" src="https://github.com/user-attachments/assets/020a731d-7994-401a-af64-02b48b643f7b" />
Authentication Failure Blocking: Nếu 1 IP đăng nhập sai mật khẩu $X$ lần trong $Y$ phút. 
Account Blocking Options:	Tự động "đóng băng" một tài khoản nếu có quá nhiều lần đăng nhập thất bại. 
Dynamic Allow/Block List:	Danh sách các IP tin tưởng/kh tin tưởng.  


## Backup và Restore
* Tạo file thực thi (.bat)  
<img width="362" height="161" alt="image" src="https://github.com/user-attachments/assets/e1839d24-2f8c-46f1-b7a1-54df4eab52b1" />

* Thiết lập Task Scheduler  
<img width="492" height="351" alt="image" src="https://github.com/user-attachments/assets/47af66f4-5b2e-496a-9ef2-88ee86351012" />

* Cấu hình nâng cao
Chọn Run whether user is logged on or not (Để nó tự chạy ngay cả khi bạn đã Log out khỏi Server).
   
Tích chọn Run with highest privileges (Chạy với quyền Admin cao nhất để có quyền copy file hệ thống).  

 <img width="386" height="266" alt="image" src="https://github.com/user-attachments/assets/b119748b-f6d2-4ad9-96b8-01ee88431e46" />
Tại tab Conditions:

   * Bỏ tích mục Start the task only if the computer is on AC power (Nếu là máy ảo thì nên bỏ tích để đảm bảo nó luôn chạy). 
<img width="386" height="295" alt="image" src="https://github.com/user-attachments/assets/03236581-14f0-43cf-9df3-49b27812df17" />

---
# Monitor Promethues + Grafana
## Tổng quan 
Prometheus là một hệ thống giám sát và cảnh báo mã nguồn mở, được thiết kế để thu thập và xử lý các chỉ số (metrics, không phải logs) từ ứng dụng và hạ tầng. Prometheus  định kỳ gửi yêu cầu HTTP để thu thập dữ liệu từ các mục tiêu được cấu hình.

### Cài đặt Promethues
#### Bước 1: Tạo user,group cho Prometheus
<img width="778" height="54" alt="image" src="https://github.com/user-attachments/assets/3956c948-1935-40ef-ae57-c02f78c755a7" />

#### Bước 2: Tải và cài đặt Prometheus
* Tải gói prometheus mới nhất, giải nén gói
<img width="895" height="401" alt="image" src="https://github.com/user-attachments/assets/4e4eef21-78ba-482c-ab4f-6b98955e3bd6" />

#### Bước 3: Tạo các thư mục cần thiết
<img width="446" height="63" alt="image" src="https://github.com/user-attachments/assets/80ef5040-e8e6-47d0-82ba-6e2277f5d78b" />

#### Bước 4: Phân quyền thư mục
<img width="476" height="109" alt="image" src="https://github.com/user-attachments/assets/0c3255cc-0783-4894-bf3b-4bdad2664590" />  

#### Bước 5: Tạo file cấu hình
sudo nano /etc/prometheus/prometheus.yml
<img width="599" height="233" alt="image" src="https://github.com/user-attachments/assets/ee61cdca-af2a-4b30-98c0-beddd2477cbf" />  

#### Bước 6 Dịch vụ Systemd dành cho Prometheus
sudo nano /etc/systemd/system/prometheus.service
<img width="581" height="266" alt="image" src="https://github.com/user-attachments/assets/5e892e20-3641-4fe7-b38b-f14e2e2d3f67" />  

#### Bước 7: Khởi động lại và check dịch vụ 
http://192.168.254.100:9090
<img width="959" height="315" alt="image" src="https://github.com/user-attachments/assets/e49f5fb0-b9a0-4374-86d1-06619bafd0d6" />

---

###  Cài đặt Node Exporter
#### Bước 1: cài đặt và giải nén node exporter  
<img width="911" height="403" alt="image" src="https://github.com/user-attachments/assets/4f6686ed-3cfc-4c0d-9957-108d5f43f5f2" />  

#### Bước 2: tạo user exporter, phân quyền user  
<img width="614" height="38" alt="image" src="https://github.com/user-attachments/assets/d373ce3c-7c23-4e07-b978-63ccfc85542d" />  

#### Bước 3:Tạo Service cho Node Exporter
<img width="614" height="269" alt="image" src="https://github.com/user-attachments/assets/1eb37cfb-de65-4a12-b396-d5f2b204bd33" />  

#### Bước 4:Khởi động dịch vụ
<img width="826" height="136" alt="image" src="https://github.com/user-attachments/assets/85a49569-5abd-4c52-9e93-f2345f4706ac" />

kết quả:
http://192.168.254.100:9100/metrics
<img width="918" height="452" alt="image" src="https://github.com/user-attachments/assets/2e1ae8a2-cc13-4cb3-bc42-ad0a929032ce" />

---

### Cài đặt Grafana
#### Bước 1: Thêm Repository và Key

<img width="898" height="49" alt="image" src="https://github.com/user-attachments/assets/1d7b4aaa-2063-4da2-8cb7-1aab56da1ab4" />

#### Bước 2: Cài đặt Grafana
<img width="576" height="328" alt="image" src="https://github.com/user-attachments/assets/40ebafe0-7201-4a8b-902c-300e400f15b8" />

#### Bước 3: Kích hoạt Service

<img width="893" height="315" alt="image" src="https://github.com/user-attachments/assets/ce43634c-4359-43f4-b250-25797426082e" />

kết quả:
http://192.168.254.100:3000/login

<img width="827" height="427" alt="image" src="https://github.com/user-attachments/assets/d698d2c6-dece-4721-b4fc-9782661fbcb7" />  
Đăng nhập mặc định là tk admin, mk admin, đổi mật khẩu ngay khi đăng nhập  

<img width="955" height="471" alt="image" src="https://github.com/user-attachments/assets/b17a403d-eb61-4ce9-87b7-3a32e3d44069" />

### MYSQL MONITORING
#### Bước 1: Cài đặt mysql, tạo user cho exporter
<img width="919" height="313" alt="image" src="https://github.com/user-attachments/assets/f9400690-0a46-442a-a914-bf9596025ffe" />

#### Bước 2: Cài đặt mysqld_exporter

<img width="899" height="404" alt="image" src="https://github.com/user-attachments/assets/9f5462bc-ab08-42dc-929f-f50cbf54cc19" />

giải nén và phân quyền thư mục 
<img width="612" height="104" alt="image" src="https://github.com/user-attachments/assets/428b7d07-1628-435b-924e-f195b2a5263a" />

#### Bước 3: Cấu hình MySQL Exporter
File /etc/mysql/conf.d/mysqld_exporter.cnf phải được phân quyền 600 để chỉ user mysqld_exporter mới đọc được mật khẩu  

<img width="626" height="103" alt="image" src="https://github.com/user-attachments/assets/8ba5150f-5da5-4fe5-ac2b-15e6121583db" />

#### Bước 4: Tạo Service MySQL Exporter

<img width="697" height="252" alt="image" src="https://github.com/user-attachments/assets/3227d583-cf86-4487-a367-9f34a0ab6d22" />

#### Bước 5: Khởi động dịch vụ 

<img width="890" height="197" alt="image" src="https://github.com/user-attachments/assets/a8943da9-4d28-4e78-93c0-4551c3d6882f" />

kết quả
<img width="944" height="397" alt="image" src="https://github.com/user-attachments/assets/8c928678-727d-45f0-9e45-f101be74e7b9" />

Khai báo với Prometheus

<img width="632" height="260" alt="image" src="https://github.com/user-attachments/assets/c484340c-81b8-42c7-b1a2-4617efa838ba" />

### KẾT NỐI GRAFANA VỚI PROMETHEUS
Home → Connections → Data Sources → Add new connection
<img width="959" height="455" alt="image" src="https://github.com/user-attachments/assets/055c24bd-c516-4d4c-a46e-99510c741887" />  
Import Dashboard:  
 Để giám sát Linux: Nhập ID 1860  
 Để giám sát MySQL: Nhập ID 7362
 
### Query promethues (PromQL)
PromQL (Ngôn ngữ truy vấn Prometheus) có ngôn ngữ truy vấn của Prometheus cho phép thực hiện các hoạt động liên quan đến số liệu dữ liệu như RAM, CPU.  
Dữ liệu của PromQL có thể sử dụng để search data tính toán, kết hợp dữ liệu, tạo các biểu đồ, cảnh báo

   | THÔNG SỐ GIÁM SÁT | CÂU LỆNH PROMQL (QUERY) |  
   | :--- | :--- |  
   | CPU Usage (%) | 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) |  
   | RAM Usage (%) | (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 |  
   | CPU Load (1m) | node_load1 |  
   | Server Uptime | node_time_seconds - node_boot_time_seconds |  
   || Disk Usage (%) | 100 - ((node_filesystem_avail_bytes{mountpoint="/"}) * 100 /             node_filesystem_size_bytes{mountpoint="/"}) | 
   | Network In | rate(node_network_receive_bytes_total[5m]) |   
   | Network Out | rate(node_network_transmit_bytes_total[5m]) |  
   | MySQL Status | mysql_up |  
   | MySQL Uptime | mysql_global_status_uptime |  
   | MySQL Connections | mysql_global_status_threads_connected |  
   | MySQL Queries/s | rate(mysql_global_status_questions[1m]) |  
   | MySQL Slow Queries | rate(mysql_global_status_slow_queries[5m]) |  

### Đưa biểu đồ lên kết hợp grafana (biểu đồ hiển thị RAM, CPU, Uptime, CPU Load, Mysql)
* Dashboard -> new Dashboard -> dùng các lệnh PromQL đã liệt kê ở trên để hiển thị
  Ví dụ
  
  <img width="466" height="353" alt="image" src="https://github.com/user-attachments/assets/7232e5b5-313f-401b-ae10-579af79eb803" />
