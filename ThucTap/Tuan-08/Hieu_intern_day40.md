# Báo cáo thực tập ngày  40 - Thực hành database
# IX. Xu Hướng và Công Nghệ Mới
 
## 1. Database as a Service (DBaaS)
 
DBaaS là mô hình cung cấp database qua cloud mà không yêu cầu người dùng tự quản lý hạ tầng bên dưới (cài đặt, vá lỗi, backup, scaling). Nhà cung cấp cloud chịu trách nhiệm toàn bộ tầng vận hành.
 
### Ưu điểm
 
- Không cần DBA chuyên biệt cho hạ tầng
- Auto-scaling, auto-backup, high availability tích hợp sẵn
- Mô hình chi phí Pay-as-you-go, giảm capex đáng kể
- Patching và upgrade tự động, giảm downtime
### Nhược điểm
 
- Vendor lock-in — khó migrate sang provider khác
- Ít kiểm soát tầng OS và engine parameter
- Chi phí tăng cao khi scale lớn so với self-hosted
- Latency tăng nếu app và DB không cùng region
### Các sản phẩm phổ biến
 
| Cloud Provider | Relational | NoSQL | Cache |
|---|---|---|---|
| AWS | RDS, Aurora | DynamoDB | ElastiCache |
| GCP | Cloud SQL, AlloyDB | Firestore, Bigtable | Memorystore |
| Azure | Azure SQL, Flexible Server | Cosmos DB | Azure Cache for Redis |
| Self-hosted / SaaS | PlanetScale, Neon | MongoDB Atlas | Upstash Redis |
 
### Kiến trúc DBaaS điển hình
 
Một deployment DBaaS production-grade thường bao gồm:
 
- **Multi-AZ deployment** — nhân bản qua nhiều Availability Zone
- **Read Replica** — tách tải đọc ra node riêng
- **Automated failover** — tự động chuyển sang replica khi primary down
- **Point-in-Time Recovery (PITR)** — khôi phục về bất kỳ thời điểm nào trong retention window
- **Encryption at rest & in transit** — mặc định bật
---
 
## 2. In-Memory Database
 
Database in-memory lưu toàn bộ hoặc phần lớn dữ liệu trong RAM thay vì disk. Kết quả là độ trễ đọc/ghi giảm từ millisecond xuống microsecond.  
 
Disk I/O là nút thắt lớn nhất của database truyền thống. In-memory loại bỏ hoàn toàn bước truy cập đĩa này, truy xuất dữ liệu chỉ qua bus bộ nhớ.
 
### Phân loại
 
| Loại | Đặc điểm | Sản phẩm |
|---|---|---|
| Pure in-memory  | Dữ liệu mất khi tắt máy | Memcached, Redis  |
| In-memory với persistence | Ghi snapshot / AOF ra disk | Redis, Apache Ignite |
| In-memory OLAP | Phân tích tốc độ cao | SAP HANA, SingleStore, DuckDB |
| Embedded in-memory | Chạy trong process, không cần server | SQLite (`:memory:`), H2 |
 
### Redis — công cụ phổ biến nhất
 
```
Data structures : String, Hash, List, Set, Sorted Set, Stream, HyperLogLog
Persistence     : RDB (snapshot) + AOF (append-only log)
Clustering      : Redis Cluster (sharding tự động), Redis Sentinel (HA)
Use cases       : Cache, session store, pub/sub, leaderboard, rate limiter, queue
```
 
### Khi nào nên dùng In-Memory Database?
 
- Session / token storage cho web application
- Cache layer trước RDBMS (giảm tải query nặng)
- Leaderboard và counter real-time
- Rate limiting cho API gateway
- Pub/Sub messaging giữa các microservice
- Lua scripting cho atomic operations phức tạp
---
 
## 3. Blockchain Database
 
Blockchain là một **distributed append-only ledger** — chuỗi các block dữ liệu liên kết với nhau bằng cryptographic hash. Mỗi block chứa hash của block trước nên không thể sửa/xóa mà không phá vỡ toàn bộ chuỗi.
 
### Đặc tính kỹ thuật
 
