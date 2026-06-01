# Báo cáo thực tập day 26 - Database Server
---
## PHẦN VI — HIGH AVAILABILITY & SCALABILITY
 
---
 
### 1. Replication
 
#### 1.1 Tổng quan — Tại sao cần Replication?
 
```
Hệ thống KHÔNG có Replication:
┌──────────────┐        ┌──────────────┐
│   APP SERVER │───────►│  DB SERVER   │  ← SPOF!
└──────────────┘        └──────────────┘
                         Server này chết → toàn bộ hệ thống chết
 
Hệ thống CÓ Replication:
┌──────────────┐  Write  ┌──────────────┐
│   APP SERVER │────────►│   PRIMARY    │──── sync ────►┌──────────┐
│              │  Read   └──────────────┘               │ REPLICA 1│
│              │─────────────────────────────────────►  └──────────┘
└──────────────┘                                         ┌──────────┐
                                                         │ REPLICA 2│
                                                         └──────────┘
Primary chết → Promote Replica → Hệ thống tiếp tục chạy
```
 
**Ba mục tiêu chính của Replication:**
 
| Mục tiêu | Giải thích | Ví dụ thực tế |
|---|---|---|
| **High Availability** | Hệ thống tiếp tục hoạt động khi 1 node chết | Promote Replica khi Primary crash |
| **Read Scalability** | Phân tải query SELECT sang nhiều Replica | App đọc từ 3 Replica, ghi vào 1 Primary |
| **Data Protection** | Có bản sao dữ liệu ở nhiều máy | Replica ở datacenter khác → DR |
 
---
 
#### 1.2 MySQL Replication
 
**Cơ chế hoạt động:**
 
```
PRIMARY                          REPLICA
┌─────────────────┐              ┌──────────────────────────┐
│ 1. Client write │              │                          │
│    INSERT/UPDATE│              │  ┌────────────────────┐  │
│    /DELETE      │              │  │    IO Thread       │  │
│                 │              │  │  Kết nối Primary   │  │
│ 2. Ghi Binary   │  Pull binlog │  │  Kéo binlog events │  │
│    Log (binlog) │◄─────────────│  │  Ghi vào Relay Log │  │
│                 │              │  └─────────┬──────────┘  │
│                 │              │            │              │
│                 │              │  ┌─────────▼──────────┐  │
│                 │              │  │    SQL Thread      │  │
│                 │              │  │  Đọc Relay Log     │  │
│                 │              │  │  Apply SQL vào DB  │  │
│                 │              │  └────────────────────┘  │
└─────────────────┘              └──────────────────────────┘
```
 
**Ba chế độ Replication MySQL:**
 
| Chế độ | Ghi log dạng | Ưu điểm | Nhược điểm |
|---|---|---|---|
| **Statement-based** | Câu SQL gốc | Log nhỏ | Hàm như NOW(), RAND() không nhất quán |
| **Row-based** | Từng row thay đổi | Chính xác tuyệt đối | Log lớn hơn |
| **Mixed** | Kết hợp tự động | Cân bằng | Phức tạp debug |
 
```
-- Kiểm tra và thiết lập binlog format
SHOW VARIABLES LIKE 'binlog_format';
SET GLOBAL binlog_format = 'ROW';  -- Khuyến nghị 2026
 
-- Kiểm tra lag Replica
SHOW REPLICA STATUS\G
-- Seconds_Behind_Source: 0   → đồng bộ hoàn toàn
-- Seconds_Behind_Source: 120 → đang lag 2 phút
 
-- Xem binlog events (debug)
SHOW BINARY LOGS;
SHOW BINLOG EVENTS IN 'mysql-bin.000003' LIMIT 20;
```
 
---
### 1.3 SQL Server Replication
 
SQL Server có **4 loại Replication** — đây là điểm khác biệt lớn so với MySQL/MongoDB:
 
