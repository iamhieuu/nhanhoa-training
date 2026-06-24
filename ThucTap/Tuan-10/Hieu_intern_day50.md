# Báo cáo thực tập ngày 50 - Zabbix


---

# CHƯƠNG 1: TỔNG QUAN ZABBIX

---


## 1.1 Monitoring là gì và tại sao cần thiết?

### 1.1.1 Định nghĩa Monitoring 

**Monitoring** là quá trình **liên tục thu thập, phân tích và hiển thị dữ liệu** về trạng thái hoạt động của hạ tầng IT — bao gồm server, mạng, ứng dụng, cơ sở dữ liệu và dịch vụ — với mục tiêu phát hiện sự cố, dự đoán vấn đề tiềm ẩn và đảm bảo hệ thống vận hành ổn định.

Nếu không có monitoring, đội IT chỉ biết hệ thống bị sự cố **khi người dùng phản ánh** — điều này là quá muộn trong môi trường doanh nghiệp.

### 1.1.2 Ba cấp độ giám sát trong doanh nghiệp

```
┌─────────────────────────────────────────────────────────┐
│                  BUSINESS LEVEL                         │
│    SLA, Uptime %, Revenue impact, User experience       │
├─────────────────────────────────────────────────────────┤
│                 APPLICATION LEVEL                       │
│    Response time, Error rate, Transaction per second    │
├─────────────────────────────────────────────────────────┤
│               INFRASTRUCTURE LEVEL                      │
│    CPU, RAM, Disk, Network, Process, Port, Service      │
└─────────────────────────────────────────────────────────┘
         ▲ Zabbix hoạt động hiệu quả ở cả 3 cấp độ
```

### 1.1.3 Các loại Monitoring

| Loại | Mô tả | Ví dụ |
|------|-------|-------|
| **Infrastructure Monitoring** | Giám sát phần cứng và OS | CPU, RAM, Disk, Network interface |
| **Network Monitoring** | Giám sát thiết bị mạng | Switch, Router, Firewall qua SNMP |
| **Application Monitoring** | Giám sát ứng dụng | Web server, Database, API |
| **Service Monitoring** | Giám sát dịch vụ | HTTP, SMTP, SSH, DNS |
| **Log Monitoring** | Phân tích log file | Syslog, Apache log, App log |
| **Security Monitoring** | Phát hiện bất thường bảo mật | Failed login, Port scan |
| **Cloud Monitoring** | Giám sát tài nguyên cloud | AWS EC2, Azure VM, GCP |

---

## 1.2 Zabbix là gì?

### 1.4.1 Định nghĩa

**Zabbix** là nền tảng giám sát hệ thống mã nguồn mở (open-source) cấp doanh nghiệp (**enterprise-grade**), được phát triển và duy trì bởi công ty **Zabbix SIA**. Zabbix cung cấp khả năng giám sát toàn diện cho hạ tầng IT: server, mạng, ứng dụng, cloud và IoT — tất cả trong một nền tảng thống nhất duy nhất.

**Đặc điểm then chốt:**
- **100% Open Source** — Mã nguồn mở hoàn toàn, không có tính năng bị giới hạn bởi license.
- **Enterprise-grade** — Được sử dụng bởi các tổ chức lớn trên toàn cầu.
- **No per-host licensing** — Không thu phí theo số lượng host giám sát.
- **Self-hosted** — Chạy trên hạ tầng của chính doanh nghiệp, toàn quyền kiểm soát dữ liệu.

### 1.4.2 Lịch sử phát triển

```
1998 ── Alexei Vladishev bắt đầu phát triển Zabbix (dự án cá nhân)
2001 ── Zabbix 1.0 alpha được phát hành (mã nguồn mở)
2005 ── Zabbix SIA được thành lập tại Latvia
2009 ── Zabbix 1.8: Hỗ trợ Distributed Monitoring (Proxy)
2012 ── Zabbix 2.0: Template-based monitoring, Low-Level Discovery
2014 ── Zabbix 2.4: Zabbix Agent Active mode cải tiến
2016 ── Zabbix 3.0 LTS: Encryption, New UI
2018 ── Zabbix 4.0 LTS: HTTP Agent, Preprocessing
2020 ── Zabbix 5.0 LTS: Secrets, High Availability
2022 ── Zabbix 6.0 LTS: Business Service Monitoring, Geomap
2023 ── Zabbix 6.4: Anomaly Detection, Top Hosts Widget
2024 ── Zabbix 7.0 LTS: New UI, Browser monitoring, SLA improvements
```

📌 **Lưu ý:** Phiên bản **LTS (Long Term Support)** được hỗ trợ trong 5 năm. Môi trường doanh nghiệp nên luôn sử dụng phiên bản LTS.

### 1.4.3 Zabbix trong bức tranh giám sát toàn cầu

💡 **Thực tế:** Zabbix được sử dụng bởi hơn **500.000 tổ chức** trên toàn thế giới, bao gồm Dell, Proximus, ICANN, và nhiều ngân hàng, viễn thông lớn tại châu Á. Tại Việt Nam, Zabbix là lựa chọn phổ biến nhất trong các hệ thống giám sát hạ tầng doanh nghiệp vừa và lớn.

---

## 1.5 Tính năng nổi bật của Zabbix

### 1.5.1 Thu thập dữ liệu đa giao thức

Zabbix hỗ trợ **nhiều phương thức thu thập dữ liệu** trong một nền tảng duy nhất:

| Phương thức | Mô tả | Dùng khi nào |
|-------------|-------|--------------|
| **Zabbix Agent** | Agent cài trên host được giám sát | Server Linux/Windows có thể cài agent |
| **Zabbix Agent 2** | Agent thế hệ mới, viết bằng Go | Cần plugin mở rộng, hiệu suất cao hơn |
| **SNMP (v1/v2c/v3)** | Giao thức giám sát mạng tiêu chuẩn | Switch, Router, Printer, Firewall |
| **IPMI** | Giám sát phần cứng server | Dell iDRAC, HP iLO, IBM IMM |
| **JMX** | Giám sát Java application | Tomcat, JBoss, WebLogic |
| **HTTP Agent** | Gửi HTTP/HTTPS request | API monitoring, web endpoint check |
| **SSH / Telnet** | Chạy lệnh từ xa qua SSH | Thiết bị không cài được agent |
| **Database Monitor** | Truy vấn database trực tiếp | MySQL, PostgreSQL, Oracle, MSSQL |
| **External Check** | Chạy script bên ngoài | Custom monitoring scripts |
| **Calculated Items** | Tính toán từ dữ liệu đã có | Công thức tổng hợp, tỷ lệ % |
| **Dependent Items** | Lấy dữ liệu từ item khác | Parse JSON/XML từ một API call |
| **Zabbix Trapper** | Nhận dữ liệu chủ động từ bên ngoài | Custom scripts push data vào Zabbix |
| **Internal Checks** | Giám sát bản thân Zabbix | Số host, queue size, process |

### 1.5.2 Low-Level Discovery (LLD) — Tự động phát hiện

Đây là một trong những tính năng **mạnh nhất và quan trọng nhất** của Zabbix.

**LLD là gì?** LLD cho phép Zabbix **tự động phát hiện** và tạo Items, Triggers, Graphs cho các thực thể động như:
- Network interfaces (eth0, eth1, bond0...)
- Mounted filesystems (/var, /opt, /home...)
- Running processes
- Windows Services
- Database tablespaces
- Docker containers

💡 **Ví dụ thực tế:** Một server có 10 ổ cứng. Thay vì tạo thủ công 10 items cho 10 ổ, LLD tự động phát hiện tất cả filesystems và tạo items, triggers, graphs tương ứng — ngay cả khi sau này bạn thêm ổ mới.

```
Không có LLD:                    Với LLD:
  Item: disk.used[/]               Discovery Rule: vfs.fs.discovery
  Item: disk.used[/var]              → Tự động tạo Items cho /
  Item: disk.used[/opt]              → Tự động tạo Items cho /var
  Item: disk.used[/home]             → Tự động tạo Items cho /opt
  (Phải tạo thủ công, dễ bỏ sót)    → Tự động tạo Items cho /home
                                     (Tự động, không bỏ sót)
```

### 1.5.3 Trigger System — Hệ thống cảnh báo thông minh

Trigger trong Zabbix không chỉ đơn giản là so sánh "nếu CPU > 90% thì cảnh báo". Trigger hỗ trợ:

- **Ngưỡng đơn giản:** `{host:cpu.load.avg(5m)} > 80`
- **Biểu thức phức tạp:** Kết hợp nhiều điều kiện với AND/OR
- **Hàm thống kê:** `avg()`, `min()`, `max()`, `last()`, `count()`, `diff()`
- **Trend prediction:** `timeleft()` — dự đoán khi nào disk đầy
- **Hysteresis:** Chống flapping (cảnh báo liên tục do threshold dao động)
- **Trigger dependencies:** Tránh cảnh báo "cascade" khi thiết bị mạng chính down

```
Ví dụ Trigger phức tạp trong doanh nghiệp:

# Cảnh báo khi disk sẽ đầy trong vòng 24 giờ
{server:vfs.fs.size[/var,pused].timeleft(1h,,100)} < 86400

# Cảnh báo CPU cao liên tục trong 5 phút
{server:system.cpu.util.avg(5m)} > 90

# Cảnh báo khi có nhiều hơn 100 kết nối ESTABLISHED
{server:net.tcp.listen[80].last()} > 100
  AND
{server:net.tcp.service.perf[http].last()} > 2
```

### 1.5.4 Action và Notification — Tự động hóa phản ứng

Khi trigger chuyển trạng thái (PROBLEM/RESOLVED), Zabbix có thể:

