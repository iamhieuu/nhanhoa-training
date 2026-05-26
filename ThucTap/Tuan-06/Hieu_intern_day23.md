# Báo cáo thực tập ngày 23 - Database

---

## 3. MongoDB: cài đặt, cấu hình hiệu năng và bảo mật
MongoDB lưu trữ dữ liệu dưới dạng các Document (tài liệu). Các tài liệu này có cấu trúc linh hoạt tương tự như định dạng JSON (chính xác hơn là BSON - Binary JSON).  
Cấu trúc của MongoDB sẽ tương ứng như sau:  
Database (Cơ sở dữ liệu) -> Vẫn gọi là Database.  
Table (Bảng) -> Gọi là Collection (Tập hợp).  
Row (Hàng/Bản ghi) -> Gọi là Document (Tài liệu).  
Column (Cột) -> Gọi là Field (Trường dữ liệu).  

### Cài đặt MongoDB 7.0 trên Ubuntu 22.04
#### 1. Import GPG key & thêm official repo
```
# Import signing key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
  | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
  --dearmor

# Thêm repo MongoDB 7.0 cho Ubuntu 22.04
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
```
#### 2. Cài MongoDB
```
sudo apt update
sudo apt install -y mongodb-org
```
#### 3. Khởi động & bật auto-start
````
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod
````

#### 4. Kết nối bằng mongosh — shell mới thay thế mongo
````
# Trong mongosh prompt — các lệnh cơ bản:
show dbs              // liệt kê databases
use myapp_db          // chuyển sang / tạo database
show collections      // liệt kê collections
db.version()          // kiểm tra version
exit                  // thoát
````
<img width="789" height="325" alt="{72B4F98A-65FA-4A08-8367-F30997E06F81}" src="https://github.com/user-attachments/assets/9a0a6c3c-03b0-4135-890d-298181ddeb3e" />

#### 5 Tạo database & collection đầu tiên
MongoDB tự động tạo database khi bạn insert document đầu tiên — không cần CREATE DATABASE như MySQL.
````
use myapp_db

// Insert document đầu tiên → tự động tạo DB + collection
db.products.insertOne({
  name: "Laptop Dell XPS",
  price: 25000000,
  category: "electronics",
  specs: { ram: "16GB", storage: "512GB SSD" },
  tags: ["laptop", "dell", "sale"]
})

// Query lại
db.products.find({ category: "electronics" }).pretty()
````
----
## File cấu hình /etc/mongod.conf 
```
# /etc/mongod.conf

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
  verbosity: 0            # 0=normal, 1-5=debug (tăng khi troubleshoot)

storage:
  dbPath: /var/lib/mongodb
  engine: wiredTiger       # storage engine mặc định và duy nhất nên dùng
  wiredTiger:
    engineConfig:
      cacheSizeGB: 2       # ~50% RAM — quan trọng nhất!
    collectionConfig:
      blockCompressor: snappy  # nén data, tiết kiệm disk

net:
  port: 27017
  bindIp: 127.0.0.1        # chỉ localhost. Remote app: thêm IP app server
  tls:
    mode: requireTLS        # bắt buộc TLS (production)
    certificateKeyFile: /etc/ssl/mongodb/mongodb.pem
    CAFile: /etc/ssl/mongodb/ca.pem

security:
  authorization: enabled   # BẮT BUỘC — xác thực user
  javascriptEnabled: false # tắt JS execution server-side (bảo mật)

operationProfiling:
  mode: slowOp
  slowOpThresholdMs: 100   # log operation chậm hơn 100ms

replication:
  replSetName: "rs0"        # bỏ comment nếu dùng Replica Set
```