```
SQL SERVER REPLICATION TYPES:
 
  1. SNAPSHOT REPLICATION                                     
     Chụp toàn bộ data tại một thời điểm → gửi sang Subscriber
     Dùng khi: data ít thay đổi, đồng bộ theo lịch          
     Ví dụ: Catalog sản phẩm, danh mục, báo cáo cuối ngày   
 
  2. TRANSACTIONAL REPLICATION (Phổ biến nhất)               
     Gần giống MySQL binlog replication                      
     Mỗi transaction được ghi vào Distribution DB → gửi đi  
     Dùng khi: cần real-time, low latency                    
     Ví dụ: OLTP → Read Replica cho reporting

  3. MERGE REPLICATION                                        
     Cả Publisher và Subscriber đều có thể ghi              
     Có cơ chế giải quyết conflict tự động                  
     Dùng khi: app offline, sync lại khi có mạng            
     Ví dụ: App bán hàng trên tablet, đồng bộ về trung tâm 
 
  4. ALWAYS ON AVAILABILITY GROUPS (Enterprise — Hiện đại)   
     Không phải "Replication" truyền thống                   
     Dùng log shipping + sync/async commit                   
     Tự động failover, readable secondaries                  
     Dùng khi: Production enterprise, HA yêu cầu cao        
```
```
-- Kiểm tra trạng thái Availability Group
SELECT ag.name AS AGName,
       ar.replica_server_name,
       ar.availability_mode_desc,   
       ars.role_desc,                
       ars.synchronization_state_desc 
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id;
 
-- Xem lag của Secondary
SELECT database_name,
       log_send_queue_size,        
       redo_queue_size,           
       log_send_rate,              
       redo_rate                
FROM sys.dm_hadr_database_replica_states;
```

### 1.4 MongoDB Replication — Replica Set
 
```
REPLICA SET STRUCTURE:
 
        ┌──────────────────────────────────────────┐
        │            REPLICA SET                    │
        │                                          │
        │  ┌──────────┐   oplog   ┌─────────────┐  │
        │  │ PRIMARY  │──────────►│ SECONDARY 1 │  │
        │  │          │           │  votes: 1   │  │
        │  │votes: 1  │◄──────────│  priority:1 │  │
        │  └────┬─────┘ heartbeat └─────────────┘  │
        │       │                                   │
        │       │ oplog  ┌─────────────┐            │
        │       └───────►│ SECONDARY 2 │            │
        │                │  votes: 1   │            │
        │                │  priority:0 │ ← Hidden   │
        │                │  hidden:true│   Replica  │
        │                └─────────────┘            │
        └──────────────────────────────────────────┘
 
Priority cao hơn → được ưu tiên làm Primary khi election
Hidden=true → không nhận query từ app, dùng cho backup/analytics
```

```
// Khởi tạo Replica Set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },  // Ưu tiên làm Primary
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 0, hidden: true, votes: 1 }
  ]
})
 
// Kiểm tra trạng thái
rs.status()
rs.printReplicationInfo()       // Xem oplog size và lag
rs.printSecondaryReplicationInfo()  // Xem lag từng Secondary
 
// Cấu hình ReadPreference — đọc từ Secondary
db.getMongo().setReadPref("secondaryPreferred")
// Các tùy chọn:
// "primary"            → luôn đọc từ Primary (mặc định)
// "primaryPreferred"   → ưu tiên Primary, dùng Secondary nếu Primary unavailable
// "secondary"          → luôn đọc từ Secondary
// "secondaryPreferred" → ưu tiên Secondary, dùng Primary nếu không có Secondary
// "nearest"            → đọc từ node có latency thấp nhất
```


 **So sánh Replication 3 hệ CSDL:**
 
| Tiêu chí | MySQL 8.4 | SQL Server 2022 | MongoDB 7 |
|---|---|---|---|
| **Log mechanism** | Binary Log | Transaction Log | Oplog |
| **Failover** | Thủ công / Orchestrator | WSFC tự động | Election tự động |
| **Readable Secondaries** | Cần cấu hình | ✅ Always On | ✅ ReadPreference |
| **Số Replica** | Không giới hạn | Up to 8 secondaries | Tối đa 50 members |
| **Sync modes** | Async / Semi-sync | Sync / Async | Tunable WriteConcern |
| **Multi-master** | Group Replication | Không | Không |
| **Tự phát hiện topology** | Không | Qua Listener | ✅ Tự động |
| **Độ phức tạp cấu hình** | Trung bình | Cao | Thấp |
 