```
TRIGGER kích hoạt
       │
       ▼
┌──────────────────────────────────────────┐
│              ACTION                      │
│  Conditions: Who? What severity? When?  │
└──────────────────────────────────────────┘
       │
       ├──► SEND MESSAGE (Operations)
       │      Email, SMS, Telegram, Slack
       │      PagerDuty, OpsGenie, Webhook
       │
       ├──► REMOTE COMMAND (Operations)
       │      Restart service tự động
       │      Clear log file
       │      Scale up server
       │
       └──► ACKNOWLEDGE & ESCALATION
              Level 1: Alert on-call engineer (0 min)
              Level 2: Alert team lead (30 min)
              Level 3: Alert manager (60 min)
```

### 1.5.5 Template System — Quản lý cấu hình tập trung

Template là **blueprint** (bản thiết kế) chứa tập hợp Items, Triggers, Graphs, Dashboards cho một loại thiết bị/dịch vụ cụ thể. Template được **link** đến Host và áp dụng ngay lập tức.

**Lợi ích của Template:**
- Cấu hình **một lần**, áp dụng cho **hàng nghìn host**.
- Thay đổi template → tự động áp dụng cho tất cả host sử dụng template đó.
- Có thể **kế thừa** (inheritance) và **lồng nhau** (nested templates).
- Zabbix cung cấp **Template Library** với hàng trăm template có sẵn cho phần mềm phổ biến.

```
Template: Linux by Zabbix Agent
    ├── Items: CPU, RAM, Disk, Network, Process...
    ├── Triggers: CPU high, Disk full, OOM...
    ├── Graphs: CPU usage, Memory usage...
    └── Dashboards: System overview

    ↓ Link to hosts

    ├── server-web-01  ← Nhận toàn bộ cấu hình
    ├── server-db-01   ← Nhận toàn bộ cấu hình
    └── server-app-01  ← Nhận toàn bộ cấu hình
```

### 1.5.6 Visualization — Trực quan hóa dữ liệu

Zabbix cung cấp nhiều hình thức hiển thị dữ liệu:

| Loại | Mô tả | Dùng khi nào |
|------|-------|--------------|
| **Graphs** | Biểu đồ theo thời gian | Xem trend, phân tích lịch sử |
| **Dashboards** | Bảng điều khiển tùy chỉnh | NOC, executive view, team view |
| **Maps** | Sơ đồ mạng tương tác | Topology network, datacenter view |
| **Screens** (legacy) | Bố cục cố định nhiều widget | Màn hình NOC |
| **Geomap** | Bản đồ địa lý | Hệ thống phân tán nhiều nơi |
| **Top Hosts** | Xếp hạng host theo metric | Performance comparison |
| **Business Services** | Giám sát theo dịch vụ kinh doanh | SLA monitoring |

### 1.5.7 Alerting — Cảnh báo đa kênh

Zabbix hỗ trợ **Media Types** (kênh thông báo) phong phú:

```
Zabbix Alert System
       │
       ├── Email (SMTP)
       ├── SMS (via gateway)
       ├── Webhook
       │     ├── Slack
       │     ├── Microsoft Teams
       │     ├── Telegram
       │     ├── PagerDuty
       │     ├── OpsGenie
       │     └── Custom webhook
       ├── Script (custom notification script)
       └── Jira / ServiceNow integration
```

### 1.5.8 Preprocessing — Xử lý dữ liệu trước khi lưu

Preprocessing cho phép **biến đổi dữ liệu thô** trước khi lưu vào database:

```
Dữ liệu thô từ agent/SNMP
       │
       ▼
┌─────────────────────────────────┐
│      PREPROCESSING STEPS       │
│  1. Regular Expression          │
│  2. JSONPath                    │
│  3. XML XPath                   │
│  4. CSV to JSON                 │
│  5. Change per second           │
│  6. Custom multiplier           │
│  7. Discard unchanged           │
│  8. Check not supported         │
└─────────────────────────────────┘
       │
       ▼
  Giá trị đã xử lý → Lưu vào DB → Trigger evaluation
```

💡 **Ví dụ thực tế:** API trả về JSON `{"cpu": {"load": 45.2, "cores": 8}}`. Dùng JSONPath preprocessing `$.cpu.load` để chỉ lấy giá trị `45.2` lưu vào database.

### 1.5.9 High Availability (Zabbix 6.0+)

Từ Zabbix 6.0, hỗ trợ **native High Availability** (HA) cho Zabbix Server:
- Nhiều Zabbix Server node chạy song song.
- Một node là **Active**, các node còn lại là **Standby**.
- Khi Active node fail, Standby node tự động takeover trong vài giây.
- Không cần Pacemaker/Corosync hay giải pháp HA bên ngoài.

### 1.5.10 API — Tích hợp và Automation

Zabbix cung cấp **JSON-RPC API** cho phép:
- Tự động hóa tạo/xóa Host, Template, User.
- Tích hợp với hệ thống CMDB (IT Asset Management).
- Lấy dữ liệu để hiển thị trong dashboard tùy chỉnh.
- Tích hợp CI/CD pipeline (tự động thêm host khi deploy server mới).

```bash
# Ví dụ API call - Lấy danh sách hosts
curl -s -X POST https://zabbix.company.com/api_jsonrpc.php \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {"output": ["hostid", "host"]},
    "auth": "your-auth-token",
    "id": 1
  }'
```

### 1.5.11 Encryption — Bảo mật truyền thông

Zabbix hỗ trợ **mã hóa toàn bộ** dữ liệu truyền thông:
- **TLS (Transport Layer Security)** cho kết nối Agent ↔ Server.
- **PSK (Pre-Shared Key)** — Đơn giản, không cần PKI.
- **Certificate-based TLS** — Phù hợp môi trường enterprise với PKI.

---

## 1.6 So sánh Zabbix với các giải pháp giám sát khác

### 1.6.1 Bảng so sánh tổng quan

| Tiêu chí | Zabbix | Nagios/Icinga | Prometheus + Grafana | Datadog |
|---------|--------|--------------|---------------------|---------|
| **License** | Open Source (GPL) | Open Source | Open Source | SaaS (trả phí) |
| **Chi phí** | Miễn phí | Miễn phí | Miễn phí | ~$15-23/host/tháng |
| **Kiến trúc** | Monolithic + Proxy | Plugin-based | Pull-based + TSDB | Cloud SaaS |
| **Dữ liệu lưu trữ** | PostgreSQL/MySQL | File-based | TimeSeries DB | Cloud |
| **Agent** | Có (Zabbix Agent) | Có (NRPE) | Có (Exporters) | Có |
| **SNMP** | ✅ Native | ✅ Plugin | ⚠️ SNMP Exporter | ✅ |
| **Auto-discovery** | ✅ LLD mạnh | ⚠️ Hạn chế | ⚠️ Service discovery | ✅ |
| **Dashboard** | ✅ Built-in | ⚠️ Cơ bản | ✅ Grafana (riêng) | ✅ |
| **Alerting** | ✅ Built-in | ✅ Built-in | ✅ Alertmanager | ✅ |
| **API** | ✅ JSON-RPC | ⚠️ Hạn chế | ✅ PromQL HTTP | ✅ REST |
| **Học tập** | Trung bình | Thấp | Cao | Thấp |
| **Scale** | Lớn (Proxy) | Trung bình | Rất lớn | Rất lớn |
| **Best for** | Enterprise all-in-one | Legacy UNIX | Cloud-native microservices | Managed cloud |

### 1.6.2 Khi nào chọn Zabbix?

✅ **Chọn Zabbix khi:**
- Cần giám sát hệ thống hỗn hợp: Linux, Windows, Network device, Database.
- Muốn giải pháp **all-in-one** (collect, store, alert, visualize trong một nền tảng).
- Cần giám sát SNMP cho switch/router.
- Đội ngũ nhỏ, muốn **quản lý tập trung**.
- Yêu cầu **data sovereignty** (dữ liệu không ra ngoài).
- Budget hạn chế, cần giải pháp enterprise miễn phí.

⚠️ **Cân nhắc khi:**
- Hệ thống **microservices cloud-native** lớn (Prometheus phù hợp hơn).
- Cần xử lý **hàng triệu metrics/giây** (Prometheus + VictoriaMetrics tốt hơn).
- Không có đội IT quản trị (Datadog/New Relic managed dễ hơn).

---

## 1.7 Thuật ngữ cốt lõi trong Zabbix

Hiểu đúng thuật ngữ là nền tảng để làm việc hiệu quả với Zabbix. Phần này giải thích tất cả thuật ngữ quan trọng theo thứ tự logic từ "đối tượng được giám sát" đến "kết quả hiển thị".

### 1.7.1 Host và Host Groups

**Host** là **bất kỳ thiết bị hoặc dịch vụ nào** được giám sát trong Zabbix. Host không nhất thiết là một máy vật lý — nó có thể là:
- Server vật lý hoặc máy ảo (VM)
- Switch, Router, Firewall
- Một ứng dụng hoặc service
- Một URL cần kiểm tra
- Một cảm biến IoT

Mỗi Host có các thuộc tính:
- **Technical name:** Tên định danh kỹ thuật (ví dụ: `web-server-01`)
- **Visible name:** Tên hiển thị thân thiện (ví dụ: `Web Server 01 - HCM`)
- **IP/DNS:** Địa chỉ để kết nối
- **Port:** Cổng mặc định (10050 cho agent)
- **Templates:** Các template được áp dụng
- **Host groups:** Nhóm mà host thuộc về

**Host Groups** là cách tổ chức host theo logic: theo loại (Servers, Network Devices), theo môi trường (Production, Staging), theo địa điểm (Hanoi, HCM), theo ứng dụng (Web Servers, Database Servers).

