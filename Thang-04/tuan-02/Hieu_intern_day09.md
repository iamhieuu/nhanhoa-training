# Báo cáo thực tập ngày 09 - Firewall, tcpdump và wireshark
## I.Firewall trên Linux
### 1. Tổng quan về Firewall
Firewall là một công cụ bảo mật mạng giúp: 
Kiểm soát luồng dữ liệu vào/ra hệ thống  
Chặn các kết nối không được phép  
Cho phép các kết nối được phép  
Bảo vệ hệ thống khỏi các cuộc tấn công mạng     
Trên Linux, các công cụ phổ biến gồm:  
* iptables: làm việc dựa trên các bảng (tables) và chuỗi (chains) để quyết định số phận của một gói tin  
* nftables: Update của iptables, được thiết kế để thay thế iptables với hiệu suất cao hơn và cú pháp dễ hiểu hơn  
* ufw: Trên Ubuntu. Nó cực kỳ đơn giản, phù hợp cho người mới  
* firewalld: Mặc định trên RHEL/CentOS.. Sử dụng Zones để quản lý lưu lượng linh hoạt mà không cần khởi động lại firewall khi thay đổi cấu hình.
* CSF & APF : Thường được sử dụng trên các máy chủ Web để chống tấn công Brute Force và bảo vệ ứng dụng web.
### 2.Yêu cầu cơ bản  
 Mọi thay đổi liên quan đến Firewall đều can thiệp vào nhân hệ thống, do đó bắt buộc phải có quyền root hoặc sử dụng lệnh sudo  
 Giao Thức Cơ Bản  
- TCP (Transmission Control Protocol): Kết nối được thiết lập  
  VD: HTTP (port 80), HTTPS (443), SSH (22)  
- UDP (User Datagram Protocol): Không cần thiết lập kết nối  
  VD: DNS (53), NTP (123), DHCP (67-68)  
- ICMP: Ping, traceroute  
  VD: ping để kiểm tra kết nối

### 3.Cấu hình

## II.Firewall trên Windows
### 1.Tổng quan về firewall trên windows
Windows Defender Firewall là một thành phần quan trọng của hệ điều hành Windows, giúp bảo vệ máy tính bằng cách chặn các lưu lượng truy cập trái phép. Khác với Linux tập trung vào "Chains", Windows quản lý Firewall dựa trên các Profiles  
Domain Profile: Áp dụng khi máy tính kết nối vào một mạng nội bộ có máy chủ quản lý tên miền.    
Private Profile: Áp dụng cho các mạng tin tưởng như mạng nhà riêng hoặc văn phòng nhỏ.  
Public Profile: Áp dụng cho các mạng công cộng (như cafe, sân bay) – đây là mức bảo mật cao nhất, chặn hầu hết các kết nối vào. 
### 2. Cấu hình qua GUI
Cách truy cập: Nhấn Win + R, gõ wf.msc và Enter  
Các thành phần chính:  
* Inbound Rules: Kiểm soát các kết nối từ bên ngoài cố gắng truy cập vào server (ví dụ: cho phép khách truy cập web port 80).  
* Outbound Rules: Kiểm soát các ứng dụng từ trong server truy cập ra internet (ví dụ: chặn một phần mềm độc hại gửi dữ liệu ra ngoài).  
* Connection Security Rules: Thiết lập các kết nối bảo mật IPsec giữa các máy tính

### 3. Cấu hình qua PowerShell

## III.So sánh

## IV.Tcpdump và wireshark