---

## 2. Cluster và Failover
 
### 2.1 Khái niệm Cluster
 
```
 
Replication: 1 node làm việc, các node còn lại chờ (Hot Standby)
             Chỉ Primary nhận ghi → Bottleneck vẫn ở Primary
 
Cluster:     NHIỀU node cùng hoạt động đồng thời
             Ghi có thể vào bất kỳ node nào
             Hệ thống đồng bộ với nhau qua consensus protocol
```
#### 1: MySQL InnoDB Cluster
```
- Tất cả node chạy Group Replication  
- MySQL Router biết ai là Primary → route write vào đó  
- Primary chết → Election → Router cập nhật tự động  
- RPO ≈ 0 (không mất data), RTO ≈ vài giây  
```
 
```
-- Kiểm tra trạng thái Group Replication
SELECT MEMBER_ID, MEMBER_HOST, MEMBER_STATE, MEMBER_ROLE
FROM performance_schema.replication_group_members;
 
-- Xem ai đang là Primary
SELECT VARIABLE_VALUE FROM performance_schema.global_status
WHERE VARIABLE_NAME = 'group_replication_primary_member';
```

 #### 2: Galera Cluster 
 ```
App có thể ghi vào BẤT KỲ node nào
Galera đảm bảo tất cả node có data giống nhau
Khi 1 node chết → 2 node còn lại tiếp tục hoạt động
```
 
```bash
# my.cnf cho Galera Cluster
[mysqld]
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="ecommerce_cluster"
wsrep_cluster_address="gcomm://192.168.1.10,192.168.1.11,192.168.1.12"
wsrep_node_address="192.168.1.10"
wsrep_node_name="node1"
wsrep_sst_method=rsync
```

#### 3. Failover — Tự động vs Thủ công
 
```
                    FAILOVER COMPARISON
 
THỜI ĐIỂM PRIMARY/MASTER CHẾT:
 
MySQL (không có cluster):
  T+0s:   Primary chết
  T+30s:  Monitoring phát hiện
  T+60s:  DBA nhận alert
  T+120s: DBA chạy lệnh promote Replica
  T+180s: App reconfigure connection string
  DOWNTIME: 3-10 phút
 
MySQL InnoDB Cluster / Galera:
  T+0s:  Node chết
  T+3s:  Heartbeat timeout
  T+5s:  Election hoàn tất, Router cập nhật
  T+5s:  App tiếp tục kết nối (qua MySQL Router)
  DOWNTIME: ~5 giây
 
 
SQL Server Always On:
  T+0s:  Primary chết
  T+5s:  WSFC phát hiện
  T+20s: Automatic Failover hoàn tất
  T+20s: Listener IP chuyển sang Secondary mới
  DOWNTIME: ~20-30 giây
```
 
```
-- Kiểm tra trạng thái Galera
SHOW STATUS LIKE 'wsrep_%';
-- wsrep_cluster_size: 3          → 3 node đang online
-- wsrep_cluster_status: Primary  → cluster healthy
-- wsrep_local_state_comment: Synced → node này đồng bộ
-- wsrep_flow_control_paused: 0   → không bị throttle
```
 
---

## 3. Sharding
 
### 3.1 Khái niệm và khi nào cần Sharding
 
> **Sharding** (hay còn gọi là **Horizontal Partitioning**) là kỹ thuật phân chia dữ liệu ra nhiều database server dựa theo một tiêu chí (Sharding Key).

 **Dấu hiệu hệ thống cần Sharding:**
- Dataset > RAM của 1 server 
- Write throughput > 10,000 ops/sec trên 1 server
- Disk I/O đạt giới hạn của 1 máy
- Query bắt đầu timeout dù đã tối ưu index

- 
## 4. Load Balancing
 
### 4.1 Tổng quan — Tại sao cần Load Balancing?
 