```
Host Groups trong doanh nghiệp điển hình:
├── /Linux Servers
│     ├── /Linux Servers/Production
│     └── /Linux Servers/Staging
├── /Windows Servers
├── /Network Devices
│     ├── /Network Devices/Core
│     └── /Network Devices/Access
├── /Databases
│     ├── /Databases/MySQL
│     └── /Databases/PostgreSQL
└── /Cloud
      ├── /Cloud/AWS
      └── /Cloud/Azure
```

### 1.7.2 Item — Đơn vị thu thập dữ liệu

**Item** là **một đơn vị thu thập dữ liệu cụ thể** từ một Host. Item định nghĩa: **thu thập gì, bằng cách nào, bao lâu một lần, lưu trữ bao lâu**.

Các thuộc tính quan trọng của Item:
- **Key:** Định danh duy nhất, quy định dữ liệu gì được thu thập (`system.cpu.util`, `vfs.fs.size[/,pused]`)
- **Type:** Phương thức thu thập (Zabbix Agent, SNMP, HTTP, ...)
- **Update interval:** Tần suất thu thập (30s, 1m, 5m)
- **History storage:** Lưu dữ liệu raw bao lâu (7 ngày, 30 ngày)
- **Trend storage:** Lưu dữ liệu thống kê (min/max/avg theo giờ) bao lâu (365 ngày)
- **Value type:** Kiểu dữ liệu (Numeric unsigned, Float, Character, Log, Text)
- **Units:** Đơn vị hiển thị (%, MB, B/s, rpm)

```
Ví dụ một Item hoàn chỉnh:
  Name:             CPU utilization
  Key:              system.cpu.util[,user]
  Type:             Zabbix Agent (active)
  Update interval:  1m
  History:          7d
  Trends:           365d
  Value type:       Numeric float
  Units:            %
  Description:      Tỷ lệ CPU sử dụng bởi user processes
```

### 1.7.3 Trigger — Quy tắc phát hiện vấn đề

**Trigger** là **biểu thức logic** định nghĩa điều kiện khi nào một tình trạng được coi là **PROBLEM** (có vấn đề). Trigger liên tục đánh giá dữ liệu từ các Items.

**Trigger có hai trạng thái chính:**
- **OK** — Hệ thống hoạt động bình thường
- **PROBLEM** — Điều kiện trong trigger được thỏa mãn

**Severity (Mức độ nghiêm trọng) của Trigger:**

| Severity | Màu | Ý nghĩa | Ví dụ |
|---------|-----|---------|-------|
| **Not classified** | Xám | Chưa phân loại | |
| **Information** | Xanh nhạt | Thông tin tham khảo | Reboot được thực hiện |
| **Warning** | Vàng | Cảnh báo, cần chú ý | CPU > 70% |
| **Average** | Cam | Vấn đề trung bình | CPU > 85%, Disk > 80% |
| **High** | Đỏ nhạt | Vấn đề nghiêm trọng | Service down |
| **Disaster** | Đỏ đậm | Thảm họa, mất dịch vụ | Server unreachable |

**Các hàm thường dùng trong Trigger:**

| Hàm | Mô tả | Ví dụ |
|-----|-------|-------|
| `last()` | Giá trị mới nhất | `last() > 90` |
| `avg(period)` | Trung bình trong khoảng thời gian | `avg(5m) > 80` |
| `min(period)` | Giá trị nhỏ nhất trong khoảng | `min(10m) > 0` |
| `max(period)` | Giá trị lớn nhất trong khoảng | `max(1h) > 100` |
| `count(period)` | Đếm số lần trong khoảng | `count(5m,,"eq",0) >= 3` |
| `diff()` | Giá trị có thay đổi so với trước? | `diff() = 1` |
| `change()` | Mức thay đổi so với giá trị trước | `change() > 100` |
| `nodata(period)` | Không nhận dữ liệu trong khoảng | `nodata(5m) = 1` |
| `timeleft()` | Dự đoán thời gian đến ngưỡng | `timeleft(1h,,100) < 86400` |

### 1.7.4 Event và Problem

**Event** là bản ghi lịch sử của một sự kiện xảy ra trong Zabbix:
- Trigger chuyển từ OK sang PROBLEM → tạo Problem Event
- Trigger chuyển từ PROBLEM sang OK → tạo Resolution Event
- Người dùng acknowledge → tạo Acknowledge Event

**Problem** là trạng thái hiện tại khi một trigger đang ở trạng thái PROBLEM. Zabbix phân biệt **Event** (lịch sử) và **Problem** (hiện tại) để tránh nhầm lẫn.

### 1.7.5 Action — Tự động hóa phản ứng

**Action** là tập hợp các **điều kiện (Conditions)** và **thao tác (Operations)** được thực hiện khi một Event xảy ra.

```
Action = Conditions + Operations

Conditions (Điều kiện):
  - Trigger severity >= High
  - Host group = Production Servers
  - Time period = Business hours (8h-18h)

Operations (Thao tác khi PROBLEM):
  - Lập tức: Gửi email tới on-call engineer
  - Sau 30 phút: Gửi email tới Team Lead
  - Sau 60 phút: Gửi SMS tới Manager

Recovery Operations (Khi RESOLVED):
  - Gửi email thông báo đã khắc phục

Acknowledgement Operations (Khi được ACK):
  - Gửi thông báo cho người liên quan
```

### 1.7.6 Template

**Template** là **container** chứa tập hợp các cấu hình có thể tái sử dụng:
- Items
- Triggers
- Graphs
- Dashboards
- Discovery Rules
- Web Scenarios

Template có thể **kế thừa từ template khác** (linked templates), tạo ra hệ thống phân cấp linh hoạt.

```
Template Hierarchy ví dụ:
  Template: Base OS
      ├── Item: system.hostname
      ├── Item: system.uptime
      └── Trigger: Host unreachable

  Template: Linux OS (kế thừa Base OS)
      ├── Item: system.cpu.util
      ├── Item: vm.memory.size
      └── Discovery: Filesystem discovery

  Template: NGINX Web Server (kế thừa Linux OS)
      ├── Item: nginx.requests.total
      ├── Item: nginx.connections.active
      └── Trigger: NGINX process down
```

### 1.7.7 Media Types và Users

**Media Type** là kênh thông báo (Email, SMS, Telegram, Webhook...). Mỗi Media Type cần cấu hình connection parameters.

**User** trong Zabbix có:
- **Zabbix account** để đăng nhập web interface.
- **Media** (cách nhận thông báo): Email cá nhân, số điện thoại, Telegram ID.
- **User role:** Super Admin, Admin, User (phân quyền truy cập).

**User Group** quản lý quyền truy cập theo nhóm, định nghĩa:
- Quyền xem (Read) hoặc Read/Write với từng Host Group.
- Quyền truy cập API.

### 1.7.8 Macro — Biến có thể tái sử dụng

**Macro** là **biến** được dùng trong Items, Triggers, Actions để tránh hardcode giá trị. Zabbix có ba loại macro:

**1. Built-in Macros (do Zabbix cung cấp sẵn):**
```
{HOST.NAME}    — Tên host
{HOST.IP}      — IP của host
{TRIGGER.NAME} — Tên trigger
{TRIGGER.SEVERITY} — Mức độ severity
{ITEM.VALUE}   — Giá trị item kích hoạt trigger
{EVENT.DATE}   — Ngày xảy ra event
{EVENT.TIME}   — Giờ xảy ra event
```

**2. User Macros (do admin định nghĩa):**
```
Định nghĩa ở Global level:
  {$SMTP_SERVER} = mail.company.com
  {$ALERT_EMAIL} = noc@company.com

Định nghĩa ở Template level:
  {$CPU.UTIL.CRIT} = 90       ← Ngưỡng critical CPU
  {$MEMORY.UTIL.MAX} = 95     ← Ngưỡng tối đa RAM

Định nghĩa ở Host level (override template):
  {$CPU.UTIL.CRIT} = 95       ← Host database chịu tải cao hơn
```

**3. LLD Macros (trong Low-Level Discovery):**
```
{#FSNAME}    — Tên filesystem được discover (/var, /home...)
{#IFNAME}    — Tên network interface (eth0, ens3...)
```

### 1.7.9 Graph và Dashboard

**Graph** là biểu đồ theo thời gian (time series) của một hoặc nhiều Items. Graph có thể là:
- **Normal:** Đường biểu đồ thông thường
- **Stacked:** Biểu đồ xếp chồng (tốt cho phân tích thành phần)
- **Pie/Exploded:** Biểu đồ tròn (tỷ lệ phần trăm)

**Dashboard** là bảng điều khiển tùy chỉnh gồm nhiều **Widget**:
- Graph widget, Plain text, Clock
- Problems, Host availability
- Map, Geomap
- Top Hosts, SLA Report
- URL widget (nhúng trang web bên ngoài)

### 1.7.10 Map 

**Map** là sơ đồ mạng tương tác trong Zabbix, cho phép:
- Vẽ topology mạng với icon thiết bị thực tế.
- Hiển thị trạng thái thời gian thực (màu sắc thay đổi theo severity).
- Hiển thị traffic trên đường kết nối.
- Drill-down từ map này sang map khác (nested maps).

💡 **Thực tế:** Team NOC thường có màn hình lớn hiển thị Network Map với tất cả thiết bị. Khi có sự cố, màu đỏ xuất hiện ngay lập tức trên map.

### 1.7.11 Maintenance

**Maintenance** là khoảng thời gian được định nghĩa trước khi hệ thống đang bảo trì. Trong thời gian maintenance:
- Trigger PROBLEM vẫn được ghi nhận.
- **Notifications KHÔNG được gửi đi** (tránh cảnh báo giả khi reboot theo kế hoạch).
- Hai chế độ: Collect data (vẫn thu thập) hoặc No data collection.

