# Báo cáo thực tập ngày 12 - Web server chuyên sâu(tiếp)
## Hiệu suất và Monitoring
Monitoring (giám sát) là quá trình theo dõi, quan sát và thu thập dữ liệu liên tục về một hệ thống, hoạt động hoặc đối tượng nào đó để biết nó đang hoạt động như thế nào.
Mục đích của monitoring:
* Phát hiện sự cố sớm
* Đảm bảo hệ thống hoạt động ổn định
* Thu thập dữ liệu để phân tích và cải thiện
* Cảnh báo khi có bất thường

Hiệu suất là mức độ hoạt động nhanh, ổn định, hiệu quả của một hệ thống.

###  Công cụ đo lường hiệu suất (Apache Benchmark, JMeter).
Mục đích của các công cụ này là  kiểm tra xem hệ thống chúng ta chịu được tối đa bao nhiêu người truy cập cùng lúc trước khi bị chậm hoặc sập
Apache Benchmark (ab):  
Đặc điểm: Là một công cụ dòng lệnh (CLI) rất nhẹ, nhỏ gọn và được tích hợp sẵn cùng Apache web server.  
Tác dụng: Dùng để test "sức chịu đựng" nhanh gọn cho một đường dẫn (URL) cụ thể. Nó sẽ gửi liên tục hàng ngàn requests đến server để xem server xử lý mất bao lâu.  
#### Cài đặt ab
sudo apt install apache2-utils: trong gói này có sẵn ab
CÚ PHÁP CƠ BẢN  
 **ab -n [tổng request] -c [concurrent] [URL]**

 VD: Baseline — 100 request, 10 cùng lúc  
ab -n 100 -c 10 http://192.168.136.131/  
<img width="516" height="366" alt="{E458DCC7-832D-4035-AE1E-D7742B7AE181}" src="https://github.com/user-attachments/assets/27c263a5-74be-45e4-9866-1a9e9e2d8319" />
<img width="386" height="234" alt="{D6A22A50-5067-4AB2-B2B1-6C8EFADD8A99}" src="https://github.com/user-attachments/assets/b0213680-83c7-4867-a0d4-bdd24357cf52" />

 Test với thời gian
 ab -t 30 -c 50 http://192.168.136.131/
<img width="446" height="405" alt="{1943E225-3F4B-4200-917F-A1986C2959E3}" src="https://github.com/user-attachments/assets/18eee4c7-b8a0-4987-a572-294b25d08bdc" />

Test post login form
```
echo "email=test@test.com&password=123" > /tmp/post.txt

ab -n 200 -c 20 \
   -p /tmp/post.txt \
   -T "application/x-www-form-urlencoded" \
   http://192.168.136.131/login.php
```
<img width="488" height="400" alt="{D380178E-CE4C-4E4B-A8D5-EA0BF280B8E2}" src="https://github.com/user-attachments/assets/4fe2224f-4d7c-439e-a2fa-0e48fad92466" />
  
ab -n 2000 -c 100 -k -s 10 http://192.168.136.131/: Gửi tổng cộng 2000 request tới server, với 100 request chạy cùng lúc, dùng keep-alive và timeout 10 giây  
<img width="465" height="396" alt="{6391E239-1261-44FC-8C1F-CE1210B743EF}" src="https://github.com/user-attachments/assets/66c29f81-7204-4c6d-9627-0c23efebc90b" />

Bash script dùng để so sánh trước/sau khi sửa 
```
#!/bin/bash

benchmark() {
    URL="$1"

    echo "=== Benchmark: $URL ==="

    for i in 1 2 3; do
        echo "--- Run $i ---"

        ab -n 1000 -c 50 -q "$URL" 2>/dev/null \
        | grep -E "Requests per second|Time per request|Failed"
    done
}

echo "=== BEFORE ==="
benchmark http://192.168.136.131/

echo ""
echo "Reloading nginx..."
sudo systemctl reload nginx

echo ""
echo "=== AFTER ==="
benchmark http://192.168.136.131/
```
<img width="490" height="405" alt="{051EC35B-3AF6-47D1-B7AE-341880050CFE}" src="https://github.com/user-attachments/assets/8f2a3334-f1dc-40dc-9db3-33eea4774ecc" />

### JMeter
JMeter mạnh hơn ab vì có thể mô phỏng kịch bản người dùng thực (login, duyệt, mua hàng, logout). Hỗ trợ nhiều protocol, phân tán tải qua nhiều máy, và xuất báo cáo HTML chuyên nghiệp.Là phần mềm có giao diện đồ họa (GUI)  
Ví dụ: Giả lập 1000 người vào trang chủ -> đăng nhập -> tìm sản phẩm -> thêm vào giỏ hàng -> thanh toán.  

