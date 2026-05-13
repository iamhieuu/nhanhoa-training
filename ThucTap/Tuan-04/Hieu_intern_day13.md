# Báo cáo thực tập ngày 13 - Xu hướng hiện đại, công cụ hỗ trợ

## Serverless, Container, Edge computing
### 1. Serverless
Serverless không có nghĩa là "không có server" — vẫn có server nhưng bạn không nhìn thấy, không quản lý, không trả tiền khi không dùng. Đây là sự dịch chuyển từ tư duy "thuê máy chủ" sang "mua kết quả tính toán".  
developer không cần:  

- quản lý máy chủ  
- cài hệ điều hành  
- scale thủ công  
- bảo trì infrastructure  

Toàn bộ được cloud provider xử lý.  
### Mô hình truyền thống (VPS)
Bạn thuê VPS cố định:  

```
$20/tháng

Dù:

traffic = 0
không có request
website không hoạt động
```
vẫn phải trả tiền đầy đủ.  

Mô hình Serverless
Bạn chỉ trả tiền khi function được gọi:
```
$0.0000002 × số lần thực thi
```
Ví dụ:
```
1.000.000 requests ≈ $0.20
```
* Ưu điểm 
  * Không quản lý server
  * Auto scaling
  * Trả tiền theo usage
  * Triển khai nhanh
  * Tối ưu chi phí cho traffic thấp
* Nhược điểm
  * Cold start
  * Khó debug
  * Vendor lock-in
  * Runtime giới hạn
  * Không phù hợp workload chạy lâu
Khi nào dùng Serverless?  
Nên dùng: API ít dùng, chức năng độc lập, xử lý event(upload ảnh, gửi mail, webhook), notification.    
Không nên dùng: App cần kết nối database liên tục, Websocket, xử lý file lớn, latency thấp.  

#### Các nền tảng Serverless phổ biến

Nền tảng | Ngôn ngữ hỗ trợ
:---|:---
AWS Lambda |	Node.js, Python, Java, Go
Google Cloud Functions |	Node.js, Python, Go
Azure Functions	| Hầu hết ngôn ngữ phổ biến
Cloudflare Workers	| JavaScript / TypeScript

#### Các khái niệm quan trọng
* FaaS:Đơn vị triển khai là một function độc lập , không phải một ứng dụng. Mỗi function làm đúng một việc, không chia sẻ trạng thái với function khác.
  * VD: login(),send_email(),resize_image()
* Event-driven:Function không ngồi chờ như server truyền thống. Nó ngủ cho đến khi có event kích hoạt — HTTP request, file upload, message queue, cron job — rồi thức dậy, chạy, và ngủ lại.  
* Cold start: Khi function chưa được gọi trong một thời gian, cloud provider sẽ giải phóng tài nguyên. Lần gọi tiếp theo phải khởi động lại container (~100-500ms). Với ứng dụng cần latency thấp, đây là vấn đề nghiêm trọng.


### 2. Container hóa với Docker
Container giải quyết bài toán "chạy được trên máy tôi nhưng không chạy trên server" bằng cách đóng gói toàn bộ môi trường chạy vào một gói duy nhất — không chỉ code, mà cả thư viện, runtime, biến môi trường, và cấu hình hệ thống.
```
Docker Image
      │
      ▼
Docker Container
      │
      ▼
Application Running
```
Image là "khuôn đúc" — bất biến, có thể share, lưu trên Docker Hub, dùng để tạo container.
Container là "sản phẩm đúc ra" — đang chạy, có thể sửa, xóa đi tạo lại được. Một image có thể tạo ra hàng chục container giống hệt nhau.

Layer caching là lý do tại sao Docker nhanh: Mỗi lệnh trong Dockerfile tạo ra một layer. Khi build lại, Docker chỉ rebuild từ layer bị thay đổi trở xuống. Vì vậy phải **đặt lệnh ít thay đổi lên đầu** (cài OS, cài Nginx), lệnh hay thay đổi xuống cuối (copy code).

Mỗi lệnh trong Dockerfile:  
```
RUN
COPY
ADD
```
đều tạo ra một layer mới.  
Dockerfile tối ưu
```
FROM ubuntu:22.04
RUN apt install nginx php
COPY config/ /etc/nginx/
COPY app/ /var/www/html/
```
Namespace và Cgroup — bí mật bên trong container: Container không phải ảo hóa phần cứng. Đây là tính năng của Linux kernel:  
  * Namespace: cô lập process, network, filesystem — container tưởng mình là một máy riêng
  * Cgroup: giới hạn tài nguyên — container chỉ dùng được X MB RAM, Y% CPU
