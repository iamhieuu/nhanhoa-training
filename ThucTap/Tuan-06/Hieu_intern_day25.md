# Báo cáo thực tập ngày 25 - Quản Trị Database Server

----

DBA phải:
* Giảm thiểu thiệt hại khi bị compromise
* Phân quyền tối thiểu
* Audit được ai làm gì
* Tách role rõ ràng
* Không để app có quyền phá DB
* Chuẩn hóa access để scale team
  
### 1: User và quản lý quyền truy cập.
Nguyên tắc tối thượng trong quản trị user là quyền hạn tối thiểu. Một ứng dụng web chỉ nên có quyền SELECT, INSERT, UPDATE, DELETE trên đúng database của nó, và tuyệt đối không có quyền DROP table hay SHUTDOWN server.  
Các hệ thống thường áp dụng Role-Based Access Control: Tạo các Role (nhóm quyền) như read_only, db_admin, app_user và gán Role đó cho User.
 
Mysql/Mariadb
```
-- Tạo user chỉ phép truy cập từ một IP cụ thể hoặc mạng nội bộ (ví dụ: web server)
CREATE USER 'app_user'@'192.168.1.100' IDENTIFIED BY 'Iamhieu123!';

-- Gán quyền DML trên một database cụ thể
GRANT SELECT, INSERT, UPDATE, DELETE ON my_app_db.* TO 'app_user'@'192.168.1.100';

-- Áp dụng thay đổi
FLUSH PRIVILEGES;
```

MongoDB (NoSQL): MongoDB quản lý user theo cơ chế Role dựa trên từng database cụ thể.

````
use sales_db
db.createUser({
  user: "report_user",
  pwd: "SecurePassword123",
  roles: [ { role: "read", db: "sales_db" } ] // Chỉ được quyền đọc data
})
````
### 2. Sao lưu và Phục hồi (Backup & Recovery)
Full Backup: Sao lưu toàn bộ dữ liệu tại một thời điểm. An toàn nhất nhưng tốn dung lượng và thời gian nhất.  
Differential/Incremental Backup: Chỉ sao lưu phần thay đổi kể từ lần Full Backup gần nhất để tiết kiệm không gian.  
Point-in-Time Recovery (PITR): Sử dụng các file log lưu vết (Binary Log trong MySQL, Oplog trong MongoDB, Transaction Log trong MSSQL) để phục hồi database về chính xác một mốc thời gian cụ thể  
MySQL (Sử dụng công cụ CLI mysqldump):
````
# Sao lưu toàn bộ database sales_db ra file script SQL
mysqldump -u root -p sales_db > /backup/sales_db_backup.sql

# Phục hồi dữ liệu từ file backup vào một database trống
mysql -u root -p new_sales_db < /backup/sales_db_backup.sql
````
Redis (In-memory Database): Redis lưu dữ liệu trên RAM nhưng có hai cơ chế ghi xuống đĩa cứng để backup: RDB (chụp ảnh snapshot) và AOF (ghi log từng lệnh thay đổi).
````
# Ép Redis tạo ngay một file snapshot rdb (chạy ngầm dạng background để không nghẽn hệ thống)
redis-cli BGSAVE
````

### 3. Theo dõi hiệu năng (Monitoring)
Để hệ thống luôn "khỏe mạnh", bạn cần giám sát đồng thời cả tài nguyên phần cứng lẫn các chỉ số nội tại của Database:  
System Metrics: CPU, RAM, Network throughput và quan trọng nhất là Disk IOPS.  
Database Metrics: Số lượng connection đang mở, số lượng Slow Queries, và Buffer Pool/Cache Hit Ratio (tỷ lệ dữ liệu tìm thấy trên RAM, nếu tỷ lệ này thấp nghĩa là DB đang phải quét ổ cứng quá nhiều).  
Xu hướng vận hành: Thường cấu hình các Exporter (như mysqld_exporter) để đẩy dữ liệu về trung tâm giám sát Prometheus và trực quan hóa qua biểu đồ Grafana.  

MongoDB (Xem hiệu năng real-time nhanh qua CLI):
```
# Hiển thị số lượng lệnh đọc/ghi, số connection và lượng RAM đang tiêu thụ mỗi giây
mongostat --rowcount 5
MSSQL (Truy vấn Dynamic Management Views - DMVs):
```
SQL
````
-- Tìm xem top 5 câu lệnh đang chiếm dụng nhiều tài nguyên CPU nhất trong bộ nhớ đệm
SELECT TOP 5 text, total_worker_time/execution_count AS [Avg CPU Time]
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
ORDER BY total_worker_time DESC;
````

