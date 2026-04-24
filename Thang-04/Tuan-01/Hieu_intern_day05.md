# Triển khai ứng dụng mail server Zimbra
## Cài đặt email server zimbra trên Ubuntu 22.04

* Tắt auto update
<img width="605" height="70" alt="image" src="https://github.com/user-attachments/assets/0a6c0f03-a3e5-4020-8581-8977903646c3" />

* Cài IP tĩnh
<img width="596" height="284" alt="image" src="https://github.com/user-attachments/assets/746d2e9d-1f2d-4ca8-bdfe-86dcc2af0f7d" />

* Chỉnh hostname,  /etc/hosts
<img width="545" height="203" alt="image" src="https://github.com/user-attachments/assets/9fc1450c-5821-4ade-a273-5ed835a05448" />


* Tắt ipv6
<img width="527" height="369" alt="image" src="https://github.com/user-attachments/assets/9fdc049d-5ad5-4d2e-ab96-cfd5d0e7fcfc" />

<img width="730" height="375" alt="image" src="https://github.com/user-attachments/assets/731ef4cd-487f-40d8-b8a9-8acf7115de2a" />

* Cài và cấu hình DNS nội bộ (dnsmasq)
<img width="628" height="374" alt="image" src="https://github.com/user-attachments/assets/b56cae9f-9247-4cf3-994a-2734eb37111f" />

* Cài đặt firewall
<img width="505" height="397" alt="image" src="https://github.com/user-attachments/assets/01aab918-ceb5-47e0-969c-c8240a379bac" />

* Cài đặt gói zimbra cho ubuntu 22.04
<img width="893" height="183" alt="image" src="https://github.com/user-attachments/assets/d5b7f4af-b170-480e-abbe-3ac1ce0a0f6d" />

* Giao diện sau khi cài
<img width="627" height="394" alt="image" src="https://github.com/user-attachments/assets/c5e2753f-f1cb-45d3-a012-e04ba01cf1f0" />

* Cài mật khẩu cho zimbra
<img width="569" height="398" alt="image" src="https://github.com/user-attachments/assets/cb7ae056-7c1f-4bb7-9365-33f2bf3048ca" />

* Lưu cấu hình và chạy
<img width="641" height="397" alt="image" src="https://github.com/user-attachments/assets/e3f63539-ebe9-4244-9023-47d4e25c55b4" />

giao diện thành công:
<img width="859" height="319" alt="image" src="https://github.com/user-attachments/assets/d688159c-e7ed-4abd-b296-e62e1deb5ea6" />

#### Tạo user mới 
<img width="673" height="288" alt="image" src="https://github.com/user-attachments/assets/7aa6c644-bca5-423c-9cf8-03b2e54bcbd2" />


#### thiết lập chính sách mật khẩu 
<img width="849" height="393" alt="image" src="https://github.com/user-attachments/assets/3ddc8d3a-3929-45a4-ba30-79efd8019693" />

#### Thiết lập Chữ ký & Forward
<img width="857" height="380" alt="image" src="https://github.com/user-attachments/assets/9a28e0b5-b19f-4f56-9c64-e5998ee24466" />
<img width="854" height="284" alt="image" src="https://github.com/user-attachments/assets/40501703-ab07-4dae-98ca-6b30c745096f" />

#### Tìm ID Mailbox & Chỉnh sửa Quota
<img width="403" height="74" alt="image" src="https://github.com/user-attachments/assets/974761ad-57a5-4914-b591-53dd80df6519" />

<img width="839" height="233" alt="image" src="https://github.com/user-attachments/assets/aeff5ba8-1b71-4970-8d15-0eeb44afd6b6" />
Chỉnh sửa quota để tránh làm "tràn" ổ cứng máy chủ
<img width="839" height="314" alt="image" src="https://github.com/user-attachments/assets/459075e2-b27d-4ab7-8d9a-28c7004c8daa" />

#### Đổi mk admin
su - zimbra -c "zmprov sp admin@domain.com *mật_khẩu_mới* ""

#### Kiểm tra Log gửi/nhận
* Xem log thời gian thực (theo dõi)
tail -f /var/log/zimbra.log
<img width="830" height="133" alt="image" src="https://github.com/user-attachments/assets/0e19c15b-2777-450b-b1a9-1ec31f70ebfe" />

* Lọc log để xem quá trình gửi nhận cụ thể:
cat /var/log/zimbra.log | grep "postfix/lmtp"
<img width="892" height="353" alt="image" src="https://github.com/user-attachments/assets/b69aa348-96ab-4634-9d14-1f22b3aeb38d" />

* log liên quan đến Amavis
grep -i "amavis" /var/log/zimbra.log | tail -n 50

#### Backup,Restore
* Tạo file script tự động backup, restore(1 user, 1 server)
<img width="904" height="371" alt="image" src="https://github.com/user-attachments/assets/3fd6d9a1-a037-4110-ab24-f27376d10cba" />

* chạy backup thủ công 
<img width="658" height="381" alt="image" src="https://github.com/user-attachments/assets/f19af92a-396b-4e4d-9e24-5768f8590b36" />
echo "0 2 * * * /opt/zimbra/zimbra_backup_complete.sh backup" | crontab - : backup tự động 2h sáng
  * Backup tất cả
/opt/zimbra/zimbra_backup_complete.sh backup

  * Backup 1 user
/opt/zimbra/zimbra_backup_complete.sh backup nguyenvana@example.com.vn

  * List backup
/opt/zimbra/zimbra_backup_complete.sh list
<img width="560" height="316" alt="image" src="https://github.com/user-attachments/assets/76d8f746-873d-4324-bfd6-b63386d511f3" />

  * Cleanup