* ƯU điểm
  * Chạy giống nhau mọi môi trường
  * Triển khai nhanh
  * Scale dễ
  * Dễ rollback
  * Isolation tốt
* Nhược điểm
  * Tốn RAM hơn process thường
  * Debug networking khó
  * Quản lý nhiều container phức tạp
  * Cần orchestration khi scale lớn

Kubernetes (K8s) là một nền tảng mã nguồn mở dùng để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng dưới dạng Container.  
* Tự phục hồi (Self-healing): Nếu một Container bị lỗi, K8s tự động khởi động lại nó. Nếu một Node chết, K8s di chuyển các Pod sang Node khác đang sống.  
* Tự động mở rộng (Auto-scaling): Khi website của bạn bị "quá tải", K8s có thể tự động tăng số lượng Pod lên để gánh tải và giảm xuống khi hết khách để tiết kiệm tiền.  
* Cập nhật không gián đoạn (Rolling updates): Bạn có thể cập nhật phiên bản phần mềm mới mà người dùng không hề hay biết (zero downtime).


### 3.Edge Computing
Edge Computing đưa khả năng tính toán ra gần người dùng nhất có thể thay vì gửi mọi thứ về data center trung tâm. Đây là sự tiến hóa của CDN: từ chỉ cache file tĩnh, sang thực thi code ngay tại điểm truy cập.  

#### Sự khác biệt cốt lõi giữa CDN và Edge:  
* CDN truyền thống chỉ cache — nó lấy file từ origin server một lần, lưu lại, rồi phục vụ bản copy đó cho người dùng gần đó. Nếu người dùng hỏi một câu cần tính toán (đăng nhập, lấy data cá nhân), request vẫn phải về tận origin server.
* Edge Computing thực thi code ngay tại PoP(Point of Presence) — không chỉ phục vụ file có sẵn mà còn chạy logic. Cloudflare Workers, Deno Deploy, Vercel Edge Functions cho phép viết JavaScript chạy tại 300+ địa điểm trên thế giới. Latency đo bằng đơn vị single-digit milliseconds.

#### Kiến trúc Edge
```
User
 │
 ▼
Edge Node gần nhất
 │
 ├── Cache static file
 ├── Execute logic
 └── Chỉ forward khi cần
 ```

#### Các nền tảng Edge phổ biến

Nền tảng	| Đặc điểm
:---| :---
Cloudflare Workers	| Không cold start
Vercel Edge Functions	| Tối ưu frontend
Deno Deploy	| Runtime hiện đại
Fastly Compute@Edge	| Hiệu năng cao


V8 Isolate: Vũ khí của Cloudflare worker
Server truyền thống dùng Container  
Edge hiện đại dùng V8 Isolate:  
  * Nhẹ hơn container
  * Không cần boot OS
  * Khởi động gần như tức thì  

→ gần như không có cold start.

* Ưu điểm của Edge
  * Latency cực thấp
  * Gần user
  * Scale toàn cầu
  * Giảm tải origin server
  * Chống DDoS tốt
* Nhược điểm
  * Runtime hạn chế
  * Không phù hợp xử lý nặng
  * Debug khó
  * Không có full OS access

* Use Case phù hợp
  * CDN thông minh
  * authentication
  * redirect
  * bot protection
  * cache API
  * personalization

---
So sánh 3 xu hướng  

| Tiêu chí | Serverless | Docker / Container | Edge Computing |
|---|---|---|---|
| Quản lý server | Không cần quản lý | Có quản lý server/container | Không cần quản lý |
| Đơn vị triển khai | Function đơn lẻ | Application + dependencies | JS Worker / WASM |
| Scaling | Auto scaling | Tự quản lý hoặc Kubernetes | Auto scaling toàn cầu |
| Khởi động | 100–500ms (cold start) | < 1s (`docker run`) | ~0ms (V8 Isolate) |
| Cold start | Có | Không | Gần như không |
| Latency | Trung bình | Trung bình | Rất thấp |
| Độ linh hoạt | Trung bình | Rất cao | Hạn chế |
| Runtime | Giới hạn | Full OS | Runtime giới hạn |
| Chi phí | Trả theo số lần gọi | Trả theo server đang chạy | Trả theo request |
| State | Stateless bắt buộc | Có thể stateful | Stateless bắt buộc |
| Use case chính | Function nhỏ | Backend hệ thống lớn | Xử lý gần user |
| Phù hợp nhất | Event, webhook, cron | Mọi loại ứng dụng | CDN logic, auth, routing |
| Ví dụ công nghệ | AWS Lambda, Cloud Functions | Docker, Kubernetes | Cloudflare Workers, Vercel Edge |
| Khả năng tùy biến hệ thống | Thấp | Rất cao | Trung bình |
| Truy cập hệ điều hành | Không | Toàn quyền | Không |
| Tốc độ triển khai | Rất nhanh | Trung bình | Rất nhanh |
| Phạm vi triển khai | Theo region cloud | Theo cluster/server | Theo PoP toàn cầu |
| Khả năng xử lý nặng | Hạn chế | Rất tốt | Không phù hợp |
| Networking | Managed | Full control | Hạn chế |
| Phù hợp realtime | Trung bình | Tốt | Rất tốt |
| Bảo trì infrastructure | Cloud provider lo | DevOps tự quản lý | Cloud provider lo |

