# Báo cáo thực tập ngày 22 - Hệ Quản Trị Cơ Sở Dữ Liệu (DBMS)

---
## 1. Khái niệm về DBMS
DBMS là phần mềm quản lý việc lưu trữ, truy xuất và bảo vệ dữ liệu. Nhiệm vụ cốt lõi của DBMS là cung cấp một môi trường an toàn, hiệu quả và nhất quán để thực hiện các thao tác CRUD:  
Create (Tạo mới): Tạo cơ sở dữ liệu, bảng, hoặc thêm dữ liệu mới.  
Read (Đọc): Truy vấn, tìm kiếm và trích xuất dữ liệu.  
Update (Cập nhật): Sửa đổi dữ liệu đã có.  
Delete (Xóa): Xóa dữ liệu không còn sử dụng.  

Ngoài ra, DBMS còn lo các tác vụ "ngầm" như bảo mật, sao lưu, phục hồi dữ liệu và kiểm soát việc nhiều người cùng truy cập vào một dữ liệu cùng lúc (Concurrency Control).  

#### Phân loại chính
Relational (SQL): Lưu dữ liệu theo dạng bảng (Cột và Hàng) có cấu trúc chặt chẽ. Gồm: MySQL/MariaDB, SQL Server, Oracle, PostgreSQL.  
Non-Relational (NoSQL): Lưu dữ liệu linh hoạt, không gò bó theo bảng. Gồm: MongoDB (dạng tài liệu JSON) và Redis (dạng Key-Value trên RAM).  

#### MySQL / MariaDB
SQL Open source Web stack  
Phổ biến nhất web (LAMP stack). MariaDB là fork của MySQL — tương thích cao, hiệu năng tốt hơn một số use-case. Dùng cho CRUD thông thường, CMS, e-commerce  

#### Microsoft SQL Server  
SQL Enterprise Windows/.NET  
Mạnh trong hệ sinh thái Microsoft. Tích hợp tốt với Windows Server, Active Directory. Có bản Express miễn phí. Thường gặp trong doanh nghiệp lớn, ERP, BI.  

#### MongoDB
NoSQL Document JSON-like  
Lưu dữ liệu dạng document (BSON/JSON). Schema linh hoạt — không cần ALTER TABLE. Tốt cho dữ liệu không đồng nhất, catalog sản phẩm, content platform.  

#### Redis
NoSQL In-memory Cache / Queue  
Lưu trên RAM → cực nhanh (sub-millisecond). Thường dùng làm cache, session store, message queue, rate limiter. Không phải DB chính — là lớp tăng tốc.  

## So Sánh Các Hệ Quản Trị Cơ Sở Dữ Liệu (DBMS)