### 4. Tối ưu hóa truy vấn (Query Optimization)
Khi bảng dữ liệu tăng từ vài nghìn lên vài triệu dòng, một câu lệnh tìm kiếm không tối ưu sẽ bắt Database thực hiện Full Table Scan (quét toàn bộ ổ cứng), đẩy CPU lên 100%.  
Index: Giống như mục lục sách, giúp tìm dữ liệu mà không cần lật từng trang. Database thường dùng cấu trúc B-Tree để phân nhánh tìm kiếm cực nhanh.  
Execution Plan: Kế hoạch thực thi mà Database tự tính toán xem nên lấy dữ liệu bằng con đường nào ngắn nhất.  

MySQL/MariaDB (Sử dụng lệnh EXPLAIN để phân tích):
````
-- Kiểm tra xem câu lệnh sau đang chạy như thế nào
EXPLAIN SELECT * FROM customers WHERE email = 'hieu@example.com';
Nếu ở cột type kết quả trả về là ALL, nghĩa là nó đang quét toàn bộ bảng (rất tệ). Ta tiến hành tạo Index:

CREATE INDEX idx_customers_email ON customers(email);
Sau khi tạo xong, chạy lại lệnh EXPLAIN, bạn sẽ thấy type chuyển thành const hoặc ref và số lượng dòng cần quét (rows) giảm xuống chỉ còn 1 dòng duy nhất.
````

### 5. Quản lý Transaction và Lock
Transaction: Đảm bảo tính ACID. Điển hình là nghiệp vụ chuyển tiền ngân hàng: (1) Trừ tiền tài khoản A → (2) Cộng tiền tài khoản B. Hai hành động này phải cùng thành công hoặc cùng thất bại và quay về trạng thái cũ. Không thể có trạng thái lấp lửng ở giữa.

Lock: Để tránh việc hai user cùng sửa đổi một dòng dữ liệu tại một thời điểm gây ra sai lệch dữ liệu.  
Shared Lock: Cho phép nhiều người cùng đọc, nhưng không ai được sửa.  
Exclusive Lock: Chỉ một người được giữ quyền sửa, block toàn bộ người khác.  
Deadlock: Hiện tượng tiến trình X giữ tài nguyên 1 và đợi tài nguyên 2, trong khi tiến trình Y giữ tài nguyên 2 và đợi tài nguyên 1. Cả hai đứng đợi nhau vô thời hạn.  

MySQL (Sử dụng Storage Engine InnoDB để quản lý Transaction):
````
START TRANSACTION;
-- Bước 1: Trừ tiền tài khoản A (Dòng này sẽ bị khóa lại, các session khác phải đợi)
UPDATE accounts SET balance = balance - 500 WHERE account_id = 'A';
-- Bước 2: Cộng tiền tài khoản B
UPDATE accounts SET balance = balance + 500 WHERE account_id = 'B';
-- Nếu cả 2 lệnh chạy mượt mà, lưu vĩnh viễn vào đĩa cứng và nhả khóa (Lock)
COMMIT;
-- Nếu lỡ bước 2 bị lỗi hệ thống, khôi phục lại như chưa có gì xảy ra
-- ROLLBACK;
````
----

## Bảo Mật Database Server
### 1. Các mối đe dọa bảo mật phổ biến
Trong môi trường database, các cuộc tấn công thường nhắm vào 4 con đường chính:

* SQL / NoSQL Injection: Đây là lỗ hổng kinh điển nhưng vẫn cực kỳ nguy hiểm. Xảy ra khi ứng dụng không kiểm tra kỹ dữ liệu nhập vào từ người dùng, cho phép kẻ tấn công "chèn" các câu lệnh database độc hại. Hậu quả là chúng có thể bypass qua màn hình đăng nhập, lấy toàn bộ dữ liệu hoặc thậm chí xóa sạch database.

* Phơi nhiễm do cấu hình sai: Lỗi này thường do người quản trị chủ quan hoặc thiếu kinh nghiệm. Ví dụ: Để database mở cổng mở ra ngoài Internet công cộng (0.0.0.0/0) mà không đổi port mặc định, không đặt mật khẩu cho tài khoản Admin, hoặc để lộ các file backup công khai trên các cloud storage.

* Tấn công Brute Force và Credential Stuffing: Kẻ tấn công sử dụng các công cụ tự động để dò quét mật khẩu liên tục hoặc sử dụng danh sách tài khoản/mật khẩu bị rò rỉ từ các hệ thống khác để thử đăng nhập vào Database Server.

