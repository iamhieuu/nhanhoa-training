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
Check 1 số thông tin cơ bản
<img width="233" height="174" alt="{F7F6010F-F32A-4552-8368-94751BF8327B}" src="https://github.com/user-attachments/assets/929550bf-b487-4b04-9c0a-ab5b23da7a82" />

#### Iptables
* Xem tất cả rule  
sudo iptables -L -n
<img width="483" height="157" alt="{EF8125E2-F66F-48FF-918E-1265C3AB5E82}" src="https://github.com/user-attachments/assets/51c2721d-d5d6-4cc6-9c7c-429e92186d83" />

* Xem dạng lệnh  
sudo iptables -S
<img width="289" height="112" alt="{09135A9E-E92E-4A86-B098-E438EDD5C838}" src="https://github.com/user-attachments/assets/edf6c338-c607-4ab2-9e46-dc388792d517" />
Cú pháp cơ bản  
iptables -[A/I/D] CHAIN -[p/s/d/i/o] [giá_trị] --dport [port] -j [ACTION]  
<img width="445" height="40" alt="{465EA0A8-D469-4207-995F-4E9FD4D62BA5}" src="https://github.com/user-attachments/assets/724e7a16-ddfe-4338-8214-557e6fb736bd" />

* Chống brute force SSH. Tối đa 3 phút 1 kết nổi 
<img width="442" height="82" alt="image" src="https://github.com/user-attachments/assets/5dd02942-2bd6-45f1-aeda-58ed34b0e1f8" />

* Chèn rule
<img width="862" height="184" alt="{1982501C-ACB2-4E9E-B87C-EB1C04577480}" src="https://github.com/user-attachments/assets/84731b3c-4b2f-469f-8474-3f97671667dc" />

* Xóa rule
<img width="872" height="220" alt="{96506455-2421-403B-B32F-F525E3F8AF9F}" src="https://github.com/user-attachments/assets/b42a5e6c-5686-41c3-9e05-41779a1ccc13" />

* Log cái rule bị drop
  sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-drop: "  

* Lưu rule vĩnh viễn
sudo iptables-save > /tmp/iptables-backup.txt  
<img width="879" height="253" alt="{FACAE0D0-3194-494C-B20B-24F4854EA615}" src="https://github.com/user-attachments/assets/0e0aa80a-a0e9-41ec-9a6c-ef2c293d5e27" />  
sudo iptables-restore < /tmp/iptables-backup.txt  
Hoặc dùng sudo netfilter-persistent save
<img width="529" height="88" alt="{3A10AA04-B675-4FFC-BF48-D58EF2510C19}" src="https://github.com/user-attachments/assets/b0631c3d-bf8c-4522-b94d-b7bc3025aaf8" />

* Clear rule
<img width="575" height="231" alt="{F1AC5CAF-38D7-4A0B-AB8C-8A60CD9FD68A}" src="https://github.com/user-attachments/assets/8919bd3a-5ace-4b44-a9a1-fce5ea39d9c1" />

### UFW
* Lệnh cơ bản check trạng thái và xem rule
<img width="495" height="337" alt="{A1C5DEFF-58E0-4868-BD89-2816E7174BB5}" src="https://github.com/user-attachments/assets/983490b4-a422-4455-9279-b2d2732817f4" />

* Thêm rule
<img width="381" height="316" alt="{925E20C1-8855-4F20-B32C-E4A6E4DBAF9C}" src="https://github.com/user-attachments/assets/db12d792-c4dd-40d5-a173-c63afc9a30e3" />
sudo ufw allow from/deny.. to..: cho phép/ chặn từ IP đến port cụ thể

* Xóa rule
<img width="410" height="219" alt="{91B86AA2-87FD-4966-B8C7-F83FE90F2091}" src="https://github.com/user-attachments/assets/511eeb31-04b2-4049-aa04-03e6fc7f79c3" />

* Bật log
<img width="324" height="72" alt="{1F354A98-C653-4FCE-8B41-DF8A3BD778F7}" src="https://github.com/user-attachments/assets/5d0b5c84-398a-4d71-a763-8143d5f087fd" />

* Check log ufw
<img width="868" height="88" alt="{EA5DC344-BC4A-4020-9D72-6493C0E193E4}" src="https://github.com/user-attachments/assets/c79763f0-03c9-4ab9-ab10-9560f768e0f5" />

* Xóa all ufw
sudo ufw reset

### CSF
Cài đặt thư viện cần thiết  
sudo apt install perl libwww-perl libio-socket-ssl-perl curl -y  
* Tải csf
  Chưa thực hiện được


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
|Tiêu chí | Linux (iptables/ufw) | Windows Defender Firewall|
|**|**|**|
|Giao diện | CLI (dòng lệnh), file config | GUI (wf.msc) + PowerShell
|Tính linh hoạt | Rất cao (mangle, raw, nat) | Trung bình (WFP platform)
|Độ khó học | Cao (iptables) / Trung (ufw) | Thấp (GUI) / Trung (PS)
|Tự động hóa | Shell script, Ansible | PowerShell, Group Policy
|Stateful inspection | Có (-m state/conntrack) | Có (tích hợp sẵn)
|Profiles / Zones | firewalld zones / ufw app | Domain / Private / Public
|Logging | /var/log/ufw.log, iptables LOG | Event Viewer, WFP log
|NAT / Routing | Có (iptables -t nat) | Hạn chế, cần RRAS
|Môi trường phù hợp | Server, cloud, DevOps | Enterprise Windows infra
## IV.Tcpdump và wireshark
