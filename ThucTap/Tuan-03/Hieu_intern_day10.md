# Báo cáo thực tập ngày 10 - Chuyên sâu Webserver 
## I.Khái niệm
### 1. Định nghĩa web server 
Web server là một hệ thống máy tính có nhiệm vụ xử lý các yêu cầu từ người dùng thông qua trình duyệt web và gửi lại nội dung trang web cho họ  
Cụ thể hơn thì Web sẽ lắng nghe các yêu cầu kết nối từ máy khách sau đó xử lý yêu cầu đó theo giao thức HTTP/HTTPS và trả về nội dung phù hợp  
Web server có phần cứng và phần mềm, phần cứng chứa phần mềm ở bên trong  

|Web server phần cứng|Web server phần mềm|
|:---|:---|
|Là một máy tính vật lý (Server) có dung lượng lưu trữ lớn, RAM mạnh và kết nối Internet tốc độ cao để hoạt động 24/7| : Là các chương trình chạy trên máy tính đó để hiểu và phản hồi các yêu cầu từ người dùng trên OS|
|Ví dụ: Dell PowerEdge, HP ProLiant|Ví dụ: Nginx, Apache, IIS, LiteSpeed|

### 2.Vai trò của Web Server trong mô hình client-server
Tầng Khách hàng (Clients): Browser, App, API gửi yêu cầu qua giao thức HTTP/HTTPS.  
Load Balancer: Nginx hoặc HAProxy tiếp nhận và phân phối lưu lượng để tránh quá tải.  
Tầng Web Server: xử lý yêu cầu giao diện người dùng.  
Tầng Hậu trường (Backend):  
  * App Server: Xử lý logic nghiệp vụ
  * Database: Lưu trữ dữ liệu lâu dài.
  * Cache: Tăng tốc độ truy xuất bằng bộ nhớ tạm.
**Máy chủ web đóng vai trò:**  
Tiếp nhận yêu cầu
Giao tiếp với Backend
Máy chủ tệp tĩnh — HTML, CSS, JS, ảnh phục vụ  
Bảo mật và kiểm soát 
Load Balancer — phân phối tải giữa nhiều máy chủ

### 3.Cách thức hoạt động  
**Bước 1: DNS Resolution**
Đây là bước check dns để tìm địa chỉ IP của máy chủ.  
Người dùng gõ: https://iamhieu.com  
Browser hỏi DNS Server: "www.iamhieu.com là IP nào?"  
DNS Server trả lời: 192.168.136.131  
Kết quả: Browser kết nối đến IP 192.168.136.131 qua port 443 (HTTPS).  

**Bước 2: TCP Handshake (Bắt tay 3 bước)**  
Thiết lập kết nối tin cậy giữa máy khách (Client) và máy chủ (Server).  
Client ──── SYN ────────────────► Server  
Client ◄─── SYN-ACK ───────────── Server  
Client ──── ACK ────────────────► Server  
Kết quả: Kết nối TCP được thiết lập thành công.  

**Bước 3: TLS Handshake (Mã hóa HTTPS)**  
Nếu website sử dụng HTTPS, bước này đảm bảo dữ liệu truyền đi không bị đánh cắp.  
Client Hello: Client gửi các phương thức mã hóa hỗ trợ.  
Server Hello + Certificate: Server gửi chứng chỉ số để xác thực danh tính.  
Key Exchange: Hai bên trao đổi khóa để thiết lập kênh truyền tin mã hóa.  

**Bước 4: HTTP Request**  

**Bước 5: Web Server Xử Lý**  
Server nhận request:  
  1. Phân tích HTTP request  
  2. Kiểm tra quyền truy cập, bảo mật  
  3. Tìm file tương ứng hoặc route đến app  
  4. Nếu static file → đọc từ disk  
  5. Nếu dynamic → gọi PHP/Python/Node.js  
  6. Tạo HTTP response  

**Bước 6: HTTP Response**  

**Bước 7: Render**  
Browser nhận response → Render HTML → Tải CSS/JS/ảnh  

Hai Loại Nội Dung Web Server Phục vụ:  Static content và Dynamic Content    