#### Ví dụ 3 mô hình xu hướng với LAMP Stack:  
Hệ thống LAMP. Docker containerize toàn bộ stack Nginx + Apache + MySQL + Redis của bạn vào các image. Serverless tách các chức năng (API login, gửi email, xử lý ảnh) ra khỏi Apache và cho cloud tự quản lý. Edge là tầng trước Nginx — Cloudflare đứng trước server của bạn, xử lý những gì có thể xử lý được mà không cần request chạm tới server.
Thực tế doanh nghiệp Việt Nam hiện tại: phần lớn dùng Container (Docker + Kubernetes) cho backend, Serverless cho các tác vụ phụ (gửi email, notification, xử lý hình ảnh), và Cloudflare Edge cho bảo vệ DDoS + cache. Hiếm khi dùng một mình, ba thứ thường kết hợp với nhau.  

---

## Tối ưu Database với LEMP
Trong kiến trúc LEMP, Nginx và PHP-FPM xử lý request rất nhanh. Nhưng mỗi request thường cần truy vấn database ít nhất vài lần. MySQL phải đọc từ disk (I/O chậm), thực hiện join giữa hàng triệu dòng, và phục vụ hàng trăm kết nối đồng thời. Thắt cổ chai thường ở đây, không phải ở Nginx hay PHP.  

* Bước 1 — Tìm query chậm (Slow Query Log)
Nguyên tắc tối ưu: Đo trước, tối ưu sau. Không đoán mò. Slow Query Log ghi lại tất cả query chạy chậm hơn ngưỡng bạn đặt — đây là danh sách "tội phạm" cần xử lý.
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
[mysqld]
# Bật slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log

# Query chậm hơn 1 giây sẽ được ghi vào log
long_query_time = 1

# Ghi cả query không dùng index (dù chạy nhanh)
# Rất hữu ích — query không có index sẽ quét toàn bộ bảng
log_queries_not_using_indexes = 1
sudo systemctl restart mysql

# Xem slow query log
sudo tail -50 /var/log/mysql/slow.log

# Phân tích và tổng hợp slow log 
sudo mysqldumpslow -s t -t 10 /var/log/mysql/slow.log
# -s t: sắp xếp theo thời gian, -t 10: top 10
```

* Bước 2 — Phân tích query với EXPLAIN
EXPLAIN là lệnh MySQL cho biết query của bạn được thực thi như thế nào — có dùng index không, quét bao nhiêu dòng, join theo kiểu gì. Đây là công cụ thiết yếu để hiểu tại sao query chậm.
```
# Kết nối MySQL
sudo mysql -u root -p

# Giả sử có query chậm tìm thấy trong slow log
mysql> EXPLAIN SELECT * FROM orders 
       WHERE user_id = 123 AND status = 'pending'
       ORDER BY created_at DESC;
```

* Bước 3 — Thêm Index đúng chỗ
Index là gì? Giống mục lục sách — thay vì đọc toàn bộ sách để tìm một chủ đề, bạn tra mục lục và đến thẳng trang cần. Index MySQL tạo cấu trúc dữ liệu B-Tree giúp tìm kiếm O(log n) thay vì O(n). Nhưng: index làm chậm INSERT/UPDATE vì phải cập nhật thêm cấu trúc index. Chỉ thêm index vào cột thực sự cần tìm kiếm/join/sort.
```
# Xem index hiện có của bảng
mysql> SHOW INDEX FROM orders;

# Thêm index đơn lẻ (single column)
mysql> CREATE INDEX idx_user_id ON orders(user_id);