sudo apt install -y openjdk-17-jre-headless
```
# Tải JMeter 5.6 (version ổn định)
wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar xzf apache-jmeter-5.6.3.tgz
sudo mv apache-jmeter-5.6.3 /opt/jmeter
echo 'export PATH=/opt/jmeter/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

jmeter --version
```
<img width="862" height="424" alt="{D11B6CEC-B61E-4322-A0B6-599DECAF342A}" src="https://github.com/user-attachments/assets/9ef4e90d-c3fd-4614-8e22-611e1c0d199c" />
Giả lập test:  Kịch bản: 50 user, login → xem trang → logout  
<img width="805" height="432" alt="{9FE8B8FD-59A7-4515-8E7B-5A90E1DCED41}" src="https://github.com/user-attachments/assets/c3e16d16-8aa6-4cf3-bf01-fa3eec8115b7" />
jmeter -n -t test_plan.jmx -l result.jtl -e -o report/
<img width="819" height="187" alt="{B6670161-556D-4AA7-8FF2-10E0B69ACA37}" src="https://github.com/user-attachments/assets/9459ecb6-1625-457f-8af8-b8c38c5b8514" />

 ## Giám sát Log
Log là nơi ghi lại mọi thứ xảy ra trong hệ thống.  
access.log cho biết ai truy cập gì, error.log cho biết gì đang hỏng, biết xem log sẽ nhanh chóng fix.  
sudo nano /etc/nginx/nginx.conf: cấu hình cho log chi tiết
```
http {
    log_format detailed '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" '
                        'cache=$upstream_cache_status '     # HIT/MISS/BYPASS
                        'upstream=$upstream_addr '          # backend nào xử lý
                        'rt=$request_time '                 # thời gian server xử lý
                        'uct=$upstream_connect_time '       # thời gian kết nối backend
                        'urt=$upstream_response_time';      # thời gian backend phản hồi

    access_log /var/log/nginx/access.log detailed buffer=16k flush=5s;
    error_log  /var/log/nginx/error.log warn;
}
```
<img width="662" height="363" alt="{12D75064-40E8-4B15-9147-566CE5F4B6F2}" src="https://github.com/user-attachments/assets/b9665f2a-988e-4229-ae3e-0029767fc020" />
Tìm lượng truy cập nhiều nhất
```
sudo awk '{print $1}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -rn | head -10
```
  <img width="435" height="58" alt="{69C44254-6228-437A-A0EE-528CA4370F02}" src="https://github.com/user-attachments/assets/f00836e6-49df-4880-8a2d-f552d3796bef" />
Tìm lỗi 4xx/5xx
```
sudo awk '$9 ~ /^[45]/ {print $9, $7}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -rn | head -10
```
theo dõi log theo thời gian thực
```
sudo tail -f /var/log/nginx/error.log | grep --color -E "error|crit|emerg"
```
<img width="618" height="134" alt="{E6343DB0-B1D0-49E0-AA87-FE91FC25BB6A}" src="https://github.com/user-attachments/assets/325c44ed-047f-4e52-a9c7-5dac37b07cf8" />

cài đặt tránh đầy disk, tự động reset log 
sudo nano /etc/logrotate.d/nginx
```
/var/log/nginx/*.log {
    daily                    # xoay mỗi ngày
    missingok
    rotate 30                # giữ 30 ngày
    compress                 # nén file cũ thành .gz
    delaycompress            # nén sau 1 ngày
    notifempty
    sharedscripts
    postrotate
        nginx -s reopen   
    endscript
}
```
### Prometheus + Grafana
Nâng cao về phần prometheus + grafana

Prometheus kéo (pull) metrics từ các target theo định kỳ (mặc định 15s) và lưu vào time-series database. Grafana kết nối vào Prometheus để vẽ dashboard. Hai công cụ này là chuẩn công nghiệp cho monitoring production
#### Cài prometheus
```
# Tạo user hệ thống (không có home, không login)
sudo useradd --no-create-home --shell /bin/false prometheus
# Tải Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.51.0/prometheus-2.51.0.linux-amd64.tar.gz
tar xzf prometheus-2.51.0.linux-amd64.tar.gz
cd prometheus-2.51.0.linux-amd64
```
<img width="907" height="425" alt="{A8400D83-37AF-4C69-B7A4-029895E78871}" src="https://github.com/user-attachments/assets/8989735b-d0ef-4dd9-b8ec-08285fc12135" />

```
# Cài vào hệ thống
sudo cp prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp -r consoles console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```
<img width="830" height="66" alt="{E63A2399-3BCB-4C26-8D64-3FCDA6ED86B9}" src="https://github.com/user-attachments/assets/3afaa4d0-ead9-4b54-ae36-8f8d69d575e1" />

