# Báo cáo thực tập ngày 28 - Công cụ giám sát database

### Lý do cần giám sát
 
```
Nếu không có giám sát:  Sự cố xảy ra → Người dùng báo → DBA mới biết
                   Response time: 30-60 phút
 
Nếu có giám sát: Metric vượt ngưỡng → Alert → DBA biết trước khi user thấy
                   Response time: 1-5 phút
```
 
### Bảng so sánh công cụ giám sát
 
| Công cụ | Loại | Hỗ trợ DB | Điểm mạnh | Hạn chế |
|---|---|---|---|---|
| **PMM** (Percona) | Full-stack | MySQL, PG, MongoDB | Query Analytics, đầy đủ | Nặng hơn, cần server riêng |
| **Prometheus + mysqld_exporter** | Metrics | MySQL | Nhẹ, tích hợp Grafana | Chỉ metrics, không query analytics |
| **MySQL Workbench** | GUI | MySQL | Visual, dễ dùng | Không real-time alert |
| **pgAdmin** | GUI | PostgreSQL | Đầy đủ tính năng PG | Chỉ cho PostgreSQL |
| **Datadog** | Cloud SaaS | Đa DB | APM tích hợp, ít setup | Đắt tiền |
| **New Relic** | Cloud SaaS | Đa DB | End-to-end visibility | Đắt tiền |
 
### Các metric quan trọng cần theo dõi — MySQL
 
| Metric | Ý nghĩa | Ngưỡng cảnh báo | Lệnh kiểm tra |
|---|---|---|---|
| **Threads_connected** | Số kết nối đang mở | > 80% max_connections | `SHOW STATUS LIKE 'Threads_connected'` |
| **Innodb_buffer_pool_hit_rate** | % đọc từ RAM | < 95% | `SHOW STATUS LIKE 'Innodb_buffer_pool%'` |
| **Slow_queries** | Query chạy chậm | Tăng đột biến | `SHOW STATUS LIKE 'Slow_queries'` |
| **Questions** | Tổng query/giây | Baseline × 3 | `SHOW STATUS LIKE 'Questions'` |
| **Seconds_Behind_Source** | Replica lag | > 30 giây | `SHOW REPLICA STATUS\G` |
| **Innodb_row_lock_waits** | Số lần chờ lock | Tăng liên tục | `SHOW STATUS LIKE 'Innodb_row_lock%'` |
 
```bash
# Cài mysqld_exporter + Prometheus trên Ubuntu 22.04
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xf mysqld_exporter-*.tar.gz
sudo mv mysqld_exporter-*/mysqld_exporter /usr/local/bin/
 
# Tạo MySQL user cho exporter
# CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'Exp@2026!';
# GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
 
mysqld_exporter --config.my-cnf=/etc/.mysqld_exporter.cnf &
# Metrics tại: http://localhost:9104/metrics
```
 
### Grafana Dashboard quan trọng cho MySQL
 
```
Dashboard ID:
  7362  → MySQL Overview (mysqld_exporter)
  14057 → MySQL InnoDB Metrics
  17320 → MySQL Replication
  763   → MySQL Overview (PMM-style)
```
 
---
 
<a name="viii2"></a>
## VIII.2 Nhận diện và xử lý Bottleneck
 
### Mô hình USE — Phương pháp debug chuẩn
 
```
USE Method cho mỗi tài nguyên:
  U = Utilization  (đang dùng bao nhiêu %)
  S = Saturation   (đang chờ queue không?)
  E = Errors       (có lỗi không?)
 
Áp dụng theo tầng:
  CPU → RAM → Disk I/O → Network → DB Lock
```
 
### Bảng nhận diện Bottleneck theo triệu chứng
 
| Triệu chứng | Tầng nghi ngờ | Lệnh kiểm tra | Hành động |
|---|---|---|---|
| Query chậm, CPU cao | Query/Index | `SHOW PROCESSLIST` | EXPLAIN query, thêm index |
| Query chậm, CPU thấp | Disk I/O | `iostat -x 1 5` | Tăng buffer pool, SSD |
| Nhiều kết nối timeout | Connection pool | `SHOW STATUS LIKE 'Threads%'` | Tăng max_connections, dùng ProxySQL |
| Replication lag tăng | Network / Slow query | `SHOW REPLICA STATUS\G` | Tối ưu query, tăng slave_threads |
| OOM Killer giết MySQL | RAM | `free -h`, `dmesg | grep oom` | Tăng RAM, giảm buffer_pool_size |
 