# Composite index — TỐT HƠN khi thường query theo nhiều điều kiện cùng lúc
# Thứ tự cột quan trọng: điều kiện = trước, range/order sau
mysql> CREATE INDEX idx_user_status ON orders(user_id, status, created_at);

# Kiểm tra query sau khi thêm index
mysql> EXPLAIN SELECT * FROM orders
       WHERE user_id = 123 AND status = 'pending'
       ORDER BY created_at DESC;
# Giờ "key" phải hiển thị "idx_user_status", rows giảm mạnh
```

* Bước 4 — Tối ưu cấu hình MySQL (InnoDB Buffer Pool)
InnoDB Buffer Pool là vùng RAM MySQL dùng để cache data và index từ disk. Càng nhiều data fit vào RAM, càng ít phải đọc disk (chậm hơn RAM 100-1000 lần). Đây là tham số quan trọng nhất để tối ưu hiệu suất MySQL
```
# Kiểm tra buffer pool hiện tại
mysql> SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
# Mặc định thường là 128MB — quá nhỏ!

# Xem tỷ lệ cache hit (cache_hit_ratio)
mysql> SHOW STATUS LIKE 'Innodb_buffer_pool_read%';
# Tỷ lệ = Innodb_buffer_pool_read_requests / (read_requests + reads)
# Nên > 99%. Nếu < 99% → buffer pool cần tăng
# Tối ưu /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
# Buffer pool: đặt 70-80% RAM của server
innodb_buffer_pool_size = 1G    # Server 2GB RAM

# Nên bằng số CPU core, max = innodb_buffer_pool_size / 1GB
innodb_buffer_pool_instances = 2

# Flush log mỗi lần commit (1=an toàn nhất, 2=nhanh hơn)
innodb_flush_log_at_trx_commit = 1

# Kích thước log file InnoDB (tăng giảm ghi disk)
innodb_log_file_size = 256M

```

Bước 5 — Redis Cache (giảm tải MySQL)
Redis là in-memory data store — lưu dữ liệu trong RAM, đọc/ghi nhanh hơn MySQL 10-100 lần. Thay vì mỗi request PHP query MySQL, kết quả được cache trong Redis. Request sau lấy từ Redis ngay lập tức, không cần đến MySQL.  
```
# Cài Redis
sudo apt install redis-server php8.1-redis -y
sudo systemctl enable --now redis-server

# Kiểm tra Redis hoạt động
redis-cli ping  # Phải trả về: PONG
# PHP — Cache kết quả query vào Redis
// Trong .env của Laravel
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

// Trong code PHP — cache query result 10 phút
$users = Cache::remember('active_users', 600, function() {
    return DB::table('users')
        ->where('active', 1)
        ->get();
});
# Cấu hình Redis tối ưu /etc/redis/redis.conf
# Giới hạn RAM Redis dùng 
maxmemory 256mb