```
KHÔNG có Load Balancing:
App gửi 1000 requests/s → 1 DB server gánh hết → quá tải

CÓ Load Balancing:
App gửi 1000 requests/s → LB phân phối đều → 3 DB servers mỗi cái 333 req/s
   
Lưu ý quan trọng với Database:
- WRITE: Luôn vào Primary (không được load balance Write)
- READ:  Có thể load balance sang nhiều Replica
```
 
### 4.2 Các thuật toán Load Balancing
 
| Thuật toán | Cách hoạt động | Phù hợp khi |
|---|---|---|
| **Round Robin** | Lần lượt: R1→R2→R3→R1→... | Các Replica có sức mạnh tương đương |
| **Weighted Round Robin** | R1 nhận 60%, R2 nhận 40% | Replica có phần cứng khác nhau |
| **Least Connections** | Gửi vào server ít kết nối nhất | Query có thời gian xử lý khác nhau |
| **Least Response Time** | Gửi vào server phản hồi nhanh nhất | Khi muốn tối ưu latency |
| **Random** | Ngẫu nhiên | Đơn giản, ít quan trọng |
 
### 4.3 Load Balancing cho MySQL — ProxySQL
 
```
ProxySQL là giải phách số 1 cho MySQL Load Balancing 2026:
 
          APP (port 3306 thông thường)
                    │
                    ▼
             PROXYSQL :6033
                    │
        ┌───────────┼───────────┐
        │ Query Rule Engine     │
        │ ^SELECT → Readers     │
        │ Else → Writers        │
        └───────────┬───────────┘
              Write │      Read
                    │      │
              ┌─────▼┐   ┌─┴──────────────┐
              │ HG 10│   │     HG 20       │
              │Master│   │Replica1 Replica2│
              └──────┘   └────────────────┘
 
```
 
```
-- Cấu hình Load Balancing với Weight trong ProxySQL
-- Replica 1 mạnh hơn → weight cao hơn → nhận nhiều request hơn
INSERT INTO mysql_servers (hostgroup_id, hostname, port, weight)
VALUES
  (20, 'replica1', 3306, 1000),  -- Nhận 66% traffic
  (20, 'replica2', 3306, 500);   -- Nhận 34% traffic
 
-- Xem thống kê traffic phân phối
SELECT srv_host, Queries, Bytes_data_sent
FROM stats_mysql_connection_pool
WHERE hostgroup = 20;
```

### 4.4 HAProxy cho Database (Giải pháp đơn giản)
 
```
HAProxy là Layer 4 (TCP) load balancer — không hiểu SQL
Phù hợp khi chỉ cần route đơn giản
 
          APP
           │
           ▼
        HAPROXY
        :3306
           │
    ┌──────┴──────┐
    ▼             ▼
 MySQL 1       MySQL 2
(Primary)     (Replica)
```
 
```
# /etc/haproxy/haproxy.cfg — MySQL Replica load balancing
 
frontend mysql_read
    bind *:3307              # Port đọc
    mode tcp
    default_backend mysql_replicas
 
backend mysql_replicas
    mode tcp
    balance leastconn        # Thuật toán least connections
    option mysql-check user haproxy_check
    server replica1 192.168.1.11:3306 weight 100 check
    server replica2 192.168.1.12:3306 weight 100 check
    server replica3 192.168.1.13:3306 weight 50  check  # Server yếu hơn
```

----------------

## PHẦN VII — TÍCH HỢP & KẾT NỐI
 
---
 
### 5. Giao Thức Kết Nối Database
 
#### 5.1 Tổng quan các giao thức
 
```
CLIENT APP
    │
    │ (giao thức nào?)
    │
    ▼
DATABASE SERVER
 
Mỗi database dùng giao thức wire protocol riêng:
┌────────────────────────────────────────────────────────┐
│ MySQL      → MySQL Protocol  (Port 3306)               │
│ PostgreSQL → PostgreSQL Wire Protocol (Port 5432)      │
│ SQL Server → TDS (Tabular Data Stream) (Port 1433)     │
│ MongoDB    → MongoDB Wire Protocol (Port 27017)        │
│ Redis      → RESP (REdis Serialization Protocol) (6379)│
│ Oracle     → SQL*Net / TNS (Port 1521)                 │
└────────────────────────────────────────────────────────┘
```
 #### 5.2 Bảo mật giao thức — TLS/SSL
 