sudo nano /etc/prometheus/prometheus.yml

<img width="613" height="378" alt="{4ED3806E-28FB-4C8C-B4D7-D5E75B5EBC2C}" src="https://github.com/user-attachments/assets/95e02410-89b1-42ae-91da-9a9a8002e22a" />

sudo nano /etc/systemd/system/prometheus.service
```
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --storage.tsdb.retention.time=30d \
    --web.listen-address=0.0.0.0:9090

Restart=always

[Install]
WantedBy=multi-user.target
```
<img width="947" height="344" alt="{B17CECFF-91B1-4CB4-85AB-24E93C3EED76}" src="https://github.com/user-attachments/assets/8f22e20c-2254-447d-8973-35a1991db958" />

#### CÀI NODE EXPORTER — metrics CPU/RAM/Disk
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xzf node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
```
<img width="875" height="344" alt="{CF478EF2-141F-43A4-ADE2-D158F7A04D2F}" src="https://github.com/user-attachments/assets/f32d82e9-446b-4a69-ac2b-ff575f6e022d" />

sudo nano /etc/systemd/system/node_exporter.service
```
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes
Restart=always

[Install]
WantedBy=multi-user.target

```
### CÀI NGINX EXPORTER
```
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v1.1.0/nginx-prometheus-exporter_1.1.0_linux_amd64.tar.gz
tar xzf nginx-prometheus-exporter_1.1.0_linux_amd64.tar.gz
sudo cp nginx-prometheus-exporter /usr/local/bin/
```
<img width="731" height="472" alt="{BCFBDE3B-D61E-4F8F-8D66-EAF42EC72998}" src="https://github.com/user-attachments/assets/7cc023df-a2a9-4999-a977-5d29d86155cc" />

 ### ALERT RULES
 Cài đặt cảnh báo 
 sudo nano /etc/prometheus/alert_rules.yml  
 ```