```

---
# Công cụ hỗ trợ quản lý web server, bảo mật, kiểm tra hiệu suất
**Control Panel:** Control Panel là hệ thống quản trị web server thông qua giao diện đồ họa (Web UI), giúp quản trị viên thao tác mà không cần nhớ hàng trăm lệnh Linux.

Thay vì cấu hình thủ công bằng terminal, người dùng có thể:

- tạo website
- quản lý domain
- quản lý email
- tạo database
- cài SSL
- quản lý DNS
- backup dữ liệu
- quản lý FTP

chỉ bằng vài cú click chuột.

Control Panel đặc biệt phù hợp với:

- quản trị viên không chuyên Linux
- hosting provider
- agency quản lý nhiều website
- người dùng VPS cá nhân

---
### Các Control Panel thương mại phổ biến
####  1. cPanel / WHM
cPanel là control panel phổ biến nhất trong ngành shared hosting.

Hệ thống gồm:

- **WHM (Web Host Manager)**  
  Dành cho admin quản lý toàn bộ server

- **cPanel**  
  Dành cho từng khách hàng quản lý hosting riêng  
* Đặc điểm
 * Hỗ trợ Apache + Nginx
 * Multi PHP version
 * Tích hợp Exim mail server
 * Hỗ trợ MySQL/MariaDB
 * Hệ sinh thái plugin rất lớn
 * Chuẩn công nghiệp trong shared hosting
* Hạn chế
  * cPanel không hỗ trợ chính thức Ubuntu.
 

#### DirectAdmin (DA)
DirectAdmin là control panel nhẹ, nhanh và tiêu thụ ít RAM hơn cPanel. Phù hợp cho:
 * VPS nhỏ
 * server tài nguyên thấp
 * người muốn tiết kiệm chi phí
Đặc điểm chính
 * Hỗ trợ Ubuntu 22.04
 * Cấu trúc 3 tầng:
 * Admin
 * Reseller
 * User
* Sử dụng CustomBuild 2.0 để cài:
 * Apache/Nginx
 * PHP
 * Database
* Ưu điểm
 * Nhẹ hơn cPanel nhiều
 * Giá rẻ
 * Dễ tối ưu VPS nhỏ
 * Tiêu thụ ít RAM

#### Plesk
Plesk là control panel đa nền tảng: Linux,Windows
* Đặc điểm chính
 * Hỗ trợ Ubuntu 22.04 đầy đủ
 * Tích hợp Docker
 * Tích hợp Git
 * WordPress Toolkit mạnh
 * Let's Encrypt tự động
 * Giao diện hiện đại

| Tiêu chí           | cPanel / WHM       | DirectAdmin   | Plesk        |
| ------------------ | ------------------ | ------------- | ------------ |
| Ubuntu 22.04       |  Không hỗ trợ     |  Hỗ trợ      |  Hỗ trợ     |
| Giá khởi điểm      | ~$15/tháng         | ~$2/tháng     | ~$14/tháng   |
| RAM tiêu thụ       | Cao (~1GB+)        | Thấp (~200MB) | Trung bình   |
| Phổ biến ở         | Mỹ, shared hosting | VPS nhỏ       | Châu Âu      |
| Dễ sử dụng         | Dễ, có GUI             | Hơi khó        | Dễ       |
| Đối tượng phù hợp  | Hosting company    | VPS cá nhân   | Agency / SMB |
| Multi-user         | Có                 | Có            | Có           |
| Docker integration | Hạn chế            | Hạn chế       | Tốt          |
| WordPress tools    | Trung bình         | Cơ bản        | Rất mạnh     |

#### Cài Plesk trên Ubuntu 22.04
```
wget https://autoinstall.plesk.com/plesk-installer -O plesk-installer
chmod +x plesk-installer
sudo ./plesk-installer install release
# https://192.168.136.131:8443
# Lấy mật khẩu admin lần đầu:
sudo plesk login
```
<img width="457" height="463" alt="{95BDA036-C8D2-4B70-83A4-89FAF54D127A}" src="https://github.com/user-attachments/assets/0a775ab8-f6ca-44d7-a300-c144b27dcfab" />

Cài DirectAdmin trên Ubuntu 22.04
```
# Bước 1: Lấy license key tại directadmin.com (có bản trial)
# Bước 2: Chạy script cài đặt
wget -O setup.sh https://www.directadmin.com/setup.sh
chmod +x setup.sh
sudo bash setup.sh auto

