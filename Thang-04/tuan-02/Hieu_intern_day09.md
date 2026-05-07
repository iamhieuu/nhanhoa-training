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


### TCPdump trên Ubuntu 22.04
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
sudo tcpdump -i ens33 port 22 -c 20     
<img width="828" height="331" alt="{E928AB06-D2DA-41AD-989F-25AB7D85F602}" src="https://github.com/user-attachments/assets/e82e5670-149a-4851-b0d8-b42345832928" />

Bắt DNS:  
sudo tcpdump -i ens33 udp port 53 -A -c 20  
<img width="689" height="350" alt="{D5C4B4AC-B18C-4D57-B2C6-B635F9C75337}" src="https://github.com/user-attachments/assets/dfe1c1c6-df3d-4abc-be72-0cec6f925456" />

Xem nội dung ASCII của gói tin  
sudo tcpdump -i ens33 -A port 80 -c 20  
<img width="817" height="404" alt="{26190858-7BC3-4BB5-9245-B0492DFE585C}" src="https://github.com/user-attachments/assets/4e24e7c4-901d-4b05-b3fa-71613b8f323f" />

Xem Hex + ASCII:  
sudo tcpdump -i ens33 -X port 80 -c 10  
<img width="860" height="330" alt="{0705BC20-2D1F-4239-B4C0-5E3A2E123565}" src="https://github.com/user-attachments/assets/a0cccfe2-6eaf-429f-a9b1-b70f2ddd98b2" />


Lưu file và đọc file  
sudo tcpdump -i ens33 -w /var/log/tcpdump/capture_$(date +%Y%m%d_%H%M%S).pcap  
<img width="873" height="354" alt="{3E6A0890-2410-46F2-B8B5-419465680967}" src="https://github.com/user-attachments/assets/e1af904a-1c25-4ed7-9452-c861be53fa20" />  

### Wireshark trên Ubuntu 22.04
Wireshark là công cụ phân tích gói tin mạng có giao diện đồ họa (GUI), miễn phí và mã nguồn mở. Nó giúp ta có thể nhìn thấy toàn bộ dữ liệu đi qua card mạng, phân tích gói tin chi tiết, debug sự cố mạng hay ứng dụng, Check bảo mật hệ thống  
Công cụ thực hiện:  
Ubuntu server: Tshark  
Ubuntu desktop: Wireshark  
Sử dụng Wireshark trên Ubuntu Server chủ yếu thông qua công cụ dòng lệnh TShark để bắt và phân tích gói tin mạng. Bạn cần cài đặt, cấu hình quyền người dùng, và sử dụng các câu lệnh tshark để ghi log, phân tích trực tiếp hoặc lưu file .pcap để phân tích sau. 
#### Cài Tshark 
Cài đặt TShark
sudo apt install -y tshark
<img width="381" height="93" alt="{6C55FC12-A9FA-47EE-A1E7-5177266237D8}" src="https://github.com/user-attachments/assets/93196040-4026-4e30-bdd5-4c5185b27ae2" />
Thêm user vào group wireshark
sudo usermod -aG wireshark $USER

---
Xem danh sách các card mạng 
tshark -D
<img width="366" height="203" alt="{2FA47188-50C4-48B2-867D-88878FDB6648}" src="https://github.com/user-attachments/assets/37e0e836-9329-4b9e-a73d-234c4ea0c299" />
tshark -i ens33 -c 10 : Bắt gói tin cơ bản
<img width="644" height="195" alt="{8D1C01A2-BE91-48F9-BDB3-050E68992352}" src="https://github.com/user-attachments/assets/2522f2ac-2e86-4d00-b189-a005afd89504" />
tshark -i ens33 -c 100 -w /var/log/tcpdump/tshark.pcap: Lưu vào file pcap
<img width="793" height="358" alt="{B4F3044F-F3AA-4A2A-A486-ED9D458CD6FB}" src="https://github.com/user-attachments/assets/0e406bab-c686-4d71-8bc6-eee69ab92dd9" />

Chỉ hiển thị IP nguồn, đích và giao thức  
```
tshark -i ens33 -c 20 -T fields \
    -e frame.number \
    -e ip.src \
    -e ip.dst \
    -e _ws.col.Protocol \
    -e frame.len
```
<img width="877" height="324" alt="{BC58000A-7F6A-4AFD-A382-7940AE4B4A1B}" src="https://github.com/user-attachments/assets/ac11cf9b-def1-4cde-9ebf-fecde9f6f722" />

#### Cài Wireshark 
 Cài đặt Wireshark GUI
sudo apt install -y wireshark
<img width="489" height="408" alt="{E2218600-F563-4D29-8F1E-3F9E0F6CC4B4}" src="https://github.com/user-attachments/assets/6d10003b-acc6-4bbd-82b8-63e9b436f3e2" />

#### Copy File PCAP Về Máy Local
scp hostname@IPserver:/var/log/tcpdump/file.pcap ~/Downloads/
<img width="367" height="240" alt="{5A23A37B-88AC-4A2F-8939-32D7CC318ACA}" src="https://github.com/user-attachments/assets/9ce5be1a-c0bd-4ca4-8e42-aae2b3cdd903" />

#### Phân Tích Với Wireshark GUI
Mở Wireshark → File → Open → Chọn file .pcap đã copy về → Click Open
<img width="479" height="418" alt="{021B106B-5C10-44D9-910D-FA2B87248BFA}" src="https://github.com/user-attachments/assets/cc665498-b0b3-4404-8dcb-8daa4cee9527" />
🟢 Xanh lá    : TCP traffic thông thường  
🔵 Xanh dương  : UDP traffic  
⚫ Đen        : Gói tin lỗi   
🟡 Vàng       : Retransmissions, out of order  
🔴 Đỏ         : TCP RST, lỗi kết nối  
🩷 Hồng       : ICMP errors  
🟣 Tím        : IPv6 traffic  

* Display Filters: Dùng để lọc trong wireshark 
Lọc theo giao thức, IP, port
<img width="475" height="403" alt="{5108A702-4BD6-4C91-9A0D-7D34EC950A47}" src="https://github.com/user-attachments/assets/ecafbc67-b15b-49a8-8e62-93e12661bf62" />

* Follow TCP Stream
 * Màu đỏ: Client gửi (request)
 * Màu xanh: Server trả lời (response)

<img width="329" height="401" alt="{9C8A1659-1921-4C95-91F1-BA127E55DE7D}" src="https://github.com/user-attachments/assets/45c28889-6110-4fe3-bd9d-3901f7a4ade1" />

* Statistics (Thống Kê)  
Menu Statistics:  
→ Protocol Hierarchy   : % từng giao thức  
→ Conversations        : Tất cả kết nối  
→ Endpoints            : Tất cả IP/port  
→ IO Graphs            : Biểu đồ băng thông theo thời gian  
→ Flow Graph           : Luồng kết nối  
→ DNS                  : Thống kê DNS queries  
→ HTTP                 : Thống kê HTTP requests  
