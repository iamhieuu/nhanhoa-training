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
✅ ƯU ĐIỂM:
   • Hiệu năng vượt trội với concurrent connections
   • RAM thấp — xử lý 10,000+ connections với ~150MB RAM
   • Xuất sắc với static file serving
   • Reverse proxy và load balancer tốt nhất
   • Cấu hình rõ ràng, dễ debug
   • HTTP/2, HTTP/3, WebSocket native support
   • Hỗ trợ tốt cho microservices, containers

❌ NHƯỢC ĐIỂM:
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