| Tính chất | Mô tả |
|---|---|
| Immutability | Dữ liệu đã ghi không thể thay đổi hay xóa |
| Decentralization | Không có single point of control hay failure |
| Transparency | Mọi node đều có thể verify toàn bộ lịch sử |
| Consensus | Đồng thuận trước khi ghi (PoW, PoS, PBFT, Raft) |
| Cryptographic integrity | Hash chain đảm bảo tính toàn vẹn |
 
### So sánh với RDBMS truyền thống
 
| Tiêu chí | RDBMS | Blockchain DB |
|---|---|---|
| Tốc độ ghi | Rất cao (millisecond) | Thấp (giây đến phút) |
| Cập nhật / Xóa | Có đầy đủ | Không — chỉ append |
| Truy vấn | SQL linh hoạt | Hạn chế |
| Trust model | Centralized, tin tưởng admin | Trustless, phi tập trung |
| Throughput | Hàng nghìn TPS | Hàng chục đến vài trăm TPS |
| Use case | Business applications | Audit trail, supply chain |
 
### Ứng dụng thực tế
 
- **Supply chain**: Theo dõi hàng hóa từ nguồn gốc đến tay người tiêu dùng
- **Tài chính**: Chuyển tiền quốc tế, thanh toán xuyên biên giới, DeFi
- **Healthcare**: Chia sẻ hồ sơ bệnh nhân có kiểm soát giữa các bệnh viện
- **Digital identity**: Xác thực danh tính phi tập trung, chống làm giả chứng chỉ
  
### Sản phẩm blockchain database
 
- **BigchainDB** — blockchain + database truy vấn
- **Amazon QLDB** — centralized immutable ledger
- **Hyperledger Fabric** — blockchain doanh nghiệp, permissioned
- **Azure Confidential Ledger** — ledger tamper-proof trên Azure
> **Lưu ý thực tế:** 90% use case thực tế không cần blockchain thật sự. Amazon QLDB hoặc immutable audit log table trong PostgreSQL/MySQL thường là đủ và đơn giản hơn nhiều. Chỉ dùng blockchain khi thực sự cần: trustless + multi-party + không có central authority.
 
---
 
## 4. AI và Machine Learning trong Quản trị Database
 
AI đang được nhúng vào nhiều tầng của database ecosystem, từ query optimization đến autonomous operations.
 
### 4.1 Autonomous Database
 
Oracle Autonomous Database, Google AlloyDB AI, Amazon Aurora ML — các hệ thống này tự động:
 
- Tuning index mà không cần DBA can thiệp
- Auto-scaling theo workload pattern học được
- Tự phát hiện và vá lỗi bảo mật
- Dự báo storage growth và cảnh báo trước

### 4.2 Query Optimization bằng ML
 
Truyền thống: Query optimizer dùng cost-based estimation từ statistics tĩnh. ML thay thế bằng mô hình học từ lịch sử thực thi query thực tế:
 
- **Bao** (Learned Query Optimizer) — extension cho PostgreSQL
- **MySQL HeatWave** — ML accelerator tích hợp trong MySQL
- **Learned cardinality estimation** — dự báo số row chính xác hơn hint-based
### 4.3 Anomaly Detection & Security
 
- Phát hiện query pattern bất thường (SQL injection pattern, data exfiltration)
- Dự báo slow query trước khi xảy ra dựa trên pattern lịch sử
- **AWS GuardDuty for RDS** — threat detection tích hợp
- **Azure Defender for SQL** — advanced threat protection
### 4.4 Vector Database — AI-native Storage
 
Vector database được thiết kế để lưu và tìm kiếm **vector embedding** — dữ liệu đầu ra của AI model (text, image, audio dạng mảng số nhiều chiều).
 
**Ứng dụng:**
- RAG (Retrieval Augmented Generation) cho LLM chatbot
- Semantic search (tìm nghĩa, không chỉ tìm từ khóa)
- Recommendation engine
- Image similarity search
- Long-term memory cho AI agent
**Sản phẩm phổ biến:**
 