# Panel chạy tại: http://192.168.136.131:2222
```
## Panel miễn phí cho Linux Server
# 1. HestiaCP
HestiaCP là fork của VestaCP và hiện là một trong những panel miễn phí phát triển tích cực nhất.

Đây là lựa chọn được khuyên dùng nhiều nhất trong nhóm free panel cho Ubuntu 22.04.

---

* Đặc điểm chính
 - Giao diện hiện đại, sạch sẽ
 - Hỗ trợ Nginx + Apache
 - PHP-FPM
 - Multi PHP version
 - Let's Encrypt tự động
 - DNS server
 - Mail server
 - FTP server
 - Webmail (Roundcube)

---
* Ưu điểm
 - Cài đặt đơn giản
 - Hoạt động ổn định trên Ubuntu 22.04
 - Nhẹ và tối ưu
 - Tài liệu cộng đồng tốt

2. aaPanel (BT Panel)
aaPanel là bản quốc tế của Baota Panel (BT Panel) từ Trung Quốc.

* Đặc điểm chính
 * Cài cực nhanh
 * Plugin phong phú
 * One-click app installer
 * File Manager mạnh
 * Hỗ trợ:
  * Redis
  * MongoDB
  * Docker
  * Firewall
  * WordPress manager

 Một số quản trị viên lo ngại: Privacy và telemetry do nguồn gốc Trung Quốc

 3. Webmin + Virtualmin
Webmin là panel quản trị Linux lâu đời nhất.
Virtualmin là module mở rộng giúp quản lý web hosting.
Đặc điểm chính
Khác với các panel khác, Webmin không chỉ quản lý hosting mà còn quản lý gần như toàn bộ hệ điều hành(users/groups,network,services,package manager)
* Ưu điểm
 * Cực kỳ linh hoạt
 * Control sâu hệ thống
 * Phù hợp sysadmin chuyên Linux
* Hạn chế
 * Giao diện cũ
 * Khó dùng hơn HestiaCP
 * Không thân thiện với người mới


4. CyberPanel
CyberPanel là panel duy nhất phổ biến sử dụng: OpenLiteSpeed

Đặc điểm chính
* Tối ưu hiệu năng WordPress
* Tích hợp LSCache
* Hỗ trợ OpenLiteSpeed
* Cài đặt nhanh
* Hỗ trợ Ubuntu 22.04
Ưu điểm
* Theo benchmark của nhà phát triển: OpenLiteSpeed nhanh hơn Nginx ~3–5x với PHP


| Tiêu chí          | HestiaCP       | aaPanel      | Webmin + Virtualmin | CyberPanel        |
| ----------------- | -------------- | ------------ | ------------------- | ----------------- |
| RAM tiêu thụ      | Thấp           | Trung bình   | Thấp                | Trung bình        |
| Docker support    | Hạn chế        | Plugin       | Thủ công            | Hạn chế           |
| Mail server       | có  hỗ trợ     | Plugin       | có hỗ trợ           | Có                |
| DNS server        | có hỗ trợ      | Có           | có hỗ trợ           | Có                |
| Web server chính  | Nginx + Apache | Nginx/Apache | Apache/Nginx        | OpenLiteSpeed     |
| WordPress tối ưu  | Tốt            | Tốt          | Trung bình          | Rất mạnh          |
| Đối tượng phù hợp | VPS cá nhân    | Người mới    | Sysadmin            | WordPress hosting |

Cài HestiaCP trên Ubuntu 22.04 
````
# Tải script cài đặt chính thức
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
Panel tại: https://192.168.136.131:8083
````
<img width="731" height="376" alt="{623A7B65-769A-4CA0-A1AF-387B42314766}" src="https://github.com/user-attachments/assets/6f901dff-b462-4903-9bbb-38a3b0872d6e" />
<img width="470" height="464" alt="{8D9907E4-537B-4F42-90E4-89E3A2B3F654}" src="https://github.com/user-attachments/assets/2abd14e9-9441-4416-b380-f6795f4ab0c1" />
<img width="475" height="469" alt="{D90047AB-1405-47C1-B3B9-4C76B782BE3D}" src="https://github.com/user-attachments/assets/c5e804d6-074c-4044-9f48-e0dbc923c7bf" />


Cài aaPanel trên Ubuntu 22.04

```
 Script cài nhanh
wget -O install.sh https://www.aapanel.com/script/install_6.0_en.sh
sudo bash install.sh aapanel

# Panel tại: http://192.168.136.131:8888
# User/Pass hiển thị sau khi cài xong
```
<img width="470" height="460" alt="{1FEE615D-D80C-4C77-9D0B-9DB35A00C588}" src="https://github.com/user-attachments/assets/3c28a98d-dcc9-48cd-bbaf-9652fcda8ba2" />

----
### ApacheBench, Jmeter: đã làm ở bài trước
----
### Siege
Công cụ stress test HTTP/HTTPS nhẹ hơn JMeter nhưng mạnh hơn ab. Điểm khác biệt lớn nhất: Siege có thể test nhiều URL cùng lúc từ một file danh sách — mô phỏng gần với traffic thực tế hơn (người dùng không chỉ vào một trang). Còn có thể thêm delay ngẫu nhiên giữa request để giả lập hành vi người dùng thực.   

```
# Cài trực tiếp từ apt
sudo apt install siege -y
siege --version   
```
<img width="408" height="121" alt="{3CD774B4-F571-4EE2-9301-ACC046E7C71D}" src="https://github.com/user-attachments/assets/7addca2f-11a5-49ef-b795-c8cbcdcad763" />

```
# Test cơ bản: 50 users đồng thời trong 1 phút
siege -c 50 -t 1M http://192.168.136.131/
# -c: concurrent users  -t: thời gian (S=giây, M=phút, H=giờ)
```

```
# Giới hạn số request thay vì thời gian
siege -c 30 -r 20 http://192.168.136.131/
# -r: repetitions — mỗi user gửi 20 request → tổng 600 request
```
<img width="429" height="203" alt="{27BD65BD-B78A-4DB5-A077-36F9BA3F0DDF}" src="https://github.com/user-attachments/assets/13e08303-60c5-4411-a401-2e2a1845bfad" />

```
# Thêm delay ngẫu nhiên giữa request (giả lập user thật)
siege -c 25 -t 2M -d 2 http://192.168.136.131/
# -d 2: delay ngẫu nhiên 0-2 giây giữa mỗi request
```

```
# Test nhiều URL từ file (MẠNH NHẤT của Siege)
cat > /tmp/urls.txt << 'URLS'
http://192.168.136.131/
http://192.168.136.131/about
http://192.168.136.131/products
http://192.168.136.131/contact
http://192.168.136.131/api/users
URLS
```

```
siege -c 40 -t 2M -f /tmp/urls.txt
# Siege random chọn URL từ file — giả lập traffic thực tế
```
<img width="359" height="181" alt="{05086D26-0432-4E81-BAC8-D2B797CAE870}" src="https://github.com/user-attachments/assets/9b033224-cc16-4b86-a486-e7a8461c9a2a" />

```
# Internet mode: random delay, giống người dùng thật nhất
siege -c 50 -t 5M --internet -f /tmp/urls.txt
```
<img width="414" height="186" alt="{F3593944-DE20-4606-97B4-483E6D048F38}" src="https://github.com/user-attachments/assets/b28e4599-91ed-4a26-b0b7-a65d30af5844" />

Đọc kết quả siege
```