|STATIC CONTENT|DYNAMIC CONTENT|
|:---|:---|
|HTML, CSS, Ảnh, Video, PDF, ZIP files|Trang web, kết quả của database, API responses|
|Nhanh, ít tốn tài nguyên   |Chậm, cần nhiều tài nguyên|
|Web Server đọc thẳng từ disk và gửi đi|Web Server gọi App Server -> App tính toán, lấy dữ liệu từ DB → trả về HTML/JSON|

**Các mã response quan trọng**

|Mã lỗi|Lý do|
|:---|:---|
 **4xx** |   LỖI TỪ PHÍA CLIENT                                     
 400  | Bad Request — Request không hợp lệ                     
 401  | Unauthorized — Cần đăng nhập                           
 403  | Forbidden — Không có quyền truy cập                    
 404  | Not Found — Không tìm thấy trang                       
 405  | HTTP method không được phép        
 408  | Request Timeout — Client quá chậm 
 413  | Payload Too Large — File upload quá lớn
 429  | Too Many Requests — Bị rate limit
 **5xx**  | LỖI TỪ PHÍA SERVER                                     
 500  | Internal Server Error — Lỗi code/config của server     
 502  | Bad Gateway — Backend không phản hồi         
 503  | Service Unavailable — Server quá tải hoặc maintenance  
 504  | Gateway Timeout — Backend phản hồi quá chậm            
 507  | Insufficient Storage — Hết dung lượng disk        


 ## II — Các loại web server
 ### 1. Apache
 Theo dữ liệu mới nhất vào tháng 4 năm 2026, Apache HTTP Server đứng ở vị trí thứ 2 trong số các máy chủ web phổ biến nhất, với thị phần khoảng 23,7%  
 * ƯU ĐIỂM:
   • .htaccess linh hoạt — hosting chia sẻ rất tiện
   • Hệ sinh thái lớn nhất, tài liệu phong phú nhất
   • mod_php cho hiệu năng PHP cao nhất
   • Dễ cấu hình và debug cho người mới
   • Tương thích tốt với mọi PHP framework, CMS
   • Được cPanel/Plesk hỗ trợ hoàn hảo

* NHƯỢC ĐIỂM:
   • Tiêu tốn RAM nhiều hơn Nginx (với Prefork/Worker)
   • Hiệu năng kém hơn Nginx với số lượng connection lớn
   • Xử lý file tĩnh chậm hơn Nginx ~2-3x
   • Cấu hình phức tạp hơn Nginx cho trường hợp nâng cao
 #### Kiến Trúc Apache
 **Cơ chế PREFORK 1 process - 1 phục vụ**: Khi có yêu cầu gửi đến, Server sẽ tạo ra một process riêng biệt để phục vụ duy nhất yêu cầu đó. Nếu có 100 người truy cập, hệ thống sẽ có 100 tiến trình chạy song song.  
 Ưu điểm: Cực kỳ ổn định. Nếu một tiến trình bị lỗi và treo, nó sẽ không ảnh hưởng đến các tiến trình khác  
 Nhược điểm: Tốn tài nguyên RAM. Mỗi tiến trình chiếm khoảng 8MB RAM, nếu Server có hàng ngàn kết nối cùng lúc, hệ thống rất dễ bị tràn RAM và treo máy   

 **Cơ chế WORKER (1 process = Nhiều luồng)**: Server tạo ra một số tiến trình con, nhưng mỗi tiến trình con lại chứa nhiều luồng nhỏ bên trong. Mỗi luồng này sẽ xử lý một yêu cầu từ khách hàng.  
Ưu điểm: Tiết kiệm RAM hơn, hệ thống có thể phục vụ nhiều người dùng hơn  
Nhược điểm: Vấn đề về Thread-safety. Nếu một luồng gặp lỗi nghiêm trọng, nó có thể kéo theo toàn bộ tiến trình đó chứa nhiều luồng khác bị sập.  

**Cơ chế EVENT**: giống Worker nhưng thông minh hơn ở chỗ xử lý các kết nối Keep-alive  
Ưu điểm vượt trội: Trong cơ chế Worker, một luồng vẫn bị chiếm dụng ngay cả khi khách hàng không gửi dữ liệu hay còn gọi là treo kết nối. Với Event MPM, các luồng này được giải phóng ngay lập tức để phục vụ người khác, chỉ khi nào khách hàng gửi dữ liệu thật sự thì nó mới cấp phát lại luồng xử lý.  
Nhược điểm: Vẫn không bằng Nginx với connection số lượng rất lớn 

