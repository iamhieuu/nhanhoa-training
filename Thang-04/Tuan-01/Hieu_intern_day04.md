<img width="490" height="323" alt="image" src="https://github.com/user-attachments/assets/b1c1d7cf-97eb-496d-8e20-ca4aeb9d6a50" /># Báo cáo thực tập ngày 04 - Triển khai ứng dụng mail server MDaemon

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
* Domain
<img width="497" height="319" alt="image" src="https://github.com/user-attachments/assets/206ccffc-3258-48f1-977d-74431c7ba16f" />
* User
<img width="429" height="317" alt="image" src="https://github.com/user-attachments/assets/16996c3c-809e-4fc3-a6f0-ab916985a360" />
* Group
<img width="490" height="323" alt="image" src="https://github.com/user-attachments/assets/4d0d1702-3b6b-41ae-9573-94e30bd52560" />
* Alias
<img width="634" height="374" alt="image" src="https://github.com/user-attachments/assets/c175fb18-0a4a-4b8b-bae8-d96ad0e18dde" />
* Mailing Lists
  <img width="401" height="316" alt="image" src="https://github.com/user-attachments/assets/02347358-dc46-41fa-95a5-59dda5ffd59c" />