```
KHÔNG có TLS:
Client ──── username + password (plaintext) ────► Server
       ──── data (plaintext) ────────────────────►
Attacker có thể nghe lén mọi thứ!
 
CÓ TLS:
Client ──── TLS Handshake ───────────────────────► Server
       ◄─── Certificate (server chứng minh danh tính)
       ──── Encrypted data ──────────────────────►
```
 
```
-- MySQL: Bắt buộc TLS cho user
ALTER USER 'appuser'@'%' REQUIRE SSL;
 
-- Kiểm tra kết nối có dùng SSL không
SHOW STATUS LIKE 'Ssl_cipher';
-- Ssl_cipher: TLS_AES_256_GCM_SHA384 → đang dùng TLS ✅
-- Ssl_cipher: (trống) → không dùng TLS ⚠️
```
 
---

## 6. ODBC / JDBC và Chuẩn Kết Nối
 
### 6.1 Tại sao cần chuẩn kết nối?
 
```
VẤN ĐỀ KHÔNG CÓ CHUẨN:
 
App Python ──► MySQL Driver riêng của MySQL
App Java  ──► SQL Server Driver riêng của Microsoft
App C#    ──► Oracle Driver riêng của Oracle
 
→ Mỗi database khác nhau → phải học API khác nhau
→ Đổi database → phải viết lại code kết nối
 
GIẢI PHÁP — CHUẨN CHUNG:
 
App Python ──► ODBC Standard ──► ODBC Driver MySQL
                             ──► ODBC Driver SQL Server
                             ──► ODBC Driver PostgreSQL
→ App không thay đổi, chỉ đổi driver!
```
### ODBC (Open Database Connectivity)
 
**Kiến trúc:**
```
Application (Python, Excel, PowerBI, R)
        ↓ ODBC API calls (chuẩn)
ODBC Driver Manager (unixODBC trên Linux)
        ↓ Load đúng driver
MySQL ODBC Driver / PostgreSQL Driver / ...
        ↓ Wire Protocol
Database Server
```

### JDBC (Java Database Connectivity)
 
**Kiến trúc:**
```
Java Application (Spring Boot, Hibernate)
        ↓ java.sql.* / javax.sql.*
JDBC Driver (mysql-connector-j-9.x.jar)
        ↓ MySQL Wire Protocol
MySQL Server
```

### So sánh ODBC vs JDBC vs Native Driver
 
| Tiêu chí | ODBC | JDBC | Native Driver |
|---|---|---|---|
| **Ngôn ngữ** | C/C++, Python, R, Excel | Java, Kotlin, Scala | Từng ngôn ngữ riêng |
| **Cấu hình** | DSN trong OS (odbcad32) | Connection string trong code | Connection string |
| **Hiệu suất** | Trung bình (có overhead) | Tốt | Tốt nhất |
| **Đa DB** | ✅ Rất rộng | ✅ Rộng (JVM) | Chỉ 1 DB |
| **Dùng khi** | BI tools, báo cáo, Excel | Java app | Cần max performance |

 ```bash
# Cài ODBC trên Ubuntu 22.04
sudo apt install unixodbc unixodbc-dev -y
odbcinst -d -q       # Xem drivers đã đăng ký
isql -v MySQL_DSN    # Test kết nối DSN
```
 
---
## 7. API và Web Services cho Database
 
### REST API — Mapping với SQL
 
| HTTP Method | URL | SQL tương đương |
|---|---|---|
| `GET /orders` | Lấy danh sách | `SELECT * FROM orders` |
| `GET /orders/123` | Lấy 1 record | `SELECT * WHERE id=123` |
| `POST /orders` | Tạo mới | `INSERT INTO orders` |
| `PUT /orders/123` | Cập nhật toàn bộ | `UPDATE ... WHERE id=123` |
| `PATCH /orders/123` | Cập nhật một phần | `UPDATE SET field=val WHERE id=123` |
| `DELETE /orders/123` | Xóa | `DELETE WHERE id=123` |
 
### GraphQL vs REST — Góc nhìn DB
 