### 2.Nginx
Web server số 1 thị trường toàn cầu,  Nginx được sử dụng bởi khoảng hơn 42% tổng số lượng web server trên toàn thế giới    
1. Nginx nhận kết nối từ Client → Đưa vào Event Queue  
2. Event Loop quét qua hàng đợi liên tục  
3. Khi một event sẵn sàng (dữ liệu đến, file đọc xong...) → Xử lý ngay  
4. Trong khi chờ I/O → Xử lý event khác  
5. Không cần tạo process/thread mới cho mỗi connection  

Kết quả: 1 worker process xử lý được hàng nghìn connections  
* ƯU ĐIỂM:  
   • Hiệu năng vượt trội với concurrent connections  
   • RAM thấp — xử lý 10,000+ connections với ~150MB RAM  
   • Xuất sắc với static file serving  
   • Reverse proxy và load balancer tốt nhất  
   • Cấu hình rõ ràng, dễ debug  
   • HTTP/2, HTTP/3, WebSocket native support  
   • Hỗ trợ tốt cho microservices, containers  

* NHƯỢC ĐIỂM:  
   • Không có .htaccess (cần reload khi thay đổi config)  
   • PHP phải qua FastCGI (PHP-FPM) — không thể embed    
   • Dynamic module support phức tạp hơn Apache  
   • Một số hosting panel chưa hỗ trợ tốt  

  ### 3.Microsoft IIS
  Internet Information Services (IIS) là web server tích hợp sẵn trong Windows Server, được phát triển và duy trì bởi Microsoft.    
Nó chia các Website vào các Application Pools riêng biệt:    
  * Nếu một Website bị lỗi (vòng lặp vô tận, tràn bộ nhớ), nó chỉ làm sập cái "Pool" đó thôi.  
  * Các Website khác trong cùng Server vẫn chạy  

IIS sử dụng HTTP.sys nằm ở mức Kernel:  
  * Nó nhận yêu cầu ngay từ lớp mạng thấp nhất trước khi đẩy lên phần mềm.  
  * Nó có khả năng ghi nhớ cực tốt. Nếu khách hàng yêu cầu lại nội dung cũ, nó trả kết quả ngay lập tức mà không cần tốn sức xử lý lại.  
Khả năng bảo mật tốt  
Nhược điểm: Để chạy IIS một cách chuyên nghiệp, bạn phải mua bản quyền Windows Server, Tốn tài nguyên hơn nginx, xử lí php chậm  

### 4.LiteSpeed Web Server
Nó có khả năng đọc và hiểu trực tiếp file cấu hình của Apache. Tốc độ tăng vọt 3-5 lần so với apache mà không cần sửa một dòng code nào  
Tích hợp sẵn tính năng chống tấn công DDoS ở tầng ứng dụng và bảo vệ các trang đăng nhập    
Nhược điểm: Phải trả phí hàng tháng, cộng đồng nhỏ, Không tự động nhận thay đổi trong .htaccess  

## III. Giao thức và công nghệ 
1. HTTP và HTTPS(Ngôn ngữ của Web)  
Request/Response: Client gửi yêu cầu, Server trả về kết quả hoặc báo lỗi.   
Status Codes: những lỗi tiêu biểu đã liệt kê trong bảng trên.  

2. SSL/TLS (bảo mật)  
Khi bạn dùng HTTPS, dữ liệu được bỏ vào mã hóa.  
Handshake: Trước khi truyền tin, Client và Server sẽ trao đổi khóa mật mã.  
Chứng chỉ số: Giống như căn cước công dân của website, được các tổ chức uy tín cấp để chứng minh không phải giả mạo.  

3. Giao thức hiện đại   
HTTP/2: Thay vì gửi từng file một, nó cho phép gửi nhiều file cùng lúc trên một kết nối duy nhất.  
QUIC & HTTP/3: Chạy trên nền UDP thay vì TCP để giảm độ trễ tối đa.  
WebSocket: Kết nối 2 chiều liên tục. Thường dùng cho các ứng dụng chat hoặc thông báo realtime  

4. Giao tiếp Server & Ứng dụng (thông dịch viên)  
Web Server (Nginx/Apache) thường không biết đọc code PHP hay Python. Nó cần một ông "thông dịch viên":  
CGI: Cổ điển, mỗi yêu cầu là tạo một tiến trình mới nhưng rất chậm.  
FastCGI: Cải tiến của CGI, giữ lại các tiến trình để dùng lại (VD: PHP-FPM).  
WSGI: Tiêu chuẩn riêng dành cho các ứng dụng Python (như Django, Flask)  

