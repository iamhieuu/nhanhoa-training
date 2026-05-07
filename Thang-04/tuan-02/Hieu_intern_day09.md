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
<img width="781" height="478" alt="image" src="https://github.com/user-attachments/assets/0ec6e956-7caa-4b79-9dc5-6fbbec5dd316" />

Các thành phần chính:  
* Inbound Rules: Kiểm soát các kết nối từ bên ngoài cố gắng truy cập vào server (ví dụ: cho phép khách truy cập web port 80).  
* Outbound Rules: Kiểm soát các ứng dụng từ trong server truy cập ra internet (ví dụ: chặn một phần mềm độc hại gửi dữ liệu ra ngoài).  
* Connection Security Rules: Thiết lập các kết nối bảo mật IPsec giữa các máy tính
#### Tạo Inbound Rule qua GUI
Inbound Rules → New Rule → Chọn Rule Type Port →→ Chọn Allow/Deny the connection → Chọn profile: Domain, Private, Public
<img width="731" height="385" alt="{40DC1218-7B97-4E67-83ED-A274BC64599F}" src="https://github.com/user-attachments/assets/cc8a79c7-e267-4f70-aebe-209f8f9756c9" />

#### Tạo Outbound Rule — Block ứng dụng
Click Outbound Rules → New Rule → Rule Type: Program Browse → executable: C:\Program Files\... → Block the connection → Đặt tên và Finish
<img width="473" height="394" alt="{79916A0B-3476-4F62-B725-08CD681DD898}" src="https://github.com/user-attachments/assets/7a3df255-806c-4355-a6da-ea5015d75eff" />

### 3. Cấu hình qua PowerShell
PowerShell cho phép tự động hóa hoàn toàn
#### Xem trạng thái rule
* Xem trạng thái tất cả profile
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction
<img width="475" height="78" alt="{67B1261E-48CB-4D11-8713-48052C05A0FA}" src="https://github.com/user-attachments/assets/f576fd31-bf5f-4126-8b1a-62f071fd7b18" />

* Xem tất cả rules
Get-NetFirewallRule | Select DisplayName, Direction, Action, Enabled | Format-Table
<img width="478" height="264" alt="{47916A39-1225-46DD-B4F6-B0F1287ABDE3}" src="https://github.com/user-attachments/assets/23e98844-9355-4fc9-ae8d-3bc26f155073" />

* Lọc rules đang bật
Get-NetFirewallRule -Enabled True | Format-Table DisplayName, Direction, Action
<img width="482" height="146" alt="{CC21258B-2B78-4A26-8CBF-75366A3A29D1}" src="https://github.com/user-attachments/assets/971ae27f-d80c-4445-ac22-4b2f898fb8c0" />

* Xem rules với thông tin port
Get-NetFirewallRule -DisplayName "Allow HTTP*" | Get-NetFirewallPortFilter
<img width="416" height="129" alt="{C2799A54-7F72-4F04-9C51-C0793C435F8D}" src="https://github.com/user-attachments/assets/399dfe41-d2db-4cc6-9d26-5a93f74d80f8" />

#### Tạo rules cơ bản trên powershell
Cho phép port inbound  
```powershell
New-NetFirewallRule `
    -DisplayName "Allow HTTP Inbound" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 80 `
    -Action Allow `
    -Profile Any `
    -Enabled True
```
<img width="486" height="312" alt="{7F1864BE-4D81-4B00-9F42-AEDD40FE1365}" src="https://github.com/user-attachments/assets/1fc15927-ef40-46a6-b5ae-06cfa21899b0" />

* Cho phép RDP chỉ từ dải mạng nội bộ
```
New-NetFirewallRule `
    -DisplayName "Allow RDP Internal Only" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3389 `
    -RemoteAddress 192.168.136.133/24 `
    -Action Allow `
    -Profile Domain,Private `
    -Enabled True
```

* Chặn ip cụ thể
```
New-NetFirewallRule `
    -DisplayName "Block Attacker 192.168.136.121" `
    -Direction Inbound `
    -RemoteAddress 192.168.136.121 `
    -Action Block `
    -Enabled True
```
## III.So sánh