/opt/zimbra/zimbra_backup_complete.sh cleanup 30

* /opt/zimbra/zimbra_backup_complete.sh restore : xem hướng dẫn restore
<img width="895" height="393" alt="image" src="https://github.com/user-attachments/assets/2b336d15-5e36-45b7-964b-de81f94afe5a" />
  restore được nhưng hiện đang không có dữ liệu gì

#### Chuyển data sang node khác
* Backup từ server cũ
/opt/zimbra/zimbra_migration_complete.sh backup-old mail.old.com

* Copy sang server mới
/opt/zimbra/zimbra_migration_complete.sh copy mail.old.com mail.new.com

* Prepare users trên server mới
/opt/zimbra/zimbra_migration_complete.sh prepare-new mail.new.com

* Restore trên server mới
/opt/zimbra/zimbra_migration_complete.sh restore-new mail.new.com

* Verify
/opt/zimbra/zimbra_migration_complete.sh verify mail.old.com mail.new.com
  
---

# HAProxy
## Tổng quan về giải pháp HAProxy
HAProxy viết tắt của High Availability Proxy giống với Load Balancer, là một phần mềm cân bằng tải open source cho TCP/HTTP.   
Mục đích chính của nó là dùng để cải thiện hiệu năng và tính tin cậy của hệ thống bằng cách dẫn tải đến các server khác.

Sơ đồ cơ bản :
Client -> HAProxy -> Các apache

## Thuật ngữ sử dụng trong HAProxy

#### Frontend
Frontend được dùng để xác định cách mà các yêu cầu được điều hướng tới backend, và nó được định nghĩa trong phần frontend của cấu hình HAProxy
* Nơi cấu hình địa chỉ IP và Port
* Nơi định nghĩa các quy tắc để điều hướng yêu cầu xuống phía sau

#### Backend
Một backend là một tập các servers nhận các requests được chuyển tiếp
* Nơi cấu hình thuật toán cân bằng tải
* Nơi cấu hình Health Check

#### ACL
 Access Control List là danh sách kiểm soát truy cập được sử dụng để xem xét các điều kiện và tiến hành thực thi hành động dựa vào kết quả xem xét đó

#### Proxy
Proxy đóng vai trò là một người trung chuyển đứng giữa client và Server. Thay vì client kết nối trực tiếp đến Server, nó sẽ gửi yêu cầu đến Proxy, Proxy sẽ xử lý và chuyển yêu cầu đó đến Server phù hợp nhất.

#### Sticky Sessions
Đảm bảo cùng một client luôn kết nối đến cùng một backend server. Nếu mỗi lần nhấn chuột lại bị chuyển sang một Server khác, client sẽ bị văng khỏi hệ thống


## các kiểu load balancing

#### Layer 4 (Transport) — Cân bằng tải TCP/UDP
Cách đơn giản nhất để cân bằng tải lưu lượng mạng tới nhiều server là sử dụng layer 4 load balancing. Cân bằng tải theo cách này sẽ chuyển tiếp lưu lượng truy cập của người dùng dựa trên phạm vi IP và port. 
* Ưu điểm: Rất nhanh, ít tiêu tốn CPU, tốt cho database
* Nhược điểm: Không thể áp dụng rules phức tạp dựa vào URL/Cookie

#### Layer 7 (Application) — Cân bằng tải HTTP/HTTPS
Các thiết lập cân bằng tải layer 4 và layer 7 đều sử dụng bộ cân bằng tải để hướng lưu lượng truy cập tới một trong những backend servers
* Ưu điểm: Linh hoạt, có thể route dựa vào URL, Cookie, Header
* Nhược điểm: Chậm hơn Layer 4

## Các giải thuật cân bằng tải phổ biến
#### Round Robin
Đây là thuật toán cân bằng tải (Load Balancing) đơn giản và phổ biến nhất. Các request sẽ được chuyển đến server theo lượt
* Ưu điểm: Đơn giản, dễ dàng, cân bằng tốt khi server giống nhau
* Nhược điểm: Không xem xét tải thực tế của server

#### Least Connections
Các request sẽ được chuyển đến server nào có ít kết nối đến nó nhất
* Ưu điểm: Tốt khi server có tài nguyên khác nhau
* Nhược điểm: Không xem xét thời gian kết nối

#### Source
Các request được chuyển đến server bằng các hash của IP người dùng. Phương pháp này giúp người dùng đảm bảo luôn kết nối tới một server

#### URI Hash
URI Hash là một thuật toán cân bằng tải dựa trên địa chỉ cụ thể (URL/URI) mà người dùng đang truy cập.

## Tìm hiểu file cấu hình HAProxy
Cấu trúc file Cấu hình (thường nằm tại /etc/haproxy/haproxy.cfg)
* File này chia làm 4 khối chính theo thứ tự từ trên xuống dưới:
  * Global: Cấu hình hệ thống (quyền hạn user, số kết nối tối đa).
  * Defaults: Các thiết lập mặc định (thời gian chờ timeout, chế độ http/tcp).
  * Frontend: Tiếp nhận yêu cầu. Định nghĩa IP/Port tiếp nhận yêu cầu và quy tắc lọc (ACL).
  * Backend: Xử lý yêu cầu. Chứa danh sách các Server thật và thuật toán chia tải.
## Cài đặt, triển khai Haproxy + Keepalive cho Apache trên Ubuntu 22.04
#### Giai đoạn chuẩn bị
* Cài 4 ubuntu server
  * 192.168.254.100  ← HAProxy Master (Server 1)
  * 192.168.254.120  ← HAProxy Backup (Server 2)
  * 192.168.254.121  ← Apache  1
  * 192.168.254.122  ← Apache  2
  * 192.168.254.50   <- VIP