## IV.  Mô Hình Xử Lý Request
```
 PREFORK (Apache mặc định với mod_php):  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  
Ưu điểm: Cực kỳ ổn định, PHP tốt nhất  
         Mỗi request hoàn toàn cô lập  
         Dễ debug  

Nhược điểm: RAM cao (mỗi process ~30-50MB với PHP)  
             10,000 requests → 10,000 processes  
             Không scale tốt  

Khi nào dùng: Shared hosting, tương thích tốt nhất  

WORKER (Apache với thread):  
━━━━━━━━━━━━━━━━━━━━━━━━━━   
Ưu điểm: RAM thấp hơn Prefork  
         Thread chia sẻ memory trong process  

Nhược điểm: Thread-safety issues với PHP extensions  
             mod_php không thread-safe → phải dùng PHP-FPM  

Khi nào dùng: Ít phổ biến hơn Event MPM  

EVENT (Apache 2.4+ khuyên dùng):  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  
Ưu điểm: Xử lý keep-alive tốt hơn Worker  
         Thread listener riêng cho idle connections  
         Hiệu năng gần Nginx  

Nhược điểm: Vẫn cần PHP-FPM  
             Phức tạp hơn  

Khi nào dùng: Apache hiện đại với traffic trung bình-cao  

EVENT-DRIVEN (Nginx):
━━━━━━━━━━━━━━━━━━━━━
Ưu điểm: 10,000+ connections với ~150MB RAM
         1 worker xử lý hàng nghìn connections
         Xuất sắc với static files
         Cực kỳ hiệu quả I/O

Nhược điểm: Không tương thích PHP trực tiếp (cần PHP-FPM)
             Cấu hình phức tạp hơn

Khi nào dùng: Mọi production server hiện đại
```
 Module/Plugin:
 Module trên APACHE
 |Tên Module|	Vai Trò & Chức Năng|
 |:---|:---|
mod_rewrite| Chỉnh sửa và làm đẹp URL.
mod_ssl	| Cung cấp khả năng mã hóa dữ liệu qua giao thức HTTPS và quản lý chứng chỉ số SSL/TLS.
mod_proxy | Cho phép Apache đóng vai trò là một Proxy server, nhận yêu cầu và chuyển tiếp cho các server khác.
mod_proxy_fcgi| Kết nối Apache với trình xử lý PHP-FPM thông qua giao thức FastCGI, giúp xử lý mã PHP nhanh hơn.
mod_headers| Cho phép can thiệp, thêm hoặc xóa các HTTP Header 
mod_expires	| Thiết lập thời gian hết hạn của các file (ảnh, CSS, JS) trong bộ nhớ đệm trình duyệt của người dùng.
mod_deflate	| Sử dụng thuật toán Gzip để nén nội dung trước khi gửi đi, giúp giảm dung lượng và tăng tốc độ tải trang
mod_security2 | Tường lửa cho ứng dụng Web, giúp ngăn chặn các cuộc tấn công phổ biến như SQL Injection hay XSS.
mod_evasive | Phát hiện và ngăn chặn các cuộc tấn công từ chối dịch vụ hoặc tấn công dò tìm mật khẩu
mod_status | Cung cấp một trang web hiển thị thông tin thời gian thực về hiệu suất và các kết nối đang hoạt động của server.

Module trên NGINX

 |Tên Module|	Vai Trò & Chức Năng|
 |:---|:---|
 ngx_http_core_module| Quản lý các cấu hình cơ bản nhất như định nghĩa cổng kết nối, thư mục chứa code và các khối xử lý vị trí.
 ngx_http_ssl_module | Cung cấp các thiết lập cần thiết để server có thể chạy được giao thức bảo mật SSL/TLS