### 1.7.12 Web Monitoring (Web Scenarios)

Zabbix có thể giả lập hành vi người dùng trên web application:
- Mở URL, gửi form, kiểm tra response.
- Kiểm tra **response code**, **response time**, **nội dung response**.
- Hỗ trợ **multi-step** (nhiều bước liên tiếp, mỗi bước phụ thuộc bước trước).

```
Web Scenario: "Check Login Portal"
  Step 1: GET https://app.company.com/
          → Expect: HTTP 200, Contains "Login"

  Step 2: POST https://app.company.com/login
          POST data: username=test&password=test
          → Expect: HTTP 302, Redirect to /dashboard

  Step 3: GET https://app.company.com/dashboard
          → Expect: HTTP 200, Contains "Welcome"
          → Check response time < 3 seconds
```

### 1.7.13 Proxy

**Zabbix Proxy** là thành phần trung gian thu thập dữ liệu thay mặt Zabbix Server. Proxy giải quyết các vấn đề:
- Giám sát **site từ xa**  qua WAN chậm.
- **Giảm tải** cho Zabbix Server bằng cách xử lý dữ liệu tại chỗ.
- Giám sát môi trường **không có kết nối trực tiếp** đến Zabbix Server (DMZ, isolated network).

*(Proxy sẽ được giải thích chi tiết trong Chương 2)*

---

## 1.8 Ví dụ thực tế trong doanh nghiệp

### 1.8.1 Tình huống 1: Công ty fintech 500 nhân viên

**Hạ tầng:** 80 server Linux , 20 server Windows (internal), 15 switch/router, 3 firewall, 2 database clusters.

**Yêu cầu monitoring:**
- Uptime 99.9% cho hệ thống thanh toán.
- Cảnh báo trong vòng 1 phút khi có sự cố.
- Report tuần/tháng cho management.

**Giải pháp Zabbix:**
- 1 Zabbix Server (production).
- Zabbix Agent trên tất cả Linux/Windows server.
- SNMP cho switch/router/firewall.
- Template tùy chỉnh cho payment gateway.
- Dashboard NOC chạy 24/7.
- Alert qua Email + Telegram cho on-call team.

### 1.8.2 Tình huống 2: Công ty sản xuất nhiều chi nhánh

**Hạ tầng:** Trụ sở HCM + 5 chi nhánh Hà Nội, Đà Nẵng, Cần Thơ, Bình Dương, Đồng Nai. Mỗi chi nhánh có 10-20 server, kết nối WAN MPLS.

**Giải pháp Zabbix:**
- 1 Zabbix Server tại trụ sở HCM.
- **1 Zabbix Proxy tại mỗi chi nhánh** — thu thập dữ liệu local, gửi về server qua WAN.
- Nếu WAN bị đứt, Proxy vẫn tiếp tục thu thập và gửi khi WAN phục hồi.
- Network Map hiển thị topology WAN toàn quốc.

---


## 2.1 Kiến trúc tổng quan

### 2.1.1 Sơ đồ kiến trúc đầy đủ

```
╔══════════════════════════════════════════════════════════════════╗
║                    ZABBIX ARCHITECTURE                          ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ┌─────────────┐    ┌─────────────┐    ┌──────────────────────┐ ║
║  │ Zabbix      │    │ Zabbix      │    │ Monitored Devices    │ ║
║  │ Web         │    │ Server      │    │                      │ ║
║  │ Frontend    │◄──►│             │◄──►│  ┌────────────────┐  │ ║
║  │ (PHP/Nginx) │    │  ┌────────┐ │    │  │ Zabbix Agent   │  │ ║
║  └─────────────┘    │  │Internal│ │    │  │ (Linux/Windows)│  │ ║
║         │           │  │Process │ │    │  └────────────────┘  │ ║
║         │           │  └────────┘ │    │                      │ ║
║         ▼           │             │    │  ┌────────────────┐  │ ║
║  ┌─────────────┐    │  ┌────────┐ │    │  │ SNMP Device    │  │ ║
║  │  Database   │◄──►│  │Poller/ │ │    │  │ (Switch/Router)│  │ ║
║  │ PostgreSQL  │    │  │Trapper │ │    │  └────────────────┘  │ ║
║  │ or MySQL    │    │  └────────┘ │    │                      │ ║
║  └─────────────┘    └─────────────┘    │  ┌────────────────┐  │ ║
║                            │           │  │ Zabbix Proxy   │  │ ║
║                            │           │  │ (Remote site)  │  │ ║
║                            └──────────►│  └────────────────┘  │ ║
║                                        └──────────────────────┘ ║
╠══════════════════════════════════════════════════════════════════╣
║  Utility Tools:  zabbix_sender │ zabbix_get │ zabbix_js        ║
╚══════════════════════════════════════════════════════════════════╝
```

### 2.1.2 Các thành phần trong hệ thống Zabbix

| Thành phần | Vai trò chính | Bắt buộc? |
|-----------|--------------|-----------|
| **Zabbix Server** | Não bộ trung tâm — điều phối, xử lý, lưu trữ | ✅ Có |
| **Database** | Lưu trữ toàn bộ cấu hình và dữ liệu | ✅ Có |
| **Zabbix Web Frontend** | Giao diện quản trị qua web browser | ✅ Thực tế |
| **Zabbix Agent / Agent 2** | Thu thập dữ liệu từ host | Tùy loại host |
| **Zabbix Proxy** | Trung gian thu thập cho remote site | Tùy kiến trúc |
| **Zabbix Sender** | Tool gửi dữ liệu vào Zabbix (script) | Tùy nhu cầu |
| **Zabbix Get** | Tool test/debug item từ command line | Tùy nhu cầu |
| **Zabbix JS** | JavaScript engine cho preprocessing | Nội bộ server |

---

## 2.2 Zabbix Server

### 2.2.1 Định nghĩa và vai trò

**Zabbix Server** là **trái tim và não bộ** của toàn bộ hệ thống Zabbix. Đây là tiến trình (daemon) trung tâm chịu trách nhiệm:

1. **Thu thập dữ liệu** từ Agents, SNMP devices, HTTP endpoints...
2. **Tính toán và đánh giá** các giá trị thu được.
3. **Đánh giá Trigger** để phát hiện PROBLEM.
4. **Tạo Event** khi trigger thay đổi trạng thái.
5. **Thực hiện Action** — gửi thông báo, chạy lệnh.
6. **Lưu trữ dữ liệu** vào database.
7. **Quản lý cấu hình** — đọc từ database, áp dụng.

### 2.2.2 Kiến trúc nội bộ của Zabbix Server

Zabbix Server là một **multi-process daemon** — khi khởi động, nó tạo ra nhiều **worker processes** (tiến trình con) chạy song song, mỗi loại đảm nhiệm một chức năng cụ thể:

```
Zabbix Server Process (zabbix_server)
│
├── Configuration Syncer    — Đồng bộ cấu hình từ DB vào memory cache
│
├── Poller (N processes)    — Chủ động poll data từ Passive Agents
├── Unreachable Poller      — Poll hosts đang không kết nối được
├── ICMP Pinger             — Ping kiểm tra host availability
│
├── Trapper (N processes)   — Nhận dữ liệu chủ động từ Active Agents
│
├── SNMP Poller             — Poll SNMP devices
├── SNMP Trapper            — Nhận SNMP traps
│
├── HTTP Agent Poller       — Thực hiện HTTP requests
│
├── Java Poller             — Poll JMX items (cần Zabbix Java Gateway)
│
├── Alerter (N processes)   — Gửi notifications (email, webhook...)
├── Alert Manager           — Quản lý hàng đợi alerts
│
├── History Syncer          — Ghi history data vào database
├── Trend Function Cache    — Cache trend data
│
├── DB Watchdog             — Giám sát kết nối database
│
├── Timer                   — Xử lý time-based events
│
├── Task Manager            — Quản lý internal tasks
│
├── Preprocessing Manager   — Điều phối preprocessing
├── Preprocessing Worker    — Thực hiện preprocessing steps
│
├── Proxy Poller            — Thu thập data từ Zabbix Proxies
│
├── Discovery Manager       — Quản lý network discovery
├── Discovery Worker        — Thực hiện discovery
│
├── VMware Collector        — Thu thập data từ VMware vCenter
│
└── Self-monitoring         — Giám sát chính Zabbix Server
```

### 2.2.3 Cấu hình quan trọng của Zabbix Server

File cấu hình: `/etc/zabbix/zabbix_server.conf`

| Tham số | Mặc định | Ý nghĩa |
|---------|---------|---------|
| `ListenPort` | 10051 | Port Zabbix Server lắng nghe (nhận từ Agents và Proxies) |
| `DBHost` | localhost | Hostname database server |
| `DBName` | zabbix | Tên database |
| `DBUser` | zabbix | User kết nối database |
| `DBPassword` | | Password database |
| `StartPollers` | 5 | Số lượng Poller processes |
| `StartTrappers` | 5 | Số lượng Trapper processes |
| `StartPreprocessors` | 3 | Số lượng Preprocessing workers |
| `StartHistorySyncers` | 4 | Số lượng History syncer processes |
| `CacheSize` | 32M | Kích thước configuration cache |
| `HistoryCacheSize` | 16M | Kích thước history cache (trước khi ghi DB) |
| `TrendCacheSize` | 4M | Kích thước trend cache |
| `Timeout` | 4 | Timeout (giây) cho agent/SNMP checks |
| `AlertScriptsPath` | /usr/lib/zabbix/alertscripts | Thư mục chứa alert scripts |
| `ExternalScripts` | /usr/lib/zabbix/externalscripts | Thư mục chứa external check scripts |
| `LogFile` | /var/log/zabbix/zabbix_server.log | File log |
| `HANodeName` | | Tên node khi dùng HA mode |

