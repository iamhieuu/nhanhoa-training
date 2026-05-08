# Báo cáo thực tập ngày 11 - Chuyên sâu về web server
## Load Balancing 
### Các thuật toán load balancing
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