| Sản phẩm | Loại | Ghi chú |
|---|---|---|
| Pinecone | Managed cloud | Dễ dùng, production-ready |
| Weaviate | Open source / Cloud | Hỗ trợ GraphQL |
| Qdrant | Open source / Cloud | Viết bằng Rust, hiệu năng cao |
| Milvus | Open source | Scale lớn, self-hosted |
| pgvector | PostgreSQL extension | Tích hợp thẳng vào PostgreSQL |
| ChromaDB | Open source | Embedded, dùng cho local/dev |
 
**Cách hoạt động:**
 
```
Text → Embedding model (OpenAI, BERT, ...) → Vector [0.12, -0.45, 0.88, ...]
                                                          ↓
                                               Lưu vào Vector DB
                                                          ↓
Query text → Embed → ANN search (cosine similarity) → Top-K kết quả
```
 
### 4.5 NL2SQL — Truy vấn bằng ngôn ngữ tự nhiên
 
AI có thể dịch câu hỏi ngôn ngữ tự nhiên thành câu lệnh SQL chính xác:
 
- GitHub Copilot tích hợp trong database IDE
- Google Gemini trong BigQuery
- Text2SQL trong Tableau, Power BI
- Claude/GPT tích hợp qua API trong internal tool
---


# X. Thực Hành
 
---
 
## Lab 1 — MySQL/MariaDB: Cài đặt, Cấu hình, Backup/Restore
 
### Cài đặt MySQL 8.0 trên Ubuntu 22.04
 
```bash
sudo apt update
sudo apt install -y mysql-server
 
# Kiểm tra service
sudo systemctl status mysql
sudo systemctl enable mysql
 
# Bảo mật ban đầu
sudo mysql_secure_installation
```
 
### Cấu hình `/etc/mysql/mysql.conf.d/mysqld.cnf` cho production
 
```ini
[mysqld]
# Basic
bind-address            = 0.0.0.0
port                    = 3306
user                    = mysql
 
# InnoDB Performance Tuning
innodb_buffer_pool_size     = 4G          # 70-80% RAM của server
innodb_buffer_pool_instances = 4      
innodb_log_file_size        = 512M
innodb_flush_log_at_trx_commit = 1     
innodb_flush_method         = O_DIRECT
 
# Connection
max_connections         = 500
thread_cache_size       = 50
wait_timeout            = 300
interactive_timeout     = 300
 
# Slow query log
slow_query_log          = 1
slow_query_log_file     = /var/log/mysql/mysql-slow.log
long_query_time         = 1           
 
# Binary log — cần cho replication và PITR
log_bin                 = /var/log/mysql/mysql-bin.log
binlog_format           = ROW
expire_logs_days        = 7
server-id               = 1
```
### Backup với `mysqldump`
 
```bash
# Logical backup toàn bộ instance
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --all-databases \
  --master-data=2 \
  > /backup/full_$(date +%Y%m%d_%H%M%S).sql
 
# Backup một database cụ thể
mysqldump -u root -p mydb > /backup/mydb_$(date +%Y%m%d).sql
 
# Nén để tiết kiệm dung lượng
mysqldump -u root -p mydb | gzip > /backup/mydb_$(date +%Y%m%d).sql.gz
```
 
### Restore
 
```bash
# Restore từ file SQL
mysql -u root -p mydb < /backup/mydb_20240115.sql
 
# Restore từ file nén
gunzip < /backup/mydb_20240115.sql.gz | mysql -u root -p mydb
```
 
### Physical Backup với Percona XtraBackup (hot backup — không lock table)
 
```bash
sudo apt install percona-xtrabackup-80
 
# Full backup
xtrabackup --backup \
  --user=root --password=secret \
  --target-dir=/backup/xtrabackup/full
 
# Prepare — apply redo log trước khi restore
xtrabackup --prepare --target-dir=/backup/xtrabackup/full
 
# Restore
sudo systemctl stop mysql
sudo rm -rf /var/lib/mysql/*
xtrabackup --copy-back --target-dir=/backup/xtrabackup/full
sudo chown -R mysql:mysql /var/lib/mysql
sudo systemctl start mysql
```
 
---

## Lab 2 — MySQL Master-Slave Replication
### Cấu hình trên Master (server-id=1)
 
