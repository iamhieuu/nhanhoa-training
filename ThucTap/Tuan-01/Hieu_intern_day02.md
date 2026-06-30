# BÁO CÁO THỰC TẬP NGÀY 02
# DNS — Tài liệu kỹ thuật nội bộ 

---

## 1. DNS là gì?

DNS (Domain Name System) là hệ thống phân giải qua lại giữa **tên miền** (dễ nhớ, dạng chữ — `example.com`) và **địa chỉ IP** (dạng số — `123.11.5.19`) mà máy móc dùng để định tuyến traffic.

Bản chất: một **database phân tán, phân cấp** (distributed hierarchical database), không tồn tại ở một điểm trung tâm duy nhất — mỗi domain có name server thẩm quyền (authoritative) riêng, tự chịu trách nhiệm cho zone của mình và có thể delegate tiếp cho sub-domain. Cơ chế này giúp DNS có khả năng chịu lỗi (fault-tolerant) và scale tốt ở quy mô toàn cầu.

Ngoài phân giải A/AAAA, DNS còn lưu các loại thông tin khác: mail server (MX), bản ghi xác thực bảo mật (TXT — SPF/DKIM/DMARC), dịch vụ (SRV)...

---

## 2. Chức năng cốt lõi

| Chức năng | Mô tả ngắn |
|---|---|
| **Phân giải tên miền** | Domain ↔ IP, để user không cần nhớ IP |
| **Quản lý domain** | Đăng ký, cập nhật, hủy bản ghi qua DNS zone |
| **Thông tin bổ sung** | MX (mail), SRV (service discovery), TXT (xác thực/bảo mật) |
| **Cache & tăng tốc** | Resolver cache kết quả theo TTL, giảm round-trip |
| **Load balancing / HA** | Nhiều bản ghi A/AAAA cho cùng 1 domain → round-robin, failover |
| **Bảo mật** | DNSSEC chống giả mạo response; DoH/DoT mã hóa query (chi tiết mục 5) |

---

## 3. Nguyên tắc làm việc

- Mỗi tổ chức/ISP vận hành DNS server riêng. DNS server thẩm quyền cho 1 domain **luôn** thuộc tổ chức quản lý domain đó, không phải của bên thứ ba.
- DNS hoạt động theo cơ chế **truy vấn đệ quy/lặp** (recursive/iterative query) giữa các resolver, không có một "trung tâm" duy nhất xử lý mọi truy vấn.
- Mỗi DNS server có hai vai trò song song:
  - **Resolve outbound**: phân giải tên cho client bên trong miền nó quản lý (cả tên trong lẫn ngoài miền).
  - **Authoritative response**: trả lời các resolver bên ngoài hỏi về domain nó quản lý.
- Resolver **cache** lại kết quả đã phân giải theo TTL của bản ghi để tối ưu cho các truy vấn lặp lại.



---

## 4. Luồng phân giải DNS (resolution flow)

```
Client → Resolver (ISP/8.8.8.8/1.1.1.1)
       → Root server        (xác định TLD server, vd .com)
       → TLD server         (xác định authoritative NS của domain)
       → Authoritative NS   (trả về bản ghi thực tế: A/CNAME/MX...)
       → Resolver cache kết quả theo TTL → trả về Client
```

**Các bước:**
1. **Check local cache** — OS/browser cache trước, có thì trả ngay.
2. **Query resolver** (thường là DNS của ISP hoặc public resolver như 8.8.8.8, 1.1.1.1).
3. **Resolver query đệ quy theo cấp**: Root → TLD (.com/.vn...) → Authoritative NS của domain.
4. **Authoritative NS trả bản ghi** tương ứng (A, CNAME, MX...).
5. **Resolver cache kết quả** (theo TTL) và trả về client.
6. Client dùng IP nhận được để kết nối thẳng đến server đích — DNS không tham gia vào bước này.

---

## 5. Bảo mật DNS — chuẩn 2026

DNS truyền thống (port 53/UDP) **không mã hóa** → dễ bị nghe lén, can thiệp (DNS spoofing, cache poisoning, ISP tracking). Ba lớp bảo mật cần nắm khi vận hành:

| Công nghệ | Bảo vệ gì | Cơ chế | Ghi chú vận hành |
|---|---|---|---|
| **DNSSEC** | Chống giả mạo/đầu độc response | Ký số (digital signature) chuỗi bản ghi bằng RRSIG/DNSKEY, resolver verify chain-of-trust từ root xuống | Bảo vệ **tính toàn vẹn** dữ liệu, **không mã hóa** query. Bắt buộc bật cho domain doanh nghiệp/tài chính |
| **DoT (DNS over TLS)** | Mã hóa kênh truyền | Query DNS được bọc trong TLS, chạy trên port riêng (853) | Dễ nhận diện & chặn ở firewall vì dùng port cố định |
| **DoH (DNS over HTTPS)** | Mã hóa kênh truyền | Query DNS gửi qua HTTPS (port 443), lẫn vào traffic web bình thường | Khó chặn/giám sát hơn DoT vì dùng chung port với HTTPS — cần lưu ý khi viết policy firewall nội bộ |