Transactions:           4823 hits       ← Tổng request thành công
Availability:          99.98 %          ← Tỷ lệ thành công (phải gần 100%)
Elapsed time:          59.94 secs       ← Thời gian chạy
Data transferred:       18.34 MB
Response time:          0.31 secs       ← Thời gian phản hồi trung bình
Transaction rate:       80.47 trans/sec ← Request/giây (như RPS của ab)
Throughput:             0.31 MB/sec     ← Băng thông
Concurrency:           24.95           ← Số kết nối đồng thời trung bình
Successful transactions: 4822
Failed transactions:       1           ← Phải = 0 hoặc rất nhỏ
Longest transaction:   3.45 secs       ← Request chậm nhất
Shortest transaction:  0.04 secs
```
Cấu hình siege.conf
````
# Tạo file cấu hình mặc định
siege.config   # Tạo ~/.siege/siege.conf

# Chỉnh ~/.siege/siege.conf
verbose = false         # Tắt print từng request (nhanh hơn)
quiet = true            # Chỉ in summary cuối
json_output = true      # Output JSON (dễ parse)
show-logfile = false

````
----

### Nmap
Nmap (Network Mapper) là gì? Công cụ quét mạng và kiểm tra bảo mật mạnh nhất, được dùng bởi cả sysadmin lẫn hacker. Nmap gửi các gói tin đặc biệt đến target và phân tích phản hồi để phát hiện: port nào đang mở, service nào đang chạy, phiên bản của service, hệ điều hành target, và các lỗ hổng đã biết (qua scripts NSE). Luôn chỉ quét server của chính mình!  
**Cảnh báo pháp lý:** Quét mạng/server mà không có sự cho phép là bất hợp pháp ở nhiều quốc gia, kể cả Việt Nam. Chỉ dùng Nmap trên server/mạng bạn sở hữu hoặc có quyền kiểm tra. 
```