### Công cụ debug nhanh
 
```bash
# 1. Xem query đang chạy (real-time)
sudo mysql -u root -p -e "SHOW FULL PROCESSLIST\G" | grep -v "Sleep"
 
# 2. Query chậm nhất hiện tại
sudo mysql -u root -p << 'SQL'
SELECT query, exec_count,
       ROUND(avg_latency/1000000000, 3) AS avg_sec,
       ROUND(total_latency/1000000000, 3) AS total_sec
FROM sys.statement_analysis
ORDER BY avg_latency DESC LIMIT 10;
SQL
 
# 3. Table nào đang bị lock
sudo mysql -u root -p -e "
SELECT r.trx_id waiting_trx,
       r.trx_mysql_thread_id waiting_thread,
       b.trx_id blocking_trx,
       b.trx_mysql_thread_id blocking_thread,
       p.info blocking_query
FROM information_schema.innodb_lock_waits w
JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id
JOIN information_schema.processlist p ON p.id = b.trx_mysql_thread_id;"
 
# 4. Buffer Pool Hit Rate (phải > 95%)
sudo mysql -u root -p -e "
SELECT ROUND(
  (1 - Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests) * 100, 2
) AS buffer_pool_hit_rate
FROM (SELECT
  (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_STATUS WHERE VARIABLE_NAME='Innodb_buffer_pool_reads') AS Innodb_buffer_pool_reads,
  (SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_STATUS WHERE VARIABLE_NAME='Innodb_buffer_pool_read_requests') AS Innodb_buffer_pool_read_requests
) t;"
 
# 5. Disk I/O
iostat -x 1 5
# %util > 80% → Disk là bottleneck
# await > 20ms → Disk latency cao
```
 
### Slow Query Log — Công cụ số 1 tối ưu
 
```ini
# Bật trong /etc/mysql/mysql.conf.d/mysqld.cnf
slow_query_log      = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time     = 1          # Log query chạy > 1 giây
log_queries_not_using_indexes = 1 # Log query không dùng index
```
 
```bash
# Phân tích slow query log
sudo mysqldumpslow -s t -t 10 /var/log/mysql/mysql-slow.log
# -s t  = sắp xếp theo tổng thời gian
# -t 10 = top 10 query
 
# Hoặc dùng pt-query-digest (Percona Toolkit)
sudo pt-query-digest /var/log/mysql/mysql-slow.log | head -100
```
 
---

## VIII.3 Deadlock và các vấn đề đồng thời
 
### Deadlock là gì?
 
```
DEADLOCK xảy ra khi:
 
Transaction A                    Transaction B
─────────────                    ─────────────
LOCK row 1 (A giữ)               LOCK row 2 (B giữ)
      │                                │
      ▼                                ▼
CHỜ lock row 2 ──────────────── CHỜ lock row 1
      (B đang giữ)                     (A đang giữ)
 
→ Vòng lặp chờ nhau → DEADLOCK!
MySQL tự phát hiện và kill transaction có ít work hơn
```
 ### Xử lý Deadlock
 
```sql
-- Xem deadlock gần nhất
SHOW ENGINE INNODB STATUS\G
-- Tìm phần "LATEST DETECTED DEADLOCK"
 
-- Xem transaction đang chạy
SELECT * FROM information_schema.INNODB_TRX
ORDER BY trx_started;
 
-- Kill transaction gây deadlock
KILL 1234;  -- thread_id từ SHOW PROCESSLIST
```
 
**Phòng tránh Deadlock — 4 nguyên tắc:**
 