### 2.2.4 Cơ sở dữ liệu (Database)

Zabbix Server **không tự lưu trữ dữ liệu** — mọi dữ liệu đều lưu trong database. Zabbix hỗ trợ:

| Database | Phiên bản tối thiểu | Khuyến nghị Production |
|---------|--------------------|-----------------------|
| **PostgreSQL** | 13+ | ✅ **Khuyến nghị nhất** |
| **MySQL** | 8.0+ | ✅ Phổ biến |
| **MariaDB** | 10.5+ | ✅ Thay thế MySQL |
| **TimescaleDB** | PostgreSQL extension | ✅ Cho hệ thống lớn |
| **Oracle** | 12c+ | Enterprise only |

**Các bảng dữ liệu quan trọng:**

```
Bảng CẤU HÌNH (ít thay đổi):
  hosts         — Danh sách hosts
  items         — Danh sách items
  triggers      — Danh sách triggers
  actions       — Danh sách actions
  users         — Tài khoản người dùng
  templates     — Danh sách templates
  groups        — Host groups

Bảng DỮ LIỆU THU THẬP (thay đổi liên tục — nhiều nhất):
  history           — Dữ liệu số nguyên
  history_uint      — Dữ liệu số nguyên không dấu
  history_dbl       — Dữ liệu số thực (float)
  history_str       — Dữ liệu chuỗi ngắn
  history_text      — Dữ liệu chuỗi dài
  history_log       — Dữ liệu log

Bảng TREND (thống kê theo giờ):
  trends            — Trend số (min/max/avg/count theo giờ)
  trends_uint       — Trend số nguyên không dấu

Bảng SỰ KIỆN:
  events            — Lịch sử events
  problem           — Problems hiện tại
  alerts            — Alerts đã được gửi
  acknowledges      — Lịch sử acknowledge
```

📌 **Lưu ý về TimescaleDB:** Với hệ thống lớn (>10.000 items, nhiều năm dữ liệu), nên dùng **PostgreSQL + TimescaleDB**. TimescaleDB tối ưu cho time-series data, giúp query nhanh hơn và nén dữ liệu hiệu quả hơn (tiết kiệm 70-90% dung lượng).

---

## 2.3 Zabbix Agent

### 2.3.1 Định nghĩa và vai trò

**Zabbix Agent** là một daemon nhỏ được cài đặt **trên máy chủ cần giám sát**. Agent thu thập dữ liệu từ hệ thống cục bộ (CPU, RAM, Disk, Process, Log...) và gửi về Zabbix Server hoặc Proxy.

**Tại sao cần Agent thay vì chỉ dùng SNMP?**
- Agent cho phép truy cập dữ liệu **chi tiết hơn** mà SNMP không có: nội dung file log, trạng thái process cụ thể, chạy custom script.
- Agent **bảo mật hơn**: không cần mở thêm port SNMP, có thể mã hóa TLS.
- Agent **hiệu suất tốt hơn**: ít overhead hơn so với SNMP polling.

### 2.3.2 Hai chế độ hoạt động: Passive vs Active

Đây là khái niệm **cực kỳ quan trọng** và thường gây nhầm lẫn. Cần hiểu từ góc nhìn của **Agent** (không phải Server).

#### Passive Mode (Chế độ thụ động)

```
Zabbix Server                    Zabbix Agent
     │                                │
     │  "Cho tôi giá trị CPU?"        │
     │ ──────────────────────────────►│
     │                                │  Thu thập CPU
     │         Giá trị: 45.2%         │
     │◄──────────────────────────────│
     │                                │
  (Lặp lại mỗi interval)
```

- **Server chủ động kết nối đến Agent** (Server → Agent).
- Server gửi yêu cầu, Agent phản hồi.
- **Agent lắng nghe trên port 10050**.
- Server phải có thể kết nối đến port 10050 của Agent.
- Mỗi item được poll độc lập → nhiều kết nối TCP.

#### Active Mode (Chế độ chủ động)

```
Zabbix Server                    Zabbix Agent
     │                                │
     │  "Tôi cần collect những gì?"   │
     │◄──────────────────────────────│ (Agent hỏi Server)
     │                                │
     │  "Hãy collect: CPU, RAM, Disk" │
     │ ──────────────────────────────►│
     │                                │
     │                                │  Thu thập theo schedule
     │                                │  Buffer data cục bộ
     │                                │
     │  [Data batch: CPU=45, RAM=70]  │
     │◄──────────────────────────────│ (Agent gửi batch về)
     │                                │
  (Server lắng nghe port 10051)
```

- **Agent chủ động kết nối đến Server** (Agent → Server).
- Agent đến hỏi Server "tôi cần collect gì?", sau đó tự collect và gửi về.
- **Server lắng nghe trên port 10051**.
- Agent cần có thể kết nối ra ngoài đến port 10051 của Server.
- Agent buffer dữ liệu cục bộ nếu Server tạm thời không kết nối được.

#### So sánh Passive vs Active

| Tiêu chí | Passive Mode | Active Mode |
|---------|-------------|-------------|
| **Ai khởi tạo kết nối** | Server → Agent | Agent → Server |
| **Port mở trên Agent** | 10050 (inbound) | Không cần (chỉ outbound) |
| **Port mở trên Server** | Không cần | 10051 (inbound) |
| **Phù hợp khi** | Agent trong vùng có thể reach từ Server | Agent sau firewall/NAT, không reach được từ ngoài |
| **Hiệu suất** | Thấp hơn (nhiều kết nối) | **Cao hơn** (batch data) |
| **Buffer khi mất kết nối** | Không (mất data) | **Có** (lưu cục bộ rồi gửi lại) |
| **Khuyến nghị** | Môi trường đơn giản | **Môi trường doanh nghiệp** |

💡 **Best Practice:** Trong môi trường doanh nghiệp, **Active Mode được khuyến nghị** vì hiệu suất tốt hơn và không cần mở port inbound trên từng host được giám sát.

### 2.3.3 Các Item Keys phổ biến của Zabbix Agent

```
Hệ thống:
  system.cpu.util[,user]         — CPU % dùng bởi user
  system.cpu.util[,system]       — CPU % dùng bởi kernel
  system.cpu.load[all,avg1]      — Load average 1 phút
  vm.memory.size[available]      — RAM available (bytes)
  vm.memory.size[pavailable]     — RAM available (%)
  system.swap.size[,pfree]       — Swap free (%)
  system.uptime                  — Thời gian uptime (giây)
  system.hostname                — Hostname
  kernel.maxfiles                — Max open files

Filesystem:
  vfs.fs.size[/,used]            — Disk used (bytes)
  vfs.fs.size[/,pfree]           — Disk free (%)
  vfs.fs.inode[/,pfree]          — Inodes free (%)

Network:
  net.if.in[eth0]                — Bytes received
  net.if.out[eth0]               — Bytes sent
  net.if.total[eth0]             — Total bytes
  net.tcp.service[ssh,,22]       — SSH service check

Process:
  proc.num[nginx]                — Số nginx processes đang chạy
  proc.mem[nginx,,sum]           — RAM dùng bởi nginx
  proc.cpu.util[mysql]           — CPU dùng bởi mysql

Log:
  log[/var/log/nginx/error.log,error,,100] — Monitor log file
  logrt[/var/log/app/*.log,CRITICAL]       — Monitor rotating logs

Custom (UserParameter):
  UserParameter=custom.check,/usr/local/bin/my_check.sh
```

### 2.3.4 UserParameter — Mở rộng Agent

**UserParameter** cho phép định nghĩa các item key tùy chỉnh, chạy bất kỳ script nào và trả về kết quả cho Zabbix.

```ini
# Trong /etc/zabbix/zabbix_agentd.conf.d/custom.conf

# Kiểm tra số kết nối đến MySQL
UserParameter=mysql.connections,mysql -u zabbix -pZabbixPass -e \
  "SHOW STATUS LIKE 'Threads_connected';" | awk '/Threads/ {print $2}'

# Kiểm tra dung lượng một thư mục cụ thể
UserParameter=dir.size[*],du -sb $1 | awk '{print $1}'

# Kiểm tra trạng thái custom application
UserParameter=app.status,/usr/local/bin/check_app_status.sh
```

### 2.3.5 Zabbix Agent vs Zabbix Agent 2

Zabbix Agent 2 là thế hệ agent mới, viết lại hoàn toàn bằng **Go** thay vì C.

| Tiêu chí | Zabbix Agent (C) | Zabbix Agent 2 (Go) |
|---------|-----------------|---------------------|
| **Ngôn ngữ** | C | Go |
| **Hiệu suất** | Tốt | **Tốt hơn** (goroutines) |
| **Plugin system** | Hạn chế | ✅ **Plugin phong phú** |
| **Concurrent checks** | Hạn chế | ✅ **Tốt hơn** |
| **Native plugins** | — | MySQL, PostgreSQL, Redis, Docker, Kubernetes, Ceph... |
| **Custom plugins** | UserParameter | UserParameter + Go plugins |
| **Configuration** | Tương tự | Tương tự + plugin config |
| **Hỗ trợ OS** | Linux, Windows, macOS | Linux, Windows |
| **Khuyến nghị** | Đủ dùng cho môi trường cơ bản | ✅ **Khuyến nghị cho môi trường mới** |

📌 **Lưu ý:** Nếu cần giám sát MySQL, PostgreSQL, Redis, Docker, Kubernetes — hãy dùng **Zabbix Agent 2** với các plugin tích hợp sẵn, thay vì viết UserParameter thủ công.