# Cài Nmap
sudo apt install nmap -y
nmap --version
```
<img width="812" height="92" alt="{6AB994A9-80A1-489D-9A32-76708FEE70CE}" src="https://github.com/user-attachments/assets/d55e4e03-5caf-487c-9ce5-0e4888225a5a" />


````
# Scan top 1000 port phổ biến nhất (default)
nmap 192.168.136.131
````
<img width="437" height="297" alt="{4BB5644E-49DE-4C5B-8CE0-2057B63AC09F}" src="https://github.com/user-attachments/assets/82a577f5-484f-44c8-b92a-7e089e248657" />
````
# Scan tất cả 65535 port — toàn diện nhưng chậm hơn
nmap -p- 192.168.136.131
````
<img width="437" height="287" alt="{AF2B4368-3A67-4BD5-9D98-AA9291C02288}" src="https://github.com/user-attachments/assets/d4680551-8f3b-42dc-8b9d-c5babd1bde4d" />

````
# Scan port cụ thể
nmap -p 22,80,443,3306,6379 192.168.136.131
````
<img width="448" height="187" alt="{B390F2A5-E529-4066-9FD8-A355351F19E0}" src="https://github.com/user-attachments/assets/bbb36422-b171-42e6-85a5-6838e0929cea" />
````
nmap -sV 192.168.136.131
# Output: 80/tcp open http nginx 1.18.0 (Ubuntu)
#         3306/tcp open mysql MySQL 8.0.34

# -O: detect hệ điều hành (cần root)
````

<img width="424" height="198" alt="{6269542C-82BE-42B5-9D2B-087EF947B8C6}" src="https://github.com/user-attachments/assets/ca9e478d-5612-4f76-b441-4e782160da2e" />

````
sudo nmap -O 192.168.136.131
````
<img width="556" height="369" alt="{2D274989-6BDD-4962-9BE3-3C8A8D56AC45}" src="https://github.com/user-attachments/assets/356ed3ae-726a-4dc4-aca3-b77feef4505a" />
````
# -A: aggressive — OS + version + script + traceroute
sudo nmap -A 192.168.136.131
````

````
# -sC: chạy default NSE scripts (kiểm tra lỗ hổng cơ bản)
sudo nmap -sC -sV 192.168.136.131
````
````
# ── NSE Scripts — kiểm tra lỗ hổng cụ thể ──────────────────
# Kiểm tra web server có lỗ hổng HTTP không
nmap --script http-vuln* -p 80,443 192.168.136.131
````
<img width="456" height="147" alt="{301E0C1A-FD2F-4123-85B2-F7F9F2E6740A}" src="https://github.com/user-attachments/assets/3ac44df8-8c18-475a-8a47-2a608dc3a16c" />
````
# Kiểm tra MySQL có cho phép anonymous login không
nmap --script mysql-empty-password -p 3306 192.168.136.131
````
<img width="441" height="113" alt="{983EEF2D-5E53-448D-ABD3-0E4F206DF42A}" src="https://github.com/user-attachments/assets/8d9e8c3d-4da8-4fe6-8760-6f4335a97a54" />
````
# Kiểm tra SSL/TLS (ciphers yếu, Heartbleed...)
nmap --script ssl-enum-ciphers -p 443 192.168.136.131
nmap --script ssl-heartbleed -p 443 192.168.136.131
````
<img width="519" height="342" alt="{24958007-2E45-4F24-A601-F60FA78E5F2C}" src="https://github.com/user-attachments/assets/1ef6f323-f5c9-4913-85dd-23fc6324b5ef" />
````
# Kiểm tra SSH brute force protection
nmap --script ssh-brute -p 22 192.168.136.131
````
<img width="471" height="143" alt="{54123D80-B231-462D-899F-DD9D50A40C32}" src="https://github.com/user-attachments/assets/57c3ac75-6d50-4315-831f-c8c43b0055da" />

----
### OpenVAS
OpenVAS là gì? Công cụ quét lỗ hổng bảo mật toàn diện, mã nguồn mở. Khác với Nmap chỉ tìm port và service, OpenVAS có cơ sở dữ liệu hơn 100.000 lỗ hổng đã biết và kiểm tra xem server có mắc lỗ hổng nào không. Cho ra báo cáo chi tiết với mức độ nghiêm trọng (Critical/High/Medium/Low) và hướng dẫn vá lỗi.  
Dungf OpenVAS trước khi đưa server vào production, sau mỗi lần cập nhật lớn, hoặc theo định kỳ hàng tháng để phát hiện lỗ hổng mới. Thường dùng kết hợp với Nmap: Nmap tìm port mở → OpenVAS kiểm tra lỗ hổng sâu hơn.  
 OpenVAS cần tối thiểu 4GB RAM và 20GB disk
````
sudo apt install docker.io docker-compose -y
sudo systemctl enable --now docker

# Tải docker-compose.yml của Greenbone
mkdir greenbone && cd greenbone
wget https://greenbone.github.io/docs/latest/_static/docker-compose.yml

# Chạy (lần đầu tải ~2GB image)
sudo docker-compose up -d

# Truy cập web UI: http://192.168.136.131:9392
# Default: admin / admin (đổi ngay!)

````

---

### ModSecurity
ModSecurity là gì? Web Application Firewall (WAF) mã nguồn mở, chạy trực tiếp trong Nginx/Apache. Phân tích từng HTTP request trước khi nó đến PHP/ứng dụng — phát hiện và chặn các tấn công: SQL Injection, XSS, Path Traversal, Remote File Inclusion, và hàng nghìn loại tấn công khác theo bộ quy tắc OWASP CRS. Lớp bảo vệ thứ 2 — dù code PHP có lỗ hổng, ModSecurity vẫn có thể chặn trước khi exploit xảy ra.
Mỗi lần ai đó truy cập website, trình duyệt gửi một HTTP request lên server. Request đó chứa URL, các tham số, cookie, header... ModSecurity đọc toàn bộ nội dung đó và so sánh với danh sách hàng chục nghìn pattern tấn công đã biết. Nếu khớp → chặn ngay, không cho request đến PHP.