```
1. LOCK THEO CÙNG THỨ TỰ: Lock A rồi B theo thứ tự cố định
 
2. TRANSACTION NGẮN NHẤT CÓ THỂ: Xử lý xong → BEGIN → UPDATE → COMMIT (ngay lập tức)
 
3. DÙNG SELECT ... FOR UPDATE ĐỦ DÙNG : SELECT id FROM orders WHERE id=1 FOR UPDATE (lock đúng row)
 
4. RETRY LOGIC TRONG APP
   try:
       execute_transaction()
   except DeadlockError:
       sleep(random * 0.1)
       execute_transaction()  # Retry
```
 
### Lock Types trong MySQL InnoDB
 
| Lock Type | Mô tả | Gây bởi | Ảnh hưởng |
|---|---|---|---|
| **Row Lock** | Khóa 1 row cụ thể | UPDATE, DELETE, SELECT FOR UPDATE | Chỉ row đó |
| **Gap Lock** | Khóa khoảng trống giữa rows | Range queries trong REPEATABLE READ | Các row mới insert vào khoảng này |
| **Next-Key Lock** | Row Lock + Gap Lock | InnoDB default | Row + khoảng phía trước |
| **Table Lock** | Khóa toàn bảng | ALTER TABLE, LOCK TABLES | Toàn bảng |
| **Intention Lock** | Báo ý định lock | Trước khi lock row | Tương tác với table lock |
 
---
## VIII.4 Log và Phân tích lỗi
 
### Các loại Log trong MySQL
 
| Log | Vị trí | Ghi gì | Dùng khi |
|---|---|---|---|
| **Error Log** | `/var/log/mysql/error.log` | Startup, shutdown, critical errors | Luôn bật, debug sự cố |
| **General Query Log** | Tắt theo mặc định | Mọi query đến server | Debug ngắn hạn (tốn I/O) |
| **Slow Query Log** | `/var/log/mysql/mysql-slow.log` | Query chậm hơn long_query_time | Tối ưu performance |
| **Binary Log** | `/var/log/mysql/mysql-bin.*` | Mọi thay đổi data (INSERT/UPDATE/DELETE) | Replication, PITR backup |
| **Relay Log** | Replica only | Binlog từ Primary | Replication |
| **InnoDB Undo Log** | Trong data directory | Snapshot cũ cho MVCC | Internal, không đọc trực tiếp |
 
### Quy trình debug sự cố chuẩn
 
```bash
# BƯỚC 1: Xem Error Log (luôn bắt đầu từ đây)
sudo tail -100 /var/log/mysql/error.log | grep -E "ERROR|Warning|FATAL"
 
# BƯỚC 2: Xem MySQL status
sudo mysql -u root -p -e "SHOW GLOBAL STATUS;" | grep -E "Error|Abort|Timeout"
 
# BƯỚC 3: Xem process đang chạy
sudo mysql -u root -p -e "SHOW FULL PROCESSLIST\G" | grep -v "Sleep"
 
# BƯỚC 4: Xem lock và transaction
sudo mysql -u root -p -e "SELECT * FROM sys.innodb_lock_waits\G"
 
# BƯỚC 5: Xem InnoDB engine status
sudo mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G" 2>/dev/null \
  | grep -A 50 "TRANSACTIONS"
```
 
### Phân tích Binary Log — Tìm ai xóa data
 
```bash
# Ví dụ: Ai đã xóa table lúc 10:30 sáng nay?
sudo mysqlbinlog \
  --start-datetime="2026-05-30 10:25:00" \
  --stop-datetime="2026-05-30 10:35:00" \
  --base64-output=DECODE-ROWS \
  -v /var/log/mysql/mysql-bin.000023 \
  | grep -E "DELETE|DROP|user@|timestamp"
```
 
### Log Rotation — Tự động để không đầy disk
 
```bash
# /etc/logrotate.d/mysql-server 
/var/log/mysql/*.log {
    daily
    rotate 7           # Giữ 7 ngày
    compress           # Nén log cũ
    delaycompress
    missingok
    notifempty
    create 640 mysql adm
    postrotate
        MYADMIN="/usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf"
        if [ -f `$MYADMIN variables 2>/dev/null | awk '{ if ($2 == "pid_file") print $4}'` ]; then
            $MYADMIN flush-logs
        fi
    endscript
}
```
 
---