---

## 2.6 Zabbix Proxy

### 2.6.1 Định nghĩa và vai trò

**Zabbix Proxy** là một thành phần tùy chọn, đóng vai trò **trung gian** (intermediate) giữa Zabbix Server và các thiết bị được giám sát. Proxy thu thập dữ liệu thay mặt Server và **lưu trữ tạm thời** trước khi chuyển tiếp về Server.

```
KHÔNG có Proxy:
  [Zabbix Server] ────────────────────────────────► [Remote Agents]
                        WAN (200ms latency, 10Mbps)

CÓ Proxy:
  [Zabbix Server] ──────► [Zabbix Proxy] ──────────► [Remote Agents]
                    WAN          │            LAN
                 (1 kết nối)     │         (nhanh, ổn định)
                                 │  Buffer data cục bộ
                                 │  Gửi batch về Server
```

### 2.6.2 Khi nào cần Zabbix Proxy?

✅ **Cần dùng Proxy khi:**

**1. Remote Sites (Chi nhánh từ xa):**
Giám sát chi nhánh qua WAN (MPLS, VPN). Proxy ở chi nhánh thu thập dữ liệu locally, giảm traffic WAN từ hàng nghìn kết nối xuống còn 1 kết nối batch.

**2. Network Segmentation / DMZ:**
Các server trong DMZ không cho phép kết nối inbound từ bên ngoài. Proxy trong DMZ thu thập dữ liệu rồi gửi về Server (outbound only).

**3. Large Scale:**
Giảm tải cho Zabbix Server. Mỗi Proxy xử lý một phần workload.

**4. Network Reliability:**
Khi WAN không ổn định. Proxy buffer dữ liệu khi mất kết nối, gửi lại khi kết nối phục hồi — không mất dữ liệu.

**5. Nhiều môi trường network riêng biệt:**
Kubernetes cluster, Cloud VPC, IoT network — Proxy cầu nối các môi trường này với Zabbix Server trung tâm.

### 2.6.3 Hai chế độ Proxy: Active vs Passive

Tương tự Agent, Proxy cũng có hai chế độ (nhìn từ góc độ **Proxy**):

| | **Proxy Active Mode** | **Proxy Passive Mode** |
|--|----------------------|----------------------|
| **Ai kết nối** | Proxy kết nối đến Server | Server kết nối đến Proxy |
| **Port** | Server port 10051 | Proxy port 10051 |
| **Proxy database** | Bắt buộc | Bắt buộc |
| **Phù hợp** | Proxy sau firewall | Server có thể reach Proxy |
| **Khuyến nghị** | ✅ **Phổ biến hơn** | Ít phổ biến |

### 2.6.4 Zabbix Proxy cần database riêng

Proxy cần một **database cục bộ** (MySQL/PostgreSQL) để:
- Buffer dữ liệu thu thập được.
- Lưu cấu hình monitoring được nhận từ Server.
- Đảm bảo không mất data khi WAN không ổn định.

```
Proxy Local DB:
  proxy_history  — Lưu tạm dữ liệu chờ gửi về Server
  proxy_dhistory — Dữ liệu discovery
  proxy_autoreg  — Auto-registration data
```

### 2.6.5 Sơ đồ kiến trúc với Proxy

```
Trụ sở HCM:
  ┌─────────────────────────────────────────────┐
  │  [Zabbix Server] ◄──► [PostgreSQL]          │
  │       ▲                                     │
  │       │ HTTPS                               │
  │  [Zabbix Web]                               │
  └───────┼─────────────────────────────────────┘
          │
          │ Internet / MPLS WAN
          │
  ┌───────┼─────────────────────────────────────┐
  │ Chi nhánh Hà Nội       ▼                    │
  │  [Zabbix Proxy] ◄──► [SQLite/MySQL]         │
  │       │                                     │
  │       │ LAN                                 │
  │  ┌────┴────┐  ┌─────────┐  ┌─────────┐     │
  │  │server-1 │  │server-2 │  │switch-1 │     │
  │  │(Agent)  │  │(Agent)  │  │(SNMP)   │     │
  │  └─────────┘  └─────────┘  └─────────┘     │
  └─────────────────────────────────────────────┘
```

---

## 2.7 Zabbix Web Frontend

### 2.7.1 Định nghĩa và vai trò

**Zabbix Web Frontend** là giao diện quản trị web được viết bằng **PHP**, chạy trên web server (Nginx hoặc Apache). Đây là giao diện mà admin sử dụng hàng ngày để:

- Xem Dashboards, Problems, Events.
- Cấu hình Hosts, Items, Triggers, Actions.
- Quản lý Users, User Groups, Roles.
- Xem và phân tích Graphs, Reports.
- Quản lý Templates, Maintenance.
- Truy cập API endpoint.

### 2.7.2 Kiến trúc Web Frontend

```
Browser
   │ HTTPS (443)
   ▼
[Nginx / Apache]
   │ PHP-FPM
   ▼
[Zabbix PHP Application]
   │         │
   │         ▼
   │    [Zabbix Server]   ← Web gửi commands tới Server
   │    (port 10051)        (force check, script execution)
   │
   ▼
[Database]               ← Web đọc/ghi trực tiếp vào DB
(port 5432/3306)           (cấu hình, lịch sử, users)
```

📌 **Quan trọng:** Zabbix Web Frontend kết nối **trực tiếp đến Database** để đọc dữ liệu hiển thị. Web cũng kết nối đến Zabbix Server để gửi một số lệnh real-time (ví dụ: force check item, chạy remote script). Tuy nhiên, **dữ liệu monitoring không đi qua Web** — chỉ đi qua Server.

### 2.7.3 Yêu cầu hệ thống cho Web Frontend

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|-----------|------------------|-------------|
| **Web server** | Nginx 1.18+ / Apache 2.4+ | Nginx |
| **PHP** | 8.0+ | 8.2+ |
| **PHP extensions** | bcmath, ctype, gd, json, ldap, mbstring, mysqli/pgsql, session, sockets, xml, xmlreader, zip | Tất cả |
| **RAM cho PHP** | 128 MB | 256 MB |
| **Thời gian thực thi PHP** | 300 giây | 300 giây |

### 2.7.4 Separation of concerns — Tách Web và Server

Trong môi trường production, **Web Frontend và Zabbix Server CÓ THỂ cài trên các server khác nhau**:

```
Server 1: Zabbix Server + Database (backend — không expose internet)
Server 2: Zabbix Web Frontend (frontend — expose HTTPS ra ngoài)

Lợi ích:
  - Web server có thể bị tấn công web, không ảnh hưởng Server
  - Có thể đặt nhiều Web Frontend instance (load balanced)
  - Database bảo mật hơn khi không expose trực tiếp
```

---

## 2.8 Zabbix Sender

### 2.8.1 Định nghĩa và vai trò

**Zabbix Sender** (`zabbix_sender`) là một **command-line utility** (công cụ dòng lệnh) cho phép **bất kỳ script hay ứng dụng nào** gửi dữ liệu vào Zabbix, mà không cần cài Zabbix Agent.

Cơ chế: Sender gửi dữ liệu đến **Zabbix Server port 10051** (cùng port với Active Agent). Trên Zabbix Server, Item tương ứng phải được cấu hình kiểu **"Zabbix Trapper"**.

### 2.8.2 Luồng hoạt động

```
[Script/Application]
    │
    │  zabbix_sender -z server -s host -k key -o value
    │
    ▼
[Zabbix Server :10051]  ← Trapper process nhận data
    │
    ▼
[Preprocessing] → [History Syncer] → [Database]
    │
    ▼
[Trigger Evaluation] → [Event] → [Action/Alert]
```

### 2.8.3 Trường hợp sử dụng thực tế

**1. Kết quả Batch Jobs:**
```bash
# Script chạy backup hàng đêm, gửi kết quả vào Zabbix
BACKUP_STATUS=0  # 0=success, 1=failed
BACKUP_SIZE=$(du -sb /backup/latest | awk '{print $1}')
BACKUP_DURATION=3600  # giây

zabbix_sender -z zabbix.company.com \
  -s "backup-server" \
  -k "backup.status" \
  -o "$BACKUP_STATUS"

zabbix_sender -z zabbix.company.com \
  -s "backup-server" \
  -k "backup.size" \
  -o "$BACKUP_SIZE"
```

**2. Custom Application Metrics:**
```bash
# Ứng dụng Java gửi metrics qua zabbix_sender
ACTIVE_SESSIONS=$(curl -s http://app:8080/metrics | jq '.sessions.active')
QUEUE_LENGTH=$(curl -s http://app:8080/metrics | jq '.queue.length')

zabbix_sender -z zabbix.company.com \
  -s "app-server-01" \
  --input-file - << EOF
app.sessions.active $ACTIVE_SESSIONS
app.queue.length $QUEUE_LENGTH
EOF
```

**3. Gửi nhiều giá trị cùng lúc (batch):**
```bash
# File chứa nhiều metrics
cat /tmp/metrics.txt
# app-server-01 app.cpu 45.2 1718000000
# app-server-01 app.memory 2048 1718000000
# app-server-02 app.cpu 32.1 1718000000

zabbix_sender -z zabbix.company.com \
  --input-file /tmp/metrics.txt \
  --with-timestamps
```

📌 **Lưu ý:** Item trên Zabbix phải có type = **"Zabbix Trapper"** để nhận dữ liệu từ Sender. Sender và Trapper dùng chung port 10051.

---

## 2.9 Zabbix Get

### 2.9.1 Định nghĩa và vai trò