* Mối đe dọa từ bên trong: Không phải mọi cuộc tấn công đều đến từ bên ngoài. Nhân viên cũ, quản trị viên có quá nhiều quyền hạn vô tình hoặc cố ý đánh cắp dữ liệu, hoặc tài khoản của họ bị hacker chiếm quyền điều khiển.

### 2. Mã hóa dữ liệu (Data Encryption)
Mã hóa là quá trình biến đổi dữ liệu từ dạng văn bản rõ thành dạng không thể đọc được nếu không có khóa giải mã. Trong quản trị Database, ta bắt buộc phải thực hiện mã hóa ở hai trạng thái:  
* Mã hóa trên đường truyền (Encryption in Transit)
    * Khái niệm: Bảo vệ dữ liệu khi nó di chuyển qua lại giữa Application Server (Web, App) và Database Server trên môi trường mạng.
    * Cơ chế: Sử dụng giao thức TLS/SSL để thiết lập một đường ống mã hóa an toàn. Toàn bộ các câu lệnh SQL gửi đi và kết quả trả về đều được mã hóa.
    * Mục đích: Ngăn chặn các cuộc tấn công nghe lén, đánh cắp gói tin trên đường truyền (Man-in-the-Middle Attack).

* Mã hóa khi lưu trữ (Encryption at Rest)
    * Khái niệm: Bảo vệ dữ liệu khi nó nằm yên trên ổ cứng, các file sao lưu (backup) hoặc các file log hệ thống.
    * Cơ chế phổ biến:
        *  Transparent Data Encryption (TDE): Đây là tính năng mã hóa ở cấp độ database (rất phổ biến ở MSSQL, MySQL Enterprise, Oracle). Nó tự động mã hóa các file dữ liệu (.mdf, .ibd) trước khi ghi xuống đĩa cứng và tự động giải mã khi nạp lên RAM. Quá trình này diễn ra hoàn toàn "trong suốt" với ứng dụng (code ứng dụng không cần thay đổi).

        * Application-level Encryption: Mã hóa trực tiếp từ code ứng dụng trước khi insert vào database. Database chỉ nhìn thấy các chuỗi ký tự vô nghĩa (thường dùng cho các trường cực kỳ nhạy cảm như số thẻ tín dụng, mật khẩu).

    * Mục đích: Đảm bảo nếu kẻ trộm có lấy được ổ cứng vật lý hoặc lấy cắp được file backup .sql, .bak mang đi nơi khác, chúng cũng không thể đọc được nội dung bên trong nếu không có khóa giải mã (Master Key).
 
### 3. Audit và theo dõi truy cập (Database Auditing)
 Audit là để "ghi vết" và "phát hiện". Audit log là một hệ thống nhật ký độc lập, ghi lại chi tiết toàn bộ các hành vi bảo mật diễn ra trên Database Server. Nó trả lời cho câu hỏi: Ai (User nào, IP nào) đã làm gì (Lệnh SELECT, DROP, GRANT...), vào lúc nào, và kết quả thành công hay thất bại.  
Sự khác biệt với log thông thường:
* Error Log: Chỉ ghi lại lỗi hệ thống để sửa chữa (debug).
* Transaction Log: Để phục hồi dữ liệu khi crash.
* Audit Log: Chỉ tập trung vào các sự kiện an ninh thông tin.
 Giá trị cốt lõi:
    * Phát hiện bất thường: Ví dụ, tài khoản của một nhân viên kế toán thông thường đột nhiên thực hiện lệnh SELECT hàng triệu dòng dữ liệu khách hàng vào lúc 2 giờ sáng, Hệ thống sẽ cảnh báo ngay lập tức.
    * Điều tra số: Khi xảy ra sự cố rò rỉ dữ liệu, Audit log là bằng chứng duy nhất để tìm ra nguyên nhân và thủ phạm.
    * Tuân thủ : Các tiêu chuẩn quốc tế như PCI-DSS (cho tài chính/thẻ), GDPR (bảo vệ dữ liệu châu Âu), ISO 27001 đều bắt buộc phải bật tính năng Database Auditing.
 