`my.cnf` đã có `log_bin` và `server-id=1` từ Lab 1.
 
```bash
# Tạo user replication
mysql -u root -p <<EOF
CREATE USER 'replicator'@'%' IDENTIFIED BY 'StrongPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF
# Ghi lại giá trị File và Position từ output
```
 
### Cấu hình trên Slave (server-id=2)
 
Thêm vào `/etc/mysql/mysql.conf.d/mysqld.cnf`:
 
```ini
server-id   = 2
relay-log   = /var/log/mysql/mysql-relay-bin.log
read_only   = 1
```
 
```bash
# Kết nối Slave đến Master
mysql -u root -p <<EOF
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='replicator',
  MASTER_PASSWORD='StrongPass123!',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
START SLAVE;
SHOW SLAVE STATUS\G
EOF
```
 
**Kiểm tra replication hoạt động bình thường:**
 
```
Slave_IO_Running  : Yes
Slave_SQL_Running : Yes
Seconds_Behind_Master : 0
```
 
---
## Lab 3 — MySQL InnoDB Cluster (Group Replication)
 
### Cài đặt MySQL Shell
 
```bash
sudo apt install mysql-shell
```
 
### Cấu hình `/etc/hosts` trên cả 3 node
 
```
192.168.1.10  node1
192.168.1.11  node2
192.168.1.12  node3
```
 
### Khởi tạo cluster từ MySQL Shell
 
```javascript
// Kết nối vào node1
mysqlsh root@node1
 
// Configure từng node
dba.configureInstance('root@node1:3306')
dba.configureInstance('root@node2:3306')
dba.configureInstance('root@node3:3306')
 
// Tạo cluster
var cluster = dba.createCluster('myCluster')
cluster.addInstance('root@node2:3306')
cluster.addInstance('root@node3:3306')
cluster.status()
```
 
### Cài MySQL Router để load balance
 
```bash
sudo apt install mysql-router
 
mysqlrouter --bootstrap root@node1:3306 \
  --directory /etc/mysqlrouter \
  --user=mysqlrouter
 
sudo systemctl start mysqlrouter
```
 
**Kết nối từ application qua Router:**
 
| Port | Chức năng |
|---|---|
| 6446 | Read/Write → Primary node |
| 6447 | Read-Only → Secondary nodes |
 
---
 
## Lab 4 — PostgreSQL: Cài đặt, Tuning, Streaming Replication
 
### Cài đặt PostgreSQL 16
 
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
 
# Đăng nhập
sudo -u postgres psql
```
 
### Cấu hình `/etc/postgresql/16/main/postgresql.conf`
 
```ini
# Memory
shared_buffers          = 2GB          # 25% RAM
effective_cache_size    = 6GB          # 75% RAM
work_mem                = 64MB         # Per sort / join operation
maintenance_work_mem    = 512MB        # VACUUM, CREATE INDEX
 
# WAL & Replication
wal_level               = replica
max_wal_senders         = 10
wal_keep_size           = 1GB
archive_mode            = on
archive_command         = 'cp %p /archive/%f'
 
# Query Planner
random_page_cost        = 1.1          # SSD: 1.1 | HDD: 4.0
effective_io_concurrency = 200         # SSD: 200 | HDD: 2
 
# Logging
log_min_duration_statement = 1000     # Log query chạy > 1 giây
log_checkpoints         = on
log_connections         = on
log_lock_waits          = on
 
# Connection
max_connections         = 200
listen_addresses        = '*'
```
 
### Backup với `pg_dump`
 
```bash
# Logical backup (custom format, nén)
pg_dump -U postgres -d mydb -F c -f /backup/mydb_$(date +%Y%m%d).dump
 
# Restore
pg_restore -U postgres -d mydb_new /backup/mydb_20240115.dump
```
 
### Physical Backup với `pg_basebackup`
 
```bash
pg_basebackup -h localhost -U replicator \
  -D /backup/pgbackup \
  -Ft -z -Xs -P
```
 
### Streaming Replication
 
**Trên Primary:**
 
```bash
sudo -u postgres psql -c \
  "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'secret';"
 