**Zabbix Get** (`zabbix_get`) là một **command-line utility** dùng để **test và debug** — giúp admin kiểm tra xem Zabbix Agent có đang hoạt động đúng không, và một Item key cụ thể trả về giá trị gì, **trực tiếp từ command line** mà không cần đợi Zabbix Server poll.

### 2.9.2 Cơ chế hoạt động

```
Admin (terminal)
    │
    │  zabbix_get -s agent-host -p 10050 -k "system.cpu.util"
    │
    ▼
[Zabbix Agent :10050]  ← Passive mode — Agent nhận request
    │                     Thu thập CPU utilization
    │
    ▼
  45.23                ← Trả về giá trị trực tiếp ra terminal
```

📌 **Lưu ý:** `zabbix_get` chỉ hoạt động với **Passive Mode** agent (kết nối trực tiếp đến port 10050 của Agent). Không thể dùng với Active Mode agent.

### 2.9.3 Các lệnh thực tế

```bash
# Test cơ bản — kiểm tra agent kết nối được không
zabbix_get -s 192.168.1.100 -p 10050 -k agent.ping
# Kết quả: 1 (thành công)

# Kiểm tra CPU utilization
zabbix_get -s 192.168.1.100 -p 10050 -k "system.cpu.util[,user]"
# Kết quả: 45.231234

# Kiểm tra disk usage
zabbix_get -s 192.168.1.100 -p 10050 -k "vfs.fs.size[/,pfree]"
# Kết quả: 68.492341

# Kiểm tra số nginx process
zabbix_get -s 192.168.1.100 -p 10050 -k "proc.num[nginx]"
# Kết quả: 4

# Kiểm tra custom UserParameter
zabbix_get -s 192.168.1.100 -p 10050 -k "custom.db.connections"
# Kết quả: 47

# Test với TLS (PSK)
zabbix_get -s 192.168.1.100 -p 10050 \
  --tls-connect psk \
  --tls-psk-identity "PSK001" \
  --tls-psk-file /etc/zabbix/zabbix_agent.psk \
  -k agent.version
```

### 2.9.4 Khi nào dùng zabbix_get?

✅ **Dùng zabbix_get để:**
- Kiểm tra agent đã cài đúng và đang chạy chưa.
- Debug tại sao một Item trên Zabbix trả về "Not supported" hoặc giá trị sai.
- Kiểm tra UserParameter script có chạy đúng không.
- Kiểm tra kết nối network từ Server đến Agent.
- Nhanh chóng lấy giá trị từ agent mà không cần vào Zabbix web.

---

## 2.10 Zabbix JS

### 2.10.1 Định nghĩa và vai trò

**Zabbix JS** (`zabbix_js`) là một **command-line utility** cho phép chạy **JavaScript code** ngoài môi trường Zabbix, sử dụng cùng JavaScript engine (**Duktape**) mà Zabbix Server dùng cho preprocessing và webhook scripts.

Mục đích chính: **Test và debug** JavaScript code trước khi đưa vào Preprocessing steps hoặc Webhook scripts trong Zabbix.

### 2.10.2 JavaScript Engine trong Zabbix — Duktape

Zabbix sử dụng **Duktape** — một JavaScript engine nhúng (embedded) tiêu thụ rất ít tài nguyên. Duktape hỗ trợ ES5/ES5.1 và một số tính năng ES6.

**Hạn chế của Duktape so với Node.js:**
- Không có `fetch()` hay `XMLHttpRequest` gốc (Zabbix bổ sung `Zabbix.Log()`, `HttpRequest`)
- Không có `require()` / module system
- Không có async/await (trừ native Zabbix functions)
- Bộ thư viện chuẩn hạn chế hơn

**Zabbix mở rộng Duktape với các objects:**
```javascript
// Zabbix built-in objects trong JavaScript context

// HTTP Client
var req = new HttpRequest();
req.addHeader('Content-Type: application/json');
var resp = req.post('https://api.example.com/data',
  JSON.stringify({key: 'value'})
);

// Logging
Zabbix.Log(4, 'Debug message');  // 4 = DEBUG level

// Trong preprocessing:
// 'value' chứa giá trị raw từ item
var data = JSON.parse(value);
return data.metrics.cpu;
```

### 2.10.3 Sử dụng zabbix_js

```bash
# Chạy JavaScript file
zabbix_js -s /path/to/script.js -p "input_parameter"

# Ví dụ script.js
cat > /tmp/test_preprocessing.js << 'EOF'
// Giả lập preprocessing: parse JSON và lấy giá trị
var input = value;  // 'value' là tham số -p
var data = JSON.parse(input);
return data.server.cpu_usage;
EOF

zabbix_js -s /tmp/test_preprocessing.js \
  -p '{"server":{"cpu_usage":45.2,"memory":70.1}}'
# Output: 45.2
```

### 2.10.4 Ứng dụng JavaScript trong Zabbix

**1. Preprocessing — Biến đổi dữ liệu:**
```javascript
// Item thu thập JSON từ API:
// {"status": "OK", "metrics": {"cpu": 45.2, "ram": 70.1}}
// Preprocessing step: JavaScript
var data = JSON.parse(value);
if (data.status !== 'OK') {
    throw 'API returned error status: ' + data.status;
}
return data.metrics.cpu;
// Item nhận giá trị: 45.2
```

**2. Webhook Script — Gửi notification:**
```javascript
// Media Type: Webhook — Gửi alert đến Telegram
var params = JSON.parse(value);
var token = params.token;
var chat_id = params.chat_id;
var message = params.message;

var req = new HttpRequest();
req.addHeader('Content-Type: application/json');

var body = JSON.stringify({
    chat_id: chat_id,
    text: '🚨 ZABBIX ALERT\n' + message,
    parse_mode: 'HTML'
});

var url = 'https://api.telegram.org/bot' + token + '/sendMessage';
var resp = req.post(url, body);

var result = JSON.parse(resp);
if (!result.ok) {
    throw 'Telegram API error: ' + result.description;
}
return 'OK';
```

---

## 2.11 Luồng dữ liệu trong hệ thống Zabbix

### 2.11.1 Tổng quan luồng dữ liệu

Đây là phần **cốt lõi nhất** của chương. Hiểu luồng dữ liệu giúp admin troubleshoot bất kỳ vấn đề nào trong Zabbix.

```
══════════════════════════════════════════════════════════════
             LUỒNG DỮ LIỆU ZABBIX — ĐẦY ĐỦ
══════════════════════════════════════════════════════════════

NGUỒN DỮ LIỆU          THU THẬP              XỬ LÝ
─────────────────────────────────────────────────────────────

[Passive Agent]  ──────►  Poller             │
[SNMP Device]    ──────►  SNMP Poller         │
[HTTP Endpoint]  ──────►  HTTP Agent Poller   │  Preprocessing
[JMX App]        ──────►  Java Poller         │  Manager &
[Active Agent]   ──────►  Trapper             │  Workers
[Zabbix Sender]  ──────►  Trapper             │
[External Script]──────►  External Poller     │
[DB Query]       ──────►  DB Poller           │
[SSH Command]    ──────►  SSH Poller          ▼

══════════════════════════════════════════════
                    │
                    ▼
            ┌──────────────┐
            │Preprocessing │  → JSONPath, Regex, Math, JS
            │Manager       │
            └──────────────┘
                    │
                    ▼ Giá trị đã xử lý
            ┌──────────────┐
            │History Cache │  → Buffer trong RAM
            │(memory)      │
            └──────────────┘
                    │
                    ▼ (flush theo batch)
            ┌──────────────┐
            │History       │  → Ghi vào Database
            │Syncer        │    (history, trends tables)
            └──────────────┘
                    │
                    │ (song song)
                    ▼
            ┌──────────────┐
            │Trigger       │  → Đánh giá expressions
            │Evaluation    │    So sánh với ngưỡng
            └──────────────┘
                    │
            ┌───────┴────────┐
            │                │
            ▼ PROBLEM        ▼ OK
        ┌────────┐      ┌────────┐
        │Problem │      │Problem │
        │Created │      │Resolved│
        └────────┘      └────────┘
            │                │
            ▼                ▼
        ┌────────────────────────┐
        │     Event Created      │
        └────────────────────────┘
                    │
                    ▼
        ┌────────────────────────┐
        │   Action Evaluation    │
        │   (Check conditions)   │
        └────────────────────────┘
                    │
            ┌───────┴────────┐
            │                │
            ▼                ▼
        ┌────────┐      ┌────────────┐
        │Send    │      │Remote      │
        │Alert   │      │Command     │
        │Email/  │      │(restart    │
        │Telegram│      │ service)   │
        └────────┘      └────────────┘
```

### 2.11.2 Luồng dữ liệu — Passive Agent (chi tiết)

```
T=0s: Item interval đến hạn (ví dụ: mỗi 60 giây)
  │
  ▼
T=0.0s: Poller process chọn item từ queue
  │     (item: "system.cpu.util" trên "web-server-01")
  │
  ▼
T=0.0s: Poller mở TCP connection đến Agent
  │     (IP: 192.168.1.10, Port: 10050)
  │
  ▼
T=0.1s: Gửi request: "system.cpu.util\n"
  │
  ▼
T=0.1s: Agent nhận request
  │     Agent thu thập CPU từ /proc/stat
  │     Agent tính toán giá trị
  │
  ▼
T=0.2s: Agent trả về: "ZBXD\x01...45.231234\n"
  │
  ▼
T=0.2s: Poller nhận response, đóng TCP connection
  │     Ghi giá trị "45.231234" vào preprocessing queue
  │
  ▼
T=0.3s: Preprocessing Worker nhận giá trị
  │     (nếu có preprocessing steps: thực hiện)
  │     Kết quả: 45.231234 (float)
  │
  ▼
T=0.3s: Giá trị được ghi vào History Cache (RAM)
  │
  ▼
T=~1s: History Syncer gom nhiều giá trị, flush vào DB
  │    INSERT INTO history_dbl (itemid, clock, value)
  │    VALUES (12345, 1718000000, 45.231234)
  │
  ▼
T=~1s: Trigger Evaluation
  │    Trigger: {web-server-01:system.cpu.util.avg(5m)} > 90
  │    avg(5m) = 45.23 → 45.23 > 90? → FALSE → OK
  │
  ▼
  Không có Problem → Không có Event → Không có Alert
```