**Khuyến nghị thực chiến:**
- Domain production (web/mail) → bật **DNSSEC** ở registrar/DNS provider (Cloudflare, Nhân Hòa DNS...).
- Endpoint/client nội bộ → cân nhắc resolver hỗ trợ **DoH/DoT** (Cloudflare 1.1.1.1, Google 8.8.8.8) để chống MITM trên mạng không tin cậy.
- DNSSEC và DoH/DoT là 2 lớp **độc lập, bổ trợ nhau** — không thay thế nhau (một bảo vệ data integrity, một bảo vệ transport).

---

## 6. Các bản ghi DNS — Bảng tra cứu nhanh

### 6.1 Bản ghi cốt lõi (Web & Mail)

| Loại | Tên đầy đủ | Chức năng thực tế |
|---|---|---|
| **A** | Address | Trỏ domain → IPv4. Bản ghi cơ bản nhất, dùng cho web server |
| **AAAA** | IPv6 Address | Trỏ domain → IPv6 |
| **CNAME** | Canonical Name | Alias domain này → domain khác (vd `www` → `example.com`). Không dùng chung được với bản ghi khác trên cùng hostname (vd MX) |
| **NS** | Name Server | Khai báo server thẩm quyền (authoritative) cho zone/domain |
| **SOA** | Start of Authority | Metadata của zone: primary NS, email admin, serial number, refresh/retry/expire/TTL — bắt buộc có 1 bản ghi/zone |
| **PTR** | Pointer (reverse lookup) | Ngược lại với A: IP → domain. Quan trọng cho mail server (reverse DNS check chống spam) |
| **MX** | Mail Exchanger | Chỉ định mail server nhận email cho domain, có priority — domain luôn nên có ≥1 MX backup |
| **SRV** | Service | Khai báo host + **port** cho 1 service cụ thể (vd SIP, VoIP, Minecraft server...) |
| **TXT** | Text | Lưu chuỗi text tùy ý — nền tảng cho xác thực email (xem bảng 6.2) và domain verification |

### 6.2 TXT record cho xác thực email — bộ ba SPF/DKIM/DMARC

| Bản ghi | Mục đích | Đặt ở đâu |
|---|---|---|
| **SPF** | Khai báo IP/server nào **được phép** gửi mail thay mặt domain | TXT tại root domain |
| **DKIM** | Ký số mỗi email gửi đi, mail nhận verify để xác minh không bị sửa nội dung trên đường truyền | TXT tại subdomain selector (vd `default._domainkey`) |
| **DMARC** | Policy: mail fail SPF/DKIM thì xử lý thế nào (reject/quarantine/none) + report về địa chỉ giám sát | TXT tại `_dmarc.domain.com` |

> Thiếu 1 trong 3 → email dễ vào spam hoặc bị giả mạo (spoofing) gửi thay domain.

### 6.3 Các bản ghi khác (ít dùng trong vận hành thường ngày)

| Bản ghi | Công dụng ngắn |
|---|---|
| **CAA** | Chỉ định CA nào được phép cấp SSL cho domain — nên cấu hình để chống cấp chứng chỉ trái phép |
| **DNSKEY / RRSIG / NSEC** | Thành phần của DNSSEC: public key, chữ ký số, chứng minh bản ghi không tồn tại |
| **DNAME** | Giống CNAME nhưng redirect cả cây sub-domain |
| **NAPTR** | Kết hợp SRV, tạo URI động bằng regex (VoIP/SIP) |
| **LOC** | Tọa độ địa lý của domain |
| **SSHFP** | Lưu fingerprint SSH public key, hỗ trợ verify host khi SSH |
| **HINFO, AFSDB, APL, HIP, IPSECKEY, CERT, CDNSKEY, DCHID, RP** | Legacy/niche, gần như không gặp trong vận hành hosting thông thường |

---


## 7. Thực hành với Bind9 (Linux)
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

### Bật tính năng IIS
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

<img width="776" height="347" alt="image" src="https://github.com/user-attachments/assets/301b4e4d-4ab4-4ddc-9935-1d9a58beea3a" />

####  Tạo file aspx cơ bản :
<img width="452" height="262" alt="image" src="https://github.com/user-attachments/assets/514e54aa-5d03-4a33-ba50-115f208bfc3f" />

#### Tạo site trên IIS:
<img width="367" height="290" alt="image" src="https://github.com/user-attachments/assets/25a02794-225d-4e2f-8e6c-d9388acd34a2" />

kết quả thu về

<img width="715" height="172" alt="image" src="https://github.com/user-attachments/assets/3f5a253e-bfc4-4ceb-9e77-3e5fdb30c0c2" />

####  Tạo file php cơ bản :
<img width="275" height="103" alt="image" src="https://github.com/user-attachments/assets/1a1ca7e5-53b3-4333-b835-adc96beebf18" />

#### Cài đặt php, nối PHP với IIS 10
<img width="730" height="330" alt="image" src="https://github.com/user-attachments/assets/57c1dea9-7964-48c1-bc88-19e0cb7ad76b" />

#### Tạo site trên IIS:
<img width="360" height="307" alt="image" src="https://github.com/user-attachments/assets/e0e7100f-19f6-41b1-a355-bf5b15fd94cd" />

Vào default document để add file php, giúp IIS tự đọc file php mà không cần gõ đuôi trên URL
<img width="516" height="188" alt="image" src="https://github.com/user-attachments/assets/1685f250-fe45-47f3-85fb-1a7d0cab5081" />

kết quả thu về:

<img width="699" height="301" alt="image" src="https://github.com/user-attachments/assets/b59730cf-add4-4d4c-ad17-c29569533678" />