ngx_http_v2_module	| Kích hoạt giao thức HTTP/2 giúp truyền tải nhiều file cùng lúc trên một kết nối, tăng tốc độ trang web đáng kể.
ngx_http_rewrite_module	| Cho phép thay đổi URL hoặc chuyển hướng khách hàng sang địa chỉ mới bằng các biểu thức chính quy 
ngx_http_proxy_module	| Tính năng quan trọng nhất của Nginx, giúp đẩy yêu cầu từ người dùng sang các ứng dụng Backend.
ngx_http_fastcgi_module	| Chuyển tiếp các yêu cầu xử lý mã động như PHP đến các bộ xử lý bên ngoài như PHP-FPM.
ngx_http_gzip_module	| Nén các phản hồi HTTP bằng Gzip để tiết kiệm băng thông và giảm thời gian chờ đợi của khách hàng.
ngx_http_cache_*	| Tập hợp các tính năng dùng để lưu trữ tạm các phản hồi (FastCGI Cache, Proxy Cache) giúp phản hồi tức thì cho người dùng sau.


## V. Cấu hình và Triển khai Web Server
###  Cấu hình virtual host (host nhiều website trên một server)
```
1 IP Server (192.168.136.131)
        │
        │  Nginx lắng nghe port 80/443
        │
        ├── Host: site-a.com → /var/www/site-a/
        ├── Host: site-b.com → /var/www/site-b/
        └── Host: site-c.com → /var/www/site-c/
```
---
* Chuẩn Bị Môi Trường

```
# ── Cài đặt Nginx và Apache ──────────────────────────────
sudo apt update
sudo apt install -y nginx apache2 php8.1-fpm php8.1-mysql \
                    php8.1-curl php8.1-xml php8.1-mbstring

# ── Tạo cấu trúc thư mục chuẩn ──────────────────────────
sudo mkdir -p /var/www/{site-a.com,site-b.com,site-c.com}/{public,logs}
# Cấp quyền
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/

# Cho phép user hiện tại upload file
sudo usermod -aG www-data $USER
newgrp www-data

# ── Tạo file index mẫu cho từng site ────────────────────
sudo mkdir -p /var/www/site-a.com/public /var/www/site-b.com/public /var/www/site-c.com/public
sudo nano /var/www/site-a.com/public/index.html
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>${site}</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px;
               background: #f0f2f5; }
        .box { background: white; padding: 40px; border-radius: 10px;
               box-shadow: 0 2px 10px rgba(0,0,0,0.1); display: inline-block; }
    </style>
</head>
<body>
    <div class="box">
        <h1>🌐 ${site}</h1>
        <p>Server: $(hostname)</p>
        <p>Thời gian: $(date '+%Y-%m-%d %H:%M:%S')</p>
    </div>
</body>
</html>

# Kiểm tra cấu trúc
ls -la /var/www/

# Tạo config cho site-a.com
sudo nano /etc/nginx/sites-available/site-a.com
server {
    listen 80;
    listen [::]:80;    

    server_name site-a.com www.site-a.com;

    root /var/www/site-a.com/public;
    index index.php index.html index.htm;

    charset utf-8;

    access_log /var/www/site-a.com/logs/access.log combined;
    error_log  /var/www/site-a.com/logs/error.log warn;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;

        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 300;   
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
        access_log off;       
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
}
Tạo config tương tự cho site-b và site-c
Kích hoạt các site
sudo ln -s /etc/nginx/sites-available/site-a.com \
           /etc/nginx/sites-enabled/


# Tắt default site để tránh tranh chấp:
sudo rm -f /etc/nginx/sites-enabled/default
#  Kiểm tra 
sudo nginx -t
#  Reload Nginx
# Test với /etc/hosts (khi chưa có DNS thật)
# Thêm dòng này vào /etc/hosts trên máy CLIENT
echo "192.168.136.131 site-a.com www.site-a.com" | sudo tee -a /etc/hosts
echo "192.168.136.131 site-b.com www.site-b.com" | sudo tee -a /etc/hosts
echo "192.168.136.131 site-c.com www.site-c.com" | sudo tee -a /etc/hosts

# Test từ terminal trên server
curl -H "Host: site-a.com" http://localhost
curl -H "Host: site-b.com" http://localhost
curl -H "Host: site-c.com" http://localhost

sudo nginx -t && sudo systemctl reload nginx

```
<img width="846" height="162" alt="{2B844760-3EA2-4C85-8089-0FE64DF8900C}" src="https://github.com/user-attachments/assets/990a1b8d-6d21-4f2d-b2e7-6577eb8190eb" />
<img width="568" height="274" alt="{FDEF48F3-9ABB-4D07-93C1-3EB04864CF29}" src="https://github.com/user-attachments/assets/02466e45-2087-4714-a610-b22cedb55731" />
 <img width="386" height="120" alt="{2D394529-48CE-46EE-B94A-734C5576906C}" src="https://github.com/user-attachments/assets/764b787f-2f0d-462a-a931-5564f733d416" />