# Thêm vào pg_hba.conf
echo "host replication replicator 192.168.1.0/24 md5" \
  >> /etc/postgresql/16/main/pg_hba.conf
 
sudo systemctl reload postgresql
```
 
**Trên Standby:**
 
```bash
# Clone từ primary (tùy chọn -R tự tạo standby.signal)
pg_basebackup -h 192.168.1.10 -U replicator \
  -D /var/lib/postgresql/16/main \
  -P -Xs -R
 
sudo systemctl start postgresql
```
 
**Kiểm tra trên Primary:**
 
```sql
SELECT * FROM pg_stat_replication;
```
 
---
 
## Lab 5 — MongoDB: Cài đặt, Replica Set, Backup
 
### Cài đặt MongoDB 7.0
 
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
 
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
 
sudo apt update && sudo apt install -y mongodb-org
sudo systemctl enable mongod && sudo systemctl start mongod
```
 
### Cấu hình `/etc/mongod.conf`
 
```yaml
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 4    
 
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
 
net:
  port: 27017
  bindIp: 0.0.0.0
 
replication:
  replSetName: "rs0"
 
security:
  authorization: enabled
  keyFile: /etc/mongodb/keyfile   
```
 
### Khởi tạo Replica Set (3 node)
 
```bash
mongosh --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 1 }
  ]
})'
 
# Kiểm tra
mongosh --eval "rs.status()"
```
 
### Backup với `mongodump`
 
```bash
# Backup toàn bộ
mongodump \
  --uri="mongodb://admin:pass@localhost:27017" \
  --authenticationDatabase=admin \
  --out=/backup/mongo_$(date +%Y%m%d)
 
# Backup một collection cụ thể
mongodump \
  --db=mydb \
  --collection=orders \
  --out=/backup/orders_$(date +%Y%m%d)
```
 
### Restore với `mongorestore`
 
```bash
mongorestore \
  --uri="mongodb://admin:pass@localhost:27017" \
  --authenticationDatabase=admin \
  /backup/mongo_20240115/
```
 
---
 
## Lab 6 — Redis: Cài đặt, Persistence, Sentinel
 
### Cài đặt Redis 7
 
```bash
sudo apt install -y redis-server
```
 
### Cấu hình `/etc/redis/redis.conf`
 
```ini
# Network
bind 0.0.0.0
port 6379
requirepass "YourStrongPassword"
 
# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru     # Evict key ít dùng nhất khi đầy bộ nhớ
 
# Persistence — RDB Snapshot
save 900 1       # 1 key thay đổi trong 900 giây → save
save 300 10      # 10 key trong 300 giây
save 60 10000    # 10000 key trong 60 giây
dbfilename dump.rdb
dir /var/lib/redis
 
# Persistence — AOF (độ bền cao hơn RDB)
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec    # everysec = cân bằng | always = an toàn nhất | no = nhanh nhất
 
# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
```
 
### Redis Sentinel (HA — tự động failover)
 
Tạo `/etc/redis/sentinel.conf` trên mỗi Sentinel node:
 
```ini
sentinel monitor mymaster 192.168.1.10 6379 2
sentinel auth-pass mymaster YourStrongPassword
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
```
 
```bash
# Khởi động Sentinel
redis-sentinel /etc/redis/sentinel.conf
 
# Kiểm tra
redis-cli -p 26379 SENTINEL masters
redis-cli -p 26379 SENTINEL slaves mymaster
```
 
### Các lệnh Redis CLI thường dùng
 
```bash
redis-cli -a YourStrongPassword
 
# String với TTL (session storage)
SET session:user123 '{"id":123,"name":"Nguyen Van A"}' EX 3600
GET session:user123
TTL session:user123
 
# Counter (rate limiting)
INCR api:rate:192.168.1.1
EXPIRE api:rate:192.168.1.1 60
 
# List (queue)
LPUSH queue:jobs "job1" "job2"
RPOP queue:jobs
 
# Monitor real-time commands
redis-cli -a YourStrongPassword MONITOR
 
# Thống kê hệ thống
redis-cli -a YourStrongPassword INFO memory
redis-cli -a YourStrongPassword INFO replication
```
 
---
 