|Tiêu chí|Linux (iptables/ufw|Windows Defender Firewall|
| :--- | :--- | :--- | 
|Giao diện | CLI, file config | GUI (wf.msc) + PowerShell|  
|Tính linh hoạt | Rất cao  | Trung bình | 
|Tự động hóa | Shell script, Ansible | PowerShell, Group Policy|  
|Stateful inspection | Có  | Có (tích hợp sẵn)|  
|Profiles / Zones | firewalld zones / ufw app | Domain / Private / Public|  
|Logging | /var/log/ufw.log, iptables LOG | Event Viewer, WFP log|  
|NAT / Routing | Có (iptables -t nat) | Hạn chế, cần RRAS|  
|Môi trường phù hợp | Server, cloud, DevOps | Enterprise Windows infra|    
|Chi Phí | FREE | Có phí |    

Không có cái nào tốt hơn, chúng phù hợp với hệ sinh thái của mình. Cần biết sử dụng cả hai.
## IV.Tcpdump và wireshark
- Tcpdump và Wireshark đều dùng để bắt và phân tích gói tin mạng (.pcap) . Chúng là công cụ giám sát/debug.
- TCPdump hoạt động ở tầng 2,3,4 trong mô hình OSI

|Tiêu chí | TCPDump | Wireshark|  
| :--- | :--- | :--- |  
|Giao diện | Dòng lệnh (CLI) | Giao diện đồ họa (GUI)|  
|Tài nguyên | Rất nhẹ, tốn ít RAM/CPU | Nặng, yêu cầu nhiều tài nguyên|  
|Dùng trên server | Rất tốt, phù hợp môi trường không màn hình | Hạn chế, cần cài thêm môi trường đồ họa (X11)|  
|Phân tích trực quan | Không có, chỉ hiện dòng text | Rất tốt, có biểu đồ và màu sắc|  
|Đọc file .pcap | Có hỗ trợ | Có hỗ trợ (rất mạnh)|  
|Cú pháp lọc | BPF  | Display Filter phức tạp và chi tiết hơn|  
|Dùng cho| Capture nhanh, automation, SSH session | Phân tích sâu, trực quan|


### TCPDUMP trên Ubuntu 22.04
1. Cài đặt tcpdump  
sudo apt install -y tcpdump  
<img width="391" height="111" alt="{B9BD8002-E595-48E9-B262-E2C51C2BC4A1}" src="https://github.com/user-attachments/assets/67e87d46-85e0-4f49-888d-0f5df5ce46ae" />  
- tcpdump cần quyền root để bắt gói tin, ta có thể sử dụng 2 cách sau  
 - 1 là dùng sudo tcpdump  
 - 2 là gán cho user vào group pcap  
<img width="437" height="129" alt="{E2E1323F-1A76-4FBF-AAB7-AA4DE43BB518}" src="https://github.com/user-attachments/assets/691150ac-d0e6-4b4d-9a9c-b906c4e9992d" />

2. Xem tất cả card mạng
sudo tcpdump -D
<img width="432" height="128" alt="{F3978C58-1BC4-4E69-AF7B-615966A004AD}" src="https://github.com/user-attachments/assets/7c68364a-e234-4d2b-ae17-eead8a028d31" />
tcpdump [options] [filter expression] : cú pháp cơ bản  
VD: sudo tcpdump -i ens33: Bắt tất cả gói tin
sudo tcpdump -i ens33 -c 10: Bắt 10 gói rồi dừng
<img width="792" height="210" alt="{54178F18-5B61-4D04-92B6-1AB5C1323A6A}" src="https://github.com/user-attachments/assets/34c840bb-a070-4210-b24a-c9562d61d0d2" />


```
-i <interface>   : Chọn card mạng
                   Ví dụ: -i ens33, -i any (tất cả)
-n               : Không phân giải DNS (hiển thị IP thay hostname)
-nn              : Không phân giải cả port (hiển thị số thay tên)
-v               : Verbose: Hiển thị thêm thông tin
-vvv             : Verbose nhất
-c <number>      : Bắt <number> gói tin rồi dừng
                   Ví dụ: -c 100
-w <file>        : Lưu vào file .pcap
                   Ví dụ: -w /tmp/capture.pcap
-r <file>        : Đọc từ file .pcap
                   Ví dụ: -r /tmp/capture.pcap
-l               : Line buffering (hiển thị ngay)
-A               : Hiển thị nội dung ASCII
-X               : Hiển thị nội dung Hex và ASCII
-XX              : Hiển thị cả Ethernet header
-e               : Hiển thị thông tin Ethernet (MAC address)
-s <size>        : Kích thước snapshot (byte)
                 : -s 0 hoặc -s 65535 = bắt toàn bộ
-q               : Quiet mode (ít thông tin hơn)
```
3. Thực hành

Bắt 10 gói tin bất kì   
<img width="858" height="224" alt="{5E92B9AA-5665-4E12-896F-EAEC81CF8820}" src="https://github.com/user-attachments/assets/58be28e5-981e-4d2b-bfa8-20897a8df6da" />

Bắt gói TCP  
sudo tcpdump -i ens33 tcp -c 20  
<img width="846" height="331" alt="{063A7491-1A97-4C97-894A-E3FF9F9B33A9}" src="https://github.com/user-attachments/assets/e6e5b0da-8c71-4061-8ad8-c361c90228b3" />

Bắt port 22 (SSH)  
sudo tcpdump -i eth0 port 22 -c 20   
<img width="828" height="331" alt="{E928AB06-D2DA-41AD-989F-25AB7D85F602}" src="https://github.com/user-attachments/assets/e82e5670-149a-4851-b0d8-b42345832928" />

Lưu file và đọc file
sudo tcpdump -i eth0 -w /var/log/tcpdump/capture_$(date +%Y%m%d_%H%M%S).pcap
<img width="873" height="354" alt="{3E6A0890-2410-46F2-B8B5-419465680967}" src="https://github.com/user-attachments/assets/e1af904a-1c25-4ed7-9452-c861be53fa20" />