#### 4. Patch Management và Cập nhật bảo mật
Không có phần mềm nào là hoàn hảo tuyệt đối. Các hệ quản trị cơ sở dữ liệu (MySQL, MSSQL, MongoDB...) liên tục bị phát hiện các lỗ hổng bảo mật mới.  
Khái niệm: Patch Managementlà quy trình mang tính chiến lược nhằm kiểm tra, cài đặt các bản vá lỗi bảo mật và cập nhật phiên bản cho cả Hệ điều hành lẫn Database Engine.  
Quy trình triển khai lý thuyết chuẩn trong doanh nghiệp:
    * Theo dõi & Đánh giá: Nhận thông tin về các lỗ hổng mới từ nhà phát hành phần mềm. Đánh giá mức độ ảnh hưởng (Nghiêm trọng, Cao, Trung bình) đối với hệ thống hiện tại.
    * Thử nghiệm: Tuyệt đối không bao giờ áp dụng bản vá trực tiếp lên server Production (Hệ thống đang chạy thật). Bản vá phải được cài đặt và chạy thử nghiệm trên môi trường Staging/UAT để đảm bảo bản vá không làm xung đột phần mềm hoặc làm sập ứng dụng.
    * Sao lưu dự phòng : Ngay trước khi tiến hành cập nhật trên Production, phải thực hiện một bản Full Backup toàn diện để có đường lùi nếu quá trình update thất bại.
    * Triển khai trong Maintenance Window: Lựa chọn khung giờ bảo trì để tiến hành áp dụng bản vá nhằm giảm thiểu ảnh hưởng đến người dùng.  

--- 

## VI. High Availability và Scalability
### 1.1 MySQL Replication — Master/Slave (Source/Replica)

> **Khái niệm:** Replication là quá trình **sao chép tự động** mọi thay đổi dữ liệu từ server chính (Primary/Master) sang một hoặc nhiều server phụ (Replica/Slave) theo thời gian thực.

#### Kiến trúc tổng quan

```
                    ┌─────────────────────────────┐
   App ghi ──────►  │        PRIMARY (Master)      │
                    │  - Nhận INSERT/UPDATE/DELETE │
                    │  - Ghi vào Binary Log (binlog)│
                    └────────────┬────────────────-┘
                                 │  Binary Log Events
                    ┌────────────▼──────────────────────────────┐
                    │           REPLICATION CHANNEL              │
                    │  IO Thread kéo binlog về Relay Log        │
                    │  SQL Thread đọc Relay Log → apply vào DB  │
                    └────────────┬──────────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                   ▼
      ┌──────────────┐  ┌──────────────┐   ┌──────────────┐
      │  REPLICA 1   │  │  REPLICA 2   │   │  REPLICA 3   │
      │  (Read only) │  │  (Read only) │   │  (Reporting) │
      └──────────────┘  └──────────────┘   └──────────────┘
              ▲                  ▲                   ▲
   App đọc ───┴──────────────────┘                   │
   (SELECT)                                     BI/Analytics
```


#### Cơ chế hoạt động chi tiết (3 luồng)

```
PHÍA PRIMARY:
┌─────────────────────────────────────────────────┐
│ 1. Client thực thi: INSERT INTO orders...       │
│ 2. Storage Engine ghi data vào disk             │
│ 3. Binlog Thread ghi event vào Binary Log       │
│    (binary log = nhật ký mọi thay đổi)         │
└─────────────────────────────────────────────────┘

PHÍA REPLICA — Có 2 thread hoạt động song song:
┌─────────────────────────────────────────────────┐
│ IO Thread:                                      │
│  - Kết nối lên Primary qua TCP                 │
│  - Liên tục kéo Binary Log events mới về       │
│  - Ghi vào Relay Log (file local của Replica)  │
│                                                 │
│ SQL Thread (Applier Thread):                    │
│  - Đọc events từ Relay Log                     │
│  - Thực thi lại các câu SQL đó trên Replica    │
│  - Replica lag = độ trễ giữa Primary và Replica│
└─────────────────────────────────────────────────┘
```

#### Các lệnh quản lý Replication MySQL thực tế

```sql
-- === TRÊN PRIMARY ===

-- Tạo user dành riêng cho replication (không dùng root!)
CREATE USER 'repl_user'@'%' IDENTIFIED BY 'StrongRepl@2026';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;

-- Xem trạng thái binlog (lấy File và Position cho Replica)
SHOW BINARY LOG STATUS\G
-- *** File: mysql-bin.000003
-- *** Position: 157

-- === TRÊN REPLICA ===

-- Khai báo Primary server
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='192.168.1.10',
  SOURCE_PORT=3306,
  SOURCE_USER='repl_user',
  SOURCE_PASSWORD='StrongRepl@2026',
  SOURCE_LOG_FILE='mysql-bin.000003',
  SOURCE_LOG_POS=157;

-- Bắt đầu replication
START REPLICA;

-- Kiểm tra trạng thái
SHOW REPLICA STATUS\G
```