groups:
  - name: server_alerts
    rules:
      # Cảnh báo khi CPU > 80% trong 5 phút liên tục
      - alert: HighCPU
        expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU cao: {{ $labels.instance }}"
          description: "CPU = {{ $value | printf \"%.1f\" }}%"

      # Cảnh báo khi RAM còn < 20%
      - alert: LowMemory
        expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 20
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "RAM thấp: {{ $labels.instance }}"
          description: "RAM còn = {{ $value | printf \"%.1f\" }}%"

      # Cảnh báo khi Disk > 85%
      - alert: DiskAlmostFull
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 85
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Disk gần đầy: {{ $labels.instance }}"

      # Cảnh báo khi tỷ lệ lỗi Nginx > 5%
      - alert: HighErrorRate
        expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) / rate(nginx_http_requests_total[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Tỷ lệ lỗi 5xx cao trên Nginx"
```
 
 <img width="879" height="420" alt="{0769C713-12EB-495D-BB7A-37409AE4DCF2}" src="https://github.com/user-attachments/assets/0fea265d-087b-4bed-b3f9-395e0a432aae" />

 ## CÀI GRAFANA
```
sudo apt install -y apt-transport-https software-properties-common
wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana.gpg

sudo nano /etc/apt/sources.list.d/grafana.list
deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main

```
```
sudo apt update
sudo apt install -y grafana

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```
<img width="919" height="410" alt="{6E9842CE-81E9-4911-AC9A-CD6A4C02935B}" src="https://github.com/user-attachments/assets/84a9240a-93ea-4fb4-a0fa-f10f5f2f2042" />
pass mặc định: admin/admin
<img width="955" height="471" alt="{773BA1BF-E221-4A65-BAEC-E8BABB2134ED}" src="https://github.com/user-attachments/assets/f96bcc2a-8190-4c13-99b9-220ff60ce346" />

```
# Thêm Prometheus làm data source:
# Configuration → Data Sources → Add → Prometheus
# URL: http://localhost:9090 → Save & Test

# Import dashboard có sẵn
# Dashboard → Import → nhập ID:
# 1860  = Node Exporter Full (CPU/RAM/Disk/Network)
# 9614  = Nginx
# 7362  = MySQL Overview
```

sudo nano /etc/nginx/sites-enabled/default
<img width="826" height="369" alt="{10835F03-EFDD-4B29-9C6C-428FFB98A968}" src="https://github.com/user-attachments/assets/346a523c-ed64-4484-889b-163ed49463d7" />

### ELK Stack 
ELK = Elasticsearch + Logstash + Kibana. Chuyên xử lý log quy mô lớn — thu thập, parse, index và visualize hàng triệu dòng log/ngày. Phù hợp khi Prometheus  không đủ, cần phân tích log chi tiết  
```
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
    | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

sudo nano /etc/apt/sources.list.d/elastic-8.x.list
deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
    https://artifacts.elastic.co/packages/8.x/apt stable main

sudo apt update && sudo apt install -y elasticsearch
sudo systemctl start elasticsearch && sudo systemctl enable elasticsearch

sudo apt install -y kibana
sudo systemctl start kibana && sudo systemctl enable kibana
# Kibana: http://192.168.136.131:5601
```
<img width="958" height="466" alt="{BFACDC05-5E99-433E-9FE4-C05879431F66}" src="https://github.com/user-attachments/assets/1316865e-7b31-4c5e-9366-2560f705aebf" />

  ---

  
# Các vấn đề thường gặp về web
## Lỗi 403, 404, 500 và cách khắc phục.
**Lỗi 403:** Server hiểu request của bạn, nhưng từ chối phục vụ vì không đủ quyền. File có đó nhưng Nginx/PHP-FPM không được phép đọc. Trong LEMP stack, lỗi này xảy ra ở nhiều tầng: quyền file hệ thống, cấu hình Nginx, hoặc SELinux/AppArmor.
<img width="333" height="146" alt="{A6FA0673-57DC-45D0-A3AC-A48FA72E0533}" src="https://github.com/user-attachments/assets/5f40fba8-4fd3-475d-a962-7b28a958fc6f" />

1. Sai quyền
Nginx chạy với user www-data. Nếu file trong /var/www/html/ không cho phép www-data đọc, Nginx sẽ trả về 403. Quyền thư mục phải là 755 (executable = có thể duyệt vào), file phải là 644 (readable).

Chẩn đoán: xem quyền hiện tại
ls -la /var/www/html/
stat /var/www/html/index.php

Xem Nginx đang chạy với user nào ps aux | grep nginx

www-data là user/group mặc định của Nginx trên Ubuntu sudo chown -R www-data:www-data /var/www/html/

Thư mục cần 755: owner đọc/ghi/thực thi, group+other chỉ đọc/thực thi
sudo find /var/www/html -type d -exec chmod 755 {} ;

File cần 644: owner đọc/ghi, group+other chỉ đọc
sudo find /var/www/html -type f -exec chmod 644 {} ;

3. không có file index.php
Check error log để xác nhận nguyên nhân
sudo tail -20 /var/log/nginx/error.log  

Nếu hiện ra directory index of ... is forbidden => thiếu index.php
```
sudo nano /etc/nginx/sites-available/default
server {
    listen 80;
    server_name 192.168.136.131;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}

```
3.PHP-FPM socket k hoạt động hoặc không đúng
sudo systemctl status php8.1-fpm: xem có hoạt động không
ls /var/run/php/: tìm đúng đường dẫn socket
grep fastcgi_pass /etc/nginx/sites-enabled/*: kiểm tra nginx dùng đúng socket chưa

**404** :Server không tìm thấy tài nguyên được yêu cầu. Nghe đơn giản nhưng trong LEMP stack với PHP framework (Laravel, WordPress...), nguyên nhân phổ biến không phải do file không tồn tại — mà do Nginx chưa cấu hình rewrite URL nên không chuyển request đến index.php của framework để routing

1. Thiếu try_file - framework routing không hoạt động
   Thiết lập trong file: sudo nano /etc/nginx/sites-available/default
```
server {
    listen 80;
    server_name 192.168.136.131;
    root /var/www/html/public; 
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
   ```
sudo nginx -t && sudo systemctl reload nginx

2. Sai document root - nginx tìm sai thư mục
Mỗi framework có cấu trúc thư mục riêng. Laravel để file public vào /public, WordPress để ở root. Nếu cấu hình root sai, Nginx tìm file ở thư mục không đúng và trả 404.
  ````
# Kiểm tra root đang cấu hình
grep -n "root" /etc/nginx/sites-enabled/default

# Laravel: root phải trỏ đến /public
root /var/www/html/public;

# WordPress: root trỏ đến thư mục chứa wp-config.php
root /var/www/html;
```` 
3. trang 404 tùy chỉnh và logging
 404 không tránh được hoàn toàn (link cũ, typo URL...). Ta cần trang 404 đẹp thay vì trang mặc định xấu xí, và theo dõi 404 nhiều để tìm broken link.
```
server {
    # Trang 404 tùy chỉnh
    error_page 404 /404.html;
    location = /404.html {
        root /var/www/html/errors;
        internal; # chỉ dùng nội bộ, không truy cập trực tiếp
    }

    # Trang 50x tùy chỉnh
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html/errors;
        internal;
    }
```

}