----
## Tối ưu hiệu năng MongoDB
* Index
```
// Xem query có dùng index không
db.products.find({ category: "electronics" }).explain("executionStats")
// Tìm: "COLLSCAN" = không có index, "IXSCAN" = có index

// Tạo single field index
db.products.createIndex({ category: 1 })

// Compound index — thứ tự trường quan trọng! (ESR rule)
// E=Equality, S=Sort, R=Range
db.orders.createIndex({ user_id: 1, status: 1, created_at: -1 })

// Text index cho full-text search
db.articles.createIndex({ title: "text", content: "text" })
db.articles.find({ $text: { $search: "mongodb devops" } })

// TTL index — tự xóa document sau X giây (dùng cho session, log)
db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 })

// Xem tất cả index của collection
db.products.getIndexes()
// Ví dụ: doanh thu theo category, top 5
db.orders.aggregate([
  // Stage 1: Lọc đơn hàng đã hoàn thành
  { $match: { status: "completed" } },

  // Stage 2: Unwind array items
  { $unwind: "$items" },

  // Stage 3: Nhóm theo category, tính tổng
  { $group: {
    _id: "$items.category",
    total_revenue: { $sum: { $multiply: ["$items.price", "$items.qty"] } },
    order_count: { $sum: 1 }
  }},

  // Stage 4: Sort giảm dần
  { $sort: { total_revenue: -1 } },

  // Stage 5: Lấy top 5
  { $limit: 5 }
])
```
* Profiler
```
// Bật profiler level 1 (log slow ops > 100ms)
db.setProfilingLevel(1, { slowms: 100 })

// Xem slow operations gần nhất
db.system.profile.find({})
  .sort({ ts: -1 })
  .limit(10)
  .pretty()

// Xem operation chậm nhất, chỉ lấy thông tin quan trọng
db.system.profile.find({}, {
  op: 1, ns: 1, millis: 1,
  "command.filter": 1, planSummary: 1
}).sort({ millis: -1 }).limit(5)

// Tắt profiler khi xong (tốn tài nguyên)
db.setProfilingLevel(0)
```
* Monitoring nhanh trong mongosh
```
// Server status tổng quan
db.serverStatus()

// Chỉ xem memory & connections
const s = db.serverStatus()
print("Cache used:", s.wiredTiger.cache["bytes currently in the cache"] / 1024/1024, "MB")
print("Connections:", s.connections.current, "/", s.connections.available)
print("Ops/s:", s.opcounters)

// Xem collection stats
db.products.stats()
// → size, count, avgObjSize, totalIndexSize
```
---

## Bảo mật MongoDB — cực kỳ quan trọng
MongoDB bị hack nhiều nhất trong số các DB phổ biến do mặc định không có auth và port 27017 bị để lộ. Hàng trăm nghìn instance bị xóa data và đòi ransom. Phần bảo mật này phải làm trước khi làm bất cứ thứ gì khác.  
#### 1. Bật Authentication — bước đầu tiên bắt buộc

```
use admin
db.createUser({
  user: "mongoAdmin",
  pwd: "Str0ngAdm!nPass",
  roles: [{ role: "userAdminAnyDatabase", db: "admin" },
          { role: "readWriteAnyDatabase", db: "admin" },
          { role: "dbAdminAnyDatabase", db: "admin" }]
})

exit
# Bật auth trong mongod.conf
# security:
#   authorization: enabled

# Bật nhanh qua CLI:
sudo sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
sudo systemctl restart mongod

# Bước 5: Đăng nhập lại với auth
mongosh -u mongoAdmin -p --authenticationDatabase admin
```
#### 2. Tạo user riêng cho từng app
```
mongosh -u mongoAdmin -p --authenticationDatabase admin

// Tạo user chỉ đọc/ghi trên 1 database cụ thể
use myapp_db
db.createUser({
  user: "myapp_user",
  pwd: "AppP@ss456!",
  roles: [{ role: "readWrite", db: "myapp_db" }]
})

// User chỉ đọc (cho reporting, analytics)
db.createUser({
  user: "reporter",
  pwd: "ReadOnly789!",
  roles: [{ role: "read", db: "myapp_db" }]
})

// Xem tất cả user
db.getUsers()
```
#### Firewall 
```
# Chỉ cho phép IP app server kết nối MongoDB
sudo ufw enable
sudo ufw allow from 10.0.1.50 to any port 27017
sudo ufw allow from 10.0.1.51 to any port 27017

# Kiểm tra không có rule nào mở 27017 ra 0.0.0.0
sudo ufw status verbose

# Scan kiểm tra port có bị expose không
nmap -p 27017 <your-server-ip>
```