#### Đọc kết quả SHOW REPLICA STATUS — những dòng quan trọng nhất

```
Replica_IO_Running: Yes          ← IO Thread đang chạy, kết nối Primary OK
Replica_SQL_Running: Yes         ← SQL Thread đang chạy, apply events OK
Seconds_Behind_Source: 0         ← Lag = 0 giây → Replica đồng bộ hoàn toàn
Last_Error:                      ← Trống = không có lỗi

-- ⚠️ Dấu hiệu có vấn đề:
Replica_IO_Running: No           → Mất kết nối với Primary (network, auth)
Replica_SQL_Running: No          → Lỗi khi apply SQL (thường do data conflict)
Seconds_Behind_Source: 3600      → Replica đang lag 1 tiếng — quá tải hoặc slow query
```

---

### 1.2 MongoDB Replication — Replica Set

> **Khái niệm:** MongoDB không gọi là Master-Slave mà là **Replica Set** — một nhóm các MongoDB instance giữ cùng một bộ dữ liệu. Khác MySQL, MongoDB có cơ chế **bầu cử tự động (election)** khi Primary gặp sự cố.

#### Kiến trúc Replica Set

```
┌─────────────────────────────────────────────────────────────┐
│                    REPLICA SET (3 nodes)                     │
│                                                             │
│   ┌──────────────┐    oplog sync    ┌──────────────────┐   │
│   │   PRIMARY    │ ───────────────► │   SECONDARY 1    │   │
│   │              │                  │                  │   │
│   │ Reads+Writes │ ◄─── Heartbeat ──│  Read (optional) │   │
│   │ oplog source │  (every 2 sec)   │  Votes in elect. │   │
│   └──────┬───────┘                  └──────────────────┘   │
│          │                                                   │
│          │ oplog sync    ┌──────────────────┐               │
│          └─────────────► │   SECONDARY 2    │               │
│                          │  (or ARBITER)    │               │
│                          │  Votes in elect. │               │
│                          └──────────────────┘               │
└─────────────────────────────────────────────────────────────┘

ARBITER: Node đặc biệt — chỉ tham gia bầu cử, không lưu data
         Dùng khi muốn có số node lẻ mà không muốn tốn tài nguyên
```

#### Cơ chế Election — Điểm khác biệt lớn nhất so với MySQL

```
Kịch bản: Primary bị crash
                    │
     Sau 10 giây không nhận heartbeat
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│              QUÁ TRÌNH BẦU CỬ                       │
│                                                     │
│ 1. Secondary nhận ra Primary mất                   │
│ 2. Secondary tự đề cử (candidate)                  │
│ 3. Gửi RequestVote đến các node khác               │
│ 4. Node có oplog mới nhất + priority cao nhất thắng│
│ 5. Cần đa số phiếu (majority): 3 nodes → cần 2    │
│ 6. Winner trở thành PRIMARY mới                    │
│ 7. Toàn bộ quá trình: ~10-30 giây                  │
│                                                     │
│ ✅ TỰ ĐỘNG — không cần can thiệp thủ công          │
│ ❌ MySQL cần DBA can thiệp failover thủ công        │
└─────────────────────────────────────────────────────┘
```

#### Oplog — Tương đương Binary Log của MySQL

```javascript
// Oplog (Operations Log) lưu trong collection capped đặc biệt:
use local
db.oplog.rs.find().sort({$natural:-1}).limit(3).pretty()

 Kết quả mẫu:
{
  "ts": Timestamp(1706000001, 1),   // Thời điểm operation
  "op": "i",                         // i=insert, u=update, d=delete
  "ns": "ecommerce.orders",          // namespace: db.collection
  "o": { "_id": ObjectId("..."), "total": 500000 }  // document
}

// Secondary liên tục đọc oplog của Primary và apply vào local
```

#### So sánh MySQL Replication vs MongoDB Replica Set

| Tiêu chí | MySQL Replication | MongoDB Replica Set |
|---|---|---|
| **Failover** | Thủ công (hoặc dùng Orchestrator/MHA) | ✅ Tự động (Election ~10-30s) |
| **Log mechanism** | Binary Log (binlog) | Oplog (capped collection) |
| **Số replica tối đa** | Không giới hạn | 50 members, 7 có quyền vote |
| **Đọc từ Replica** | Cần cấu hình app | Cấu hình ReadPreference |
| **Consistency đọc** | Eventual (mặc định) | Tunable (local/majority/linearizable) |
| **Cấu hình** | File config + SQL commands | Replica Set config document |
| **Monitoring** | `SHOW REPLICA STATUS` | `rs.status()` |

---