<img width="420" height="130" alt="{2A305A50-9FF6-4235-A438-3D6ADE041263}" src="https://github.com/user-attachments/assets/984c4afc-a3cc-4ae1-85e3-6aaa510e95db" />
<img width="408" height="68" alt="{735F79EC-6380-4B16-993C-284ED03A33F6}" src="https://github.com/user-attachments/assets/4bf14842-3f4d-4318-9b9e-145b9b394830" />
<img width="958" height="427" alt="{87619F03-28ED-470E-BBE4-963ED50751A2}" src="https://github.com/user-attachments/assets/e208b28c-602b-4509-976d-97856fddf38d" />

---

### Reverse proxy,load balancing
Apache rất tốt với PHP (mod_php, .htaccess)  
Nhưng Apache yếu với concurrent connections  
Nginx tốt với concurrent connections, static files  
Nhưng Nginx không có .htaccess  
=> Nên kết hợp cả 2, nginx đứng trước dùng cổng 80, apache đứng sau dùng cổng 8080
#### Cấu hình apache
* Đổi cổng apache sang 8080 để không đánh nhau
sudo nano /etc/apache2/ports.conf
<img width="644" height="286" alt="{6312E6FD-70A6-43FE-A3F5-AC2C9FC8EEB7}" src="https://github.com/user-attachments/assets/17405e99-317d-4a22-9623-5e9dc976b0b9" />

* Cập nhật Virtual Host Apache sang port 8080
sudo nano /etc/apache2/sites-available/site-a.com.conf
```
<VirtualHost *:8080>      ← Đổi từ *:80 thành *:8080
    ServerName site-a.com
    DocumentRoot /var/www/site-a.com/public

    <Directory /var/www/site-a.com/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch "\.php$">
        SetHandler "proxy:unix:/run/php/php8.1-fpm.sock|fcgi://localhost"
    </FilesMatch>

    # ── Quan trọng: Nhận IP thật từ Nginx ────────────────
    # Cần module remoteip
    RemoteIPHeader X-Forwarded-For
    RemoteIPInternalProxy 127.0.0.1

    ErrorLog  /var/www/site-a.com/logs/apache_error.log
    CustomLog /var/www/site-a.com/logs/apache_access.log combined  
</VirtualHost>
```
* Bật module remoteip để Apache nhận IP thật
sudo a2enmod remoteip  
sudo systemctl reload apache2  
sudo ss -tlnp | grep apache2 :check xem apache chạy chưa  
<img width="866" height="140" alt="{CBC7FB36-3F98-43C4-AC5E-25EA4B137365}" src="https://github.com/user-attachments/assets/00a59611-7f45-41ae-8e8a-8b5d0df53f37" />

#### Cấu hình nginx reserve proxy
sudo nano /etc/nginx/sites-available/site-a.com
```
# /etc/nginx/sites-available/site-a.com

upstream apache_backend {
    server 127.0.0.1:8080;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;

    server_name _;

    root /var/www/site-a.com/public;

    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|pdf|zip)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";

        try_files $uri @proxy_to_apache;

        access_log off;
    }

    # Dynamic requests
    location / {
        try_files $uri $uri/ @proxy_to_apache;
    }

    # Reverse proxy đến Apache
    location @proxy_to_apache {
        proxy_pass http://apache_backend;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Connection "";

        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    access_log /var/www/site-a.com/logs/nginx_access.log;
    error_log  /var/www/site-a.com/logs/nginx_error.log;
}
```
sudo nginx -t  
sudo systemctl reload nginx  

<img width="871" height="254" alt="{2F218589-3BDF-4A43-BE80-9DB9501E35C0}" src="https://github.com/user-attachments/assets/685bd414-15ac-4561-9d2d-f2efeeb91b2a" />
 request đi qua nginx.
<img width="353" height="130" alt="{BC2C00D0-F68C-4089-AD9B-7CB40FE2ED22}" src="https://github.com/user-attachments/assets/38a1eaff-7ef0-4bc2-9187-0bb8781f3775" />