#### TLS/SSL
```
# Tạo self-signed cert (dev) hoặc dùng Let's Encrypt/CA cert (prod)
sudo mkdir -p /etc/ssl/mongodb
sudo openssl req -x509 -nodes -newkey rsa:2048 \
  -subj "/CN=mongodb-server" \
  -keyout /etc/ssl/mongodb/mongodb.key \
  -out /etc/ssl/mongodb/mongodb.crt -days 365

# MongoDB cần file .pem (cert + key ghép lại)
sudo cat /etc/ssl/mongodb/mongodb.crt \
  /etc/ssl/mongodb/mongodb.key \
  | sudo tee /etc/ssl/mongodb/mongodb.pem

sudo chown mongodb:mongodb /etc/ssl/mongodb/mongodb.pem
sudo chmod 600 /etc/ssl/mongodb/mongodb.pem
```
##### Disable HTTP Interface & Kiểm tra cấu hình
```
# Kiểm tra MongoDB có đang listen ra ngoài không
ss -tlnp | grep 27017
# Kết quả an toàn: 127.0.0.1:27017
# Kết quả nguy hiểm: 0.0.0.0:27017

# Kiểm tra auth đã bật chưa
mongosh --eval "db.adminCommand({getCmdLineOpts:1})" \
  | grep -i auth

# Xem cấu hình đang chạy
mongosh -u mongoAdmin -p --authenticationDatabase admin \
  --eval "db.adminCommand({getCmdLineOpts:1})"
```
----

## Redis: cài đặt, cấu hình hiệu năng và bảo mật
In-Memory Database — dữ liệu sống trong RAM  
Redis không phải replacement cho MySQL — nó là lớp đứng phía trước để giảm tải. Kiến trúc phổ biến nhất: App → Redis (cache hit?) → MySQL (cache miss)  
* Tốc độ siêu nhanh: Vì mọi thao tác đọc/ghi đều diễn ra trực tiếp trên RAM, thời gian phản hồi của Redis thường chỉ tính bằng độ trễ micro giây.

* Cấu trúc dữ liệu phong phú: Khác với hệ thống Memcached chỉ lưu chuỗi đơn giản, Redis hỗ trợ rất nhiều kiểu dữ liệu phức tạp như Strings, Lists, Sets, Hashes, và Sorted Sets.

* Tính bền bỉ: Dù chạy trên RAM, Redis vẫn an toàn. Nó có cơ chế thỉnh thoảng snapshot dữ liệu trên RAM và ghi dự phòng xuống ổ cứng, hoặc ghi log lại các thao tác. Nếu máy chủ bị cúp điện, khi khởi động lại, Redis sẽ lấy dữ liệu từ ổ cứng nạp ngược lại lên RAM.

### Cài đặt Redis 7.x trên Ubuntu 22.04
#### Cài từ official Redis repo (v7.x mới nhất)
````
Cài từ official Redis repo (v7.x mới nhất)
# Thêm Redis official repo
curl -fsSL https://packages.redis.io/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] \
https://packages.redis.io/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis
````

#### Khởi động & kiểm tra
```
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo systemctl status redis-server
```
#### Test bằng redis-cli
```
redis-cli

# Trong redis-cli prompt:
PING                    # → PONG (Redis đang sống)
SET hello "world"        # lưu key-value
GET hello                # → "world"
INFO server             # thông tin server
INFO memory             # dùng bao nhiêu RAM
DBSIZE                  # số key đang có

```
#### Benchmark
```
redis-benchmark -n 100000 -q -P 16

# Kết quả thường thấy:
# SET: ~800,000 requests/second
# GET: ~900,000 requests/second
# LPUSH: ~700,000 requests/second
```
<img width="519" height="237" alt="image" src="https://github.com/user-attachments/assets/4dd07855-c7b2-4fb1-8d2e-c4585bc6d6b2" />