### 2.11.3 Luồng dữ liệu — Active Agent (chi tiết)

```
PHASE 1: Active Agent đăng ký và lấy cấu hình (mỗi ~2 phút)
──────────────────────────────────────────────────────────────

T=0s: Zabbix Agent khởi động
  │
  ▼
Agent → Server (port 10051):
  "active checks" request với hostname: "web-server-01"
  │
  ▼
Server → Agent:
  Gửi danh sách items cần collect:
  [
    {"key": "system.cpu.util", "delay": 60},
    {"key": "vm.memory.size[available]", "delay": 30},
    {"key": "vfs.fs.size[/,pfree]", "delay": 300}
  ]
  │
  ▼
Agent lưu list vào memory, bắt đầu schedule collecting

PHASE 2: Agent thu thập và gửi data (liên tục)
──────────────────────────────────────────────────────────────

T=60s: Item "system.cpu.util" đến hạn
  │
  ▼
Agent thu thập CPU từ /proc/stat → 45.23%
Agent buffer giá trị cùng timestamp

T=60.1s: Agent gửi batch đến Server (port 10051):
  {
    "request": "agent data",
    "data": [
      {"host": "web-server-01",
       "key": "system.cpu.util",
       "value": "45.231234",
       "clock": 1718000000}
    ]
  }
  │
  ▼
Server Trapper nhận → Preprocessing → History Cache → DB → Trigger
```

### 2.11.4 Luồng cảnh báo — Từ PROBLEM đến Notification

```
Database: history_dbl chứa 5 phút CPU data
  [45.1, 45.8, 92.3, 93.1, 91.7]  ← giá trị mới nhất cao bất thường

Trigger Evaluation (mỗi khi có giá trị mới):
  Expression: {web-server-01:system.cpu.util.avg(5m)} > 90
  avg(45.1, 45.8, 92.3, 93.1, 91.7) = 73.6
  73.6 > 90? → FALSE → Vẫn OK...

  [Sau thêm 2 phút dữ liệu cao]
  avg(92.3, 93.1, 91.7, 94.2, 95.8) = 93.4
  93.4 > 90? → TRUE → PROBLEM! 🔴
  │
  ▼
Event Manager:
  Tạo Problem event:
  - Trigger: "CPU utilization too high on web-server-01"
  - Severity: High
  - Time: 2026-06-23 10:15:32
  │
  ▼
Action Engine — Đánh giá tất cả Actions:
  Action: "Alert Production Server Issues"
  Conditions:
    ✓ Trigger severity >= High
    ✓ Host group = Production Servers
    ✓ Trigger name contains "CPU"
  → Conditions met → Execute Operations
  │
  ▼
Operation 1 (0 phút): Send message
  Recipients: on-call-group
  Media: Email + Telegram
  Message:
    "PROBLEM: CPU utilization too high on web-server-01
     Host: web-server-01 (192.168.1.10)
     Severity: HIGH
     Value: 93.4%
     Time: 2026-06-23 10:15:32"
  │
  ▼
Alerter Process:
  → Gửi Email qua SMTP
  → Gửi Telegram qua Bot API
  → Ghi vào alerts table trong DB
  │
  ▼
[30 phút sau — vẫn chưa resolve]
Escalation Operation 2:
  → Gửi thông báo cho Team Lead
  │
  ▼
[CPU về bình thường < 90% trong 5 phút]
Trigger: OK
  │
  ▼
Event Manager: Tạo Recovery Event
  │
  ▼
Recovery Operations:
  → Gửi "RESOLVED" notification
  → Đóng Problem
```

### 2.11.5 Luồng dữ liệu qua Zabbix Proxy

```
[Remote Site — Hà Nội]                    [HCM — Zabbix Server]
─────────────────────────────────────────────────────────────────

Zabbix Proxy                               Zabbix Server
  │                                              │
  │ 1. Kết nối đến Server (port 10051)           │
  │ 2. Yêu cầu: "cấu hình monitor của tôi?"      │
  │ ────────────────────────────────────────────►│
  │                                              │
  │    Gửi config: hosts, items, triggers         │
  │    của site Hà Nội                           │
  │◄────────────────────────────────────────────│
  │                                              │
  │ Lưu config vào Proxy local DB                │
  │                                              │

[Cứ mỗi interval:]
Proxy poll/nhận data từ local agents:
  ├── server-hn-01 (Agent Active)
  ├── server-hn-02 (Agent Passive)
  └── switch-hn-01 (SNMP)
  │
  ▼
Preprocessing (ngay tại Proxy)
  │
  ▼
Lưu vào Proxy Local DB (buffer)
  │
  ▼ (batch gửi về, mặc định mỗi 1 giây)

  │ Kết nối đến Server (port 10051)
  │ Gửi batch data:
  │ {"request": "proxy data",
  │  "data": [...all buffered values...]}
  │ ────────────────────────────────────────────►│
  │                                              │
  │               "OK"                          │
  │◄────────────────────────────────────────────│
  │                                              │
  │ Xóa data đã gửi khỏi local DB               │ Nhận data
  │                                              │ → History Cache
  │                                              │ → DB
  │                                              │ → Trigger Evaluation
  │                                              │ → Actions/Alerts
```

---

## 2.12 Ports và Network Requirements

### 2.12.1 Tổng hợp ports Zabbix

| Kết nối | Source | Destination | Port | Protocol |
|---------|--------|------------|------|---------|
| Zabbix Server ← Passive Agent | Server | Agent | **10050** | TCP |
| Zabbix Server ← Active Agent | Agent | Server | **10051** | TCP |
| Zabbix Web ← Browser | Browser | Web Server | **443** (80) | HTTPS |
| Zabbix Web → Database | Web | DB | 5432 (PG) / 3306 (MySQL) | TCP |
| Zabbix Server → Database | Server | DB | 5432 / 3306 | TCP |
| Zabbix Server ← Proxy (Active) | Proxy | Server | **10051** | TCP |
| Zabbix Server → Proxy (Passive) | Server | Proxy | **10051** | TCP |
| Zabbix Server → SNMP Device | Server | Device | **161** | UDP |
| SNMP Device → Zabbix Server | Device | Server | **162** | UDP (traps) |
| Zabbix Server → JMX | Server | Java GW | **10052** | TCP |

### 2.12.2 Firewall rules mẫu

```
Trên Zabbix Server (iptables/ufw):
  ALLOW IN  tcp 10051  (từ Agents Active và Proxies Active)
  ALLOW IN  tcp 443    (từ admin browsers)
  ALLOW OUT tcp 10050  (đến Passive Agents)
  ALLOW OUT udp 161    (đến SNMP devices)
  ALLOW IN  udp 162    (từ SNMP traps)

Trên Zabbix Agent (Passive Mode):
  ALLOW IN  tcp 10050  (từ Zabbix Server IP only)

Trên Zabbix Agent (Active Mode):
  ALLOW OUT tcp 10051  (đến Zabbix Server)
  (Không cần mở port inbound nào)
```

---

## 2.13 Ví dụ thực tế trong doanh nghiệp

### 2.13.1 Tình huống: E-commerce company — Kiến trúc monitoring đầy đủ

**Hạ tầng:**
- 50 Linux servers (production, staging)
- 3 MySQL database servers
- 10 Nginx web servers
- 5 Redis cache servers
- 2 Kubernetes clusters
- 2 data center: HCM + Hà Nội (kết nối MPLS)
- Cloud: AWS (10 EC2 instances)

**Kiến trúc Zabbix đề xuất:**

```
                    ┌─────────────────────────────┐
                    │   Zabbix Server (HCM DC)    │
                    │   Ubuntu 22.04, 16 CPU, 32GB│
                    │   Zabbix 7.0 LTS            │
                    ├─────────────────────────────┤
                    │   PostgreSQL + TimescaleDB   │
                    │   Ubuntu 22.04, 8 CPU, 64GB  │
                    ├─────────────────────────────┤
                    │   Zabbix Web Frontend       │
                    │   Nginx + PHP 8.2           │
                    └──────────┬──────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
  ┌──────────────┐   ┌──────────────┐   ┌─────────────────┐
  │ Zabbix Proxy │   │ Zabbix Proxy │   │  Zabbix Proxy   │
  │ HN DC        │   │ AWS Region   │   │  K8s Cluster    │
  │              │   │              │   │                 │
  │ Monitor:     │   │ Monitor:     │   │ Monitor:        │
  │ HN servers   │   │ EC2 instances│   │ Pods, Nodes     │
  │ HN network   │   │ RDS, ELB     │   │ Services        │
  └──────────────┘   └──────────────┘   └─────────────────┘
```

**Lý do thiết kế:**
- **Proxy HN DC:** Giám sát 20 server tại HN, giảm WAN traffic, đảm bảo data không mất khi MPLS chập chờn.
- **Proxy AWS:** Giám sát cloud resources trong private VPC (không expose internet).
- **Proxy K8s:** Kubernetes có network riêng, Proxy trong cluster truy cập nội bộ.
- **TimescaleDB:** Lượng data lớn (50+ servers × nhiều items × nhiều năm), TimescaleDB nén và query hiệu quả hơn PostgreSQL thuần.

---


---