| Hệ thống | Loại DBMS | Ưu điểm nổi bật | Nhược điểm | Ứng dụng phổ biến |
|---|---|---|---|---|
| **MySQL / MariaDB** | SQL (Mã nguồn mở) | Rất nhanh, nhẹ, dễ sử dụng, cộng đồng hỗ trợ lớn. Hoạt động cực kỳ ổn định với các ứng dụng Web. | Xử lý các truy vấn quá phức tạp hoặc phân tích dữ liệu lớn (Big Data) kém hơn PostgreSQL/Oracle. | Làm database cho website, blog (WordPress), ứng dụng web vừa và nhỏ. |
| **PostgreSQL** | SQL (Mã nguồn mở) | Tuân thủ tiêu chuẩn SQL cực kỳ nghiêm ngặt. Xử lý dữ liệu không gian (GIS), kiểu dữ liệu phức tạp (JSON, mảng) và truy vấn siêu nặng rất tốt. | Tốn nhiều RAM hơn MySQL do kiến trúc tạo Process riêng cho mỗi kết nối. Khó cấu hình tối ưu ban đầu. | Hệ thống tài chính, ứng dụng phân tích dữ liệu chuyên sâu, hệ thống ERP. |
| **Microsoft SQL Server** | SQL (Thương mại) | Tích hợp hoàn hảo với hệ sinh thái Microsoft (.NET, C#, Azure). Cung cấp bộ công cụ quản lý đồ họa (SSMS) cực kỳ mạnh mẽ và trực quan. | Chi phí bản quyền (License) rất đắt đỏ. Dù đã có bản cho Linux nhưng chạy tốt nhất vẫn là trên Windows Server. | Phần mềm doanh nghiệp, phần mềm kế toán, hệ thống sử dụng công nghệ Microsoft. |
| **Oracle Database** | SQL (Thương mại) | "Vua" của DBMS về độ tin cậy, bảo mật và khả năng mở rộng. Xử lý khối lượng dữ liệu khổng lồ cho các tập đoàn lớn mà không bị crash. | Giá cực kỳ đắt. Đòi hỏi quản trị viên (DBA) phải có trình độ chuyên môn rất cao để vận hành. | Hệ thống ngân hàng, viễn thông, tập đoàn đa quốc gia. |
| **MongoDB** | NoSQL (Document) | Dữ liệu lưu dưới dạng JSON siêu linh hoạt (không cần tạo cấu trúc cột trước). Dễ dàng mở rộng ngang (Scale-out) trên nhiều server. | Tốn nhiều dung lượng lưu trữ hơn SQL. Không hỗ trợ tốt các giao dịch phức tạp (Complex Transactions) đòi hỏi tính toàn vẹn cao. | Ứng dụng Real-time, mạng xã hội, IoT, hệ thống lưu trữ log, ứng dụng có cấu trúc dữ liệu thay đổi liên tục. |
| **Redis** | NoSQL (In-memory) | Tốc độ truy xuất dữ liệu cực nhanh (micro-second) vì toàn bộ dữ liệu được lưu trên RAM. | Lưu trên RAM nên chi phí tài nguyên cao. Dữ liệu có thể mất nếu server tắt đột ngột (dù có cơ chế persist xuống disk). | Cache, Session đăng nhập, View Counter, Queue, Leaderboard, Rate Limiting. |

---

## Tiêu chí lựa chọn DBMS
Cấu trúc dữ liệu: Dữ liệu có schema cố định, quan hệ phức tạp → SQL. Dữ liệu thay đổi liên tục, nested JSON → NoSQL.  
Yêu cầu hiệu năng: Cần cache, tốc độ ms → Redis. Cần write throughput cao, phân tán → MongoDB/Cassandra. 
Môi trường & hệ sinh thái: Stack .NET / Windows → MSSQL. Stack LAMP/LEMP → MySQL. Cloud-native → xem managed services (RDS, Atlas…)  
Chi phí & license: MySQL/MariaDB/MongoDB Community/Redis OSS = miễn phí. MSSQL/Oracle = license đắt. Cân nhắc TCO (Total Cost of Ownership).  
Compliance & bảo mật: Dữ liệu tài chính, y tế → cần ACID + audit log → SQL. MSSQL/Oracle có tooling compliance mạnh nhất.  

---

## Microsoft SQL Server: cài đặt, cấu hình hiệu năng và bảo mật
*Thông tin cơ bản*  
Nhà phát triển: Microsoft  
Phiên bản mới nhất: SQL Server 2022  
Chạy trên: Windows, Linux, Docker  
Default port: 1433  
License: Trả phí (có bản Express miễn phí)  

Khi app gửi query → SQL Server Engine nhận → Query Optimizer chọn execution plan tối ưu → đọc/ghi data qua Buffer Pool (RAM cache) → nếu data chưa trong RAM thì mới đọc từ disk.  

### Cài đặt và cấu hình 
1 Import GPG key & thêm repository
Xác thực package từ Microsoft trước khi cài.
````
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
````
<img width="784" height="304" alt="{E4BA8849-BF1D-48BE-B62B-6F30F7A4AB6B}" src="https://github.com/user-attachments/assets/21570bba-c895-4cf6-a653-bc408253f6fd" />

2 Cài SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server  

3 Chạy setup ban đầu  
````
Wizard này sẽ hỏi bạn chọn edition và đặt password cho SA (System Administrator).
sudo /opt/mssql/bin/mssql-conf setup # Wizard hỏi: # 1) Choose edition: Developer (free) → nhập "2" # 2) Accept license: Yes # 3) SA password: đặt password phức tạp (≥8 ký tự)
Lưu ý: SA là tài khoản sysadmin cấp cao nhất. Đặt password mạnh và không dùng SA cho app thông thường (sẽ học ở phần Bảo mật).
````
4 Kiểm tra service đang chạy
sudo systemctl status mssql-server
sudo systemctl enable mssql-server # auto-start khi reboot  
5 Cài sqlcmd — công cụ CLI để thao tác DB
````
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-tools.list
# Lệnh 2: Cập nhật danh sách gói
sudo apt-get update
# Lệnh 3: Cài đặt mssql-tools và unixodbc-dev
sudo apt-get install -y mssql-tools18 unixodbc-dev
# Lệnh 4: Thêm công cụ vào biến môi trường PATH
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
# Lệnh 5: Áp dụng thay đổi cấu hình
source ~/.bashrc
````
6 Test kết nối lần đầu
````
sqlcmd -S localhost -U SA -P 'Iamhieu2026a@' -C
Trong sqlcmd prompt: SELECT @@VERSION
GO

````
<img width="431" height="33" alt="{48ACBD80-98F8-4F8C-9F9B-03B9C59A2DFF}" src="https://github.com/user-attachments/assets/eec8aaee-a460-4231-9e89-edd0a97bdeb7" />

<img width="496" height="202" alt="{6B4D141C-63C7-4C6A-8494-7AD2EF280F33}" src="https://github.com/user-attachments/assets/8f4d0896-7b9c-4f2e-9fe3-f01711204721" />

---
### Cấu hình hiệu năng 
/var/opt/mssql/mssql.conf : file cấu hình hiệu năng  
 1. Giới hạn RAM — quan trọng nhất
```
[memory] memorylimitmb = 4096 # Giới hạn 4GB
Hoặc
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 4096
```
2.Tách data, log, backup ra ổ đĩa riêng  
```
# Tạo thư mục với đúng permission
sudo mkdir -p /mnt/data/mssql/{data,log,backup}
sudo chown mssql:mssql /mnt/data/mssql/{data,log,backup}
# Cấu hình đường dẫn mặc định
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /mnt/data/mssql/data
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /mnt/data/mssql/log
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultbackupdir /mnt/data/mssql/backup
sudo systemctl restart mssql-server
```
3. Kiểm tra hiệu năng thực tế  
````
Xem các query đang chạy chậm nhất
SELECT TOP 10 total_elapsed_time / execution_count AS avg_ms, execution_count, SUBSTRING(st.text, 1, 100) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_ms DESC;
-- Xem memory usage hiện tại
SELECT physical_memory_in_use_kb / 1024 AS memory_mb, page_fault_count
FROM sys.dm_os_process_memory;
````
<img width="742" height="404" alt="{DFBE9D5F-EA77-45BA-A73F-9CE1C2128007}" src="https://github.com/user-attachments/assets/e33d81d1-cf81-4c32-8310-06b97c711748" />

----
 ### Bảo mật cơ bản
 #### 1. Vô hiệu hóa tài khoản SA 
```
CREATE LOGIN dba_admin WITH PASSWORD = 'Str0ngP@ssw0rd!';
ALTER SERVER ROLE sysadmin ADD MEMBER dba_admin; 
-- Tạo login riêng cho từng app (quyền tối thiểu) 
CREATE LOGIN app_myapp WITH PASSWORD = 'AppP@ss456!';
-- Disable SA 
ALTER LOGIN SA DISABLE;
ALTER LOGIN SA WITH NAME = sa_disabled; -- đổi tên thêm
```

#### 2. Cấp quyền đúng mức
```
-- Chọn database cần thao tác
USE MyAppDB;
-- Tạo user từ login đã tạo ở bước 1
CREATE USER app_myapp FOR LOGIN app_myapp;
-- Cấp các quyền cơ bản trên các bảng dữ liệu
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO app_myapp;
-- LƯU Ý: KHÔNG bao giờ cấp các quyền phá hoại như DROP, ALTER, TRUNCATE cho app.
```
#### 3. Bật mã hóa kết nối TLS
```
# 1. Tạo chứng chỉ tự ký (Self-signed certificate) cho môi trường Dev
openssl req -x509 -nodes -newkey rsa:2048 \
  -subj "/CN=mssql-server" \
  -keyout /etc/ssl/private/mssql.key \
  -out /etc/ssl/certs/mssql.pem -days 365

# 2. Cấp quyền sở hữu file chứng chỉ cho dịch vụ mssql
sudo chown mssql:mssql /etc/ssl/private/mssql.key
sudo chmod 600 /etc/ssl/private/mssql.key

# 3. Cấu hình SQL Server sử dụng chứng chỉ này và ép buộc mã hóa
sudo /opt/mssql/bin/mssql-conf set network.tlscert /etc/ssl/certs/mssql.pem
sudo /opt/mssql/bin/mssql-conf set network.tlskey /etc/ssl/private/mssql.key
sudo /opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
sudo /opt/mssql/bin/mssql-conf set network.forceencryption 1

# 4. Khởi động lại dịch vụ để áp dụng
sudo systemctl restart mssql-server
```

#### 4.Firewall
```
# 1. Bật tường lửa UFW
sudo ufw enable
# 2. Tạo luật (rule): Chỉ cho phép IP 10.0.1.50 kết nối vào port 1433
sudo ufw allow from 10.0.1.50 to any port 1433
# 3. Kiểm tra lại trạng thái tường lửa
sudo ufw status verbose
```
#### 5. Bật audit log
```
-- 1. Tạo Audit chỉ định nơi lưu file log trên máy chủ Linux
CREATE SERVER AUDIT SecurityAudit 
TO FILE (FILEPATH = '/var/opt/mssql/audit/');

-- 2. Chỉ định điều kiện ghi log: Ghi lại các lần đăng nhập thất bại
CREATE SERVER AUDIT SPECIFICATION AuditLogins 
FOR SERVER AUDIT SecurityAudit 
ADD (FAILED_LOGIN_GROUP);

-- 3. Bật tính năng Audit
ALTER SERVER AUDIT SecurityAudit WITH (STATE = ON);
ALTER SERVER AUDIT SPECIFICATION AuditLogins WITH (STATE = ON);
```
---
 ## MySQL/MariaDB: cài đặt, cấu hình hiệu năng và bảo mật
 MariaDB là một fork của MySQL, được tạo ra vào năm 2009 sau khi Oracle mua lại Sun Microsystems.  
Cú pháp SQL của MariaDB gần như tương thích hoàn toàn với MySQL, vì vậy người dùng MySQL có thể chuyển sang MariaDB rất dễ dàng.

---

| Tiêu chí | MySQL 8.0 | MariaDB 11.x |
|---|---|---|
| **Nguồn gốc** | Oracle Corporation phát triển | Fork từ MySQL bởi cộng đồng MariaDB Foundation |
| **License** | GPL + Oracle Commercial | GPL thuần — hoàn toàn mã nguồn mở |
| **Storage Engine** | InnoDB (mặc định) | InnoDB + Aria + MyRocks + nhiều engine khác |
| **JSON Support** | Native JSON type mạnh hơn | Hỗ trợ JSON đủ dùng, đang cải thiện dần |
| **Replication** | Replication tiêu chuẩn | Hỗ trợ Galera Cluster Multi-Master tốt hơn |
| **Hiệu năng** | Tối ưu tốt cho workload phổ biến | Nhiều benchmark cho thấy nhanh hơn MySQL |
| **Cloud Support** | Được hỗ trợ mạnh trên AWS RDS, Azure | Ít managed service hơn |
| **Độ phổ biến** | Rất phổ biến trong enterprise | Phổ biến trong môi trường self-hosted |
| **Khả năng tương thích** | Chuẩn ecosystem MySQL | Tương thích phần lớn với MySQL |
| **Dùng khi nào** | Cloud managed, enterprise standard | Self-hosted, full open-source, cluster |


### Cài đặt mariadb
#### Bước 1: Cài MariaDB từ official repo
```
 sudo apt update 
 sudo apt install -y mariadb-server mariadb-client
```
#### Bước 2: Khởi động & bật auto-start
sudo systemctl start mariadb 
sudo systemctl enable mariadb
sudo systemctl status mariadb

#### Bước 3: Chạy script bảo mật ban đầu  
sudo mysql_secure_installation
````
# Trả lời theo hướng dẫn:
# Enter current root password: (Enter — blank lần đầu) 
# Switch to unix_socket auth? n 
# Change root password? y → đặt password mạnh
# Remove anonymous users? y
# Disallow root login remotely? y 
# Remove test database? y 
# Reload privilege tables? y
````
#### Bước 4: Đăng nhập kiểm tra
```
mysql -u root -p
SELECT VERSION();
SHOW DATABASES; EXIT;
```
<img width="283" height="242" alt="{7598BC39-1B4A-47BD-9CF2-CA1CE6F81DF2}" src="https://github.com/user-attachments/assets/f3bb9622-05a7-48d2-9b82-75a902f92eed" />

### Cài đặt MYSQL 8.0
#### Bước 1: Cài mysql
sudo apt update 
sudo apt install mysql-server -y  

#### Bước 2: Khởi động bảo mật
sudo systemctl enable --now mysql 
sudo mysql_secure_installation

#### Bước 3: Đăng nhập
sudo mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'StrongPass!';
FLUSH PRIVILEGES;

---
## Tối Ưu Hiệu Năng MariaDB
### 1. Kiểm Tra Slow Query

Sau khi bật `slow_query_log`, sử dụng:

```
# Top 10 query chậm nhất
sudo mysqldumpslow -s t -t 10 /var/log/mysql/mysql-slow.log
-- Xem query đang chạy
SHOW FULL PROCESSLIST;
-- Query chạy lâu hơn 5 giây
SELECT id, user, host, db, time, state,
LEFT(info,80)
FROM information_schema.PROCESSLIST
WHERE time > 5
ORDER BY time DESC;
```
### 2. EXPLAIN
```
EXPLAIN
SELECT *
FROM orders o
JOIN customers c
ON o.customer_id = c.id
WHERE o.status = 'pending';
 -- Xem cột "type" trong kết quả:
-- const/eq_ref = tốt nhất (dùng index) -- ref/range = chấp nhận được -- ALL = ĐỌC TOÀN BỘ BẢNG → cần index! -- Nếu type = ALL
 → thêm index:
CREATE INDEX idx_orders_status
ON orders(status);
CREATE INDEX idx_orders_customer
ON orders(customer_id);
```
### 3. Kiểm tra trạng thái InnoDB Buffer Pool
```
SHOW STATUS LIKE 'Innodb_buffer_pool_%';
 -- Tính hit rate (nên > 99%)
SELECT
(1 - Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests) * 100
AS buffer_pool_hit_rate;

```

### 4. Cấu hình connection pool 
````
-- Xem max connections hiện tại
SHOW VARIABLES LIKE 'max_connections';
-- Xem peak connections từ khi khởi động 
SHOW STATUS LIKE 'Max_used_connections'; 
-- Thay đổi không cần restart (tạm thời)
SET GLOBAL max_connections = 300; 
-- Xem connections đang dùng
SHOW STATUS LIKE 'Threads_connected';
````

---
## Bảo mật MySQL/MariaDB
### 1. Kiểm tra và dọn user nguy hiểm
-- Xem tất cả user và host
SELECT user, host, plugin, password_expired 
FROM mysql.user ORDER BY user;
-- Xóa anonymous user (nếu còn sót) 
DELETE FROM mysql.user WHERE user = '';
-- Xóa user không cần thiết 
DROP USER ''@'localhost';
DROP USER ''@'%';
FLUSH PRIVILEGES;

### 2. Password policy — bắt buộc password mạnh
-- Bật plugin validate_password
INSTALL PLUGIN validate_password
SONAME 'validate_password.so';
-- Cấu hình mức độ (MEDIUM yêu cầu chữ hoa, số, ký tự đặc biệt)
SET GLOBAL validate_password_policy = 'MEDIUM';
SET GLOBAL validate_password_length = 12; 
-- Thêm vào my.cnf để persistent sau restart: -- [mysqld] -- validate_password_policy = MEDIUM -- validate_password_length = 12

### 3. Ngăn remote root login & bind address
-- Đảm bảo root chỉ login từ localhost
UPDATE mysql.user
SET host = 'localhost'
WHERE user = 'root'
AND host != 'localhost';
FLUSH PRIVILEGES;
--/etc/mysql/mariadb.conf.d/50-server.cnf — chỉ lắng nghe localhost (không nhận kết nối từ ngoài) -- bind-address = 127.0.0.1 -- Nếu cần remote app kết nối: bind-address = 0.0.0.0 -- nhưng phải kết hợp firewall ufw  

