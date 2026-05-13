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


