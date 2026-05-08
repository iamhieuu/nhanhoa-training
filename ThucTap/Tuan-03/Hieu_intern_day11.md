# Báo cáo thực tập ngày 11 - Chuyên sâu về web server
## Load Balancing 
Load Balancing là việc phân phối lưu lượng mạng hoặc lưu lượng truy cập ứng dụng trên nhiều máy chủ khác nhau
Mục tiêu chính là:
Tăng tính sẵn sàng (High Availability): Nếu một máy chủ bị hỏng, bộ cân bằng tải sẽ tự động chuyển hướng khách sang các máy chủ còn lại.  
Tăng khả năng mở rộng (Scalability): Bạn có thể dễ dàng thêm hoặc bớt máy chủ tùy theo lượng truy cập.  
Tối ưu hiệu suất: Tránh tình trạng một server đầy trong khi server khác lại đang không có gì.  
### Các thuật toán load balancing
```
round-robin  → Xoay vòng đều: 1→2→3→1→2→3
              Phù hợp: Servers có cấu hình tương đương

least_conn   → Gửi đến server có ít connections nhất
              Phù hợp: Requests có thời gian xử lý khác nhau

ip_hash      → Cùng IP → Cùng server (Session Sticky)
              Phù hợp: App có session trên từng server

hash $uri    → Hash theo URL → Cùng URL → Cùng server
              Phù hợp: Cache consistency

random       → Ngẫu nhiên
least_time   → Thời gian phản hồi thấp nhất (NGINX Plus)
```