---
##  Cấu hình file /etc/redis/redis.conf
```
# ── Network ─────────────────────────────────────────
bind            127.0.0.1        # chỉ localhost. Thêm IP app nếu remote
port            6379
protected-mode yes              # từ chối kết nối nếu không có auth
tcp-backlog    511

# ── Auth ─────────────────────────────────────────────
requirepass    StrongRedisPass123!  # BẮT BUỘC đặt password

# ── Memory ───────────────────────────────────────────
maxmemory      2gb              # giới hạn RAM tối đa
maxmemory-policy allkeys-lru   # khi đầy: xóa key ít dùng nhất
#   allkeys-lru   = xóa bất kỳ key ít dùng (cache thuần)
#   volatile-lru  = chỉ xóa key có TTL (mix cache+persistent)
#   volatile-ttl  = xóa key sắp hết TTL nhất
#   noeviction    = từ chối write khi đầy (không dùng cho cache)

# ── Persistence ──────────────────────────────────────
# RDB Snapshot — backup nhanh, có thể mất data gần nhất
save            900 1           # sau 900s nếu có ≥1 thay đổi
save            300 10          # sau 300s nếu có ≥10 thay đổi
save            60  10000       # sau 60s nếu có ≥10000 thay đổi
dbfilename      dump.rdb
dir             /var/lib/redis

# AOF — log mọi lệnh, an toàn hơn nhưng tốn disk
appendonly      yes
appendfsync     everysec        # flush mỗi giây (cân bằng an toàn/hiệu năng)
#   always   = flush mỗi lệnh (an toàn nhất, chậm nhất)
#   everysec = flush mỗi giây (khuyên dùng)
#   no       = OS quyết định (nhanh nhất, nguy hiểm)

# ── Performance ──────────────────────────────────────
maxclients      1000            # số connection đồng thời tối đa
tcp-keepalive   300
lazyfree-lazy-eviction yes     # xóa key lớn không đồng bộ (tránh block)

# ── Logging ──────────────────────────────────────────
loglevel        notice          # verbose | notice | warning
logfile         /var/log/redis/redis-server.log

# ── TLS (production) ─────────────────────────────────
# tls-port 6380
# tls-cert-file /etc/ssl/redis/redis.crt
# tls-key-file  /etc/ssl/redis/redis.key
```

### Bảo mật Redis
Redis mặc định không có password và lắng nghe 0.0.0.0 trên nhiều distro. Kết hợp với port 6379 scan liên tục từ internet → rất nguy hiểm. Làm phần này ngay sau khi cài.  
#### 1. Đặt Password — bắt buộc
```
# Trong redis.conf:
requirepass Hieucute123!

# Hoặc đặt ngay không cần restart (tạm thời):
redis-cli
CONFIG SET requirepass "Hieucute123!"

# Sau khi đặt password, đăng nhập:
redis-cli -a Hieucute123!
# hoặc sau khi kết nối:
AUTH Hieucute123!

# Lưu vào file config để persistent
redis-cli -a Hieucute123! CONFIG REWRITE
```
#### 2 bind + Firewall — không để lộ port 6379
```
# redis.conf — chỉ lắng nghe localhost
bind 127.0.0.1

# Nếu app server ở IP khác (ví dụ 10.0.1.50):
bind 127.0.0.1 10.0.1.10   # 10.0.1.10 = IP của Redis server
# + cần thêm ufw rule:

sudo ufw allow from 10.0.1.50 to any port 6379
sudo ufw enable

# Kiểm tra port đang listen ở đâu
ss -tlnp | grep 6379
# An toàn: 127.0.0.1:6379
# Nguy hiểm: 0.0.0.0:6379
```
#### 3 Rename hoặc disable lệnh nguy hiểm
```
rename-command FLUSHALL ""          # disable hoàn toàn
rename-command FLUSHDB  ""          # disable hoàn toàn
rename-command CONFIG   "HIDDEN_CONFIG_9x2k"  # đổi tên khó đoán
rename-command DEBUG    ""          # disable
rename-command KEYS     "SCAN_KEYS" # khuyến khích dùng SCAN thay KEYS
```

#### 4. Dùng ACL (Redis 6+) — phân quyền chi tiết theo user  
```
redis-cli -a Hieucute123!

# Tạo user chỉ đọc được key "cache:*"
ACL SETUSER readonly_user on >ReadOnlyPass!
  ~cache:* +GET +MGET +EXISTS +TTL -@all

# Tạo user cho app — chỉ SET/GET, không FLUSH
ACL SETUSER app_user on >AppPass456!
  ~* +@read +@write -FLUSHDB -FLUSHALL -CONFIG -DEBUG

# Xem danh sách ACL
ACL LIST
ACL WHOAMI    # user hiện tại đang dùng
```