```
Vấn đề của REST:
GET /users/1       → {id, name, email, address, phone, ...}  (lấy thừa)
GET /orders?user=1 → [...]                                    (request thứ 2)
GET /products/...  → [...]                                    (request thứ 3)
= 3 requests, nhiều data thừa
 
GraphQL:
POST /graphql
query {
  user(id: 1) {
    name                    ← chỉ lấy đúng field cần
    orders { id total }     ← join sẵn trong 1 request
  }
}
= 1 request, đúng data cần
```
 
| Tiêu chí | REST | GraphQL | gRPC |
|---|---|---|---|
| **Overfetching** | Phổ biến |  Không |  Không |
| **Số request** | Nhiều (N+1) |  1 request |  Streaming |
| **Caching** |  HTTP cache dễ | Khó hơn | Phức tạp |
| **Learning curve** | Thấp | Trung bình | Cao |
| **Dùng khi** | Public API đơn giản | Internal API, mobile | Microservices nội bộ |
 
### Database Gateway Pattern
 
```
App → API Gateway → Auth/Rate Limit → Database API → DB
                                           ↑
                              (Hasura, PostgREST, Supabase)
                              Tự động generate API từ DB schema
```
 
---
 
<a name="vii4"></a>
## 8. ETL — Extract, Transform, Load
 
### Khái niệm
 
```
ETL = Quy trình di chuyển và biến đổi dữ liệu giữa các hệ thống
 
EXTRACT          TRANSFORM              LOAD
Trích xuất  →   Làm sạch, chuẩn hóa  →  Nạp vào đích
từ nguồn        Join, aggregate           (Data Warehouse,
                Convert, deduplicate      Analytics DB)
 
Ví dụ thực tế:
MySQL OLTP ──┐
CSV files   ─┼─► ETL Engine ──► BigQuery / Redshift (Data Warehouse)
REST API    ─┘
                 └► BI Tool (Grafana, Tableau, Metabase)
```
 
### ETL vs ELT — Xu hướng 2026
 
| Tiêu chí | ETL (truyền thống) | ELT (hiện đại) |
|---|---|---|
| **Thứ tự** | Extract → Transform → Load | Extract → Load → Transform |
| **Transform ở đâu** | Server ETL riêng | Trong Data Warehouse |
| **Phù hợp** | Data Warehouse cũ, on-premise | Cloud DW  |
| **Công cụ** | Informatica, SSIS, Pentaho | dbt, Airbyte + dbt |
| **Xu hướng 2026** | Đang giảm |  Đang tăng |
 
### CDC — Change Data Capture (Real-time ETL)
 
```
ETL batch truyền thống: Chạy mỗi đêm → Data lag 24 giờ
 
CDC: Đọc binlog MySQL → Stream events real-time → lag vài giây
 
MySQL binlog ──► Debezium ──► Kafka ──► Consumer
                 (đọc như       (event   ├─► Elasticsearch
                  replica)       bus)    ├─► Data Warehouse
                                         └─► Cache invalidation
```
 
**Ví dụ Debezium config:**
```json
{
  "connector.class": "io.debezium.connector.mysql.MySqlConnector",
  "database.hostname": "192.168.1.10",
  "database.include.list": "ecommerce",
  "table.include.list": "ecommerce.orders"
}
```
 
### Công cụ ETL phổ biến 2026
 
| Công cụ | Loại | Điểm mạnh | Dùng khi |
|---|---|---|---|
| **Apache Airflow** | Orchestrator | DAG-based, Python, schedule | Cần lên lịch và monitor ETL jobs |
| **dbt** | Transform | SQL-based, version control, test | ELT trong Data Warehouse |
| **Airbyte** | Extract + Load | 300+ connectors, open source | Cần connector nhanh, ít code |
| **Debezium** | CDC | Real-time, đọc binlog | Sync real-time, event streaming |
| **Apache Spark** | Batch + Stream | Xử lý TB data, ML integration | Big Data, phức tạp |
| **Fivetran** | EL managed | Tự động, ít maintain | Team nhỏ, ưu tiên tốc độ setup |
 
---
